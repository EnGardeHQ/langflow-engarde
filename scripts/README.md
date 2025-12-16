# EnGarde Management Scripts

Collection of utility scripts for managing the EnGarde platform and Langflow integration.

## Langflow Management

### Quick Reference

```bash
# Initial setup
./init-langflow.sh              # Initialize database and schema

# Start/Restart
./restart-langflow.sh           # Simple restart
./restart-langflow.sh -r        # Rebuild and restart
./restart-langflow.sh -r -l     # Rebuild, restart, and follow logs

# Validation
./validate-langflow.sh          # Run all health checks

# Cleanup
./cleanup-langflow.sh           # Basic cleanup
./cleanup-langflow.sh --full    # Complete reset (WARNING: deletes data)
./cleanup-langflow.sh -k        # Keep data volumes
```

### Script Details

#### init-langflow.sh
**Purpose**: Initialize Langflow database schema and permissions

**Usage**:
```bash
./init-langflow.sh
```

**Actions**:
- Checks database connection
- Creates Langflow schema (if needed)
- Sets up database roles and permissions
- Verifies schema configuration
- Optionally runs migrations

**When to use**:
- First-time setup
- After database reset
- Schema permission issues

---

#### restart-langflow.sh
**Purpose**: Restart Langflow service with optional rebuild

**Usage**:
```bash
./restart-langflow.sh [OPTIONS]
```

**Options**:
- `--rebuild, -r` - Rebuild Docker image before restarting
- `--logs, -l` - Follow logs after restart
- `--help, -h` - Show help message

**Examples**:
```bash
# Quick restart
./restart-langflow.sh

# After code changes
./restart-langflow.sh --rebuild

# Debug mode
./restart-langflow.sh --rebuild --logs
```

**When to use**:
- After configuration changes
- After code updates to custom components
- Service appears stuck or unresponsive
- Testing new Docker image

---

#### validate-langflow.sh
**Purpose**: Comprehensive validation of Langflow setup

**Usage**:
```bash
./validate-langflow.sh
```

**Tests**:
1. Docker environment (Docker, Compose installed and running)
2. Container status (all containers running and healthy)
3. Database schema (schema exists, permissions correct)
4. Service endpoints (health, API, Web UI responding)
5. Network configuration (containers on correct network)
6. Volume configuration (volumes mounted correctly)
7. Environment variables (all required vars set)
8. Log analysis (no critical errors)
9. Integration tests (API accessible)

**Exit codes**:
- `0` - All tests passed
- `1` - One or more tests failed

**When to use**:
- After initial setup
- Before deploying to production
- Troubleshooting issues
- Verifying configuration changes

---

#### cleanup-langflow.sh
**Purpose**: Clean up Langflow installation

**Usage**:
```bash
./cleanup-langflow.sh [OPTIONS]
```

**Options**:
- `--full, -f` - Full cleanup including database schema
- `--keep-data, -k` - Preserve data volumes
- `--yes, -y` - Skip confirmation prompts
- `--help, -h` - Show help message

**Cleanup levels**:

| Option | Container | Image | Volumes | Database |
|--------|-----------|-------|---------|----------|
| (default) | ✓ | ✓ | ✓ | ✗ |
| --keep-data | ✓ | ✓ | ✗ | ✗ |
| --full | ✓ | ✓ | ✓ | ✓ |

**Examples**:
```bash
# Basic cleanup (safe)
./cleanup-langflow.sh

# Complete reset (WARNING: deletes all data)
./cleanup-langflow.sh --full --yes

# Remove container but keep data
./cleanup-langflow.sh --keep-data
```

**When to use**:
- Starting fresh installation
- Removing old/broken installation
- Reclaiming disk space
- Testing initialization scripts

---

## Common Workflows

### First-Time Setup

```bash
# 1. Start infrastructure
docker-compose up -d postgres redis

# 2. Initialize Langflow
./scripts/init-langflow.sh

# 3. Start Langflow
docker-compose up -d langflow

# 4. Validate
./scripts/validate-langflow.sh

# 5. Access
open http://localhost:7860
```

### After Configuration Changes

```bash
# 1. Restart with changes
./scripts/restart-langflow.sh

# 2. Validate
./scripts/validate-langflow.sh
```

### After Code Changes

```bash
# 1. Rebuild and restart
./scripts/restart-langflow.sh --rebuild

# 2. Follow logs
docker-compose logs -f langflow

# 3. Test changes
curl http://localhost:7860/health
```

### Troubleshooting

```bash
# 1. Check current state
./scripts/validate-langflow.sh

# 2. View logs
docker-compose logs --tail=100 langflow

# 3. Try restart
./scripts/restart-langflow.sh

# 4. If still broken, clean reinstall
./scripts/cleanup-langflow.sh --full
./scripts/init-langflow.sh
docker-compose up -d langflow
```

### Complete Reset

```bash
# 1. Full cleanup (deletes everything)
./scripts/cleanup-langflow.sh --full --yes

# 2. Reinitialize
./scripts/init-langflow.sh

# 3. Start fresh
docker-compose up -d langflow

# 4. Validate
./scripts/validate-langflow.sh
```

## Environment Requirements

All scripts require:
- Bash 4.0+
- Docker 20.10+
- Docker Compose 2.0+
- PostgreSQL client tools (psql)
- curl (for health checks)
- nc (netcat, for port checks)

## Exit Codes

Standard exit codes across all scripts:
- `0` - Success
- `1` - General error
- `2` - Missing dependency
- `3` - Configuration error

## Logging

All scripts output color-coded messages:
- 🔵 **Blue** - Information messages
- 🟢 **Green** - Success messages
- 🟡 **Yellow** - Warnings
- 🔴 **Red** - Errors

## Best Practices

1. **Always validate after changes**: Run `validate-langflow.sh` after any configuration changes

2. **Use --rebuild sparingly**: Only rebuild when Dockerfile or dependencies change

3. **Check logs first**: Before restarting, check logs for the actual issue

4. **Backup before full cleanup**: Use `--keep-data` unless you're certain

5. **Test in sequence**: init → start → validate → use

## Troubleshooting Scripts

If a script fails:

1. **Check permissions**:
   ```bash
   chmod +x /Users/cope/EnGardeHQ/scripts/*.sh
   ```

2. **Verify environment**:
   ```bash
   # Check .env exists
   ls -la /Users/cope/EnGardeHQ/.env

   # Verify DATABASE_URL is set
   grep DATABASE_URL /Users/cope/EnGardeHQ/.env
   ```

3. **Run with debug output**:
   ```bash
   bash -x ./scripts/validate-langflow.sh
   ```

4. **Check dependencies**:
   ```bash
   # Docker
   docker --version
   docker-compose --version

   # PostgreSQL
   psql --version

   # Utilities
   curl --version
   nc -h
   ```

## Additional Resources

- Main documentation: `/Users/cope/EnGardeHQ/LANGFLOW_SETUP.md`
- Docker configuration: `/Users/cope/EnGardeHQ/docker-compose.yml`
- Database scripts: `/Users/cope/EnGardeHQ/production-backend/scripts/`
- Langflow docs: https://docs.langflow.org

## Support

For issues:
1. Run `./scripts/validate-langflow.sh` for diagnostics
2. Check `docker-compose logs langflow` for errors
3. Review `/Users/cope/EnGardeHQ/LANGFLOW_SETUP.md` for detailed troubleshooting

---

**Location**: `/Users/cope/EnGardeHQ/scripts/`
**Version**: 1.0.0
**Last Updated**: 2025-10-05
