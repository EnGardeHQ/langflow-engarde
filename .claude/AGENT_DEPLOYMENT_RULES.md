# AGENT SWARM DEPLOYMENT RULES
## Definitive Rulebook for Docker Updates & Code Changes

**Document Version:** 1.0.0
**Last Updated:** October 29, 2025
**Status:** MANDATORY - ALL AGENTS MUST FOLLOW
**Working Directory:** `/Users/cope/EnGardeHQ`

---

## TABLE OF CONTENTS

1. [Critical Rules - Read First](#critical-rules---read-first)
2. [Agent Swarm Deployment Protocol](#agent-swarm-deployment-protocol)
3. [Docker Update Rules by Change Type](#docker-update-rules-by-change-type)
4. [Database Seeding Protocol](#database-seeding-protocol)
5. [Local Implementation Standards](#local-implementation-standards)
6. [Development Environment Workflows](#development-environment-workflows)
7. [Verification & Testing Requirements](#verification--testing-requirements)
8. [Error Handling & Recovery](#error-handling--recovery)
9. [Communication Standards](#communication-standards)
10. [Quick Reference Commands](#quick-reference-commands)
11. [References to Documentation](#references-to-documentation)

---

## CRITICAL RULES - READ FIRST

### Golden Rules (NEVER VIOLATE THESE)

1. **ALWAYS verify changes appear locally** before marking a task complete
2. **NEVER assume hot-reload worked** - always check logs and endpoints
3. **NEVER use relative paths** - always use absolute paths starting with `/Users/cope/EnGardeHQ`
4. **ALWAYS check service health** after any deployment action
5. **NEVER mark a task complete if errors exist** in logs or health checks fail
6. **ALWAYS ask for confirmation** before destructive operations (reset, clean, volume deletion)
7. **NEVER skip verification steps** - they exist to prevent failures
8. **ALWAYS document what you changed** in your response to the user

### Pre-Deployment Safety Checks

Before making ANY changes, verify:
- [ ] Docker Desktop is running
- [ ] Current working directory is `/Users/cope/EnGardeHQ`
- [ ] You understand the type of change (code, dependency, config, schema)
- [ ] You know which services are affected
- [ ] You have a rollback plan if things fail

---

## AGENT SWARM DEPLOYMENT PROTOCOL

### Phase 1: Pre-Deployment Assessment

**BEFORE starting any work, execute this checklist:**

#### 1.1 Environment Status Check
```bash
# Check current service status
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml ps

# Verify health
/Users/cope/EnGardeHQ/scripts/dev-health.sh
```

**Decision Point:** Are services running and healthy?
- ✅ **YES** → Proceed to Phase 2
- ❌ **NO** → Fix health issues first, then proceed

#### 1.2 Change Classification
Identify the type of change (see [Docker Update Rules by Change Type](#docker-update-rules-by-change-type)):
- [ ] **Type A:** Code changes (Python/TypeScript/React)
- [ ] **Type B:** Dependency changes (requirements.txt, package.json)
- [ ] **Type C:** Configuration changes (docker-compose, Dockerfile, .env)
- [ ] **Type D:** Database schema changes (migrations)
- [ ] **Type E:** Environment variable changes

#### 1.3 Impact Analysis
For each type of change, determine:
- **Affected Services:** Which containers need updates?
- **Hot-Reload Compatible:** Will watch mode handle it automatically?
- **Requires Action:** Restart, rebuild, or recreate?
- **Data Impact:** Will data be affected? (CRITICAL for schema changes)

### Phase 2: Deployment Decision Tree

```
┌─────────────────────────────────────────────────┐
│         What Type of Change?                     │
└─────────────────────────────────────────────────┘
                     │
    ┌────────────────┼────────────────┐
    ▼                ▼                ▼
┌─────────┐    ┌──────────┐    ┌──────────┐
│  Code   │    │Dependency│    │  Config  │
│ Change  │    │  Change  │    │  Change  │
└─────────┘    └──────────┘    └──────────┘
    │                │                │
    ▼                ▼                ▼
┌─────────┐    ┌──────────┐    ┌──────────┐
│NO ACTION│    │ REBUILD  │    │ RECREATE │
│REQUIRED │    │ REQUIRED │    │ REQUIRED │
└─────────┘    └──────────┘    └──────────┘
    │                │                │
    ▼                ▼                ▼
Watch mode      Rebuild         Rebuild +
handles it      affected        restart all
automatically   services        affected
```

### Phase 3: Execution Procedures

#### 3.1 Type A: Code Changes (NO ACTION REQUIRED)
**Example:** Editing `production-backend/app/api/users.py`

**Procedure:**
1. Make the code change using Edit tool
2. Wait 2-3 seconds for watch mode to sync
3. Check logs for reload confirmation:
```bash
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 50 backend
# Look for: "Reloading..." or "Compiled successfully"
```
4. Verify endpoint works (see verification steps)

**Expected Behavior:**
- Backend: Uvicorn auto-reloads in < 500ms
- Frontend: Next.js Fast Refresh updates in < 200ms
- No container restart required

**Common Pitfalls:**
- ❌ Not waiting for sync to complete
- ❌ Not checking logs for reload confirmation
- ❌ Assuming change worked without testing endpoint

#### 3.2 Type B: Dependency Changes (REBUILD REQUIRED)
**Example:** Adding package to `requirements.txt` or `package.json`

**Procedure:**
1. Make the dependency change
2. Inform user: "This requires a rebuild (5-10 minutes)"
3. Execute rebuild command:
```bash
/Users/cope/EnGardeHQ/scripts/dev-rebuild.sh
```
4. Wait for rebuild to complete (monitor logs)
5. Verify services are healthy:
```bash
/Users/cope/EnGardeHQ/scripts/dev-health.sh
```

**Expected Behavior:**
- Watch mode detects file change
- Container rebuilds automatically (or you rebuild manually)
- Services restart with new dependencies
- Total time: 5-10 minutes

**Common Pitfalls:**
- ❌ Not informing user about rebuild time
- ❌ Not waiting for rebuild to complete
- ❌ Marking complete before health check passes

#### 3.3 Type C: Configuration Changes (RECREATE REQUIRED)
**Example:** Changing `docker-compose.dev.yml` or `Dockerfile`

**Procedure:**
1. Make the configuration change
2. Stop services:
```bash
/Users/cope/EnGardeHQ/scripts/dev-stop.sh
```
3. Rebuild with no cache:
```bash
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml build --no-cache
```
4. Start services:
```bash
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```
5. Verify all services healthy:
```bash
/Users/cope/EnGardeHQ/scripts/dev-health.sh --verbose
```

**Expected Behavior:**
- Full container recreation
- All services restart with new config
- Total time: 10-15 minutes

**Common Pitfalls:**
- ❌ Using cached builds (defeats purpose of config change)
- ❌ Not stopping services first
- ❌ Starting without verifying build succeeded

#### 3.4 Type D: Database Schema Changes (RESET MAY BE REQUIRED)
**Example:** Creating Alembic migration or changing schema

**Procedure:**
1. **CRITICAL:** Ask user if data preservation is needed
2. Create migration (if needed):
```bash
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  alembic revision --autogenerate -m "Description"
```
3. Apply migration:
```bash
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  alembic upgrade head
```
4. Verify migration succeeded:
```bash
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 100 backend | grep -i "migration\|alembic"
```
5. If migration fails, may need reset:
```bash
# Ask user first!
/Users/cope/EnGardeHQ/scripts/dev-reset.sh
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```

**Expected Behavior:**
- Migration applies successfully
- Backend continues running
- Data preserved (unless reset required)

**Common Pitfalls:**
- ❌ Not asking about data preservation
- ❌ Resetting database without user approval
- ❌ Not verifying migration succeeded
- ❌ Not checking for migration errors in logs

#### 3.5 Type E: Environment Variable Changes (RESTART REQUIRED)
**Example:** Adding new API key to `.env`

**Procedure:**
1. Update the `.env` file(s)
2. Restart affected services:
```bash
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml restart backend frontend
```
3. Verify environment variables loaded:
```bash
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend env | grep VARIABLE_NAME
```
4. Check logs for confirmation:
```bash
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 50 backend
```

**Expected Behavior:**
- Services restart in < 30 seconds
- New environment variables available
- Application reads new values

**Common Pitfalls:**
- ❌ Not restarting services (env vars cached)
- ❌ Editing wrong .env file (root vs service-specific)
- ❌ Not verifying env var loaded

### Phase 4: Post-Deployment Verification

**MANDATORY - NEVER SKIP THIS PHASE**

Execute ALL of these checks:

#### 4.1 Service Health Verification
```bash
# Run comprehensive health check
/Users/cope/EnGardeHQ/scripts/dev-health.sh --verbose
```

**Required Results:**
- ✅ All containers running
- ✅ All health checks passing
- ✅ No recent errors in logs
- ✅ Resource usage normal

#### 4.2 Hot-Reload Verification (for code changes)
```bash
# Check backend logs for reload
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 20 backend | grep -i "reload\|restart"

# Check frontend logs for compilation
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 20 frontend | grep -i "compiled\|ready"
```

#### 4.3 Endpoint Verification
Test the specific endpoint/feature you changed:

**Backend API:**
```bash
# Health endpoint
curl http://localhost:8000/health

# Specific endpoint (example)
curl http://localhost:8000/api/users
```

**Frontend:**
```bash
# Check frontend responds
curl http://localhost:3000

# Check specific page (if applicable)
curl http://localhost:3000/dashboard
```

#### 4.4 Error Log Check
```bash
# Check for errors in last 100 lines
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 100 -g "error\|ERROR\|Error\|exception" --no-follow
```

**Required Result:** No errors related to your changes

#### 4.5 Browser/Visual Verification (if UI change)
For frontend changes:
1. Open browser to http://localhost:3000
2. Navigate to affected page
3. Verify change is visible
4. Check browser console for errors (F12)
5. Test functionality works as expected

### Phase 5: Rollback Procedures

If ANY verification step fails, execute rollback:

#### 5.1 Rollback Code Changes
```bash
# Undo file changes using Git
cd /Users/cope/EnGardeHQ
git checkout -- path/to/changed/file.py
```

#### 5.2 Rollback Dependency Changes
```bash
# Restore previous dependencies
cd /Users/cope/EnGardeHQ
git checkout -- production-backend/requirements.txt
git checkout -- production-frontend/package.json

# Rebuild
/Users/cope/EnGardeHQ/scripts/dev-rebuild.sh
```

#### 5.3 Rollback Database Changes
```bash
# Rollback one migration
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  alembic downgrade -1

# Or full reset if needed (ask user first!)
/Users/cope/EnGardeHQ/scripts/dev-reset.sh
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```

#### 5.4 Nuclear Reset (Last Resort)
```bash
# Full environment reset (ask user first!)
/Users/cope/EnGardeHQ/scripts/dev-reset.sh --yes
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```

**When to Use Nuclear Reset:**
- Environment completely broken
- Multiple failed rollback attempts
- Corrupted state that can't be fixed
- User explicitly requests it

---

## DOCKER UPDATE RULES BY CHANGE TYPE

### Type A: Code Changes (Python/TypeScript/React)

**Files:**
- `production-backend/app/**/*.py`
- `production-frontend/app/**/*.tsx`
- `production-frontend/components/**/*.tsx`
- `production-frontend/lib/**/*.ts`

**Required Action:** ❌ NONE (watch mode handles it)

**Exact Workflow:**
1. Make code change using Edit tool
2. Wait 2-3 seconds
3. Check logs for reload confirmation
4. Verify change appeared

**Expected Behavior:**
- Backend: Uvicorn detects change, reloads module automatically
- Frontend: Next.js Fast Refresh updates browser without full reload
- Watch mode syncs files from host to container

**Verification Command:**
```bash
# Backend
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 20 backend

# Frontend
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 20 frontend
```

**Common Pitfalls:**
- Not waiting for sync (file system delay)
- Syntax errors preventing reload
- File not in watched directory

---

### Type B: Dependency Changes

**Files:**
- `production-backend/requirements.txt`
- `production-frontend/package.json`
- `production-frontend/package-lock.json`

**Required Action:** ✅ REBUILD CONTAINER

**Exact Commands:**
```bash
# Recommended (uses dev-rebuild script)
/Users/cope/EnGardeHQ/scripts/dev-rebuild.sh

# Manual (if you need more control)
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml down
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml build --no-cache backend
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml up -d
```

**Expected Behavior:**
- Watch mode detects file change
- Triggers automatic rebuild (may take 5-10 minutes)
- Or you manually rebuild
- Container restarts with new dependencies

**Verification Commands:**
```bash
# Check rebuild completed
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml ps

# Verify package installed (Python example)
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  pip list | grep package-name

# Verify package installed (Node example)
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec frontend \
  npm list package-name

# Check health
/Users/cope/EnGardeHQ/scripts/dev-health.sh
```

**Common Pitfalls:**
- Not waiting for rebuild to complete
- Using cached build (defeats purpose)
- Not verifying package installed

---

### Type C: Configuration Changes

**Files:**
- `docker-compose.dev.yml`
- `docker-compose.yml`
- `production-backend/Dockerfile`
- `production-frontend/Dockerfile`
- `production-backend/next.config.js`
- `production-backend/tailwind.config.js`

**Required Action:** ✅ RECREATE CONTAINERS

**Exact Commands:**
```bash
# Stop services
/Users/cope/EnGardeHQ/scripts/dev-stop.sh

# Rebuild without cache
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml build --no-cache

# Start services
/Users/cope/EnGardeHQ/scripts/dev-start.sh

# OR use rebuild script
/Users/cope/EnGardeHQ/scripts/dev-rebuild.sh
```

**Expected Behavior:**
- Full container recreation
- All configuration changes applied
- Services start with new config
- Takes 10-15 minutes

**Verification Commands:**
```bash
# Verify new configuration loaded
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml config

# Check container config
docker inspect engarde_backend_dev | grep -A 20 "Config"

# Verify services healthy
/Users/cope/EnGardeHQ/scripts/dev-health.sh --verbose
```

**Common Pitfalls:**
- Using cached builds (config won't apply)
- Not stopping services first
- Not verifying config actually changed

---

### Type D: Database Schema Changes

**Files:**
- `production-backend/alembic/versions/*.py`
- Database models in `production-backend/app/models/`

**Required Action:** ✅ RUN MIGRATIONS (or RESET if incompatible)

**Exact Commands:**

**Option 1: Create and Apply Migration (Preserves Data)**
```bash
# Create migration
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  alembic revision --autogenerate -m "Add new column to users table"

# Review migration (IMPORTANT!)
cat production-backend/alembic/versions/XXXX_add_new_column.py

# Apply migration
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  alembic upgrade head

# Verify migration
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  alembic current
```

**Option 2: Reset Database (Destroys Data - ASK USER FIRST)**
```bash
# CRITICAL: Ask user for confirmation first!
echo "WARNING: This will delete ALL database data. Proceed? (y/n)"

# If user confirms:
/Users/cope/EnGardeHQ/scripts/dev-reset.sh
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```

**Expected Behavior:**
- Migration applies without errors
- Database schema updated
- Existing data preserved (Option 1)
- Services continue running normally

**Verification Commands:**
```bash
# Check migration logs
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 200 backend | grep -i "alembic\|migration"

# Verify database schema
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec postgres \
  psql -U engarde_user -d engarde -c "\d+ table_name"

# Check backend health
curl http://localhost:8000/health
```

**Common Pitfalls:**
- Not reviewing migration before applying
- Resetting database without asking user
- Not checking for migration errors
- Applying incompatible migrations

---

### Type E: Environment Variable Changes

**Files:**
- `.env` (root)
- `production-backend/.env`
- `production-frontend/.env`

**Required Action:** ✅ RESTART SERVICES

**Exact Commands:**
```bash
# Edit .env file(s) using Edit tool

# Restart affected services
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml restart backend frontend

# OR restart specific service
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml restart backend
```

**Expected Behavior:**
- Services restart in < 30 seconds
- New environment variables loaded
- Application reads new values on next request

**Verification Commands:**
```bash
# Verify environment variable set
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  env | grep VARIABLE_NAME

# Check if app reads it (backend example)
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  python -c "import os; print(os.getenv('VARIABLE_NAME'))"

# Check logs for confirmation
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 50 backend
```

**Common Pitfalls:**
- Editing wrong .env file (root vs service-specific)
- Not restarting services (env vars cached)
- Typo in variable name
- Not verifying variable loaded

---

## DATABASE SEEDING PROTOCOL

### Overview

The database seeding system provides automated, versioned seeding of demo data with built-in tracking to prevent duplicate seeding and ensure data consistency across development environments.

**Key Features:**
- Version tracking in `database_seed_versions` table
- Idempotent seeding (safe to run multiple times)
- Automatic check during environment startup
- Interactive prompts for user consent
- Manual management commands

### Golden Rules for Database Seeding

1. **ALWAYS check seed status** before marking deployment complete
2. **NEVER seed database without user consent** (unless auto-yes mode explicitly enabled)
3. **ALWAYS verify seed version** matches expected version (1.0.0)
4. **NEVER skip seed version recording** after successful seeding
5. **ALWAYS provide clear feedback** about seed status to user
6. **NEVER assume seeding worked** - verify with status check
7. **ALWAYS document seed version** in deployment reports

### Seeding Architecture

#### Component Overview

```
Database Seeding System
├── Tracking Table
│   └── database_seed_versions (tracks what's been seeded)
│
├── Seed Scripts
│   ├── create_seed_versions_table.sql (initialize tracking)
│   └── seed_demo_data.sql (version 1.0.0 demo data)
│
├── Management Scripts
│   ├── check-seed-status.sh (check if seeding needed)
│   ├── prompt-seed-database.sh (interactive seeding)
│   ├── seed-database.sh (manual seeding)
│   ├── reset-seed.sh (reset version tracking)
│   └── seed-status.sh (show detailed status)
│
└── Integration
    └── dev-start.sh (automatic check on startup)
```

#### Version Tracking Schema

The `database_seed_versions` table tracks:
- **version**: Semantic version (e.g., "1.0.0")
- **seed_type**: Type of seed (e.g., "demo_data", "production_setup")
- **description**: Human-readable description
- **seeded_at**: Timestamp when seeded
- **seeded_by**: User/system that applied seed
- **seed_file**: Name of seed file executed
- **row_count**: Number of rows inserted
- **metadata**: Additional JSON metadata

### Current Seed Version: 1.0.0

**What's Included:**
- 4 demo brands:
  - TechFlow Solutions (B2B SaaS)
  - EcoStyle Fashion (Sustainable Fashion)
  - GlobalEats Delivery (Food Delivery)
  - Team Testing Brand (Shared for team)

- 3 demo users:
  - demo1@engarde.local / demo123 (TechFlow)
  - demo2@engarde.local / demo123 (EcoStyle)
  - demo3@engarde.local / demo123 (GlobalEats)
  - All users have access to Team Testing Brand

- 11 platform connections across all tenants
- Sample campaign structure
- Tenant roles and permissions

### Seeding Workflows

#### Workflow 1: Automatic Check During Startup

**When:** Environment startup via `dev-start.sh`

**Process:**
1. Services start and become healthy
2. Automatic seed status check runs
3. If seed is current → Continue to display URLs
4. If seed is missing/outdated → Prompt user interactively
5. User chooses to seed or skip
6. If seeded → Verify success and display credentials
7. Continue to normal startup completion

**Commands Executed:**
```bash
# Automatically called by dev-start.sh
/Users/cope/EnGardeHQ/scripts/check-seed-status.sh --quiet

# If seeding needed
/Users/cope/EnGardeHQ/scripts/prompt-seed-database.sh
```

**Agent Responsibilities:**
- Monitor seed status check results
- Report to user if seeding is needed
- Wait for user decision before proceeding
- Verify seeding completed successfully if user accepts
- Include seed status in deployment report

#### Workflow 2: Manual Seeding

**When:** User manually runs seed command

**Process:**
1. Check if seed version already exists
2. If exists and no --force → Exit with message
3. If --force → Reset version tracking first
4. Create seed versions table (if needed)
5. Execute seed script
6. Record version in database_seed_versions
7. Display success message with credentials

**Commands:**
```bash
# Manual seeding
/Users/cope/EnGardeHQ/scripts/seed-database.sh

# Force re-seeding
/Users/cope/EnGardeHQ/scripts/seed-database.sh --force
```

#### Workflow 3: Checking Seed Status

**When:** Need to verify seed state

**Process:**
1. Check if database_seed_versions table exists
2. Query for current demo_data seed version
3. Compare to expected version (1.0.0)
4. Return status: CURRENT, MISSING, or OUTDATED
5. Display detailed information if verbose

**Commands:**
```bash
# Quick status check
/Users/cope/EnGardeHQ/scripts/check-seed-status.sh

# Detailed status with metadata
/Users/cope/EnGardeHQ/scripts/check-seed-status.sh --verbose

# Quiet mode for scripts
/Users/cope/EnGardeHQ/scripts/check-seed-status.sh --quiet

# Comprehensive status display
/Users/cope/EnGardeHQ/scripts/seed-status.sh --verbose
```

**Exit Codes:**
- 0 = Seed is current (no action needed)
- 1 = Seed is missing or outdated (action needed)
- 2 = Error (cannot determine status)

#### Workflow 4: Resetting Seed Version

**When:** Need to re-seed for testing

**Process:**
1. Show current seed versions
2. Prompt for confirmation (unless --yes)
3. Delete version record from database_seed_versions
4. Confirm reset successful
5. Provide command to re-seed

**Commands:**
```bash
# Reset with confirmation
/Users/cope/EnGardeHQ/scripts/reset-seed.sh

# Reset without confirmation
/Users/cope/EnGardeHQ/scripts/reset-seed.sh --yes

# Reset specific version
/Users/cope/EnGardeHQ/scripts/reset-seed.sh --version 1.0.0 --type demo_data

# Reset all versions
/Users/cope/EnGardeHQ/scripts/reset-seed.sh --all --yes
```

**Important:** Resetting seed version does NOT delete data, only version tracking

### Agent Integration Rules

#### Rule 1: Always Check Seed Status Before Completion

**When to Check:**
- After environment startup
- After database reset
- After schema migrations
- Before marking deployment complete
- When user reports missing data

**How to Check:**
```bash
# Check seed status
/Users/cope/EnGardeHQ/scripts/check-seed-status.sh --quiet

# Check exit code
if [ $? -eq 0 ]; then
  # Seed is current
else
  # Seed is needed
fi
```

**What to Report:**
- Current seed version (or "Not Seeded")
- Whether action is needed
- Command to seed if needed

#### Rule 2: Prompt User If Seeding Needed

**When to Prompt:**
- Seed status check returns exit code 1
- After fresh database initialization
- After dev-reset.sh execution
- When database is empty

**How to Prompt:**
```bash
# Interactive prompt with info
/Users/cope/EnGardeHQ/scripts/prompt-seed-database.sh

# Auto-yes for CI/CD
/Users/cope/EnGardeHQ/scripts/prompt-seed-database.sh --yes
```

**What to Communicate:**
- Clearly explain what will be seeded
- List demo users and credentials
- Explain this is safe and idempotent
- Wait for user decision
- Respect user's choice

#### Rule 3: Verify Seeding Success

**After Seeding:**
1. Check seed status again
2. Verify version matches expected (1.0.0)
3. Query database for demo users
4. Test user login if possible
5. Display credentials to user

**Verification Commands:**
```bash
# Verify seed version recorded
/Users/cope/EnGardeHQ/scripts/check-seed-status.sh --verbose

# Check demo users exist
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec -T postgres \
  psql -U engarde_user -d engarde -c \
  "SELECT email FROM users WHERE email LIKE 'demo%@engarde.local';"

# Check brands exist
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec -T postgres \
  psql -U engarde_user -d engarde -c \
  "SELECT name FROM brands WHERE tenant_id LIKE 'tenant-%';"
```

#### Rule 4: Document Seed Status in Deployment Reports

**Always Include:**
- Seed version status (Current/Missing/Outdated)
- Current version number (if seeded)
- Whether seeding was performed
- User credentials (if newly seeded)
- Link to seed management commands

**Example Report Section:**
```markdown
## Database Seed Status

**Status:** Current
**Version:** 1.0.0
**Type:** demo_data
**Seeded At:** 2025-10-29 16:30:45

### Demo Credentials

- demo1@engarde.local / demo123 (TechFlow Solutions)
- demo2@engarde.local / demo123 (EcoStyle Fashion)
- demo3@engarde.local / demo123 (GlobalEats Delivery)

### Management Commands

- Check status: `./scripts/check-seed-status.sh`
- View details: `./scripts/seed-status.sh --verbose`
- Re-seed: `./scripts/seed-database.sh --force`
- Reset version: `./scripts/reset-seed.sh`
```

#### Rule 5: Handle Seeding Errors Gracefully

**Common Errors and Solutions:**

**Error: database_seed_versions table does not exist**
```bash
# Solution: Initialize table first
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec -T postgres \
  psql -U engarde_user -d engarde -f - < \
  /Users/cope/EnGardeHQ/production-backend/scripts/create_seed_versions_table.sql
```

**Error: Seed version already exists**
```bash
# Solution: Reset version or use --force
/Users/cope/EnGardeHQ/scripts/reset-seed.sh --yes
/Users/cope/EnGardeHQ/scripts/seed-database.sh
```

**Error: Foreign key constraint violation**
```bash
# Solution: Database may be partially seeded or corrupted
# Check current state
/Users/cope/EnGardeHQ/scripts/seed-status.sh --verbose

# If needed, reset database
/Users/cope/EnGardeHQ/scripts/dev-reset.sh
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```

**Error: PostgreSQL container not running**
```bash
# Solution: Start services first
/Users/cope/EnGardeHQ/scripts/dev-start.sh

# Wait for PostgreSQL to be ready
/Users/cope/EnGardeHQ/scripts/dev-health.sh
```

### Seeding Best Practices

#### For Agents

1. **Check Before Assume**: Always verify seed status, never assume
2. **User First**: Always get user consent before seeding
3. **Verify After**: Always verify seeding succeeded
4. **Communicate Clearly**: Explain what's happening and why
5. **Provide Context**: Show credentials and access info after seeding
6. **Document Everything**: Include seed status in all reports

#### For Maintenance

1. **Version Increment**: Increment version when seed data changes
2. **Backward Compatible**: Design seeds to be additive when possible
3. **Idempotent Scripts**: Use ON CONFLICT for all inserts
4. **Test Reset**: Regularly test reset → re-seed cycle
5. **Document Changes**: Update version description in SQL script

#### For Testing

1. **Test Idempotency**: Run seed script multiple times
2. **Test Reset**: Verify reset-seed.sh works correctly
3. **Test Force**: Verify --force flag works
4. **Test Status**: Verify status checks are accurate
5. **Test Integration**: Verify dev-start.sh integration works

### Quick Reference: Seeding Commands

#### Status and Information
```bash
# Quick status check
./scripts/check-seed-status.sh

# Detailed status
./scripts/check-seed-status.sh --verbose

# Comprehensive info
./scripts/seed-status.sh --verbose

# Quiet check (for scripts)
./scripts/check-seed-status.sh --quiet
```

#### Seeding Operations
```bash
# Interactive seeding
./scripts/prompt-seed-database.sh

# Auto-yes seeding
./scripts/prompt-seed-database.sh --yes

# Manual seeding
./scripts/seed-database.sh

# Force re-seed
./scripts/seed-database.sh --force
```

#### Version Management
```bash
# Reset version (with prompt)
./scripts/reset-seed.sh

# Reset without prompt
./scripts/reset-seed.sh --yes

# Reset specific version
./scripts/reset-seed.sh --version 1.0.0 --type demo_data

# Reset all versions
./scripts/reset-seed.sh --all --yes
```

#### Direct SQL Access (Advanced)
```bash
# View all seed versions
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec -T postgres \
  psql -U engarde_user -d engarde -c \
  "SELECT * FROM database_seed_versions ORDER BY seeded_at DESC;"

# Check demo users
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec -T postgres \
  psql -U engarde_user -d engarde -c \
  "SELECT email, first_name, last_name FROM users WHERE email LIKE 'demo%';"

# Check brands
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec -T postgres \
  psql -U engarde_user -d engarde -c \
  "SELECT name, description FROM brands;"
```

### Integration with Development Workflow

#### Automatic Integration Points

1. **dev-start.sh**: Automatically checks and prompts after services start
2. **dev-reset.sh**: Clears database (seed version tracking deleted)
3. **dev-rebuild.sh**: Preserves seed versions (no action needed)
4. **dev-stop.sh**: No impact on seed versions

#### Manual Intervention Points

- After database reset → Re-seed needed
- After schema changes → May need re-seed
- After alembic downgrade → May need re-seed
- Testing new seed versions → Use reset-seed.sh

### Troubleshooting Seeding Issues

#### Issue 1: Seed Script Fails Halfway

**Symptoms:**
- Partial data created
- Seed version not recorded
- Some tables populated, others empty

**Diagnosis:**
```bash
# Check what exists
./scripts/seed-status.sh --verbose

# Check for errors in logs
cat /Users/cope/EnGardeHQ/logs/seed-database.log
```

**Solution:**
```bash
# Reset database and try again
/Users/cope/EnGardeHQ/scripts/dev-reset.sh
/Users/cope/EnGardeHQ/scripts/dev-start.sh
# Seeding will be prompted automatically
```

#### Issue 2: Wrong Seed Version Shown

**Symptoms:**
- Version mismatch warning
- Old version shown but new data expected

**Diagnosis:**
```bash
# Check actual version
./scripts/seed-status.sh --verbose
```

**Solution:**
```bash
# Reset old version
./scripts/reset-seed.sh --yes

# Apply new version
./scripts/seed-database.sh
```

#### Issue 3: Cannot Login with Demo Credentials

**Symptoms:**
- demo@engarde.local credentials don't work
- Authentication failures

**Diagnosis:**
```bash
# Check if users exist
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec -T postgres \
  psql -U engarde_user -d engarde -c \
  "SELECT email, is_active FROM users WHERE email LIKE 'demo%';"
```

**Solution:**
```bash
# If users missing, re-seed
./scripts/seed-database.sh --force

# If users exist but password wrong, check hashed_password column
# Expected hash for "demo123": $2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyXNJr0s2fKu
```

### File Locations

**SQL Scripts:**
- `/Users/cope/EnGardeHQ/production-backend/scripts/create_seed_versions_table.sql`
- `/Users/cope/EnGardeHQ/production-backend/scripts/seed_demo_data.sql`

**Shell Scripts:**
- `/Users/cope/EnGardeHQ/scripts/check-seed-status.sh`
- `/Users/cope/EnGardeHQ/scripts/prompt-seed-database.sh`
- `/Users/cope/EnGardeHQ/scripts/seed-database.sh`
- `/Users/cope/EnGardeHQ/scripts/reset-seed.sh`
- `/Users/cope/EnGardeHQ/scripts/seed-status.sh`

**Integration:**
- `/Users/cope/EnGardeHQ/scripts/dev-start.sh` (automatic check)

**Logs:**
- `/Users/cope/EnGardeHQ/logs/seed-database.log`

---

## LOCAL IMPLEMENTATION STANDARDS

### File Modification Protocol

**Rule 1: Always Use Absolute Paths**
```bash
# ✅ CORRECT
/Users/cope/EnGardeHQ/production-backend/app/main.py

# ❌ WRONG
./production-backend/app/main.py
```

**Rule 2: Read Before Edit**
Before editing a file, ALWAYS read it first:
```python
# 1. Read file
Read("/Users/cope/EnGardeHQ/production-backend/app/api/users.py")

# 2. Make changes using Edit tool
Edit(
    file_path="/Users/cope/EnGardeHQ/production-backend/app/api/users.py",
    old_string="def get_user():",
    new_string="def get_user(user_id: int):"
)
```

**Rule 3: Verify File Changed**
After editing, verify the change:
```bash
# Check file timestamp changed
ls -la /Users/cope/EnGardeHQ/production-backend/app/api/users.py

# Check file contents (if needed)
cat /Users/cope/EnGardeHQ/production-backend/app/api/users.py | grep "def get_user"
```

### Hot-Reload Confirmation Steps

#### Backend (FastAPI/Uvicorn)

**Step 1: Check Logs for Reload**
```bash
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 20 backend
```

**Expected Output:**
```
INFO:     Reloading...
INFO:     Application startup complete.
```

**Step 2: Verify No Errors**
```bash
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 100 backend | grep -i "error\|exception"
```

**Expected Output:** No errors (empty output)

**Step 3: Test Endpoint**
```bash
curl http://localhost:8000/health
curl http://localhost:8000/api/your-endpoint
```

#### Frontend (Next.js Fast Refresh)

**Step 1: Check Logs for Compilation**
```bash
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 20 frontend
```

**Expected Output:**
```
event - compiled successfully
wait  - compiling...
event - compiled client and server successfully
```

**Step 2: Verify No Build Errors**
```bash
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 100 frontend | grep -i "error\|failed"
```

**Expected Output:** No errors (empty output)

**Step 3: Browser Verification**
1. Open http://localhost:3000
2. Open DevTools (F12) → Console tab
3. Look for: `[Fast Refresh] rebuilding`
4. Verify no console errors
5. Check UI reflects change

### Browser Cache Handling

**Problem:** Browser caching can hide changes

**Solution: Force Refresh**
- **Chrome/Edge:** Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)
- **Firefox:** Cmd+Shift+R (Mac) or Ctrl+F5 (Windows)
- **Safari:** Cmd+Option+R (Mac)

**Or Disable Cache:**
1. Open DevTools (F12)
2. Network tab
3. Check "Disable cache"
4. Keep DevTools open

### Volume Mount Verification

**Purpose:** Ensure files are actually syncing to containers

**Check Backend Mounts:**
```bash
# List mounted directories
docker inspect engarde_backend_dev | grep -A 10 "Mounts"

# Verify file exists in container
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  ls -la /app/app/api/users.py

# Check file timestamp matches host
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  stat /app/app/api/users.py
```

**Check Frontend Mounts:**
```bash
# List mounted directories
docker inspect engarde_frontend_dev | grep -A 10 "Mounts"

# Verify file exists in container
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec frontend \
  ls -la /app/app/dashboard/page.tsx
```

**Expected Result:** File exists and timestamp matches host

---

## DEVELOPMENT ENVIRONMENT WORKFLOWS

### Workflow 1: Starting Development Environment

**When to Use:** Beginning work, after reboot, morning startup

**Command:**
```bash
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```

**What Happens:**
1. Checks Docker is running
2. Validates configuration
3. Starts all services (postgres, redis, backend, frontend)
4. Waits for health checks
5. Displays service URLs

**Expected Timeline:**
- First run: 5-10 minutes (builds images)
- Subsequent runs: 1-2 minutes (uses cached images)

**Verification:**
```bash
# All services should be healthy
/Users/cope/EnGardeHQ/scripts/dev-health.sh

# Check URLs are accessible
curl http://localhost:8000/health
curl http://localhost:3000
```

### Workflow 2: Making Code Changes (Watch Mode)

**When to Use:** Daily development, editing Python/TypeScript code

**Steps:**
1. Edit file using Edit tool
2. Wait 2-3 seconds for sync
3. Check logs for reload confirmation
4. Verify change worked

**Example:**
```bash
# 1. Make change (via Edit tool)
# Edit: /Users/cope/EnGardeHQ/production-backend/app/api/users.py

# 2. Check logs
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 20 backend

# 3. Test endpoint
curl http://localhost:8000/api/users

# 4. Verify no errors
/Users/cope/EnGardeHQ/scripts/dev-health.sh
```

**Expected Result:** Changes appear automatically, no restart needed

### Workflow 3: Handling Dependency Updates (Rebuild)

**When to Use:** After adding packages to requirements.txt or package.json

**Command:**
```bash
/Users/cope/EnGardeHQ/scripts/dev-rebuild.sh
```

**What Happens:**
1. Stops all containers
2. Clears build cache
3. Rebuilds images without cache
4. Restarts services
5. Waits for health checks

**Expected Timeline:** 5-10 minutes

**Verification:**
```bash
# Check package installed (Python)
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  pip list | grep package-name

# Check package installed (Node)
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec frontend \
  npm list package-name

# Verify all healthy
/Users/cope/EnGardeHQ/scripts/dev-health.sh
```

### Workflow 4: Troubleshooting Issues

**When to Use:** Something not working, services unhealthy, errors appearing

**Step-by-Step:**

**1. Check Health Status**
```bash
/Users/cope/EnGardeHQ/scripts/dev-health.sh --verbose
```

**2. View Logs**
```bash
# All services
/Users/cope/EnGardeHQ/scripts/dev-logs.sh

# Specific service
/Users/cope/EnGardeHQ/scripts/dev-logs.sh backend

# Filter for errors
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -g "error\|ERROR\|exception"
```

**3. Try Restart**
```bash
/Users/cope/EnGardeHQ/scripts/dev-stop.sh
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```

**4. If Still Broken: Rebuild**
```bash
/Users/cope/EnGardeHQ/scripts/dev-rebuild.sh
```

**5. Nuclear Option: Reset**
```bash
# ASK USER FIRST - DELETES DATA!
/Users/cope/EnGardeHQ/scripts/dev-reset.sh
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```

### Workflow 5: Complete Reset Procedure

**When to Use:** Environment completely broken, major changes, clean slate needed

**CRITICAL:** Always ask user for confirmation - this deletes ALL data!

**Command:**
```bash
/Users/cope/EnGardeHQ/scripts/dev-reset.sh
```

**What It Does:**
1. Stops all containers
2. Removes all containers
3. Removes all volumes (DATABASE DELETED!)
4. Removes all networks
5. Cleans Docker build cache
6. Removes dangling images
7. Cleans local caches (__pycache__, .next)

**What Is Preserved:**
- ✅ Source code
- ✅ Docker images (for faster rebuild)
- ✅ Local files in your directories

**What Is Deleted:**
- ❌ All database data
- ❌ All Docker volumes
- ❌ Build cache
- ❌ Compiled/generated files

**After Reset:**
```bash
# Start fresh
/Users/cope/EnGardeHQ/scripts/dev-start.sh

# Verify everything healthy
/Users/cope/EnGardeHQ/scripts/dev-health.sh
```

---

## VERIFICATION & TESTING REQUIREMENTS

### CRITICAL: Never Mark Tasks Complete Without These Checks

#### Checklist - EVERY Task Must Pass ALL of These

- [ ] **Service Health:** All containers running and healthy
- [ ] **Hot-Reload Working:** Logs confirm reload/compilation
- [ ] **No Errors in Logs:** Recent logs are clean
- [ ] **User-Facing Changes Visible:** Tested endpoint or viewed in browser
- [ ] **Documentation Updated:** Informed user of what changed

### Service Health Checks

**Command:**
```bash
/Users/cope/EnGardeHQ/scripts/dev-health.sh --verbose
```

**Required Results:**
- ✅ PostgreSQL: Accepting connections, database accessible
- ✅ Redis: Responding to PING
- ✅ Backend: Health endpoint returns 200, no errors in logs
- ✅ Frontend: Accessible on port 3000, no build errors
- ✅ All containers: Status "Up", health "healthy"

**If ANY Check Fails:** Do NOT mark task complete. Fix the issue first.

### Hot-Reload Confirmation

**Backend (Python):**
```bash
# Check last 20 lines for reload
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 20 backend | grep -i "reload"
```

**Expected Output:**
```
INFO:     Reloading...
INFO:     Application startup complete.
```

**Frontend (Next.js):**
```bash
# Check last 20 lines for compilation
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 20 frontend | grep -i "compiled"
```

**Expected Output:**
```
event - compiled successfully
```

**If No Reload Detected:** Wait 5 more seconds, check again. If still no reload, investigate.

### Error Log Verification

**Check for Errors:**
```bash
# Backend errors
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 100 backend | grep -i "error\|exception\|traceback"

# Frontend errors
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 100 frontend | grep -i "error\|failed"

# Database errors
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 100 postgres | grep -i "error\|fatal"
```

**Expected Result:** No errors related to your changes

**If Errors Found:** Do NOT mark complete. Fix errors first.

### Endpoint Testing

**Backend API Testing:**
```bash
# Health endpoint
curl -f http://localhost:8000/health || echo "FAILED"

# Specific endpoint (example)
curl -f http://localhost:8000/api/users || echo "FAILED"

# With authentication (example)
curl -f -H "Authorization: Bearer TOKEN" http://localhost:8000/api/protected || echo "FAILED"
```

**Expected Result:** 200 OK response, no errors

**Frontend Testing:**
```bash
# Homepage
curl -f http://localhost:3000 || echo "FAILED"

# Specific page (example)
curl -f http://localhost:3000/dashboard || echo "FAILED"
```

**Expected Result:** 200 OK response, HTML content returned

### Browser/Visual Testing (for UI changes)

**Steps:**
1. Open browser to http://localhost:3000
2. Navigate to affected page/component
3. Verify change is visible
4. Open DevTools (F12) → Console
5. Check for JavaScript errors
6. Test user interactions work

**Screenshot for User:** If significant UI change, take screenshot and share with user

### Documentation Update Requirement

**Always Document:**
- What files you changed
- What type of change (code, dependency, config, schema)
- What action was taken (hot-reload, rebuild, restart, reset)
- What verification was done
- Any issues encountered and how they were resolved

**Example Good Documentation:**
```
Changes Made:
- Modified: /Users/cope/EnGardeHQ/production-backend/app/api/users.py
- Added new endpoint: GET /api/users/{user_id}
- Type: Code change (Python)

Action Taken:
- No action required (hot-reload handled it)
- Watched logs for reload confirmation
- Tested endpoint with curl

Verification:
✅ Backend reloaded successfully in 0.5s
✅ No errors in logs
✅ Endpoint returns 200 OK
✅ All health checks passing

The new endpoint is now available at http://localhost:8000/api/users/1
```

---

## ERROR HANDLING & RECOVERY

### Common Error Scenarios and Solutions

#### Error 1: Service Won't Start

**Symptoms:**
- Container exits immediately
- Health check fails
- Port binding error

**Diagnosis:**
```bash
# Check container status
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml ps

# View logs
/Users/cope/EnGardeHQ/scripts/dev-logs.sh backend

# Check for port conflicts
lsof -i :8000  # Backend
lsof -i :3000  # Frontend
lsof -i :5432  # PostgreSQL
```

**Solutions:**

**If Port Already in Use:**
```bash
# Kill process using port
lsof -i :8000 | grep LISTEN | awk '{print $2}' | xargs kill -9
```

**If Database Connection Failed:**
```bash
# Check PostgreSQL is running
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml ps postgres

# Check health
/Users/cope/EnGardeHQ/scripts/dev-health.sh

# If unhealthy, restart
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml restart postgres
```

**If Container Keeps Crashing:**
```bash
# Rebuild container
/Users/cope/EnGardeHQ/scripts/dev-rebuild.sh
```

#### Error 2: Hot-Reload Not Working

**Symptoms:**
- Code changes not appearing
- No reload messages in logs
- Stale code running

**Diagnosis:**
```bash
# Check watch mode is running
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml ps

# Check file exists in container
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  ls -la /app/app/main.py

# Check file timestamp
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  stat /app/app/main.py
```

**Solutions:**

**If File Not Syncing:**
```bash
# Restart services to remount volumes
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml restart backend frontend
```

**If Syntax Error Preventing Reload:**
```bash
# Check logs for syntax errors
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 50 backend | grep -i "syntax\|error"

# Fix syntax error, save again
```

**If Watch Mode Not Running:**
```bash
# Stop and start with watch mode
/Users/cope/EnGardeHQ/scripts/dev-stop.sh
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```

#### Error 3: Database Migration Failed

**Symptoms:**
- Migration command fails
- Backend won't start
- Database schema out of sync

**Diagnosis:**
```bash
# Check migration logs
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 200 backend | grep -i "alembic\|migration"

# Check current migration state
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  alembic current

# Check migration history
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  alembic history
```

**Solutions:**

**If Migration Has Errors:**
```bash
# Rollback one migration
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  alembic downgrade -1

# Fix migration file
# Then reapply
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  alembic upgrade head
```

**If Database Schema Corrupted:**
```bash
# ASK USER FIRST - THIS DELETES DATA!
echo "Database reset required. This will delete all data. Proceed? (y/n)"

# If approved:
/Users/cope/EnGardeHQ/scripts/dev-reset.sh
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```

#### Error 4: Build Failure

**Symptoms:**
- docker-compose build fails
- Dependency installation errors
- Image build crashes

**Diagnosis:**
```bash
# Build with verbose output
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml build --progress=plain backend

# Check for missing files
ls -la /Users/cope/EnGardeHQ/production-backend/requirements.txt
ls -la /Users/cope/EnGardeHQ/production-frontend/package.json
```

**Solutions:**

**If Dependency Download Failed:**
```bash
# Clear build cache and retry
docker builder prune -a -f
/Users/cope/EnGardeHQ/scripts/dev-rebuild.sh
```

**If Dockerfile Syntax Error:**
```bash
# Validate Dockerfile
docker build -f /Users/cope/EnGardeHQ/production-backend/Dockerfile \
  /Users/cope/EnGardeHQ/production-backend/

# Fix syntax errors
# Then rebuild
/Users/cope/EnGardeHQ/scripts/dev-rebuild.sh
```

### When to Automatically Rollback

**Automatic Rollback Triggers:**
1. Service fails health check after deployment
2. Errors appear in logs immediately after change
3. Endpoint returns 500 error after code change
4. Build fails during dependency update
5. Migration fails to apply

**Rollback Procedure:**
```bash
# 1. Inform user
echo "ERROR: Deployment failed. Rolling back changes..."

# 2. Revert code changes
cd /Users/cope/EnGardeHQ
git checkout -- path/to/changed/file

# 3. Restart services
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml restart backend

# 4. Verify rollback succeeded
/Users/cope/EnGardeHQ/scripts/dev-health.sh

# 5. Report to user
echo "Rollback complete. System restored to previous state."
```

### Data Preservation During Failures

**What to Preserve:**
- Database data (unless reset explicitly requested)
- User uploads
- Application logs
- Environment variables

**How to Preserve:**
```bash
# Stop services without deleting volumes
/Users/cope/EnGardeHQ/scripts/dev-stop.sh

# Restart services (data preserved)
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```

**What NOT to Do:**
- ❌ Don't use `--clean` flag unless necessary
- ❌ Don't delete volumes without asking user
- ❌ Don't reset database without confirmation

### Error Reporting to User

**Always Report:**
- What error occurred
- What you tried to fix it
- Whether rollback was necessary
- Current system state
- Recommended next steps

**Example Error Report:**
```
ERROR: Deployment Failed

What Happened:
- Modified /Users/cope/EnGardeHQ/production-backend/app/api/users.py
- Backend failed to reload due to syntax error on line 45

What I Did:
- Detected error in logs
- Rolled back changes
- Verified system is healthy again

Current State:
✅ All services running and healthy
✅ System restored to pre-change state
❌ Requested changes not applied

Recommended Next Step:
- Fix syntax error on line 45 (missing colon)
- Reapply changes
```

### Recovery Procedures

#### Level 1: Soft Recovery (Restart)
```bash
# Restart affected services
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml restart backend frontend
```

**When to Use:** Minor issues, service lockup, temporary glitches

#### Level 2: Medium Recovery (Rebuild)
```bash
# Rebuild affected services
/Users/cope/EnGardeHQ/scripts/dev-rebuild.sh
```

**When to Use:** Dependency issues, build cache problems, config changes

#### Level 3: Hard Recovery (Reset)
```bash
# Full environment reset (ask user first!)
/Users/cope/EnGardeHQ/scripts/dev-reset.sh
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```

**When to Use:** Corrupted state, multiple failures, database schema issues

#### Level 4: Nuclear Recovery (Full Cleanup)
```bash
# Remove everything (ask user first!)
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml down -v --rmi all
docker system prune -a --volumes -f
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```

**When to Use:** Complete breakdown, Docker corruption, last resort

---

## COMMUNICATION STANDARDS

### What to Report to User

**Always Include:**
1. What files you changed (absolute paths)
2. What type of change (code, dependency, config, schema)
3. What action you took (hot-reload, rebuild, restart, reset)
4. What verification you performed
5. Results of verification
6. Current status of system
7. How user can access/test the changes

**Example Good Communication:**
```
✅ Changes Applied Successfully

What Changed:
- Modified: /Users/cope/EnGardeHQ/production-backend/app/api/users.py
- Added: New endpoint GET /api/users/{user_id}/profile

Type of Change:
- Code change (Python) - hot-reload handled automatically

Action Taken:
- Made code changes
- Monitored logs for reload confirmation
- Backend reloaded in 0.4 seconds
- Tested new endpoint

Verification Results:
✅ Backend hot-reload successful
✅ No errors in logs
✅ Health checks passing
✅ New endpoint returns 200 OK
✅ Response format validated

Current Status:
All services running and healthy. New endpoint is live.

Test It Yourself:
curl http://localhost:8000/api/users/1/profile

Next Steps:
The endpoint is ready to use. No further action needed.
```

### When to Ask for Confirmation

**ALWAYS Ask Before:**
1. Resetting database (deletes data)
2. Using `--clean` flag (deletes volumes)
3. Removing Docker volumes
4. Running `/Users/cope/EnGardeHQ/scripts/dev-reset.sh`
5. Making changes that affect production configuration
6. Modifying environment variables that could affect services
7. Applying database migrations that can't be easily rolled back

**Example Confirmation Request:**
```
⚠️  Confirmation Required

Action: Database Reset
Impact: ALL database data will be deleted
Reason: Migration cannot be applied to current schema

This will delete:
- All user data
- All application data
- All database tables

This will preserve:
- Source code
- Docker images
- Application configuration

Estimated downtime: 2-3 minutes

Do you want to proceed with database reset? (yes/no)
```

### How to Document Changes

**Use This Template:**

```markdown
## Change Summary

**Date:** [Current date]
**Agent:** [Your agent ID/name]
**Task:** [Brief description]

### Changes Made

**Files Modified:**
- /Users/cope/EnGardeHQ/production-backend/app/api/users.py (lines 45-60)
- /Users/cope/EnGardeHQ/production-backend/app/models/user.py (lines 12-20)

**Type of Change:** Code change (Python)

**Description:**
[Detailed description of what changed and why]

### Actions Taken

1. Modified user model to add new field
2. Updated API endpoint to return new field
3. Monitored logs for hot-reload
4. Tested endpoint

### Verification

**Health Checks:**
- ✅ All services healthy
- ✅ Backend reloaded successfully
- ✅ No errors in logs

**Functional Testing:**
- ✅ GET /api/users returns new field
- ✅ Response format validated
- ✅ No breaking changes

**Performance:**
- Hot-reload time: 0.4 seconds
- API response time: < 100ms

### Current Status

All services running normally. Changes are live and tested.

### How to Test

```bash
# Test endpoint
curl http://localhost:8000/api/users/1

# Expected response includes new field
```

### Rollback Instructions

If issues arise:
```bash
git checkout -- production-backend/app/api/users.py production-backend/app/models/user.py
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml restart backend
```
```

### Status Update Requirements

**Update User When:**
1. Starting a long-running operation (rebuild, reset)
2. Waiting for health checks to pass
3. Encountering any errors or issues
4. Completing a major step
5. Task is complete

**Status Update Format:**
```
[⏳ IN PROGRESS] Rebuilding backend container...
[⏳ IN PROGRESS] Waiting for health checks (30s)...
[✅ COMPLETE] Backend rebuilt and healthy
[❌ ERROR] Build failed - rolling back
[⚠️  WARNING] This will delete data - confirmation needed
```

---

## QUICK REFERENCE COMMANDS

### Common Workflows

#### Start Development
```bash
# Standard start
/Users/cope/EnGardeHQ/scripts/dev-start.sh

# Check status
/Users/cope/EnGardeHQ/scripts/dev-health.sh
```

#### View Logs
```bash
# All services
/Users/cope/EnGardeHQ/scripts/dev-logs.sh

# Specific service
/Users/cope/EnGardeHQ/scripts/dev-logs.sh backend
/Users/cope/EnGardeHQ/scripts/dev-logs.sh frontend

# Filter for errors
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -g "error\|ERROR"

# Last 50 lines
/Users/cope/EnGardeHQ/scripts/dev-logs.sh -n 50 backend
```

#### Stop Development
```bash
# Stop (preserve data)
/Users/cope/EnGardeHQ/scripts/dev-stop.sh

# Stop and clean (deletes data)
/Users/cope/EnGardeHQ/scripts/dev-stop.sh --clean
```

#### Rebuild Services
```bash
# Full rebuild
/Users/cope/EnGardeHQ/scripts/dev-rebuild.sh

# Rebuild specific service
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml build backend
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml up -d backend
```

#### Reset Environment
```bash
# Nuclear reset (ask user first!)
/Users/cope/EnGardeHQ/scripts/dev-reset.sh

# Reset without confirmation (dangerous!)
/Users/cope/EnGardeHQ/scripts/dev-reset.sh --yes
```

### One-Liners for Frequent Operations

#### Health Checks
```bash
# Quick health check
/Users/cope/EnGardeHQ/scripts/dev-health.sh

# Detailed health check
/Users/cope/EnGardeHQ/scripts/dev-health.sh --verbose

# Check specific service
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml ps backend
```

#### Service Management
```bash
# Restart single service
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml restart backend

# Restart multiple services
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml restart backend frontend

# View service logs (last 20 lines)
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml logs --tail=20 backend
```

#### Database Operations
```bash
# Access PostgreSQL
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec postgres \
  psql -U engarde_user -d engarde

# Run migration
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  alembic upgrade head

# Check migration status
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  alembic current

# Create migration
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  alembic revision --autogenerate -m "Description"
```

#### Dependency Management
```bash
# Check Python package
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  pip list | grep package-name

# Check Node package
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec frontend \
  npm list package-name

# Install package (then rebuild required)
# Edit requirements.txt or package.json, then:
/Users/cope/EnGardeHQ/scripts/dev-rebuild.sh
```

#### Testing Endpoints
```bash
# Backend health
curl http://localhost:8000/health

# Backend API endpoint
curl http://localhost:8000/api/users

# Frontend
curl http://localhost:3000

# With headers
curl -H "Authorization: Bearer TOKEN" http://localhost:8000/api/protected
```

### Emergency Procedures

#### Service Won't Start
```bash
# 1. Check logs
/Users/cope/EnGardeHQ/scripts/dev-logs.sh backend

# 2. Check health
/Users/cope/EnGardeHQ/scripts/dev-health.sh --verbose

# 3. Restart
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml restart backend

# 4. Rebuild if restart fails
/Users/cope/EnGardeHQ/scripts/dev-rebuild.sh

# 5. Reset if rebuild fails (ask user first!)
/Users/cope/EnGardeHQ/scripts/dev-reset.sh
```

#### Environment Completely Broken
```bash
# Nuclear option (ask user first!)
/Users/cope/EnGardeHQ/scripts/dev-reset.sh --yes
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```

#### Port Conflicts
```bash
# Find process using port
lsof -i :8000  # Backend
lsof -i :3000  # Frontend
lsof -i :5432  # PostgreSQL

# Kill process
lsof -i :8000 | grep LISTEN | awk '{print $2}' | xargs kill -9
```

#### Database Locked/Corrupted
```bash
# Stop services
/Users/cope/EnGardeHQ/scripts/dev-stop.sh

# Remove database volume (ask user first!)
docker volume rm engardehq_postgres_dev_data

# Restart (will reinitialize DB)
/Users/cope/EnGardeHQ/scripts/dev-start.sh
```

### Diagnostic Commands

#### Container Inspection
```bash
# View container details
docker inspect engarde_backend_dev

# Check volume mounts
docker inspect engarde_backend_dev | grep -A 20 "Mounts"

# Check environment variables
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend env

# Check running processes
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend ps aux
```

#### Resource Usage
```bash
# Real-time stats
docker stats

# Specific container
docker stats engarde_backend_dev

# Disk usage
docker system df

# Volume sizes
docker volume ls
docker volume inspect engardehq_postgres_dev_data
```

#### Network Debugging
```bash
# Test connectivity between containers
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  curl http://postgres:5432

docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  curl http://redis:6379

# Check DNS resolution
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml exec backend \
  nslookup postgres
```

---

## REFERENCES TO DOCUMENTATION

### Core Documentation Files

**Essential Reading:**
1. `/Users/cope/EnGardeHQ/docs/DOCKER_DEVELOPMENT_ARCHITECTURE.md`
   - Comprehensive architecture guide
   - Volume strategy and watch mode details
   - Multi-stage build explanation

2. `/Users/cope/EnGardeHQ/DEV_QUICK_START.md`
   - Quick start guide for developers
   - Essential commands and workflows
   - Common issues and solutions

3. `/Users/cope/EnGardeHQ/scripts/DEV_SCRIPTS_README.md`
   - Detailed documentation of all dev scripts
   - Usage examples and options
   - Exit codes and error handling

4. `/Users/cope/EnGardeHQ/scripts/DEV_QUICK_REFERENCE.md`
   - Quick reference for dev scripts
   - Common workflows cheat sheet

### Configuration Files

**Key Files:**
1. `/Users/cope/EnGardeHQ/docker-compose.dev.yml`
   - Development Docker Compose configuration
   - Service definitions and watch mode config
   - Volume mounts and health checks

2. `/Users/cope/EnGardeHQ/production-backend/Dockerfile`
   - Backend container definition
   - Multi-stage build configuration

3. `/Users/cope/EnGardeHQ/production-frontend/Dockerfile`
   - Frontend container definition
   - Next.js build configuration

### Development Scripts

**Available Scripts:**
1. `/Users/cope/EnGardeHQ/scripts/dev-start.sh` - Start environment
2. `/Users/cope/EnGardeHQ/scripts/dev-stop.sh` - Stop environment
3. `/Users/cope/EnGardeHQ/scripts/dev-logs.sh` - View logs
4. `/Users/cope/EnGardeHQ/scripts/dev-health.sh` - Health checks
5. `/Users/cope/EnGardeHQ/scripts/dev-rebuild.sh` - Rebuild services
6. `/Users/cope/EnGardeHQ/scripts/dev-reset.sh` - Reset environment

### Architecture Diagrams

**Located In:** `/Users/cope/EnGardeHQ/docs/DOCKER_DEVELOPMENT_ARCHITECTURE.md`

Key diagrams to reference:
- High-level flow diagram (lines 156-220)
- Code change flow (lines 223-252)
- Service dependency chain (lines 254-293)
- Docker Compose layering strategy (lines 380-465)

### Troubleshooting Guides

**Issue Resolution:**
1. Code changes not reflected → Lines 1277-1327 in DOCKER_DEVELOPMENT_ARCHITECTURE.md
2. Container fails to start → Lines 1329-1402 in DOCKER_DEVELOPMENT_ARCHITECTURE.md
3. Slow performance → Lines 1403-1459 in DOCKER_DEVELOPMENT_ARCHITECTURE.md
4. Database connection errors → Lines 1461-1509 in DOCKER_DEVELOPMENT_ARCHITECTURE.md
5. Build failures → Lines 1511-1551 in DOCKER_DEVELOPMENT_ARCHITECTURE.md
6. Frontend HMR not working → Lines 1553-1590 in DOCKER_DEVELOPMENT_ARCHITECTURE.md

### Best Practices

**Guidelines Located In:** `/Users/cope/EnGardeHQ/docs/DOCKER_DEVELOPMENT_ARCHITECTURE.md`

Key sections:
- Configuration Management (lines 1896-1920)
- Dockerfile Design (lines 1922-1948)
- Volume Strategy (lines 1950-1974)
- Networking (lines 1976-2004)
- Security (lines 2006-2042)
- Performance (lines 2044-2056)
- Logging (lines 2058-2085)
- Testing (lines 2087-2112)
- Debugging (lines 2114-2159)
- Maintenance (lines 2161-2200)

### Service URLs & Ports

**When Services Running:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- PostgreSQL: localhost:5432 (engarde_user/engarde_password)
- Redis: localhost:6379

### File Structure Reference

```
/Users/cope/EnGardeHQ/
├── .claude/
│   └── AGENT_DEPLOYMENT_RULES.md         # This file
│
├── scripts/
│   ├── dev-start.sh                       # Start environment
│   ├── dev-stop.sh                        # Stop environment
│   ├── dev-logs.sh                        # View logs
│   ├── dev-health.sh                      # Health checks
│   ├── dev-rebuild.sh                     # Rebuild services
│   └── dev-reset.sh                       # Reset environment
│
├── docs/
│   ├── DOCKER_DEVELOPMENT_ARCHITECTURE.md # Architecture guide
│   ├── DOCKER_BEST_PRACTICES.md          # Best practices
│   └── DOCKER_ARCHITECTURE_DIAGRAMS.md   # Visual diagrams
│
├── docker-compose.dev.yml                 # Development config
├── docker-compose.yml                     # Base/production config
├── DEV_QUICK_START.md                    # Quick start guide
│
├── production-backend/
│   ├── Dockerfile                         # Backend container
│   ├── requirements.txt                   # Python dependencies
│   ├── app/                              # Backend code (hot-reload)
│   ├── alembic/                          # Database migrations
│   └── .env                              # Backend env vars
│
└── production-frontend/
    ├── Dockerfile                         # Frontend container
    ├── package.json                       # Node dependencies
    ├── app/                              # Frontend code (Fast Refresh)
    └── .env                              # Frontend env vars
```

---

## APPENDIX: Decision Matrix

### Quick Decision Guide

Use this matrix to determine the correct action:

| Change Type | Files Affected | Action Required | Command | Time |
|------------|----------------|-----------------|---------|------|
| **Python code** | `production-backend/app/**/*.py` | None (hot-reload) | Wait 2-3s | < 1s |
| **TypeScript/React** | `production-frontend/app/**/*.tsx` | None (Fast Refresh) | Wait 2-3s | < 1s |
| **Python deps** | `requirements.txt` | Rebuild backend | `dev-rebuild.sh` | 5-10m |
| **Node deps** | `package.json` | Rebuild frontend | `dev-rebuild.sh` | 5-10m |
| **Dockerfile** | `Dockerfile` | Rebuild all | `dev-rebuild.sh` | 10-15m |
| **Docker Compose** | `docker-compose.dev.yml` | Recreate | Stop → Build → Start | 10-15m |
| **Environment** | `.env` | Restart services | `restart backend` | < 30s |
| **Database model** | `app/models/*.py` | Run migration | `alembic upgrade head` | < 1m |
| **Schema change** | New migration | Apply or reset | Migration or `dev-reset.sh` | 1-3m |
| **Config files** | `next.config.js`, etc | Restart service | `restart frontend` | < 30s |

### Verification Checklist Matrix

| Check | Command | Expected Result | If Failed |
|-------|---------|-----------------|-----------|
| **Services running** | `docker compose ps` | All "Up" | Restart services |
| **Health checks** | `dev-health.sh` | All ✅ | Check logs, restart |
| **No errors** | `dev-logs.sh -g "error"` | Empty output | Investigate error |
| **Backend reload** | `dev-logs.sh -n 20 backend` | "Reloading..." | Check syntax, restart |
| **Frontend compile** | `dev-logs.sh -n 20 frontend` | "compiled successfully" | Check errors, rebuild |
| **Backend API** | `curl localhost:8000/health` | `{"status":"healthy"}` | Check logs, restart |
| **Frontend** | `curl localhost:3000` | HTML content | Check build, restart |
| **Database** | `dev-health.sh` | ✅ PostgreSQL | Restart postgres |
| **Redis** | `dev-health.sh` | ✅ Redis | Restart redis |

---

## FINAL REMINDERS

### Golden Rules (Repeat)

1. ✅ **VERIFY changes appear locally** before marking complete
2. ✅ **CHECK logs** for reload/compilation confirmation
3. ✅ **USE absolute paths** always
4. ✅ **RUN health checks** after every deployment
5. ✅ **DON'T mark complete** if errors exist
6. ✅ **ASK before destructive** operations
7. ✅ **DOCUMENT all changes** made
8. ✅ **TEST endpoints** after code changes

### Success Criteria

A task is ONLY complete when:
- [ ] Change successfully applied
- [ ] Services are healthy
- [ ] Hot-reload confirmed (if applicable)
- [ ] No errors in logs
- [ ] Endpoint tested and working
- [ ] User informed of changes
- [ ] Documentation updated

### When In Doubt

If unsure about ANYTHING:
1. Check this document
2. Check referenced documentation
3. Run health checks
4. Check logs
5. Ask the user for clarification

**NEVER assume or guess - always verify!**

---

**END OF DOCUMENT**

**Document Version:** 1.0.0
**Last Updated:** October 29, 2025
**Location:** `/Users/cope/EnGardeHQ/.claude/AGENT_DEPLOYMENT_RULES.md`
**Status:** MANDATORY FOR ALL AGENTS

This document is the definitive rulebook. All agents in the swarm must follow these rules without exception. Failure to follow these rules will result in deployment failures and wasted time.

**REMEMBER:** Verify everything. Document everything. Never assume anything.
