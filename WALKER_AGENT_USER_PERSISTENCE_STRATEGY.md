# Walker Agent User Persistence & Admin Update Strategy

## Ensuring User Customizations Survive Admin Flow Updates

This document provides detailed technical strategies for maintaining user data, integrations, and customizations when admin users update Walker agent flow templates in Langflow.

---

## Table of Contents

1. [The Challenge](#the-challenge)
2. [Architecture Overview](#architecture-overview)
3. [Database Schema for User Configs](#database-schema-for-user-configs)
4. [Flow Variable Management](#flow-variable-management)
5. [Config Injection System](#config-injection-system)
6. [Admin Update Workflow](#admin-update-workflow)
7. [Migration Scripts](#migration-scripts)
8. [User Reconnection Process](#user-reconnection-process)
9. [Rollback Procedures](#rollback-procedures)
10. [Frontend Integration](#frontend-integration)

---

## The Challenge

### Problem Statement

Walker agents are system-level flows maintained by admins but customized by individual users. Each user may have:

- **Unique Data Integrations**: BigQuery projects, custom API endpoints, ZeroDB instances
- **Personal Thresholds**: Minimum confidence scores, revenue thresholds, suggestion limits
- **Notification Preferences**: Channels, quiet hours, frequency settings
- **Historical Context**: Past suggestions, feedback, execution history

When an admin updates a Walker agent flow (e.g., adds new data source, improves AI prompt, fixes bugs), users must:
1. **Retain all customizations** without manual reconfiguration
2. **Automatically adopt improvements** in the updated flow
3. **Seamlessly transition** with zero downtime
4. **Maintain data continuity** across versions

### Current Langflow Limitations

Langflow's built-in features do not provide:
- User-specific flow instances with variable overrides
- Automatic config migration between flow versions
- Per-user state management for shared flows

### Our Solution

Implement a **hybrid persistence system** combining:
1. **Database-backed user configs** (PostgreSQL)
2. **Runtime variable injection** (custom Langflow component)
3. **Version-aware migration scripts** (Alembic)
4. **Graceful degradation** (fallback to defaults if migration fails)

---

## Architecture Overview

### Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          USER LAYER                             │
├─────────────────────────────────────────────────────────────────┤
│  User A Config        User B Config        User C Config        │
│  - tenant_id: A       - tenant_id: B       - tenant_id: C       │
│  - bigquery: proj-a   - bigquery: proj-b   - bigquery: proj-c   │
│  - min_conf: 0.8      - min_conf: 0.7      - min_conf: 0.9      │
└───────────────┬────────────────┬────────────────┬───────────────┘
                │                │                │
                ↓                ↓                ↓
┌─────────────────────────────────────────────────────────────────┐
│                   PERSISTENCE LAYER (PostgreSQL)                │
├─────────────────────────────────────────────────────────────────┤
│  walker_agent_user_configs table                                │
│  - Stores JSON configs per user/tenant/agent                    │
│  - Tracks flow_version for migration detection                  │
│  - Updated via API endpoints                                    │
└───────────────┬────────────────┬────────────────┬───────────────┘
                │                │                │
                ↓                ↓                ↓
┌─────────────────────────────────────────────────────────────────┐
│                   INJECTION LAYER (Langflow)                    │
├─────────────────────────────────────────────────────────────────┤
│  LoadUserConfig Component (First node in flow)                  │
│  1. Fetches config from database                                │
│  2. Detects version mismatch                                    │
│  3. Triggers migration if needed                                │
│  4. Injects variables into flow context                         │
└───────────────┬────────────────┬────────────────┬───────────────┘
                │                │                │
                ↓                ↓                ↓
┌─────────────────────────────────────────────────────────────────┐
│                   FLOW EXECUTION LAYER                          │
├─────────────────────────────────────────────────────────────────┤
│  SEO Walker Flow v1.1.0 (Shared Template)                       │
│  - Uses injected variables from LoadUserConfig                  │
│  - Executes with user-specific customizations                   │
│  - Admin updates flow → All users inherit improvements          │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **User Initial Setup**
   ```
   User completes setup wizard
   → Frontend POST /api/v1/walker-agents/config
   → Backend stores in walker_agent_user_configs
   → Config includes flow_id and current version
   ```

2. **Daily Execution**
   ```
   Schedule Trigger fires
   → LoadUserConfig component runs
   → Fetches user config from DB
   → Checks version match
   → Injects variables into flow
   → Flow executes with user's data sources
   ```

3. **Admin Updates Flow**
   ```
   Admin saves updated flow (v1.1.0)
   → Backend detects version increment
   → Migration script analyzes changes
   → Prepares transformation mappings
   → Notifies users of update availability
   ```

4. **User Next Execution**
   ```
   Schedule Trigger fires
   → LoadUserConfig detects version mismatch
   → Runs migration (1.0.0 → 1.1.0)
   → Updates config in database
   → Injects updated variables
   → Flow executes with new version
   ```

---

## Database Schema for User Configs

### Core Table: `walker_agent_user_configs`

```sql
CREATE TYPE config_status_enum AS ENUM ('active', 'migrating', 'failed', 'archived');

CREATE TABLE walker_agent_user_configs (
    -- Identity
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    agent_type agent_type_enum NOT NULL,

    -- Flow Versioning
    flow_id TEXT NOT NULL, -- e.g., "seo-walker-v1"
    flow_version TEXT NOT NULL, -- e.g., "1.1.0"
    flow_hash TEXT, -- SHA256 of flow JSON for integrity check

    -- Configuration Storage
    config_json JSONB NOT NULL,
    config_schema_version TEXT NOT NULL DEFAULT '1.0.0',

    -- Migration Tracking
    migration_status config_status_enum DEFAULT 'active',
    previous_version TEXT,
    migration_attempted_at TIMESTAMP,
    migration_completed_at TIMESTAMP,
    migration_error TEXT,

    -- Metadata
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_executed_at TIMESTAMP,
    execution_count INTEGER DEFAULT 0,

    -- Constraints
    UNIQUE(tenant_id, user_id, agent_type),
    CHECK (flow_version ~ '^[0-9]+\.[0-9]+\.[0-9]+$'), -- Semantic versioning
    CHECK (jsonb_typeof(config_json) = 'object')
);

-- Indexes for fast lookups
CREATE INDEX idx_user_configs_tenant_agent ON walker_agent_user_configs(tenant_id, agent_type);
CREATE INDEX idx_user_configs_user ON walker_agent_user_configs(user_id);
CREATE INDEX idx_user_configs_version ON walker_agent_user_configs(flow_version);
CREATE INDEX idx_user_configs_status ON walker_agent_user_configs(migration_status);
CREATE INDEX idx_user_configs_config_json ON walker_agent_user_configs USING gin(config_json);
```

### Config JSON Structure

```json
{
  "version": "1.0.0",
  "tenant_id": "uuid-string",

  "data_sources": {
    "microservice": {
      "url": "http://onside:8000/api/v1/seo/analyze",
      "api_key_ref": "WALKER_AGENT_API_KEY_ONSIDE_SEO",
      "timeout": 30,
      "retry_attempts": 3
    },
    "bigquery": {
      "enabled": true,
      "project_id": "user-custom-project",
      "dataset": "analytics",
      "credentials_secret": "bigquery_credentials_user_123"
    },
    "zerodb": {
      "enabled": true,
      "url": "http://zerodb:6379",
      "database": 0
    },
    "postgresql_cache": {
      "enabled": true,
      "max_age_days": 30
    }
  },

  "processing": {
    "ai_model": "gpt-4",
    "temperature": 0.7,
    "max_tokens": 2000,
    "custom_prompt_additions": "Focus on local SEO opportunities.",
    "suggestion_limit": 5
  },

  "thresholds": {
    "min_confidence_score": 0.75,
    "min_revenue_increase": 1000,
    "priority_rules": {
      "high": {"confidence": 0.85, "revenue": 5000},
      "medium": {"confidence": 0.7, "revenue": 1000},
      "low": {"confidence": 0.5, "revenue": 500}
    }
  },

  "notifications": {
    "channels": ["email", "whatsapp"],
    "email": {
      "enabled": true,
      "frequency": "instant",
      "recipients": ["user@example.com"]
    },
    "whatsapp": {
      "enabled": true,
      "phone_number": "+1234567890",
      "quiet_hours": {
        "enabled": true,
        "start": "22:00",
        "end": "08:00",
        "timezone": "America/New_York"
      }
    },
    "chat": {
      "enabled": false
    }
  },

  "execution": {
    "auto_execute_high_confidence": false,
    "require_approval_threshold": 0.9,
    "max_auto_executions_per_day": 3
  },

  "metadata": {
    "setup_completed": true,
    "onboarding_version": "1.0.0",
    "custom_tags": ["local-business", "ecommerce"]
  }
}
```

### Version History Table (Optional)

```sql
CREATE TABLE walker_agent_config_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_id UUID NOT NULL REFERENCES walker_agent_user_configs(id) ON DELETE CASCADE,
    version TEXT NOT NULL,
    config_snapshot JSONB NOT NULL,
    changed_by UUID REFERENCES users(id),
    change_reason TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_config_versions_config ON walker_agent_config_versions(config_id);
CREATE INDEX idx_config_versions_created ON walker_agent_config_versions(created_at);
```

---

## Flow Variable Management

### Langflow Variable System

Langflow flows can define variables that are injected at runtime. We leverage this for user-specific customizations.

### Variable Definition in Flow

When building a Walker agent flow in Langflow UI:

1. **Right-click** any input node (e.g., "Tenant ID Input")
2. Select **"Mark as Variable"**
3. Set variable properties:
   - **Name**: `tenant_id` (must match config JSON key)
   - **Type**: `string`, `number`, `boolean`, `object`
   - **Required**: `true` or `false`
   - **Default Value**: Fallback if user config missing

### Variable Naming Convention

Use hierarchical dot notation matching config JSON structure:

| Config Path | Variable Name | Example Value |
|-------------|---------------|---------------|
| `tenant_id` | `tenant_id` | `"uuid-string"` |
| `data_sources.bigquery.project_id` | `bigquery_project_id` | `"my-project"` |
| `thresholds.min_confidence_score` | `min_confidence_score` | `0.75` |
| `notifications.email.enabled` | `email_notifications_enabled` | `true` |

### Flow Metadata File

Langflow stores flow configuration in JSON. Add custom metadata section:

```json
{
  "flow_id": "seo-walker-v1",
  "flow_version": "1.1.0",
  "flow_name": "SEO Walker Agent",
  "nodes": [...],
  "edges": [...],
  "custom_metadata": {
    "user_configurable": true,
    "config_schema_version": "1.0.0",
    "required_variables": [
      {
        "name": "tenant_id",
        "type": "string",
        "description": "Tenant UUID for data filtering",
        "required": true
      },
      {
        "name": "min_confidence_score",
        "type": "number",
        "description": "Minimum confidence threshold (0.0-1.0)",
        "required": false,
        "default": 0.7
      }
    ],
    "optional_data_sources": [
      "bigquery",
      "zerodb",
      "postgresql_cache"
    ]
  }
}
```

---

## Config Injection System

### Custom Langflow Component: `LoadUserConfig`

This component is the **first node** in every Walker agent flow. It:
1. Fetches user config from database
2. Detects version mismatches
3. Triggers migration if needed
4. Injects variables into flow context

### Component Code

```python
# File: production-backend/langflow/custom_components/walker_agents/load_user_config.py

from langflow.custom import CustomComponent
from langflow.field_typing import Text
from sqlalchemy import create_engine, text
from typing import Dict, Any
import os
import json
import logging

logger = logging.getLogger(__name__)

class LoadUserConfigComponent(CustomComponent):
    display_name = "Load User Config"
    description = "Loads user-specific Walker agent configuration with version migration"
    documentation = "https://docs.engarde.media/walker-agents/config-persistence"

    def build_config(self):
        return {
            "tenant_id": {
                "display_name": "Tenant ID",
                "info": "UUID of the tenant",
                "required": True
            },
            "agent_type": {
                "display_name": "Agent Type",
                "options": ["seo", "content", "paid_ads", "audience_intelligence"],
                "required": True
            },
            "flow_version": {
                "display_name": "Current Flow Version",
                "info": "Semantic version of this flow (e.g., 1.1.0)",
                "required": True
            },
            "database_url": {
                "display_name": "Database URL",
                "password": True,
                "value": os.getenv("DATABASE_PUBLIC_URL")
            }
        }

    def build(
        self,
        tenant_id: str,
        agent_type: str,
        flow_version: str,
        database_url: str
    ) -> Dict[str, Any]:
        """
        Load user config and handle version migration
        """
        engine = create_engine(database_url)

        # Fetch user config
        query = text("""
            SELECT
                id,
                config_json,
                flow_version,
                migration_status
            FROM walker_agent_user_configs
            WHERE tenant_id = :tenant_id
              AND agent_type = :agent_type
            LIMIT 1
        """)

        with engine.connect() as conn:
            result = conn.execute(
                query,
                {"tenant_id": tenant_id, "agent_type": agent_type}
            ).fetchone()

        if not result:
            # User config doesn't exist, create default
            logger.warning(f"No config found for tenant {tenant_id}, agent {agent_type}. Creating default.")
            default_config = self._create_default_config(tenant_id, agent_type, flow_version)
            self._save_config(engine, tenant_id, agent_type, flow_version, default_config)
            return default_config

        config_id, config_json, stored_version, migration_status = result

        # Check version mismatch
        if stored_version != flow_version:
            logger.info(f"Version mismatch: stored={stored_version}, current={flow_version}. Migrating...")

            # Trigger migration
            migrated_config = self._migrate_config(
                engine,
                config_id,
                config_json,
                stored_version,
                flow_version,
                agent_type
            )

            return migrated_config

        # Version matches, return config as-is
        return config_json

    def _create_default_config(
        self,
        tenant_id: str,
        agent_type: str,
        flow_version: str
    ) -> Dict[str, Any]:
        """
        Create default configuration for new user
        """
        return {
            "version": flow_version,
            "tenant_id": tenant_id,
            "data_sources": {
                "microservice": {"enabled": True},
                "bigquery": {"enabled": False},
                "zerodb": {"enabled": True},
                "postgresql_cache": {"enabled": True}
            },
            "thresholds": {
                "min_confidence_score": 0.7,
                "min_revenue_increase": 1000
            },
            "notifications": {
                "channels": ["email"],
                "email": {"enabled": True}
            }
        }

    def _save_config(
        self,
        engine,
        tenant_id: str,
        agent_type: str,
        flow_version: str,
        config_json: Dict[str, Any]
    ):
        """
        Save config to database
        """
        # Get user_id from tenant (assume first user)
        user_query = text("""
            SELECT id FROM users
            WHERE tenant_id = :tenant_id
            LIMIT 1
        """)

        with engine.connect() as conn:
            user_result = conn.execute(user_query, {"tenant_id": tenant_id}).fetchone()
            user_id = user_result[0] if user_result else None

            if not user_id:
                logger.error(f"No user found for tenant {tenant_id}")
                return

            insert_query = text("""
                INSERT INTO walker_agent_user_configs
                (tenant_id, user_id, agent_type, flow_id, flow_version, config_json, config_schema_version)
                VALUES
                (:tenant_id, :user_id, :agent_type, :flow_id, :flow_version, :config_json, '1.0.0')
            """)

            conn.execute(insert_query, {
                "tenant_id": tenant_id,
                "user_id": user_id,
                "agent_type": agent_type,
                "flow_id": f"{agent_type}-walker-v1",
                "flow_version": flow_version,
                "config_json": json.dumps(config_json)
            })
            conn.commit()

    def _migrate_config(
        self,
        engine,
        config_id: str,
        old_config: Dict[str, Any],
        old_version: str,
        new_version: str,
        agent_type: str
    ) -> Dict[str, Any]:
        """
        Migrate config from old version to new version
        """
        # Import migration functions
        from .migrations import get_migration_path, apply_migrations

        migration_path = get_migration_path(old_version, new_version)
        logger.info(f"Migration path: {' -> '.join(migration_path)}")

        # Mark as migrating
        with engine.connect() as conn:
            update_query = text("""
                UPDATE walker_agent_user_configs
                SET migration_status = 'migrating',
                    migration_attempted_at = NOW(),
                    previous_version = :old_version
                WHERE id = :config_id
            """)
            conn.execute(update_query, {"config_id": config_id, "old_version": old_version})
            conn.commit()

        try:
            # Apply migrations step by step
            migrated_config = apply_migrations(old_config, migration_path, agent_type)

            # Update database with new config
            with engine.connect() as conn:
                success_query = text("""
                    UPDATE walker_agent_user_configs
                    SET config_json = :config_json,
                        flow_version = :new_version,
                        migration_status = 'active',
                        migration_completed_at = NOW(),
                        migration_error = NULL,
                        updated_at = NOW()
                    WHERE id = :config_id
                """)
                conn.execute(success_query, {
                    "config_id": config_id,
                    "config_json": json.dumps(migrated_config),
                    "new_version": new_version
                })
                conn.commit()

            logger.info(f"Migration successful: {old_version} -> {new_version}")
            return migrated_config

        except Exception as e:
            logger.error(f"Migration failed: {str(e)}")

            # Mark as failed
            with engine.connect() as conn:
                fail_query = text("""
                    UPDATE walker_agent_user_configs
                    SET migration_status = 'failed',
                        migration_error = :error
                    WHERE id = :config_id
                """)
                conn.execute(fail_query, {"config_id": config_id, "error": str(e)})
                conn.commit()

            # Return old config with warning
            old_config["_migration_failed"] = True
            old_config["_migration_error"] = str(e)
            return old_config
```

### Migration Functions Module

```python
# File: production-backend/langflow/custom_components/walker_agents/migrations.py

from typing import Dict, Any, List
import logging

logger = logging.getLogger(__name__)

def get_migration_path(from_version: str, to_version: str) -> List[str]:
    """
    Calculate migration path between versions
    Returns list of versions to migrate through
    """
    # Parse semantic versions
    from_parts = [int(x) for x in from_version.split('.')]
    to_parts = [int(x) for x in to_version.split('.')]

    # Simple case: direct migration exists
    path = [from_version, to_version]

    # TODO: Handle complex paths (e.g., 1.0.0 -> 1.1.0 -> 2.0.0)
    # For now, assume direct migration

    return path

def apply_migrations(
    config: Dict[str, Any],
    migration_path: List[str],
    agent_type: str
) -> Dict[str, Any]:
    """
    Apply series of migrations to config
    """
    current_config = config.copy()

    for i in range(len(migration_path) - 1):
        from_ver = migration_path[i]
        to_ver = migration_path[i + 1]

        migration_func = get_migration_function(from_ver, to_ver, agent_type)

        if migration_func:
            logger.info(f"Applying migration: {from_ver} -> {to_ver}")
            current_config = migration_func(current_config)
        else:
            logger.warning(f"No migration function for {from_ver} -> {to_ver}, skipping")

    return current_config

def get_migration_function(from_version: str, to_version: str, agent_type: str):
    """
    Get migration function for version pair
    """
    # Migration registry
    migrations = {
        ("1.0.0", "1.1.0"): migrate_1_0_0_to_1_1_0,
        ("1.1.0", "1.2.0"): migrate_1_1_0_to_1_2_0,
        ("1.2.0", "2.0.0"): migrate_1_2_0_to_2_0_0,
    }

    key = (from_version, to_version)
    return migrations.get(key)

# ============================================================================
# MIGRATION FUNCTIONS
# ============================================================================

def migrate_1_0_0_to_1_1_0(config: Dict[str, Any]) -> Dict[str, Any]:
    """
    Migration: 1.0.0 -> 1.1.0

    Changes:
    - Added data_sources.search_console (new integration)
    - Renamed thresholds.min_confidence_score -> thresholds.min_confidence_threshold
    - Added notifications.push (new channel)
    """
    new_config = config.copy()

    # Add Search Console (disabled by default)
    if "data_sources" in new_config:
        new_config["data_sources"]["search_console"] = {
            "enabled": False,
            "property_url": None
        }

    # Rename threshold key
    if "thresholds" in new_config:
        if "min_confidence_score" in new_config["thresholds"]:
            new_config["thresholds"]["min_confidence_threshold"] = \
                new_config["thresholds"].pop("min_confidence_score")

    # Add push notifications (disabled by default)
    if "notifications" in new_config:
        new_config["notifications"]["push"] = {
            "enabled": False
        }

    # Update version
    new_config["version"] = "1.1.0"

    return new_config

def migrate_1_1_0_to_1_2_0(config: Dict[str, Any]) -> Dict[str, Any]:
    """
    Migration: 1.1.0 -> 1.2.0

    Changes:
    - Added execution.auto_execute_high_confidence flag
    - Added metadata.custom_tags array
    """
    new_config = config.copy()

    # Add auto-execution settings
    if "execution" not in new_config:
        new_config["execution"] = {}

    new_config["execution"]["auto_execute_high_confidence"] = False

    # Add custom tags
    if "metadata" not in new_config:
        new_config["metadata"] = {}

    new_config["metadata"]["custom_tags"] = []

    new_config["version"] = "1.2.0"

    return new_config

def migrate_1_2_0_to_2_0_0(config: Dict[str, Any]) -> Dict[str, Any]:
    """
    Migration: 1.2.0 -> 2.0.0 (BREAKING CHANGES)

    Changes:
    - Restructured data_sources (flattened hierarchy)
    - Changed thresholds to priority_rules with rule engine
    - Removed notifications.channels array (redundant)
    """
    new_config = {
        "version": "2.0.0",
        "tenant_id": config.get("tenant_id")
    }

    # Restructure data sources
    old_sources = config.get("data_sources", {})
    new_config["integrations"] = {
        "microservice_url": old_sources.get("microservice", {}).get("url"),
        "bigquery_project": old_sources.get("bigquery", {}).get("project_id"),
        "zerodb_enabled": old_sources.get("zerodb", {}).get("enabled", True)
    }

    # Transform thresholds to priority rules
    old_thresholds = config.get("thresholds", {})
    new_config["priority_rules"] = [
        {
            "name": "high_priority",
            "conditions": {
                "confidence_min": 0.85,
                "revenue_min": 5000
            },
            "priority": "high"
        },
        {
            "name": "medium_priority",
            "conditions": {
                "confidence_min": 0.7,
                "revenue_min": 1000
            },
            "priority": "medium"
        }
    ]

    # Simplify notifications
    old_notifications = config.get("notifications", {})
    new_config["notifications"] = {
        "email": old_notifications.get("email", {}),
        "whatsapp": old_notifications.get("whatsapp", {}),
        "chat": old_notifications.get("chat", {}),
        "push": old_notifications.get("push", {})
    }

    return new_config
```

---

## Admin Update Workflow

### Step-by-Step Process

#### 1. Admin Makes Changes to Flow

Admin opens Langflow UI and modifies a Walker agent flow:
- Adds new data source (e.g., Google Search Console API)
- Improves AI prompt template for better suggestions
- Fixes bug in suggestion builder component
- Optimizes HTTP request retry logic

#### 2. Admin Increments Version

Before saving:
1. Update flow metadata:
   ```json
   {
     "flow_version": "1.1.0",  // Was 1.0.0
     "changelog": "Added Search Console integration, improved AI prompts"
   }
   ```

2. Document changes in `CHANGELOG.md`:
   ```markdown
   ## [1.1.0] - 2026-01-15

   ### Added
   - Google Search Console API integration for more accurate ranking data
   - Custom prompt additions field for user-specific AI instructions

   ### Improved
   - AI prompt template now considers historical trends more effectively
   - Suggestion confidence scoring algorithm

   ### Fixed
   - Bug where BigQuery timeout caused flow failure
   ```

#### 3. Admin Exports Updated Flow

```bash
# Export flow JSON
langflow export --flow-id seo-walker-v1 --output seo-walker-v1.1.0.json
```

#### 4. Admin Creates Migration Script

```python
# File: production-backend/alembic/versions/20260115_migrate_walker_configs_v1_1_0.py

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = '20260115_walker_configs_v1_1_0'
down_revision = 'previous_revision_id'

def upgrade():
    """
    Migrate user configs from 1.0.0 to 1.1.0
    """
    # Update all SEO walker configs
    op.execute("""
        UPDATE walker_agent_user_configs
        SET
            config_json = config_json || '{"data_sources": {"search_console": {"enabled": false}}}'::jsonb,
            config_schema_version = '1.1.0',
            updated_at = NOW()
        WHERE agent_type = 'seo'
          AND flow_version = '1.0.0'
    """)

    # Update flow_version field
    op.execute("""
        UPDATE walker_agent_user_configs
        SET flow_version = '1.1.0'
        WHERE agent_type = 'seo'
          AND flow_version = '1.0.0'
    """)

def downgrade():
    """
    Rollback migration
    """
    # Remove search_console key
    op.execute("""
        UPDATE walker_agent_user_configs
        SET
            config_json = config_json - 'data_sources' -> 'search_console',
            config_schema_version = '1.0.0',
            flow_version = '1.0.0'
        WHERE agent_type = 'seo'
          AND flow_version = '1.1.0'
    """)
```

#### 5. Admin Tests Migration

```bash
# Run migration on staging environment
railway run --service Main --environment staging alembic upgrade head

# Test flow execution
curl -X POST https://langflow-staging.engarde.media/api/v1/flows/seo-walker-v1/run \
  -H "Authorization: Bearer ${LANGFLOW_API_KEY}" \
  -d '{"inputs": {"tenant_id": "test-tenant-uuid"}}'

# Verify migrated config loaded correctly
psql $DATABASE_URL -c "
  SELECT config_json->'data_sources'->'search_console'
  FROM walker_agent_user_configs
  WHERE tenant_id = 'test-tenant-uuid' AND agent_type = 'seo'
"
```

#### 6. Admin Deploys to Production

```bash
# Run migration
railway run --service Main --environment production alembic upgrade head

# Import updated flow
langflow import --file seo-walker-v1.1.0.json

# Verify deployment
railway logs --service langflow-server --filter "seo-walker"
```

#### 7. Admin Notifies Users

Send email to all affected users:

```html
<h2>Your SEO Walker Agent has been upgraded! 🚀</h2>

<p>We've released version 1.1.0 of the SEO Walker Agent with exciting new features:</p>

<ul>
  <li><strong>Google Search Console Integration:</strong> Get even more accurate ranking insights</li>
  <li><strong>Custom Prompt Additions:</strong> Add your own context to AI analysis</li>
  <li><strong>Improved Confidence Scoring:</strong> More reliable suggestion prioritization</li>
</ul>

<p>Your customizations and data integrations have been automatically preserved.</p>

<p><a href="https://app.engarde.media/walker-agents/seo/config">Review Your Settings</a></p>

<p>Questions? <a href="https://docs.engarde.media/walker-agents/v1.1.0">View Full Changelog</a></p>
```

---

## Migration Scripts

### Handling Different Migration Types

#### Type 1: Additive Changes (Non-Breaking)

New features added, all existing functionality preserved.

**Example**: Adding Search Console integration (disabled by default)

```python
def migrate_additive(config: Dict[str, Any]) -> Dict[str, Any]:
    """
    Safe migration - only adds new keys with defaults
    """
    new_config = config.copy()

    # Add new data source (disabled)
    if "data_sources" in new_config:
        new_config["data_sources"]["search_console"] = {
            "enabled": False,
            "property_url": None,
            "credentials_secret": None
        }

    return new_config
```

#### Type 2: Rename/Restructure (Potentially Breaking)

Keys renamed, hierarchy changed, but data preserved.

**Example**: Renaming `min_confidence_score` to `min_confidence_threshold`

```python
def migrate_rename(config: Dict[str, Any]) -> Dict[str, Any]:
    """
    Rename keys while preserving values
    """
    new_config = config.copy()

    # Rename key
    if "thresholds" in new_config:
        thresholds = new_config["thresholds"]
        if "min_confidence_score" in thresholds:
            thresholds["min_confidence_threshold"] = thresholds.pop("min_confidence_score")

    return new_config
```

#### Type 3: Transformative (Breaking Changes)

Data structure fundamentally changed, requires transformation logic.

**Example**: Converting flat thresholds to rule engine

```python
def migrate_transformative(config: Dict[str, Any]) -> Dict[str, Any]:
    """
    Transform data structure (breaking change)
    """
    new_config = config.copy()

    # Convert thresholds to priority rules
    old_thresholds = config.get("thresholds", {})

    new_config["priority_rules"] = [
        {
            "name": "high_priority",
            "conditions": {
                "confidence_min": old_thresholds.get("min_confidence_score", 0.7) + 0.15,
                "revenue_min": old_thresholds.get("min_revenue_increase", 1000) * 5
            },
            "actions": ["auto_notify", "highlight"]
        },
        {
            "name": "medium_priority",
            "conditions": {
                "confidence_min": old_thresholds.get("min_confidence_score", 0.7),
                "revenue_min": old_thresholds.get("min_revenue_increase", 1000)
            },
            "actions": ["notify"]
        }
    ]

    # Remove old structure
    if "thresholds" in new_config:
        del new_config["thresholds"]

    return new_config
```

#### Type 4: Deprecation

Old features removed, users must reconfigure.

```python
def migrate_deprecation(config: Dict[str, Any]) -> Dict[str, Any]:
    """
    Remove deprecated features, prompt user for new setup
    """
    new_config = config.copy()

    # Check if user was using deprecated feature
    if "old_feature" in config:
        # Flag for user attention
        new_config["_migration_warnings"] = [
            {
                "type": "deprecation",
                "feature": "old_feature",
                "message": "This feature has been removed. Please configure 'new_feature' instead.",
                "action_required": True,
                "documentation": "https://docs.engarde.media/walker-agents/new-feature"
            }
        ]

        # Remove old feature
        del new_config["old_feature"]

    return new_config
```

---

## User Reconnection Process

### Automatic Reconnection (No User Action)

For additive or minor changes:

1. User's next scheduled flow execution
2. LoadUserConfig detects version mismatch
3. Migration runs automatically
4. Config updated in database
5. Flow executes with new version
6. User receives notification of upgrade

### Manual Reconnection (User Action Required)

For breaking changes or deprecations:

1. Migration script flags config as `requires_user_action`
2. User receives email: "Action required: Update your SEO Walker configuration"
3. User clicks link → Opens configuration wizard
4. Wizard shows:
   - What changed
   - Why action is needed
   - Current settings
   - Recommended new settings
5. User completes wizard
6. Config updated, flow resumes

### Reconnection UI Flow

```typescript
// Frontend component for user reconnection

interface MigrationWizardProps {
  agentType: 'seo' | 'content' | 'paid_ads' | 'audience_intelligence';
  oldVersion: string;
  newVersion: string;
  warnings: MigrationWarning[];
}

function MigrationWizard({ agentType, oldVersion, newVersion, warnings }: MigrationWizardProps) {
  const [step, setStep] = useState(0);
  const [config, setConfig] = useState(null);

  const steps = [
    {
      title: "What's Changed",
      component: <ChangelogView oldVersion={oldVersion} newVersion={newVersion} />
    },
    {
      title: "Review Warnings",
      component: <WarningsList warnings={warnings} />
    },
    {
      title: "Reconfigure",
      component: <ConfigurationForm config={config} onChange={setConfig} />
    },
    {
      title: "Confirm",
      component: <ConfirmationView config={config} />
    }
  ];

  const handleComplete = async () => {
    await api.post(`/walker-agents/${agentType}/config`, config);
    showToast("Configuration updated successfully!");
    router.push(`/walker-agents/${agentType}`);
  };

  return (
    <div>
      <h1>Update {agentType.toUpperCase()} Walker Agent Configuration</h1>
      <p>Version {oldVersion} → {newVersion}</p>

      <Stepper activeStep={step} steps={steps.map(s => s.title)} />

      {steps[step].component}

      <div>
        {step > 0 && <Button onClick={() => setStep(step - 1)}>Back</Button>}
        {step < steps.length - 1 && <Button onClick={() => setStep(step + 1)}>Next</Button>}
        {step === steps.length - 1 && <Button onClick={handleComplete}>Complete Update</Button>}
      </div>
    </div>
  );
}
```

---

## Rollback Procedures

### When to Rollback

- Migration fails for significant % of users (>5%)
- New flow version has critical bugs
- Performance degradation detected
- User complaints exceed threshold

### Rollback Process

#### 1. Database Rollback

```bash
# Rollback Alembic migration
railway run --service Main alembic downgrade -1

# Verify configs reverted
psql $DATABASE_URL -c "
  SELECT flow_version, COUNT(*)
  FROM walker_agent_user_configs
  WHERE agent_type = 'seo'
  GROUP BY flow_version
"
```

#### 2. Flow Rollback

```bash
# Import previous flow version
langflow import --file seo-walker-v1.0.0.json --force

# Verify
curl https://langflow.engarde.media/api/v1/flows/seo-walker-v1
```

#### 3. User Notification

```
Subject: SEO Walker Agent Rollback

We've temporarily rolled back the SEO Walker Agent to version 1.0.0 while we investigate issues with version 1.1.0.

Your customizations and data are safe. The agent will continue operating normally.

We'll notify you when version 1.1.0 is ready for re-deployment.
```

### Rollback Safety

- All migrations must have `downgrade()` function
- Config version history table allows point-in-time recovery
- Flow JSON exports stored in version control
- Automated rollback triggers based on error rate

---

## Frontend Integration

### User Configuration UI

```typescript
// Frontend API calls for managing user configs

import axios from 'axios';

const api = axios.create({
  baseURL: 'https://api.engarde.media/api/v1',
  headers: {
    Authorization: `Bearer ${getUserToken()}`
  }
});

// Get current config
export async function getUserConfig(agentType: string) {
  const response = await api.get(`/walker-agents/${agentType}/config`);
  return response.data;
}

// Update config
export async function updateUserConfig(agentType: string, config: any) {
  const response = await api.put(`/walker-agents/${agentType}/config`, config);
  return response.data;
}

// Check for migration warnings
export async function checkMigrationStatus(agentType: string) {
  const response = await api.get(`/walker-agents/${agentType}/migration-status`);
  return response.data;
}

// Trigger manual migration
export async function triggerMigration(agentType: string, newVersion: string) {
  const response = await api.post(`/walker-agents/${agentType}/migrate`, {
    target_version: newVersion
  });
  return response.data;
}
```

### Configuration Form Component

```typescript
import { useState, useEffect } from 'react';
import { getUserConfig, updateUserConfig } from './api';

function WalkerAgentConfigForm({ agentType }) {
  const [config, setConfig] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadConfig();
  }, [agentType]);

  const loadConfig = async () => {
    const data = await getUserConfig(agentType);
    setConfig(data);
    setLoading(false);
  };

  const handleSave = async () => {
    await updateUserConfig(agentType, config);
    alert('Configuration saved!');
  };

  if (loading) return <div>Loading...</div>;

  return (
    <form>
      <h2>{agentType.toUpperCase()} Walker Agent Configuration</h2>

      {/* Data Sources */}
      <section>
        <h3>Data Sources</h3>

        <label>
          <input
            type="checkbox"
            checked={config.data_sources.bigquery.enabled}
            onChange={(e) => setConfig({
              ...config,
              data_sources: {
                ...config.data_sources,
                bigquery: { ...config.data_sources.bigquery, enabled: e.target.checked }
              }
            })}
          />
          Enable BigQuery Integration
        </label>

        {config.data_sources.bigquery.enabled && (
          <input
            type="text"
            placeholder="BigQuery Project ID"
            value={config.data_sources.bigquery.project_id || ''}
            onChange={(e) => setConfig({
              ...config,
              data_sources: {
                ...config.data_sources,
                bigquery: { ...config.data_sources.bigquery, project_id: e.target.value }
              }
            })}
          />
        )}
      </section>

      {/* Thresholds */}
      <section>
        <h3>Thresholds</h3>

        <label>
          Minimum Confidence Score:
          <input
            type="range"
            min="0"
            max="1"
            step="0.05"
            value={config.thresholds.min_confidence_score}
            onChange={(e) => setConfig({
              ...config,
              thresholds: { ...config.thresholds, min_confidence_score: parseFloat(e.target.value) }
            })}
          />
          {config.thresholds.min_confidence_score}
        </label>

        <label>
          Minimum Revenue Increase:
          <input
            type="number"
            value={config.thresholds.min_revenue_increase}
            onChange={(e) => setConfig({
              ...config,
              thresholds: { ...config.thresholds, min_revenue_increase: parseInt(e.target.value) }
            })}
          />
        </label>
      </section>

      {/* Notifications */}
      <section>
        <h3>Notifications</h3>

        <label>
          <input
            type="checkbox"
            checked={config.notifications.email.enabled}
            onChange={(e) => setConfig({
              ...config,
              notifications: {
                ...config.notifications,
                email: { ...config.notifications.email, enabled: e.target.checked }
              }
            })}
          />
          Email Notifications
        </label>

        <label>
          <input
            type="checkbox"
            checked={config.notifications.whatsapp.enabled}
            onChange={(e) => setConfig({
              ...config,
              notifications: {
                ...config.notifications,
                whatsapp: { ...config.notifications.whatsapp, enabled: e.target.checked }
              }
            })}
          />
          WhatsApp Notifications
        </label>
      </section>

      <button type="button" onClick={handleSave}>Save Configuration</button>
    </form>
  );
}
```

---

## Summary

This user persistence strategy ensures:

✅ **Zero Data Loss**: User customizations preserved across admin updates
✅ **Automatic Migration**: Most updates require no user action
✅ **Version Control**: Track config history, rollback if needed
✅ **Graceful Degradation**: Fallback to defaults if migration fails
✅ **User Control**: Clear UI for reviewing and updating settings
✅ **Admin Flexibility**: Easy to deploy improvements without disrupting users

### Next Steps

1. **Implement `LoadUserConfig` component** in Langflow custom components
2. **Create migration registry** with version-specific transformations
3. **Build frontend configuration UI** for user settings management
4. **Set up monitoring** for migration success rates
5. **Document admin update workflow** in internal wiki
6. **Create rollback runbook** for operations team

---

**Document Version**: 1.0.0
**Last Updated**: 2026-01-05
**Related Documents**:
- WALKER_AGENT_END_TO_END_FLOW_BUILDING_GUIDE.md
- LANGFLOW_WALKER_AGENTS_SETUP_INSTRUCTIONS.md
- WALKER_AGENTS_IMPLEMENTATION.md
