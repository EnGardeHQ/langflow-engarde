# Database Seeding System - Workflow Example

## Real-World Usage Example

This document shows what users will experience when using the automated seeding system.

---

## Scenario 1: Fresh Environment Startup

### User Action
```bash
./scripts/dev-start.sh
```

### System Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  EnGarde Development Environment Startup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ Checking dependencies...
✓ All dependencies installed

ℹ Checking if Docker is running...
✓ Docker is running

ℹ Checking Docker Compose file...
✓ Docker Compose file found

ℹ Checking environment configuration...
✓ Environment file found

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Starting Development Services
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ Starting services with docker-compose...
ℹ Using: /Users/cope/EnGardeHQ/docker-compose.dev.yml
✓ Services started

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Waiting for Services to be Healthy
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ Waiting for postgres to be healthy...
✓ postgres is healthy

ℹ Waiting for redis to be healthy...
✓ redis is healthy

ℹ Waiting for backend to be healthy...
✓ backend is healthy

ℹ Waiting for frontend to be healthy...
✓ frontend is healthy

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Checking Service Endpoints
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ PostgreSQL is ready
✓ Redis is ready
✓ Backend API is ready
✓ Frontend is ready

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Database Seeding Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠ Database seeding is required

════════════════════════════════════════════════════════════════════════
                    DATABASE SEEDING REQUIRED
════════════════════════════════════════════════════════════════════════

Your database needs to be seeded with demo data.

This will create:
  • 4 demo brands (TechFlow, EcoStyle, GlobalEats, SharedTeam)
  • 3 demo users with credentials: demo1@engarde.local / demo123
  • Platform connections for testing
  • Sample campaign data

What happens:
  1. Create seed versions tracking table (if needed)
  2. Seed database with version 1.0.0 demo data
  3. Record seed version to prevent duplicate seeding

Safe operation:
  • Idempotent (safe to run multiple times)
  • Uses ON CONFLICT to handle existing data
  • No data loss - only adds missing records

════════════════════════════════════════════════════════════════════════

Do you want to seed the database now? (y/n)
> y

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Database Seeding Workflow
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ Ensuring seed versions table exists...
✓ Seed versions table initialized

ℹ Running seed script...

Seeding database...
NOTICE:  🌱 Starting Demo Data Seeding - Version 1.0.0
NOTICE:  ============================================================================
NOTICE:  📦 Creating demo tenants...
NOTICE:    ✓ Created 4 tenants
NOTICE:  👤 Creating demo users...
NOTICE:    ✓ Created 3 users
NOTICE:  🔑 Creating admin roles...
NOTICE:    ✓ Created 4 roles
NOTICE:  🔗 Linking users to tenants...
NOTICE:    ✓ Created 6 tenant-user links
NOTICE:  🏢 Creating demo brands...
NOTICE:    ✓ Created 4 brands
NOTICE:  🔌 Creating platform connections...
NOTICE:    ✓ Created 11 platform connections
NOTICE:  📝 Recording seed version...
NOTICE:  ============================================================================
NOTICE:  ✅ Demo Data Seeding Completed Successfully!
NOTICE:  ============================================================================
NOTICE:
NOTICE:  📊 Summary:
NOTICE:    • Version: 1.0.0
NOTICE:    • Tenants: 4 (techflow, ecostyle, globaleats, shared)
NOTICE:    • Users: 3
NOTICE:    • Brands: 4
NOTICE:    • Platform Connections: 11
NOTICE:
NOTICE:  🔐 Demo User Credentials:
NOTICE:    • demo1@engarde.local / demo123 (TechFlow Solutions)
NOTICE:    • demo2@engarde.local / demo123 (EcoStyle Fashion)
NOTICE:    • demo3@engarde.local / demo123 (GlobalEats Delivery)
NOTICE:    • All users have access to Team Testing Brand
NOTICE:
NOTICE:  🌐 Access:
NOTICE:    • Frontend: http://localhost:3000
NOTICE:    • Backend API: http://localhost:8000
NOTICE:    • API Docs: http://localhost:8000/docs
NOTICE:

✓ Database seeded successfully

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Database Seeding Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Demo data has been successfully seeded!

You can now log in with:
  • demo1@engarde.local / demo123 (TechFlow Solutions)
  • demo2@engarde.local / demo123 (EcoStyle Fashion)
  • demo3@engarde.local / demo123 (GlobalEats Delivery)

Access your environment:
  • Frontend: http://localhost:3000
  • Backend API: http://localhost:8000
  • API Docs: http://localhost:8000/docs

Happy developing! 🚀

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Development Environment Ready
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 Services are running!

Service URLs:
  Frontend:        http://localhost:3000
  Backend API:     http://localhost:8000
  API Docs:        http://localhost:8000/docs
  PostgreSQL:      localhost:5432
  Redis:           localhost:6379

Useful Commands:
  View logs:       ./scripts/dev-logs.sh
  Check health:    ./scripts/dev-health.sh
  Stop services:   ./scripts/dev-stop.sh
  Rebuild:         ./scripts/dev-rebuild.sh

Hot Reload:
  Backend:  Edit files in production-backend/app/ - changes apply immediately
  Frontend: Edit files in production-frontend/ - Next.js auto-reloads

Happy coding! 🎉
```

---

## Scenario 2: Startup with Existing Seed

### User Action
```bash
./scripts/dev-start.sh
```

### System Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  EnGarde Development Environment Startup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ Checking dependencies...
✓ All dependencies installed

ℹ Checking if Docker is running...
✓ Docker is running

[... services start and become healthy ...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Database Seeding Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Database seed is current

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Development Environment Ready
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 Services are running!

[... displays service URLs and commands ...]
```

**Result:** Skips seeding prompt, continues directly to ready state

---

## Scenario 3: User Declines Seeding

### User Action
```bash
./scripts/dev-start.sh
# When prompted, enters 'n'
```

### System Output

```
[... services start and seed check runs ...]

Do you want to seed the database now? (y/n)
> n

⚠ Database seeding declined

⚠  You chose not to seed the database.

To seed later, run:
  ./scripts/seed-database.sh

Note: The application may not function properly without seed data.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Development Environment Ready
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[... continues with startup ...]
```

**Result:** User warned, seeding skipped, can seed manually later

---

## Scenario 4: Manual Seeding

### User Action
```bash
./scripts/seed-database.sh
```

### System Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Manual Database Seeding
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ Checking for existing seed...
✓ No existing seed found

ℹ Ensuring seed versions table exists...
✓ Seed versions table ready

ℹ Running seed script...

[... seeding output ...]

✓ Database seeded successfully

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Seeding Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Database has been successfully seeded

Test credentials:
  • demo1@engarde.local / demo123
  • demo2@engarde.local / demo123
  • demo3@engarde.local / demo123
```

**Result:** Database seeded manually

---

## Scenario 5: Checking Seed Status

### User Action
```bash
./scripts/check-seed-status.sh
```

### System Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Database Seed Status Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Seed versions table exists
✓ Seed version is current

Status: CURRENT
  Version: 1.0.0
  Type: demo_data

✓ No seeding action required
```

**Exit Code:** 0 (success)

---

## Scenario 6: Detailed Status Report

### User Action
```bash
./scripts/seed-status.sh --verbose
```

### System Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Database Seed Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Seed versions table exists

✓ Demo data seed is current

Current Status:
  Version:     1.0.0
  Type:        demo_data
  Expected:    1.0.0

Detailed Information:
 version | seed_type | description                           | seeded_at              | seeded_by    | brands | users
---------+-----------+---------------------------------------+------------------------+--------------+--------+-------
 1.0.0   | demo_data | Demo data with 4 brands, 3 users     | 2025-10-29 16:30:45    | dev-start.sh | 4      | 3

All Seed Versions:
 version | seed_type      | description                           | seeded_at           | seeded_by
---------+----------------+---------------------------------------+---------------------+--------------
 1.0.0   | demo_data      | Demo data with 4 brands, 3 users     | 2025-10-29 16:30:45 | dev-start.sh
 0.0.0   | schema_setup   | Initial database_seed_versions table | 2025-10-29 16:25:12 | system

Demo Data Counts:
  Demo Users:              3
  Brands:                  4
  Tenants:                 4
  Platform Connections:    11

Management Commands:
  Check status:    ./scripts/check-seed-status.sh
  Seed database:   ./scripts/seed-database.sh
  Reset seed:      ./scripts/reset-seed.sh
  Interactive:     ./scripts/prompt-seed-database.sh
```

**Result:** Comprehensive status information displayed

---

## Scenario 7: Force Re-Seeding

### User Action
```bash
./scripts/seed-database.sh --force
```

### System Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Manual Database Seeding
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ Checking for existing seed...
⚠ Force mode enabled - resetting existing seed
ℹ Resetting seed version...
✓ Seed version reset

ℹ Ensuring seed versions table exists...
✓ Seed versions table ready

ℹ Running seed script...

[... seeding output ...]

✓ Database seeded successfully

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Seeding Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Database has been successfully seeded

Test credentials:
  • demo1@engarde.local / demo123
  • demo2@engarde.local / demo123
  • demo3@engarde.local / demo123
```

**Result:** Existing seed reset and database re-seeded

---

## Scenario 8: Reset Seed Version

### User Action
```bash
./scripts/reset-seed.sh
```

### System Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Reset Database Seed Versions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ Current seed versions:

 version | seed_type    | description                              | seeded_at
---------+--------------+------------------------------------------+------------------------
 1.0.0   | demo_data    | Demo data with 4 brands, 3 users        | 2025-10-29 16:30:45
 0.0.0   | schema_setup | Initial database_seed_versions table    | 2025-10-29 16:25:12

⚠  WARNING: This will clear seed version tracking

This will allow:
  • Re-running seed scripts
  • Testing seed idempotency
  • Forcing fresh seed data

Note: This does NOT delete existing data, only version tracking

Are you sure you want to continue? (y/n)
> y

ℹ Resetting seed version: 1.0.0 (demo_data)
✓ Reset seed version: 1.0.0 (demo_data)

✓ Seed version tracking has been reset

You can now re-seed the database with:
  ./scripts/seed-database.sh
```

**Result:** Version tracking reset (data preserved)

---

## Scenario 9: Agent Deployment Check

### Agent Action
Agent runs deployment and checks seed status

### Agent Output (to user)

```markdown
## Deployment Complete

**Status:** ✓ Successful
**Date:** 2025-10-29 16:45:30

### Services Status

All services are running and healthy:
- ✓ PostgreSQL (healthy)
- ✓ Redis (healthy)
- ✓ Backend API (healthy)
- ✓ Frontend (healthy)

### Database Seed Status

**Status:** Current
**Version:** 1.0.0
**Type:** demo_data
**Seeded At:** 2025-10-29 16:30:45

### Demo Credentials

You can log in with these test accounts:
- demo1@engarde.local / demo123 (TechFlow Solutions)
- demo2@engarde.local / demo123 (EcoStyle Fashion)
- demo3@engarde.local / demo123 (GlobalEats Delivery)

### Access Points

- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs

### Management Commands

- Check seed status: `./scripts/check-seed-status.sh`
- View seed details: `./scripts/seed-status.sh --verbose`
- Re-seed database: `./scripts/seed-database.sh --force`
- Reset seed version: `./scripts/reset-seed.sh`

### Next Steps

Your environment is ready for development. All demo data has been seeded and verified.
```

**Result:** Agent provides comprehensive deployment report with seed status

---

## Key Benefits Demonstrated

### 1. Automatic Integration
- Seeding check runs automatically during startup
- No manual intervention needed unless prompted

### 2. User Control
- User consent required before seeding
- Clear information about what will be created
- Can decline and seed later

### 3. Status Transparency
- Easy to check current seed status
- Detailed information available on demand
- Clear feedback at every step

### 4. Safe Operations
- Idempotent seeding (safe to run multiple times)
- Reset doesn't delete data, only tracking
- Force flag for intentional re-seeding

### 5. Comprehensive Documentation
- All commands have help text
- Clear error messages
- Guidance on next steps

### 6. Agent Integration
- Agents check seed status automatically
- Include seed status in reports
- Provide management commands to users

---

## Common Use Cases Summary

| Use Case | Command | Result |
|----------|---------|--------|
| **Start environment** | `./scripts/dev-start.sh` | Automatic check, prompt if needed |
| **Check status** | `./scripts/check-seed-status.sh` | Quick status check |
| **View details** | `./scripts/seed-status.sh --verbose` | Comprehensive information |
| **Manual seed** | `./scripts/seed-database.sh` | Seed if not already seeded |
| **Force re-seed** | `./scripts/seed-database.sh --force` | Reset and re-seed |
| **Reset tracking** | `./scripts/reset-seed.sh` | Clear version tracking |
| **Test workflow** | `./scripts/test-seed-workflow.sh` | Interactive demo |

---

This automated seeding system provides a seamless, user-friendly experience while maintaining complete control and transparency throughout the process.
