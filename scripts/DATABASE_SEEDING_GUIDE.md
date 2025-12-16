# Database Seeding System - Complete Guide

## Overview

The EnGarde database seeding system provides automated, versioned seeding of demo data with built-in tracking to prevent duplicate seeding and ensure data consistency across development environments.

## Key Features

- **Version Tracking**: Tracks seed versions in `database_seed_versions` table
- **Idempotent**: Safe to run multiple times (uses ON CONFLICT)
- **Automatic Integration**: Checks and prompts during dev-start.sh
- **Interactive Prompts**: User consent required before seeding
- **Management Commands**: Full CLI toolset for seed management
- **Comprehensive Logging**: All operations logged for debugging

## Architecture

### Components

```
Database Seeding System
├── SQL Scripts
│   ├── create_seed_versions_table.sql  - Initialize tracking table
│   └── seed_demo_data.sql             - v1.0.0 demo data
│
├── Shell Scripts
│   ├── check-seed-status.sh           - Check if seeding needed
│   ├── prompt-seed-database.sh        - Interactive seeding
│   ├── seed-database.sh               - Manual seeding
│   ├── reset-seed.sh                  - Reset version tracking
│   └── seed-status.sh                 - Show detailed status
│
├── Integration
│   └── dev-start.sh                   - Automatic check on startup
│
└── Logs
    └── logs/seed-database.log         - Operation logs
```

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    dev-start.sh                             │
│                  (Environment Startup)                       │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│            check-seed-status.sh                             │
│         (Check if seeding needed)                           │
└─────────────────────────┬───────────────────────────────────┘
                          │
                ┌─────────┴──────────┐
                ▼                    ▼
        ┌───────────────┐    ┌──────────────┐
        │ Seed Current  │    │ Seed Missing │
        │   (Exit 0)    │    │  (Exit 1)    │
        └───────┬───────┘    └──────┬───────┘
                │                    │
                ▼                    ▼
        ┌───────────────┐    ┌──────────────────┐
        │   Continue    │    │ prompt-seed-     │
        │   Startup     │    │ database.sh      │
        └───────────────┘    └──────┬───────────┘
                                     │
                          ┌──────────┴──────────┐
                          ▼                      ▼
                  ┌───────────────┐     ┌───────────────┐
                  │ User Says Yes │     │ User Says No  │
                  └───────┬───────┘     └───────┬───────┘
                          │                      │
                          ▼                      ▼
              ┌───────────────────┐     ┌───────────────┐
              │ Execute Seeding   │     │ Skip Seeding  │
              │ Record Version    │     │ Show Warning  │
              └───────┬───────────┘     └───────────────┘
                      │
                      ▼
              ┌───────────────────┐
              │ Display           │
              │ Credentials       │
              └───────────────────┘
```

## Current Seed Version: 1.0.0

### What's Included

**Demo Brands (4):**
- TechFlow Solutions - B2B SaaS platform
- EcoStyle Fashion - Sustainable fashion brand
- GlobalEats Delivery - Food delivery service
- Team Testing Brand - Shared brand for collaboration

**Demo Users (3):**
- demo1@engarde.local / demo123 (TechFlow Solutions)
- demo2@engarde.local / demo123 (EcoStyle Fashion)
- demo3@engarde.local / demo123 (GlobalEats Delivery)
- All users have access to Team Testing Brand

**Platform Connections (11):**
- Google Ads (TechFlow, GlobalEats, Shared)
- LinkedIn (TechFlow)
- Meta (EcoStyle, GlobalEats, Shared)
- Google Analytics (TechFlow, GlobalEats)
- Shopify (EcoStyle)
- Pinterest (EcoStyle)

**Additional Data:**
- 4 tenants with different plan tiers
- Admin roles for each tenant
- Tenant-user associations
- Campaign structure foundation

## Quick Start

### First Time Setup

```bash
# 1. Start development environment (automatic seeding check)
./scripts/dev-start.sh

# 2. When prompted, choose to seed database
# Enter 'y' when asked: "Do you want to seed the database now?"

# 3. Verify seed was successful
./scripts/seed-status.sh
```

### Manual Seeding

```bash
# Seed database manually
./scripts/seed-database.sh

# Force re-seed (resets version first)
./scripts/seed-database.sh --force
```

### Check Status

```bash
# Quick status check
./scripts/check-seed-status.sh

# Detailed status with metadata
./scripts/seed-status.sh --verbose
```

## Command Reference

### Status Commands

#### check-seed-status.sh

Check if database seeding is needed.

```bash
# Basic check
./scripts/check-seed-status.sh

# Verbose output
./scripts/check-seed-status.sh --verbose

# Quiet mode (for scripts)
./scripts/check-seed-status.sh --quiet
```

**Exit Codes:**
- 0 = Seed is current (no action needed)
- 1 = Seed is missing or outdated (action needed)
- 2 = Error (cannot determine status)

#### seed-status.sh

Display detailed seed version information.

```bash
# Basic status
./scripts/seed-status.sh

# Verbose with data counts
./scripts/seed-status.sh --verbose
```

**Shows:**
- Current seed version
- Seed metadata
- Data counts (users, brands, tenants)
- Management command reference

### Seeding Commands

#### prompt-seed-database.sh

Interactive seeding with user consent.

```bash
# Interactive prompt
./scripts/prompt-seed-database.sh

# Auto-yes (for CI/CD)
./scripts/prompt-seed-database.sh --yes

# Skip status check, force prompt
./scripts/prompt-seed-database.sh --skip-check
```

**Features:**
- Displays what will be seeded
- Explains safety (idempotent)
- Shows credentials after seeding
- Logs all operations

#### seed-database.sh

Manual database seeding.

```bash
# Seed if not already seeded
./scripts/seed-database.sh

# Force re-seed (resets version first)
./scripts/seed-database.sh --force
```

**Behavior:**
- Checks for existing seed version
- Exits if already seeded (unless --force)
- Creates tracking table if needed
- Records version after success

### Management Commands

#### reset-seed.sh

Reset seed version tracking.

```bash
# Reset with confirmation
./scripts/reset-seed.sh

# Reset without confirmation
./scripts/reset-seed.sh --yes

# Reset specific version/type
./scripts/reset-seed.sh --version 1.0.0 --type demo_data

# Reset all versions (except schema)
./scripts/reset-seed.sh --all --yes
```

**Important:** Does NOT delete data, only version tracking

## Integration with Development Workflow

### Automatic Integration

The seeding system is automatically integrated into the development workflow:

#### During Startup (dev-start.sh)

1. Services start and become healthy
2. Seed status check runs automatically
3. If seed is missing/outdated:
   - User is prompted interactively
   - User chooses to seed or skip
   - If seeded, credentials are displayed
4. Environment startup completes

#### During Reset (dev-reset.sh)

1. Database is completely cleared
2. Seed version tracking is deleted
3. Next dev-start.sh will prompt for re-seeding

#### During Rebuild (dev-rebuild.sh)

1. Containers are rebuilt
2. Database data is preserved
3. Seed versions remain intact
4. No re-seeding needed

### Manual Workflows

#### Testing Idempotency

```bash
# Run seed multiple times
./scripts/seed-database.sh --force
./scripts/seed-database.sh --force
./scripts/seed-database.sh --force

# Verify data integrity
./scripts/seed-status.sh --verbose
```

#### Testing Reset Cycle

```bash
# Reset and re-seed
./scripts/reset-seed.sh --yes
./scripts/seed-database.sh

# Verify success
./scripts/seed-status.sh
```

#### CI/CD Integration

```bash
# Non-interactive seeding for CI
./scripts/prompt-seed-database.sh --yes

# Or use direct command
./scripts/seed-database.sh --force
```

## Troubleshooting

### Common Issues

#### Issue: "database_seed_versions table does not exist"

**Cause:** First time running, table not initialized

**Solution:**
```bash
# Run seeding script (creates table automatically)
./scripts/seed-database.sh
```

#### Issue: "Seed version already exists"

**Cause:** Attempting to seed when already seeded

**Solutions:**
```bash
# Option 1: Use force flag
./scripts/seed-database.sh --force

# Option 2: Reset then seed
./scripts/reset-seed.sh --yes
./scripts/seed-database.sh
```

#### Issue: Demo credentials don't work

**Cause:** Users not created or password hash incorrect

**Diagnosis:**
```bash
# Check if users exist
docker compose -f docker-compose.dev.yml exec -T postgres \
  psql -U engarde_user -d engarde -c \
  "SELECT email, is_active FROM users WHERE email LIKE 'demo%';"
```

**Solution:**
```bash
# Re-seed with force
./scripts/seed-database.sh --force
```

#### Issue: PostgreSQL container not running

**Cause:** Services not started

**Solution:**
```bash
# Start development environment
./scripts/dev-start.sh

# Or start specific service
docker compose -f docker-compose.dev.yml up -d postgres
```

#### Issue: Partial seed data

**Cause:** Seed script failed halfway

**Diagnosis:**
```bash
# Check logs
cat /Users/cope/EnGardeHQ/logs/seed-database.log

# Check what exists
./scripts/seed-status.sh --verbose
```

**Solution:**
```bash
# Full reset and re-seed
./scripts/dev-reset.sh
./scripts/dev-start.sh
# Answer 'y' when prompted to seed
```

### Debug Commands

```bash
# View seed versions table directly
docker compose -f docker-compose.dev.yml exec -T postgres \
  psql -U engarde_user -d engarde -c \
  "SELECT * FROM database_seed_versions ORDER BY seeded_at DESC;"

# Count demo users
docker compose -f docker-compose.dev.yml exec -T postgres \
  psql -U engarde_user -d engarde -c \
  "SELECT COUNT(*) FROM users WHERE email LIKE 'demo%';"

# List brands
docker compose -f docker-compose.dev.yml exec -T postgres \
  psql -U engarde_user -d engarde -c \
  "SELECT name, tenant_id FROM brands;"

# Check platform connections
docker compose -f docker-compose.dev.yml exec -T postgres \
  psql -U engarde_user -d engarde -c \
  "SELECT platform_name, tenant_id FROM platform_connections;"
```

### Log Files

All seeding operations are logged to:
```
/Users/cope/EnGardeHQ/logs/seed-database.log
```

To view logs:
```bash
# View entire log
cat /Users/cope/EnGardeHQ/logs/seed-database.log

# View recent entries
tail -n 50 /Users/cope/EnGardeHQ/logs/seed-database.log

# Watch log in real-time
tail -f /Users/cope/EnGardeHQ/logs/seed-database.log
```

## Advanced Usage

### Creating New Seed Versions

When demo data needs to change:

1. **Increment Version**: Update version in `seed_demo_data.sql` (e.g., 1.1.0)
2. **Update Check Script**: Update EXPECTED_VERSION in `check-seed-status.sh`
3. **Modify Data**: Update INSERT statements in `seed_demo_data.sql`
4. **Test Idempotency**: Ensure ON CONFLICT clauses work correctly
5. **Update Documentation**: Document changes in seed description

### Adding New Seed Types

To add different seed types (e.g., test_data, production_setup):

1. **Create SQL Script**: Copy and modify `seed_demo_data.sql`
2. **Update Seed Type**: Change v_seed_type variable
3. **Create Management Script**: Duplicate and modify commands
4. **Update Integration**: Add to dev-start.sh if needed

### Custom Seed Scripts

```bash
# Execute custom SQL seed
docker compose -f docker-compose.dev.yml exec -T postgres \
  psql -U engarde_user -d engarde -f - < custom_seed.sql

# Record custom seed version
docker compose -f docker-compose.dev.yml exec -T postgres \
  psql -U engarde_user -d engarde -c \
  "INSERT INTO database_seed_versions (version, seed_type, description, seeded_by)
   VALUES ('custom-1.0', 'custom_data', 'My custom seed', 'developer');"
```

## Best Practices

### For Development

1. **Always check status** before assuming database state
2. **Use interactive prompts** for manual operations
3. **Review credentials** after seeding
4. **Test login** with demo accounts
5. **Check logs** if anything fails

### For CI/CD

1. **Use --yes flags** for non-interactive operation
2. **Check exit codes** to detect failures
3. **Log all operations** for debugging
4. **Reset state** between test runs
5. **Verify data** after seeding

### For Production

**NEVER use demo seed scripts in production!**

- Demo passwords are public
- Data is for testing only
- Use production-specific seeds
- Implement proper secret management
- Audit all seed operations

## File Locations

### SQL Scripts
- `/Users/cope/EnGardeHQ/production-backend/scripts/create_seed_versions_table.sql`
- `/Users/cope/EnGardeHQ/production-backend/scripts/seed_demo_data.sql`

### Shell Scripts
- `/Users/cope/EnGardeHQ/scripts/check-seed-status.sh`
- `/Users/cope/EnGardeHQ/scripts/prompt-seed-database.sh`
- `/Users/cope/EnGardeHQ/scripts/seed-database.sh`
- `/Users/cope/EnGardeHQ/scripts/reset-seed.sh`
- `/Users/cope/EnGardeHQ/scripts/seed-status.sh`

### Integration
- `/Users/cope/EnGardeHQ/scripts/dev-start.sh` (automatic check)

### Logs
- `/Users/cope/EnGardeHQ/logs/seed-database.log`

### Documentation
- `/Users/cope/EnGardeHQ/.claude/AGENT_DEPLOYMENT_RULES.md` (Agent rules)
- `/Users/cope/EnGardeHQ/scripts/DATABASE_SEEDING_GUIDE.md` (This file)

## Support

For issues or questions:

1. Check this documentation
2. Review logs: `/Users/cope/EnGardeHQ/logs/seed-database.log`
3. Check status: `./scripts/seed-status.sh --verbose`
4. Consult Agent Deployment Rules: `.claude/AGENT_DEPLOYMENT_RULES.md`
5. Try full reset: `./scripts/dev-reset.sh && ./scripts/dev-start.sh`

## Version History

### v1.0.0 (Current)
- Initial automated seeding system
- 4 demo brands (TechFlow, EcoStyle, GlobalEats, Shared)
- 3 demo users (demo1, demo2, demo3)
- 11 platform connections
- Version tracking table
- Management scripts
- Integration with dev-start.sh
- Comprehensive documentation

## Future Enhancements

Planned improvements:

- Multiple environment support (dev, staging, prod)
- Seed data versioning with migrations
- Backup/restore of seed versions
- Performance metrics collection
- Seed data validation
- Health checks for seeded data
- Automated testing of seeds
