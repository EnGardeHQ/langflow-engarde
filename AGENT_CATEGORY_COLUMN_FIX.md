# Agent Display Issues - Complete Fix

## Issues Summary

### 1. My Agents Page (FIXED)
The "My Agents" page at https://app.engarde.media/agents/my-agents was showing zero agents despite 11 agents existing in the database for the demo user.

#### Root Cause
Database schema mismatch: The SQLAlchemy `AIAgent` model defined TWO fields that didn't exist in the PostgreSQL `ai_agents` table:
- `agent_category`
- `is_system_agent`

#### Error Details
```
psycopg2.errors.UndefinedColumn: column ai_agents.agent_category does not exist
psycopg2.errors.UndefinedColumn: column ai_agents.is_system_agent does not exist
Location: /app/app/routers/agents_api.py:1467
Endpoint: GET /api/agents/installed/
```

### 2. Agent Gallery Page (FIXED)
The Agent Gallery page at https://app.engarde.media/agent-gallery was showing zero agents.

#### Root Cause
The gallery queries the `marketplace_agents` table for public agents (`is_public == True` and `status == "approved"`), but the 11 EnGarde agents existed only in the `ai_agents` table. No synchronization had occurred.

#### Difference from "My Agents"
- **My Agents** (https://app.engarde.media/agents/my-agents): Shows user's personal installed agents from `ai_agents` table
- **Agent Gallery** (https://app.engarde.media/agent-gallery): Shows public marketplace agents from `marketplace_agents` table

## Solution Implemented

### Migrations Created

1. **add_agent_category_column.sql**
   - Added `agent_category VARCHAR(50) NOT NULL DEFAULT 'en_garde'`
   - Created index: `idx_ai_agents_agent_category`

2. **add_is_system_agent_column.sql**
   - Added `is_system_agent BOOLEAN NOT NULL DEFAULT false`
   - Created index: `idx_ai_agents_is_system_agent`

3. **sync_agents_to_marketplace.sql**
   - Syncs all agents from `ai_agents` to `marketplace_agents` table
   - Sets `is_public = true` and `status = 'approved'` for gallery visibility
   - Maps agent types to marketplace categories
   - Links source agents via `source_agent_id` foreign key
   - Prevents duplicates with NOT EXISTS check

### Migrations Applied
Successfully applied to Railway PostgreSQL database on 2025-12-21

### Verification
- Both columns successfully added with correct defaults
- All 11 demo user agents now queryable from `ai_agents` table
- All 11 agents synced to `marketplace_agents` table
- No UndefinedColumn errors in logs for these fields
- Database queries working correctly

## Model Definitions
From `app/models/core.py:592-593`:
```python
agent_category = Column(String(50), default="en_garde", nullable=False, index=True)  # "walker" or "en_garde"
is_system_agent = Column(Boolean, default=False, nullable=False, index=True)  # True for Walker agents
```

## Results

### My Agents Page
- API endpoint `/api/agents/installed/` functioning properly
- All 11 agents display at https://app.engarde.media/agents/my-agents
- Database queries work correctly

### Agent Gallery Page
- All 11 agents synced to `marketplace_agents` with `is_public=true` and `status='approved'`
- Agents visible at https://app.engarde.media/agent-gallery
- Gallery API endpoints now return agents successfully:
  - `/api/gallery/browse` - returns 11 agents
  - `/api/gallery/analytics` - tracks gallery metrics
  - `/api/gallery/filters` - provides category/tag filters

## Test Data Confirmed
Demo tenant (550e8400-e29b-41d4-a716-446655440000) has 11 agents:
- Ad Creative Testing Agent (walker_optimization)
- Audience Segmentation Agent (walker_audience)
- And 9 more agents

All with `agent_category = 'en_garde'` (default value)
