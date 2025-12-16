# EnGarde Application Cleanup Guide

## Quick Reference

### Emergency Cleanup (Current Issue)
```bash
# Complete cleanup - kills all processes and containers
./cleanup.sh --hard
```

### Regular Cleanup Options
```bash
# Standard cleanup (graceful termination)
./cleanup.sh

# Aggressive cleanup (force kill processes)
./cleanup.sh --hard

# Check what's running without cleanup
./cleanup.sh --verify-only
```

## Common Port Conflicts

| Port | Service | Purpose |
|------|---------|---------|
| 3000 | Frontend | Next.js development server |
| 3001 | Frontend | Docker container (production) |
| 8000 | Backend | FastAPI/uvicorn server |
| 8001 | Backend | Alternative backend instance |
| 8002 | Backend | Alternative backend instance |
| 7860 | Langflow | AI workflow interface |
| 5432 | PostgreSQL | Database |
| 6379 | Redis | Cache/session store |

## Manual Cleanup Commands

### Kill Specific Process Types
```bash
# Kill all Node.js dev servers
pkill -f "node.*next"
pkill -f "node.*dev"

# Kill all Python backend servers
pkill -f "uvicorn"
pkill -f "gunicorn"

# Check specific ports
lsof -i :3000 -i :3001 -i :8000 -i :8001 -i :8002
```

### Docker Management
```bash
# Stop all containers
docker-compose down

# Remove all stopped containers
docker container prune -f

# Remove unused networks
docker network prune -f

# Nuclear option - stop everything
docker stop $(docker ps -q)
```

### Port-Specific Cleanup
```bash
# Kill process on specific port
kill -9 $(lsof -ti :3000)  # Replace 3000 with target port
```

## Verification Commands

```bash
# Check running processes
ps aux | grep -E "(node|uvicorn|gunicorn)" | grep -v grep

# Check port usage
lsof -i :3000 -i :3001 -i :8000 -i :8001 -i :8002

# Check Docker status
docker ps
docker-compose ps
```

## Starting Fresh

### Development Mode
```bash
# Frontend
cd production-frontend
npm run dev  # Runs on port 3000

# Backend
cd production-backend
python3 -m uvicorn app.main:app --reload --port 8000
```

### Production Mode (Docker)
```bash
# All services
docker-compose up

# Specific services
docker-compose up frontend backend
```

## Authentication Issues Resolution

The authentication issues were caused by:
1. **Multiple backend instances** running on different ports (8000, 8001, 8002)
2. **Frontend connecting to wrong backend** instance
3. **Port conflicts** between Docker containers and development servers
4. **Stale processes** from previous application starts

### Resolution Steps
1. Kill all running processes on target ports
2. Stop all Docker containers cleanly
3. Clear port bindings
4. Start services in correct order with proper configuration

## Prevention

### Before Starting Development
```bash
# Always check current state
./cleanup.sh --verify-only

# Clean up if needed
./cleanup.sh
```

### Proper Shutdown
```bash
# Stop development servers gracefully
Ctrl+C in terminal windows

# Stop Docker services properly
docker-compose down
```

## Troubleshooting

### Script Fails
- Check permissions: `chmod +x cleanup.sh`
- Run with verbose output: `bash -x cleanup.sh`
- Manual cleanup using commands above

### Persistent Processes
- Some processes may require `sudo` to kill
- Check for parent processes: `pstree -p <pid>`
- System processes may restart automatically

### Docker Issues
- Restart Docker Desktop if containers won't stop
- Check Docker daemon: `docker info`
- Reset Docker if necessary (nuclear option)

## Log Analysis

The cleanup script provides colored output:
- **BLUE**: Information messages
- **GREEN**: Success messages
- **YELLOW**: Warnings (process found, needs attention)
- **RED**: Errors (cleanup failed)

Always verify the cleanup succeeded before starting new instances.