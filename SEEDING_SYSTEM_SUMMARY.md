# Database Seeding System - Implementation Summary

## Overview

A comprehensive automated database seeding system has been implemented for the EnGarde platform. This system provides versioned, idempotent seeding with automatic checks and interactive user prompts.

## Created Files

### SQL Scripts (2 files)

#### 1. create_seed_versions_table.sql
**Location:** `/Users/cope/EnGardeHQ/production-backend/scripts/create_seed_versions_table.sql`

**Purpose:** Creates the `database_seed_versions` table for tracking seed versions

**Features:**
- Tracks version, seed_type, description, timestamps
- Stores metadata in JSONB format
- Includes indexes for performance
- Self-documents with PostgreSQL comments
- Inserts initial schema version (0.0.0)

**Usage:**
```sql
-- Executed automatically by seeding scripts
psql -U engarde_user -d engarde -f create_seed_versions_table.sql
```

#### 2. seed_demo_data.sql
**Location:** `/Users/cope/EnGardeHQ/production-backend/scripts/seed_demo_data.sql`

**Purpose:** Version 1.0.0 demo data seed script

**Features:**
- Checks if version already exists (idempotent)
- Creates 4 demo brands, 3 users, 11 platform connections
- Uses ON CONFLICT for safe re-running
- Records seed version after success
- Comprehensive output with verification

**Demo Data:**
- **Brands:** TechFlow, EcoStyle, GlobalEats, Team Testing
- **Users:** demo1@engarde.local, demo2@engarde.local, demo3@engarde.local
- **Password:** demo123 (all users)
- **Tenants:** 4 tenants with different plan tiers
- **Connections:** 11 platform connections

**Usage:**
```sql
psql -U engarde_user -d engarde -f seed_demo_data.sql
```

### Shell Scripts (5 files)

#### 3. check-seed-status.sh
**Location:** `/Users/cope/EnGardeHQ/scripts/check-seed-status.sh`

**Purpose:** Check if database seeding is needed

**Features:**
- Checks if seed versions table exists
- Queries current seed version
- Compares to expected version (1.0.0)
- Returns appropriate exit code
- Supports verbose and quiet modes

**Exit Codes:**
- 0 = Seed is current
- 1 = Seed is missing/outdated
- 2 = Error occurred

**Usage:**
```bash
# Basic check
./scripts/check-seed-status.sh

# Verbose output
./scripts/check-seed-status.sh --verbose

# Quiet mode (for scripts)
./scripts/check-seed-status.sh --quiet
```

#### 4. prompt-seed-database.sh
**Location:** `/Users/cope/EnGardeHQ/scripts/prompt-seed-database.sh`

**Purpose:** Interactive seeding prompt with user consent

**Features:**
- Displays detailed information about what will be seeded
- Prompts user for yes/no decision
- Creates seed versions table if needed
- Executes seed script
- Shows credentials after success
- Logs all operations

**Modes:**
- Interactive (default)
- Auto-yes (--yes flag)
- Skip check (--skip-check flag)

**Usage:**
```bash
# Interactive prompt
./scripts/prompt-seed-database.sh

# Auto-yes (for CI/CD)
./scripts/prompt-seed-database.sh --yes
```

#### 5. seed-database.sh
**Location:** `/Users/cope/EnGardeHQ/scripts/seed-database.sh`

**Purpose:** Manual database seeding (non-interactive)

**Features:**
- Checks for existing seed version
- Exits if already seeded (unless --force)
- Creates seed versions table
- Executes seed script
- Displays credentials
- Logs operations

**Usage:**
```bash
# Seed database
./scripts/seed-database.sh

# Force re-seed
./scripts/seed-database.sh --force
```

#### 6. reset-seed.sh
**Location:** `/Users/cope/EnGardeHQ/scripts/reset-seed.sh`

**Purpose:** Reset seed version tracking

**Features:**
- Shows current seed versions
- Prompts for confirmation (unless --yes)
- Deletes version record (NOT data)
- Supports specific version or all versions
- Safe operation (data preserved)

**Important:** Resets tracking only, does NOT delete actual data

**Usage:**
```bash
# Reset with confirmation
./scripts/reset-seed.sh

# Reset without confirmation
./scripts/reset-seed.sh --yes

# Reset specific version
./scripts/reset-seed.sh --version 1.0.0 --type demo_data

# Reset all versions
./scripts/reset-seed.sh --all --yes
```

#### 7. seed-status.sh
**Location:** `/Users/cope/EnGardeHQ/scripts/seed-status.sh`

**Purpose:** Display detailed seed information

**Features:**
- Shows all seed versions
- Displays seed metadata
- Shows data counts (verbose mode)
- Lists management commands
- Comprehensive status report

**Usage:**
```bash
# Basic status
./scripts/seed-status.sh

# Verbose with counts
./scripts/seed-status.sh --verbose
```

### Modified Files (1 file)

#### 8. dev-start.sh (Updated)
**Location:** `/Users/cope/EnGardeHQ/scripts/dev-start.sh`

**Changes:**
- Added `check_and_prompt_seeding()` function
- Integrated seed checking after services start
- Automatically prompts user if seeding needed
- Shows seed status before displaying URLs

**Integration Point:**
```bash
# After services are healthy
check_and_prompt_seeding

# Then display URLs
display_urls
```

### Documentation Files (3 files)

#### 9. AGENT_DEPLOYMENT_RULES.md (Updated)
**Location:** `/Users/cope/EnGardeHQ/.claude/AGENT_DEPLOYMENT_RULES.md`

**Changes:**
- Added "Database Seeding Protocol" section (500+ lines)
- Documented all workflows and commands
- Added agent integration rules
- Included troubleshooting guides
- Updated table of contents

**Key Sections:**
- Overview and architecture
- Current seed version details
- 4 seeding workflows
- 5 agent integration rules
- Best practices
- Quick reference
- Troubleshooting

#### 10. DATABASE_SEEDING_GUIDE.md (New)
**Location:** `/Users/cope/EnGardeHQ/scripts/DATABASE_SEEDING_GUIDE.md`

**Purpose:** Complete user guide for database seeding

**Contents:**
- Overview and architecture
- Quick start guide
- Command reference (all scripts)
- Integration with dev workflow
- Troubleshooting common issues
- Debug commands
- Advanced usage
- Best practices
- File locations

#### 11. test-seed-workflow.sh (New)
**Location:** `/Users/cope/EnGardeHQ/scripts/test-seed-workflow.sh`

**Purpose:** Interactive demo of seeding workflow

**Features:**
- Step-by-step demonstration
- Tests all commands
- Verifies data creation
- Tests idempotency
- Shows credentials
- Pauses between steps

**Usage:**
```bash
./scripts/test-seed-workflow.sh
```

## System Architecture

### Component Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                    Database Seeding System                      │
└────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌────────────────┐    ┌──────────────────┐
│  SQL Scripts  │    │ Shell Scripts  │    │  Integration     │
├───────────────┤    ├────────────────┤    ├──────────────────┤
│ • create_     │    │ • check-seed-  │    │ • dev-start.sh   │
│   seed_       │    │   status.sh    │    │   (automatic)    │
│   versions_   │    │ • prompt-seed- │    │                  │
│   table.sql   │    │   database.sh  │    │ • Agent rules    │
│               │    │ • seed-        │    │   (guidelines)   │
│ • seed_demo_  │    │   database.sh  │    │                  │
│   data.sql    │    │ • reset-seed.sh│    │ • Documentation  │
│   (v1.0.0)    │    │ • seed-        │    │   (guides)       │
│               │    │   status.sh    │    │                  │
└───────────────┘    └────────────────┘    └──────────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                              ▼
              ┌──────────────────────────────┐
              │  database_seed_versions      │
              │  (PostgreSQL Table)          │
              ├──────────────────────────────┤
              │ • version                    │
              │ • seed_type                  │
              │ • description                │
              │ • seeded_at                  │
              │ • seeded_by                  │
              │ • metadata (JSONB)           │
              └──────────────────────────────┘
```

### Workflow Integration

```
User runs: ./scripts/dev-start.sh
                │
                ▼
┌───────────────────────────────────────┐
│ 1. Start all services                 │
│ 2. Wait for health checks             │
│ 3. Check service endpoints            │
└───────────────┬───────────────────────┘
                │
                ▼
┌───────────────────────────────────────┐
│ check_and_prompt_seeding()            │
│                                       │
│ Calls: check-seed-status.sh --quiet  │
└───────────────┬───────────────────────┘
                │
        ┌───────┴────────┐
        ▼                ▼
┌──────────────┐  ┌────────────────────┐
│ Seed Current │  │ Seed Missing       │
│ (Exit 0)     │  │ (Exit 1)           │
└──────┬───────┘  └─────────┬──────────┘
       │                    │
       │                    ▼
       │         ┌─────────────────────────┐
       │         │ prompt-seed-database.sh │
       │         │                         │
       │         │ • Show info             │
       │         │ • Prompt user (y/n)     │
       │         └─────────┬───────────────┘
       │                   │
       │         ┌─────────┴─────────┐
       │         ▼                   ▼
       │   ┌──────────┐        ┌──────────┐
       │   │ User: y  │        │ User: n  │
       │   └────┬─────┘        └────┬─────┘
       │        │                   │
       │        ▼                   │
       │   ┌──────────────────┐    │
       │   │ Execute Seeding  │    │
       │   │ Show Credentials │    │
       │   └────┬─────────────┘    │
       │        │                   │
       └────────┴───────────────────┘
                │
                ▼
        ┌───────────────┐
        │ display_urls  │
        │ (Continue)    │
        └───────────────┘
```

## Key Features

### 1. Version Tracking

All seed operations are tracked in the `database_seed_versions` table:

```sql
CREATE TABLE database_seed_versions (
    id SERIAL PRIMARY KEY,
    version VARCHAR(50) NOT NULL UNIQUE,
    seed_type VARCHAR(100) NOT NULL,
    description TEXT,
    seeded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    seeded_by VARCHAR(255),
    seed_file VARCHAR(255),
    row_count INTEGER,
    metadata JSONB
);
```

### 2. Idempotent Seeding

All INSERT statements use ON CONFLICT to handle existing data:

```sql
INSERT INTO users (id, email, ...)
VALUES ('user-demo1', 'demo1@engarde.local', ...)
ON CONFLICT (email) DO UPDATE SET
    hashed_password = EXCLUDED.hashed_password;
```

### 3. Automatic Integration

Seeding is automatically checked during environment startup:

```bash
# In dev-start.sh
check_and_prompt_seeding() {
    if "${PROJECT_ROOT}/scripts/check-seed-status.sh" --quiet; then
        log_success "Database seed is current"
    else
        "${PROJECT_ROOT}/scripts/prompt-seed-database.sh"
    fi
}
```

### 4. Interactive Prompts

Users are asked for consent before seeding:

```
════════════════════════════════════════════════════════════════════════
                    DATABASE SEEDING REQUIRED
════════════════════════════════════════════════════════════════════════

Your database needs to be seeded with demo data.

This will create:
  • 4 demo brands (TechFlow, EcoStyle, GlobalEats, SharedTeam)
  • 3 demo users with credentials: demo1@engarde.local / demo123
  • Platform connections for testing
  • Sample campaign data

Do you want to seed the database now? (y/n)
>
```

### 5. Comprehensive Logging

All operations are logged for debugging:

```
/Users/cope/EnGardeHQ/logs/seed-database.log
```

## Demo Data Details

### Version 1.0.0 Includes:

#### Tenants (4)
- **tenant-techflow**: TechFlow Solutions (Professional)
- **tenant-ecostyle**: EcoStyle Fashion (Starter)
- **tenant-globaleats**: GlobalEats Delivery (Enterprise)
- **tenant-shared**: EnGarde Team Testing (Enterprise)

#### Users (3)
- **demo1@engarde.local** / demo123
  - Owns: TechFlow Solutions
  - Access: Team Testing Brand

- **demo2@engarde.local** / demo123
  - Owns: EcoStyle Fashion
  - Access: Team Testing Brand

- **demo3@engarde.local** / demo123
  - Owns: GlobalEats Delivery
  - Access: Team Testing Brand

#### Brands (4)
- **TechFlow Solutions**: B2B SaaS workflow automation
- **EcoStyle Fashion**: Sustainable fashion for eco-conscious consumers
- **GlobalEats Delivery**: Food delivery with global cuisine focus
- **Team Testing Brand**: Shared brand for collaborative testing

#### Platform Connections (11)
- TechFlow: Google Ads, LinkedIn, Google Analytics
- EcoStyle: Meta, Shopify, Pinterest
- GlobalEats: Google Ads, Meta, Google Analytics
- Shared: Google Ads, Meta

#### Additional Data
- Admin roles for each tenant
- Tenant-user associations
- Campaign structure foundation

## Usage Examples

### Example 1: First Time Setup

```bash
# Start development environment
./scripts/dev-start.sh

# Services start...
# Seeding check runs automatically
# User is prompted: "Do you want to seed the database now? (y/n)"
# User enters: y
# Database is seeded
# Credentials are displayed
# Environment startup completes
```

### Example 2: Check Status Anytime

```bash
# Quick check
./scripts/check-seed-status.sh

# Output:
# ℹ Checking database seed status...
# ✓ Seed version is current
# Status: CURRENT
# Version: 1.0.0
```

### Example 3: Force Re-seed

```bash
# Reset version tracking
./scripts/reset-seed.sh --yes

# Re-seed database
./scripts/seed-database.sh

# Output:
# ℹ Running seed script...
# 🌱 Starting Demo Data Seeding - Version 1.0.0
# ✓ Created 4 tenants
# ✓ Created 3 users
# ✓ Database seeded successfully
```

### Example 4: Detailed Status

```bash
./scripts/seed-status.sh --verbose

# Output shows:
# - Current seed version
# - Seed metadata
# - Data counts (users, brands, etc.)
# - Management commands
```

## Agent Integration

Agents must follow these rules when deploying:

### Rule 1: Always Check Seed Status
```bash
# Before marking deployment complete
/Users/cope/EnGardeHQ/scripts/check-seed-status.sh --quiet
if [ $? -ne 0 ]; then
    # Report that seeding is needed
fi
```

### Rule 2: Prompt User If Needed
```bash
# If seeding needed
/Users/cope/EnGardeHQ/scripts/prompt-seed-database.sh
```

### Rule 3: Verify Success
```bash
# After seeding
/Users/cope/EnGardeHQ/scripts/check-seed-status.sh --verbose
```

### Rule 4: Document in Reports
```markdown
## Database Seed Status

**Status:** Current
**Version:** 1.0.0
**Type:** demo_data

### Demo Credentials
- demo1@engarde.local / demo123
```

### Rule 5: Handle Errors Gracefully
```bash
# Check logs
cat /Users/cope/EnGardeHQ/logs/seed-database.log

# Reset and retry if needed
./scripts/dev-reset.sh
./scripts/dev-start.sh
```

## Testing

### Test the Complete Workflow

```bash
# Run interactive demo
./scripts/test-seed-workflow.sh

# This will:
# 1. Check current status
# 2. Show detailed info
# 3. Reset seed version
# 4. Seed database
# 5. Verify success
# 6. Query demo data
# 7. Test idempotency
# 8. Show final status
```

### Test Idempotency

```bash
# Run seed multiple times
./scripts/seed-database.sh --force
./scripts/seed-database.sh --force
./scripts/seed-database.sh --force

# Should succeed each time without errors
```

### Test Reset Cycle

```bash
# Reset and re-seed
./scripts/reset-seed.sh --yes
./scripts/seed-database.sh
./scripts/seed-status.sh
```

## Troubleshooting

### Common Commands

```bash
# Check seed status
./scripts/check-seed-status.sh

# View logs
cat /Users/cope/EnGardeHQ/logs/seed-database.log

# Query database directly
docker compose -f docker-compose.dev.yml exec -T postgres \
  psql -U engarde_user -d engarde -c \
  "SELECT * FROM database_seed_versions;"

# Full reset and re-seed
./scripts/dev-reset.sh
./scripts/dev-start.sh
```

## File Summary

**Total Files Created:** 11
- SQL Scripts: 2
- Shell Scripts: 5
- Modified Scripts: 1
- Documentation: 3

**Total Lines of Code:** ~3,500+
- SQL: ~200 lines
- Shell: ~1,500 lines
- Documentation: ~1,800 lines

## Next Steps

The seeding system is ready to use! Here's what to do:

1. **Test the workflow:**
   ```bash
   ./scripts/test-seed-workflow.sh
   ```

2. **Integrate into your routine:**
   - Use `./scripts/dev-start.sh` normally
   - System will prompt when seeding is needed

3. **Manage seeds as needed:**
   - Check status: `./scripts/check-seed-status.sh`
   - View details: `./scripts/seed-status.sh --verbose`
   - Re-seed: `./scripts/seed-database.sh --force`
   - Reset: `./scripts/reset-seed.sh`

4. **Refer to documentation:**
   - User guide: `/Users/cope/EnGardeHQ/scripts/DATABASE_SEEDING_GUIDE.md`
   - Agent rules: `/Users/cope/EnGardeHQ/.claude/AGENT_DEPLOYMENT_RULES.md`

## Success Criteria

All success criteria met:

- ✅ Version tracking in database
- ✅ Automatic check on deployment
- ✅ User prompt if seeding needed
- ✅ Integrated into dev workflow
- ✅ Management commands created
- ✅ Comprehensive documentation
- ✅ Agent deployment rules updated
- ✅ Test workflow provided

## Support

For questions or issues:

1. Check DATABASE_SEEDING_GUIDE.md
2. Review logs: `/Users/cope/EnGardeHQ/logs/seed-database.log`
3. Run status check: `./scripts/seed-status.sh --verbose`
4. Consult AGENT_DEPLOYMENT_RULES.md
5. Try full reset: `./scripts/dev-reset.sh && ./scripts/dev-start.sh`

---

**Implementation Date:** October 29, 2025
**System Version:** 1.0.0
**Status:** Production Ready
