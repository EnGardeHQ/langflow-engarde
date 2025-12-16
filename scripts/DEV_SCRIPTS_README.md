# EnGarde Development Scripts

Modern Docker development workflow scripts for the EnGarde platform.

## Quick Start

```bash
# Start development environment
./scripts/dev-start.sh

# View logs
./scripts/dev-logs.sh

# Check health
./scripts/dev-health.sh

# Stop environment
./scripts/dev-stop.sh
```

## Development Scripts

### dev-start.sh
**Purpose**: Start the complete development environment with hot-reload enabled

**Usage**:
```bash
./scripts/dev-start.sh
```

**What it does**:
- ✓ Checks all dependencies (Docker, docker-compose, curl)
- ✓ Validates Docker Compose configuration
- ✓ Starts all services (postgres, redis, backend, frontend)
- ✓ Waits for health checks to pass
- ✓ Verifies service endpoints
- ✓ Displays URLs and helpful commands

**Output**:
```
Frontend:        http://localhost:3000
Backend API:     http://localhost:8000
API Docs:        http://localhost:8000/docs
PostgreSQL:      localhost:5432
Redis:           localhost:6379
```

**Hot Reload**:
- Backend: Edit files in `production-backend/app/` - uvicorn auto-reloads
- Frontend: Edit files in `production-frontend/src/` - Next.js Fast Refresh
- Docker Compose Watch Mode: Automatically syncs file changes

**First run**: May take 3-5 minutes to build images and initialize database

---

### dev-stop.sh
**Purpose**: Stop development environment cleanly

**Usage**:
```bash
# Stop services (preserve data)
./scripts/dev-stop.sh

# Stop and remove all volumes (delete data)
./scripts/dev-stop.sh --clean
```

**Options**:
- `--clean, -c` - Remove volumes and networks (WARNING: deletes database data)
- `--help, -h` - Show help message

**What it does**:
- Stops all running containers
- Optionally removes volumes (with --clean flag)
- Removes orphaned containers
- Shows cleanup status

**Note**: By default, volumes are preserved so your database data persists

---

### dev-rebuild.sh
**Purpose**: Force clean rebuild of services without cache

**Usage**:
```bash
# Basic rebuild
./scripts/dev-rebuild.sh

# Rebuild and follow logs
./scripts/dev-rebuild.sh --logs
```

**Options**:
- `--logs, -l` - Follow logs after rebuild
- `--help, -h` - Show help message

**What it does**:
1. Stops all containers
2. Clears Docker build cache
3. Rebuilds images without cache
4. Restarts services
5. Waits for health checks

**When to use**:
- After changing Dockerfiles
- After updating dependencies (package.json, requirements.txt)
- Weird caching issues
- Major code changes affecting build

**Build time**: Typically 5-10 minutes (frontend is the slowest)

---

### dev-logs.sh
**Purpose**: View and filter logs from development services

**Usage**:
```bash
# Follow all logs
./scripts/dev-logs.sh

# View last 50 backend logs
./scripts/dev-logs.sh -n 50 backend

# Filter for errors
./scripts/dev-logs.sh -g "error|ERROR|Error"

# View with timestamps
./scripts/dev-logs.sh -t frontend

# Dump logs without following
./scripts/dev-logs.sh --no-follow -n 200
```

**Options**:
- `-f, --follow` - Follow log output (default)
- `-n, --tail LINES` - Number of lines to show (default: 100)
- `-g, --grep PATTERN` - Filter logs by pattern
- `-t, --timestamps` - Show timestamps
- `--no-follow` - Just dump logs and exit

**Services**:
- `frontend` - Next.js frontend logs
- `backend` - FastAPI backend logs
- `postgres` - PostgreSQL logs
- `redis` - Redis logs
- (none) - All services

**Filtering examples**:
```bash
# Error logs
./scripts/dev-logs.sh -g "error\|ERROR\|Error"

# HTTP errors
./scripts/dev-logs.sh -g "\" 4[0-9][0-9]"  # 4xx errors
./scripts/dev-logs.sh -g "\" 5[0-9][0-9]"  # 5xx errors

# Specific API endpoint
./scripts/dev-logs.sh -g "/api/auth"

# Database queries
./scripts/dev-logs.sh -g "SELECT\|INSERT\|UPDATE" postgres
```

---

### dev-health.sh
**Purpose**: Comprehensive health check of all services

**Usage**:
```bash
# Basic health check
./scripts/dev-health.sh

# Detailed health check with resource usage
./scripts/dev-health.sh --verbose
```

**Options**:
- `--verbose, -v` - Show detailed information
- `--help, -h` - Show help message

**What it checks**:
1. ✓ Docker daemon status
2. ✓ Container status (running/stopped)
3. ✓ Container health (healthy/unhealthy)
4. ✓ Port mappings
5. ✓ PostgreSQL connectivity and database access
6. ✓ Redis connectivity
7. ✓ Backend API health endpoint
8. ✓ Frontend accessibility
9. ✓ Recent errors in logs
10. ✓ Resource usage (CPU, memory) in verbose mode

**Exit codes**:
- `0` - All services healthy
- `1` - One or more health issues detected

**Example output**:
```
✓ PostgreSQL is accepting connections
✓ Database 'engarde' is accessible
✓ Redis is responding to PING
✓ Backend API /health endpoint is responding
✓ Frontend is responding on http://localhost:3000
✓ backend: No errors in last 100 lines
```

---

### dev-reset.sh
**Purpose**: Complete environment reset (nuclear option)

**Usage**:
```bash
# Interactive reset (will prompt for confirmation)
./scripts/dev-reset.sh

# Reset without confirmation
./scripts/dev-reset.sh --yes
```

**Options**:
- `--yes, -y` - Skip confirmation prompt
- `--help, -h` - Show help message

**What it does**:
1. Stops all containers
2. Removes all containers
3. Removes all volumes (DATABASE DATA DELETED!)
4. Removes all networks
5. Cleans Docker build cache
6. Removes dangling images
7. Cleans local caches (__pycache__, .next)

**What is preserved**:
- ✓ Source code
- ✓ Docker images (for faster rebuild)
- ✓ Local files (uploads, logs in your directories)

**What is deleted**:
- ✗ All database data
- ✗ All Docker volumes
- ✗ Build cache
- ✗ Compiled/generated files

**When to use**:
- Environment is completely broken
- Want a truly fresh start
- Cleaning up after major changes
- Database schema changes require reset

**Safety**: Prompts for confirmation and has 5-second countdown unless --yes flag is used

---

## Common Workflows

### Daily Development

```bash
# Morning - Start environment
./scripts/dev-start.sh

# Work on code (files auto-reload)
# Edit production-backend/app/*.py
# Edit production-frontend/src/*.tsx

# View logs while developing
./scripts/dev-logs.sh backend
./scripts/dev-logs.sh frontend

# Check if everything is healthy
./scripts/dev-health.sh

# Evening - Stop environment
./scripts/dev-stop.sh
```

### After Pulling Changes

```bash
# If only code changed
./scripts/dev-start.sh  # Hot-reload handles it

# If dependencies changed
./scripts/dev-rebuild.sh

# If database schema changed
./scripts/dev-reset.sh  # Nuclear option
./scripts/dev-start.sh
```

### Debugging Issues

```bash
# 1. Check health status
./scripts/dev-health.sh --verbose

# 2. View logs
./scripts/dev-logs.sh

# 3. Try restart
./scripts/dev-stop.sh
./scripts/dev-start.sh

# 4. If still broken, rebuild
./scripts/dev-rebuild.sh

# 5. Nuclear option
./scripts/dev-reset.sh
./scripts/dev-start.sh
```

### Dependency Updates

```bash
# After updating requirements.txt (Python)
./scripts/dev-rebuild.sh

# After updating package.json (Node.js)
./scripts/dev-rebuild.sh

# Docker Compose Watch will auto-rebuild!
# Just edit the file and watch mode detects it
```

### Performance Optimization

```bash
# Check resource usage
./scripts/dev-health.sh --verbose

# View logs for slow queries
./scripts/dev-logs.sh -g "slow query" postgres

# Monitor backend performance
./scripts/dev-logs.sh -g "ms\|seconds" backend
```

### Testing Specific Features

```bash
# Test authentication flow
./scripts/dev-logs.sh -g "/api/auth" backend

# Test database operations
./scripts/dev-logs.sh -g "SELECT\|INSERT\|UPDATE" backend

# Watch for errors
./scripts/dev-logs.sh -g "error\|ERROR" --follow
```

## Docker Compose Watch Mode

The development environment uses Docker Compose v2 Watch Mode for intelligent hot-reload:

**Backend (FastAPI)**:
- Syncs `production-backend/app/` → auto-reload via uvicorn
- Syncs `production-backend/alembic/` → migration changes
- Rebuilds on `requirements.txt` changes

**Frontend (Next.js)**:
- Syncs `production-frontend/src/` → Fast Refresh
- Syncs `production-frontend/public/` → asset changes
- Restarts on config file changes (next.config.js, tailwind.config.js)
- Rebuilds on `package.json` changes

**To use watch mode**:
```bash
# Start with watch mode (alternative to dev-start.sh)
docker compose -f docker-compose.dev.yml up --build
docker compose -f docker-compose.dev.yml watch

# Or use our convenience script (recommended)
./scripts/dev-start.sh
```

## Environment Configuration

### Required Files

- `/Users/cope/EnGardeHQ/.env` - Root environment variables
- `/Users/cope/EnGardeHQ/production-backend/.env` - Backend-specific vars
- `/Users/cope/EnGardeHQ/production-frontend/.env` - Frontend-specific vars

### Key Environment Variables

```bash
# Database
DATABASE_URL=postgresql://engarde_user:engarde_password@postgres:5432/engarde

# Redis
REDIS_URL=redis://redis:6379/0

# Backend
DEBUG=true
LOG_LEVEL=debug
SECRET_KEY=dev-secret-key-change-in-production

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=dev-nextauth-secret

# Development
NODE_ENV=development
RELOAD=true
```

## Troubleshooting

### Containers won't start

```bash
# Check Docker is running
docker info

# Check for port conflicts
lsof -i :3000  # Frontend
lsof -i :8000  # Backend
lsof -i :5432  # PostgreSQL

# Reset and start fresh
./scripts/dev-reset.sh --yes
./scripts/dev-start.sh
```

### Health checks failing

```bash
# View detailed health status
./scripts/dev-health.sh --verbose

# Check specific service logs
./scripts/dev-logs.sh backend
./scripts/dev-logs.sh frontend

# Rebuild if needed
./scripts/dev-rebuild.sh
```

### Hot reload not working

```bash
# Verify volumes are mounted
docker compose -f docker-compose.dev.yml ps

# Check watch mode is active
docker compose -f docker-compose.dev.yml ps --format json

# Restart with rebuild
./scripts/dev-rebuild.sh
```

### Database connection errors

```bash
# Check PostgreSQL health
./scripts/dev-health.sh

# View PostgreSQL logs
./scripts/dev-logs.sh postgres

# Reset database (WARNING: deletes data)
./scripts/dev-reset.sh --yes
./scripts/dev-start.sh
```

### Frontend build errors

```bash
# View frontend build logs
./scripts/dev-logs.sh frontend

# Clear caches and rebuild
./scripts/dev-reset.sh --yes
./scripts/dev-rebuild.sh
```

### Permission errors on macOS

```bash
# Make scripts executable
chmod +x /Users/cope/EnGardeHQ/scripts/dev-*.sh

# Fix Docker permissions
# Settings > Resources > File Sharing
# Add /Users/cope/EnGardeHQ
```

## System Requirements

### Software
- Docker Desktop 4.20+ (includes Docker Compose v2)
- macOS 12+ (Darwin 24.5.0+)
- Bash 4.0+
- curl (for health checks)

### Hardware (Recommended)
- 8GB+ RAM
- 20GB+ free disk space
- Multi-core CPU for faster builds

### Optional Tools
- `pg_isready` - Better PostgreSQL health checks
- `redis-cli` - Better Redis health checks
- `jq` - JSON parsing in scripts

## Performance Tips

1. **Use SSD**: Docker volumes on SSD are much faster
2. **Allocate memory**: Docker Desktop > Settings > Resources > 8GB RAM
3. **Enable BuildKit**: `export DOCKER_BUILDKIT=1`
4. **Prune regularly**: `docker system prune -a --volumes` (careful!)
5. **Use watch mode**: Faster than manual rebuilds
6. **Keep images**: Don't delete images unless space-constrained

## Script Exit Codes

All scripts follow this convention:

- `0` - Success
- `1` - General error
- `2` - Missing dependency

Use in CI/CD or automation:
```bash
if ./scripts/dev-health.sh; then
    echo "All healthy!"
else
    echo "Health check failed"
    exit 1
fi
```

## Contributing

When modifying scripts:
1. Maintain consistent output format (colored, structured)
2. Include helpful error messages
3. Use absolute paths (not relative)
4. Test on macOS (Darwin platform)
5. Update this README with changes

## Additional Resources

- Main documentation: `/Users/cope/EnGardeHQ/`
- Docker Compose file: `/Users/cope/EnGardeHQ/docker-compose.dev.yml`
- Production Compose: `/Users/cope/EnGardeHQ/docker-compose.yml`
- Langflow scripts: See `README.md` in this directory

---

**Location**: `/Users/cope/EnGardeHQ/scripts/`
**Version**: 2.0.0
**Last Updated**: 2025-10-29
**Platform**: macOS (Darwin)
