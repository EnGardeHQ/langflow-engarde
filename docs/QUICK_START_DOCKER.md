# EnGarde Docker Quick Start Guide

Get up and running with EnGarde in under 5 minutes.

## Prerequisites

- **Docker Desktop 4.20+** (includes Docker Compose v2.22+)
  - Download: https://www.docker.com/products/docker-desktop
  - Verify: `docker compose version` (should be >= 2.22.0)
- **Git**
- **8GB+ RAM** available for Docker Desktop

## First-Time Setup

### 1. Clone and Configure

```bash
# Clone the repository
git clone <repository-url>
cd EnGardeHQ

# Copy environment template
cp .env.example .env

# Edit .env with your settings (optional for local development)
# nano .env  # or use your preferred editor
```

### 2. Start Development Environment

```bash
# Start all services with hot-reload
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --watch

# Or use the build flag on first run to ensure fresh images
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build --watch
```

### 3. Wait for Services to Initialize

Watch the logs for these messages:

```
✓ postgres  | database system is ready to accept connections
✓ redis     | Ready to accept connections
✓ backend   | Uvicorn running on http://0.0.0.0:8000
✓ frontend  | Ready in X.Xs
```

Expected startup time: **~2 minutes** (longer on first run)

### 4. Access the Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Langflow** (if enabled): http://localhost:7860

### 5. Verify Everything Works

```bash
# Test backend health
curl http://localhost:8000/health

# Expected response:
# {"status":"healthy","timestamp":"...","database":"connected","redis":"connected"}

# Test frontend (in browser)
# Open: http://localhost:3000
# You should see the EnGarde login page
```

## Development Workflow

### Making Code Changes

#### Backend Changes (Python/FastAPI)

1. Edit any file in `production-backend/app/`
2. Save the file
3. Watch terminal logs: `Reloading...` appears within 1 second
4. Test your changes: `curl http://localhost:8000/your-endpoint`

Example:
```bash
# Edit a file
nano production-backend/app/api/users.py

# Save and watch the logs
# You'll see: "WARNING:  WatchFiles detected changes in 'app/api/users.py'. Reloading..."

# Test immediately
curl http://localhost:8000/api/users
```

#### Frontend Changes (Next.js/React)

1. Edit any file in `production-frontend/src/`
2. Save the file
3. Browser automatically updates (Fast Refresh) within 500ms
4. Component state is preserved (no page reload)

Example:
```bash
# Edit a component
nano production-frontend/src/components/UserList.tsx

# Save and watch your browser
# The component updates automatically without losing state
```

### Common Commands

```bash
# View logs
docker compose logs -f                    # All services
docker compose logs -f backend            # Backend only
docker compose logs -f frontend           # Frontend only
docker compose logs --tail=100 backend    # Last 100 lines

# Restart a service
docker compose restart backend            # Restart backend
docker compose restart frontend           # Restart frontend

# Stop services
docker compose down                       # Stop all services (keeps volumes)
docker compose down -v                    # Stop and remove volumes (fresh start)

# Rebuild a service
docker compose build backend              # Rebuild backend image
docker compose up -d --build backend      # Rebuild and restart backend

# Execute commands in containers
docker compose exec backend bash          # Open shell in backend
docker compose exec frontend sh           # Open shell in frontend
docker compose exec backend python manage.py  # Run management command
docker compose exec backend alembic upgrade head  # Run migrations

# Database operations
docker compose exec postgres psql -U engarde_user -d engarde
```

## Shell Aliases (Recommended)

Add these to your `~/.bashrc`, `~/.zshrc`, or `~/.profile`:

```bash
# Docker Compose shortcuts
alias dc='docker compose -f docker-compose.yml -f docker-compose.dev.yml'
alias dcup='dc up --watch'
alias dcdown='dc down'
alias dcbuild='dc build'
alias dclogs='dc logs -f'
alias dcps='dc ps'
alias dcrestart='dc restart'

# Service-specific shortcuts
alias dcbackend='dc logs -f backend'
alias dcfrontend='dc logs -f frontend'
alias dcdb='dc exec postgres psql -U engarde_user -d engarde'

# Common operations
alias dcclean='dc down -v && docker system prune -f'
alias dcrebuild='dc down && dc build --no-cache && dcup'
```

Usage after adding aliases:
```bash
dcup              # Start development environment
dclogs            # View all logs
dcbackend         # View backend logs
dcdown            # Stop services
```

## Troubleshooting

### Services Won't Start

**Check if ports are in use:**
```bash
# Check if ports are available
lsof -i :3000  # Frontend
lsof -i :8000  # Backend
lsof -i :5432  # PostgreSQL

# If occupied, either stop the service or change the port in docker-compose.dev.yml
```

**Reset everything:**
```bash
docker compose down -v              # Remove containers and volumes
docker system prune -f              # Clean up Docker cache
rm -rf production-backend/__pycache__
rm -rf production-frontend/.next
docker compose up --build --watch   # Fresh start
```

### Code Changes Not Reflecting

**Check if watch mode is active:**
```bash
docker compose ps
# Look for "Watch" indicator next to service names
```

**Verify volume mounts:**
```bash
docker compose exec backend ls -la /app/app
# Should show your source files with recent timestamps
```

**Force restart:**
```bash
docker compose restart backend frontend
```

### Slow Performance (macOS/Windows)

**Enable VirtioFS in Docker Desktop:**
```
Docker Desktop → Settings → General → "Enable VirtioFS accelerated directory sharing"
```

**Check resource allocation:**
```
Docker Desktop → Settings → Resources
Recommended: 4+ CPUs, 8+ GB Memory
```

### Database Issues

**Reset database:**
```bash
docker compose down -v  # WARNING: Deletes all data
docker compose up
# Database will reinitialize with clean schema
```

**Access database directly:**
```bash
docker compose exec postgres psql -U engarde_user -d engarde

# Common queries:
\dt              # List tables
\d users         # Describe users table
SELECT * FROM users LIMIT 10;
```

### Build Failures

**Clear build cache:**
```bash
docker builder prune -a             # Remove all build cache
docker compose build --no-cache     # Rebuild without cache
```

**Check .dockerignore:**
```bash
# Ensure these files are NOT excluded:
# - requirements.txt (backend)
# - package.json (frontend)
# - package-lock.json (frontend)
```

## Development Scenarios

### Scenario: Backend-Only Development

```bash
# Start only backend dependencies
docker compose -f docker-compose.yml -f docker-compose.dev.yml up postgres redis backend --watch

# Frontend won't start, so you can test APIs directly
curl http://localhost:8000/api/users
```

### Scenario: Frontend-Only Development

```bash
# Start all services (backend in stable mode)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --watch

# Frontend will hot-reload, backend stays stable
```

### Scenario: Database Schema Changes

```bash
# Create migration
docker compose exec backend alembic revision --autogenerate -m "Add user preferences"

# Apply migration
docker compose exec backend alembic upgrade head

# Rollback if needed
docker compose exec backend alembic downgrade -1
```

### Scenario: Testing Production Build Locally

```bash
# Build production images
docker compose build

# Start with production configuration
docker compose up

# Test in browser: http://localhost:3001 (note different port)
```

### Scenario: Fresh Start (Clean Database)

```bash
# Complete reset
docker compose down -v              # Stop and remove volumes
docker system prune -f              # Clean cache
docker compose up --build --watch   # Fresh start with new database
```

## Performance Tips

1. **Close unused services:**
   ```bash
   docker compose -f docker-compose.yml -f docker-compose.dev.yml up postgres redis backend --watch
   # Start only what you need
   ```

2. **Monitor resource usage:**
   ```bash
   docker stats
   # Ctrl+C to exit
   ```

3. **Prune regularly:**
   ```bash
   docker system prune -a --volumes  # Weekly cleanup
   # WARNING: Removes all unused data
   ```

## Next Steps

- Read the full architecture: [DOCKER_DEVELOPMENT_ARCHITECTURE.md](./DOCKER_DEVELOPMENT_ARCHITECTURE.md)
- Check troubleshooting guide: [TROUBLESHOOTING_DOCKER.md](./TROUBLESHOOTING_DOCKER.md)
- Review Docker best practices in the main architecture doc

## Getting Help

1. Check logs first: `docker compose logs -f`
2. Verify service health: `docker compose ps`
3. Try a restart: `docker compose restart <service>`
4. Full reset if stuck: `docker compose down -v && docker compose up --build --watch`
5. Create an issue in the project repository with logs attached

---

**Quick Reference Card:**
```
Start Dev:     docker compose -f docker-compose.yml -f docker-compose.dev.yml up --watch
Stop Dev:      docker compose down
View Logs:     docker compose logs -f
Rebuild:       docker compose build <service>
Shell Access:  docker compose exec <service> bash
Fresh Start:   docker compose down -v && docker compose up --build --watch
```
