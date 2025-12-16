# EnGarde Development Environment Guide

This guide explains how to use the modern Docker development setup with hot-reload capabilities.

## Features

- **Hot-Reload**: Automatic code synchronization and container reloading
- **Docker Compose Watch Mode**: Modern Docker Compose v2 feature for instant updates
- **Multi-Stage Dockerfiles**: Optimized development and production builds
- **Named Volumes**: Fast performance by keeping node_modules and build caches in containers
- **Health Checks**: Automated service health monitoring
- **Minimal Rebuilds**: Only rebuild when dependencies change

## Prerequisites

- Docker Desktop 4.24+ or Docker Engine with Compose v2.22+
- At least 8GB RAM available for Docker
- 10GB free disk space

## Quick Start

### Option 1: Using the Startup Script (Recommended)

```bash
# Start development environment (manual watch mode)
./dev-start.sh

# Start with automatic watch mode (recommended)
./dev-start.sh --watch

# Clean up old containers and start fresh
./dev-start.sh --clean --watch
```

### Option 2: Manual Docker Compose Commands

```bash
# Build and start all services
docker compose -f docker-compose.dev.yml up --build

# In a separate terminal, enable watch mode for hot-reload
docker compose -f docker-compose.dev.yml watch
```

## Access Points

Once started, the services are available at:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

## How It Works

### Backend Hot-Reload (FastAPI + Uvicorn)

The backend uses Uvicorn's `--reload` flag to watch for Python file changes:

1. Edit any `.py` file in `/Users/cope/EnGardeHQ/production-backend/app/`
2. Docker Compose watch mode syncs the file to the container
3. Uvicorn detects the change and reloads the FastAPI app
4. Changes are reflected immediately (usually < 1 second)

**What triggers reload:**
- Python source files (`.py`)
- Alembic migrations

**What triggers rebuild:**
- `requirements.txt` changes

### Frontend Hot-Reload (Next.js Fast Refresh)

The frontend uses Next.js Fast Refresh for instant updates:

1. Edit any file in `/Users/cope/EnGardeHQ/production-frontend/src/`
2. Docker Compose watch mode syncs the file to the container
3. Next.js Fast Refresh updates the browser automatically
4. Changes are reflected immediately without full page reload

**What triggers hot-reload:**
- React components (`.tsx`, `.jsx`)
- Pages and layouts
- Styles and CSS
- Public assets

**What triggers container restart:**
- `next.config.js` changes
- `tailwind.config.js` changes

**What triggers rebuild:**
- `package.json` changes

## Watch Mode Actions

Docker Compose watch mode supports three types of actions:

### 1. Sync (Instant File Copy)
Files are immediately copied to the container without restart.

**Backend:**
- `production-backend/app/**/*.py` → Hot-reload via Uvicorn
- `production-backend/alembic/**/*` → Available immediately

**Frontend:**
- `production-frontend/app/**/*` → Fast Refresh (Next.js app router)
- `production-frontend/components/**/*` → Fast Refresh
- `production-frontend/lib/**/*` → Fast Refresh
- `production-frontend/public/**/*` → Static assets update
- `production-frontend/styles/**/*` → Style updates

### 2. Sync+Restart (Copy + Container Restart)
Files are copied and the container restarts.

**Frontend:**
- `next.config.js` → Restart needed
- `tailwind.config.js` → Restart needed

### 3. Rebuild (Full Container Rebuild)
Container is rebuilt from Dockerfile.

**Backend:**
- `requirements.txt` → New dependencies require rebuild

**Frontend:**
- `package.json` → New dependencies require rebuild

## Development Workflow

### Daily Development

```bash
# 1. Start the development environment
./dev-start.sh --watch

# 2. Make code changes in your editor
# - Backend: Edit files in production-backend/app/
# - Frontend: Edit files in production-frontend/app/ or production-frontend/components/

# 3. Changes are automatically synced and reflected

# 4. View logs if needed
docker compose -f docker-compose.dev.yml logs -f backend
docker compose -f docker-compose.dev.yml logs -f frontend

# 5. Stop when done (Ctrl+C to stop watch mode)
docker compose -f docker-compose.dev.yml down
```

### Adding New Dependencies

**Backend (Python):**
```bash
# 1. Add package to production-backend/requirements.txt
echo "new-package>=1.0.0" >> production-backend/requirements.txt

# 2. Watch mode will automatically rebuild the container
# Or manually rebuild:
docker compose -f docker-compose.dev.yml up --build backend
```

**Frontend (Node):**
```bash
# 1. Add package to production-frontend/package.json
cd production-frontend
npm install new-package

# 2. Watch mode will automatically rebuild the container
# Or manually rebuild:
docker compose -f docker-compose.dev.yml up --build frontend
```

### Debugging

**Backend Debugging:**
```bash
# View backend logs
docker compose -f docker-compose.dev.yml logs -f backend

# Access backend container shell
docker compose -f docker-compose.dev.yml exec backend bash

# Run Python REPL with app context
docker compose -f docker-compose.dev.yml exec backend python
```

**Frontend Debugging:**
```bash
# View frontend logs
docker compose -f docker-compose.dev.yml logs -f frontend

# Access frontend container shell
docker compose -f docker-compose.dev.yml exec frontend sh

# Check Next.js build output
docker compose -f docker-compose.dev.yml exec frontend npm run build
```

## Volumes and Data Persistence

### Named Volumes (High Performance)

These are stored inside Docker and provide fast I/O:

- `frontend_node_modules` - Node.js dependencies
- `frontend_next_cache` - Next.js build cache
- `backend_pycache` - Python bytecode cache
- `backend_ml_cache` - ML model cache
- `postgres_dev_data` - PostgreSQL data
- `redis_dev_data` - Redis data

### Bind Mounts (Code Sync)

These are mounted from your host filesystem:

- `./production-backend/app` → Backend source code
- `./production-frontend/src` → Frontend source code
- `./production-backend/uploads` → File uploads
- `./production-backend/logs` → Application logs

## Performance Optimization

### File Exclusions

The following files are automatically excluded from sync for performance:

**Backend:**
- `__pycache__/`
- `*.pyc`, `*.pyo`, `*.pyd`
- `.pytest_cache/`
- `*.egg-info/`

**Frontend:**
- `node_modules/` (uses named volume)
- `.next/` (uses named volume)
- `**/*.test.tsx`, `**/*.spec.ts`

### Tips for Faster Development

1. **Keep node_modules in container**: Never mount `node_modules` from host
2. **Use named volumes for caches**: Let Docker manage `.next` and `__pycache__`
3. **Minimize bind mounts**: Only mount source code directories
4. **Use .dockerignore**: Exclude unnecessary files from build context
5. **Enable BuildKit**: Set `DOCKER_BUILDKIT=1` environment variable

## Common Issues and Solutions

### Issue: Changes not reflected in container

**Solution 1: Check watch mode is running**
```bash
# Ensure watch mode is active
docker compose -f docker-compose.dev.yml watch
```

**Solution 2: Check file permissions**
```bash
# Ensure files are readable
ls -la production-backend/app/
```

**Solution 3: Restart containers**
```bash
docker compose -f docker-compose.dev.yml restart backend frontend
```

### Issue: Frontend shows "Cannot find module"

**Solution: Rebuild frontend with fresh node_modules**
```bash
docker compose -f docker-compose.dev.yml down
docker volume rm engarde_dev_frontend_node_modules
docker compose -f docker-compose.dev.yml up --build frontend
```

### Issue: Backend shows import errors

**Solution: Rebuild backend with fresh dependencies**
```bash
docker compose -f docker-compose.dev.yml down
docker compose -f docker-compose.dev.yml up --build backend
```

### Issue: Database schema not initialized

**Solution: Recreate database volume**
```bash
docker compose -f docker-compose.dev.yml down -v
docker compose -f docker-compose.dev.yml up --build
```

### Issue: Port already in use

**Solution: Check and stop conflicting services**
```bash
# Check what's using the port
lsof -i :3000  # Frontend
lsof -i :8000  # Backend

# Stop the conflicting service or change ports in docker-compose.dev.yml
```

## Production vs Development

### Development (docker-compose.dev.yml)

- Uses `development` target in Dockerfiles
- Mounts source code as volumes
- Enables hot-reload and debugging
- Verbose logging
- Permissive CORS
- No rate limiting
- Uses local database/redis data

### Production (docker-compose.yml)

- Uses `production` target in Dockerfiles
- Copies code into image
- Uses Gunicorn for backend
- Optimized builds
- Strict security settings
- Rate limiting enabled
- Uses production secrets

## Advanced Usage

### Running Tests

```bash
# Backend tests
docker compose -f docker-compose.dev.yml exec backend pytest

# Frontend tests
docker compose -f docker-compose.dev.yml exec frontend npm test
```

### Database Migrations

```bash
# Create migration
docker compose -f docker-compose.dev.yml exec backend alembic revision --autogenerate -m "description"

# Run migrations
docker compose -f docker-compose.dev.yml exec backend alembic upgrade head
```

### Accessing Services Directly

```bash
# PostgreSQL
docker compose -f docker-compose.dev.yml exec postgres psql -U engarde_user -d engarde

# Redis
docker compose -f docker-compose.dev.yml exec redis redis-cli
```

### Clean Slate Start

```bash
# Remove all containers, volumes, and images
docker compose -f docker-compose.dev.yml down -v --rmi local

# Rebuild everything from scratch
docker compose -f docker-compose.dev.yml up --build
```

## Environment Variables

Environment variables are loaded in this order:

1. `.env` (root) - Shared configuration
2. `production-backend/.env` - Backend-specific
3. `production-frontend/.env` - Frontend-specific
4. `docker-compose.dev.yml` environment section - Override for development

## Monitoring and Logs

### View Logs

```bash
# All services
docker compose -f docker-compose.dev.yml logs -f

# Specific service
docker compose -f docker-compose.dev.yml logs -f backend

# Last 100 lines
docker compose -f docker-compose.dev.yml logs --tail=100 backend
```

### Service Status

```bash
# Check running services
docker compose -f docker-compose.dev.yml ps

# Check health status
docker compose -f docker-compose.dev.yml ps --format json | jq '.[] | {name: .Name, health: .Health}'
```

### Resource Usage

```bash
# Check container resource usage
docker stats engarde_backend_dev engarde_frontend_dev
```

## Additional Resources

- [Docker Compose Watch Mode Documentation](https://docs.docker.com/compose/file-watch/)
- [Next.js Fast Refresh](https://nextjs.org/docs/architecture/fast-refresh)
- [Uvicorn Auto-reload](https://www.uvicorn.org/#command-line-options)
- [FastAPI Development](https://fastapi.tiangolo.com/deployment/docker/)

## Support

For issues or questions:
1. Check this documentation
2. Review logs: `docker compose -f docker-compose.dev.yml logs`
3. Check Docker status: `docker info`
4. Verify disk space: `docker system df`
