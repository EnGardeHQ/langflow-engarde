# EnGarde Development Scripts - Quick Reference

## One-Line Commands

```bash
# Start development
./scripts/dev-start.sh

# Stop development
./scripts/dev-stop.sh

# View all logs
./scripts/dev-logs.sh

# Check health
./scripts/dev-health.sh

# Rebuild everything
./scripts/dev-rebuild.sh

# Nuclear reset
./scripts/dev-reset.sh
```

## Common Tasks

### Start Working
```bash
cd /Users/cope/EnGardeHQ
./scripts/dev-start.sh
# Wait 1-2 minutes for services to start
# Open http://localhost:3000
```

### View Logs
```bash
# All logs
./scripts/dev-logs.sh

# Specific service
./scripts/dev-logs.sh backend
./scripts/dev-logs.sh frontend

# Filter for errors
./scripts/dev-logs.sh -g "error|ERROR"

# Last 50 lines, no follow
./scripts/dev-logs.sh -n 50 --no-follow
```

### Check Status
```bash
# Quick health check
./scripts/dev-health.sh

# Detailed with resource usage
./scripts/dev-health.sh --verbose
```

### Stop Working
```bash
# Stop (keep data)
./scripts/dev-stop.sh

# Stop and clean
./scripts/dev-stop.sh --clean
```

### Rebuilding
```bash
# After dependency changes
./scripts/dev-rebuild.sh

# Rebuild and watch logs
./scripts/dev-rebuild.sh --logs
```

### Complete Reset
```bash
# Interactive (will ask for confirmation)
./scripts/dev-reset.sh

# No confirmation (dangerous!)
./scripts/dev-reset.sh --yes
```

## Troubleshooting One-Liners

```bash
# Service not responding
./scripts/dev-stop.sh && ./scripts/dev-start.sh

# Weird behavior
./scripts/dev-rebuild.sh

# Everything is broken
./scripts/dev-reset.sh --yes && ./scripts/dev-start.sh

# Check what's wrong
./scripts/dev-health.sh --verbose

# View recent errors
./scripts/dev-logs.sh -g "error|ERROR" --no-follow
```

## Service URLs

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

## File Locations

- **Scripts**: `/Users/cope/EnGardeHQ/scripts/`
- **Backend**: `/Users/cope/EnGardeHQ/production-backend/`
- **Frontend**: `/Users/cope/EnGardeHQ/production-frontend/`
- **Docker Compose**: `/Users/cope/EnGardeHQ/docker-compose.dev.yml`
- **Environment**: `/Users/cope/EnGardeHQ/.env`

## Hot Reload

Changes to these directories auto-reload:
- `production-backend/app/` → Backend reloads
- `production-frontend/src/` → Frontend Fast Refresh

Requires rebuild:
- `requirements.txt` → Backend dependencies
- `package.json` → Frontend dependencies
- `Dockerfile` → Container configuration

## Quick Debugging

```bash
# 1. Health check
./scripts/dev-health.sh

# 2. View logs
./scripts/dev-logs.sh [service]

# 3. Restart
./scripts/dev-stop.sh && ./scripts/dev-start.sh

# 4. Rebuild
./scripts/dev-rebuild.sh

# 5. Reset
./scripts/dev-reset.sh
```

## Exit Codes

- `0` = Success
- `1` = Error
- `2` = Missing dependency

Use in scripts:
```bash
if ./scripts/dev-health.sh; then
    echo "Healthy!"
fi
```

## Help Commands

```bash
./scripts/dev-start.sh --help
./scripts/dev-stop.sh --help
./scripts/dev-logs.sh --help
./scripts/dev-health.sh --help
./scripts/dev-rebuild.sh --help
./scripts/dev-reset.sh --help
```

## Keyboard Shortcuts

- `Ctrl+C` - Stop following logs
- `Ctrl+C` - Cancel reset operation
- Type `yes` - Confirm destructive operations

## Common Patterns

### Morning Routine
```bash
cd /Users/cope/EnGardeHQ
./scripts/dev-start.sh
# Code while services run
```

### Evening Routine
```bash
./scripts/dev-stop.sh
# Data is preserved for tomorrow
```

### After Git Pull
```bash
# If only code changed
./scripts/dev-start.sh

# If dependencies changed
./scripts/dev-rebuild.sh
```

### Debugging Session
```bash
# Terminal 1: Logs
./scripts/dev-logs.sh backend

# Terminal 2: Watch health
watch -n 5 './scripts/dev-health.sh'

# Terminal 3: Development
# Edit code
```

## Script Cheat Sheet

| Script | Purpose | Data Safe? | Speed |
|--------|---------|------------|-------|
| `dev-start.sh` | Start environment | ✓ Yes | Fast |
| `dev-stop.sh` | Stop services | ✓ Yes | Fast |
| `dev-stop.sh --clean` | Stop + delete data | ✗ No | Fast |
| `dev-logs.sh` | View logs | ✓ Yes | Instant |
| `dev-health.sh` | Check status | ✓ Yes | Fast |
| `dev-rebuild.sh` | Force rebuild | ✓ Yes | Slow (5-10m) |
| `dev-reset.sh` | Nuclear reset | ✗ No | Medium |

## Tips

1. **Use watch mode**: Just edit files, they auto-reload
2. **Keep data**: Use `dev-stop.sh` not `dev-stop.sh --clean`
3. **Check health first**: Run `dev-health.sh` before debugging
4. **View logs**: Use `dev-logs.sh` with grep filters
5. **Reset last resort**: Try restart and rebuild before reset

---

**Keep this handy!** Bookmark or print for quick reference.
