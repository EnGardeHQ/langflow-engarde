# EnGarde Docker Development Guide

**Quick Reference for Docker-based Development**

## Quick Start (5 Minutes)

### Prerequisites
- Docker Desktop 4.20+ with Docker Compose v2.22+
- 8GB+ RAM allocated to Docker
- Git

### One-Time Setup

```bash
# 1. Clone repository
git clone <repository-url>
cd EnGardeHQ

# 2. Copy environment template
cp .env.example .env

# 3. Start development environment
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build --watch
```

### Access Your Application

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8000
- **API Documentation:** http://localhost:8000/docs
- **Langflow:** http://localhost:7860 (optional)

---

## Daily Commands

```bash
# Start development (with automatic file sync)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --watch

# View logs
docker compose logs -f                    # All services
docker compose logs -f backend            # Backend only
docker compose logs -f frontend           # Frontend only

# Stop services
docker compose down                       # Keep volumes (data preserved)
docker compose down -v                    # Remove volumes (fresh start)

# Restart a service
docker compose restart backend
docker compose restart frontend

# Rebuild after dependency changes
docker compose build backend
docker compose build frontend

# Access container shell
docker compose exec backend bash
docker compose exec frontend sh

# Run commands inside containers
docker compose exec backend alembic upgrade head
docker compose exec backend pytest
docker compose exec frontend npm test
```

---

## Shell Aliases (Recommended)

Add these to your `~/.bashrc` or `~/.zshrc`:

```bash
# Docker Compose shortcuts
alias dc='docker compose -f docker-compose.yml -f docker-compose.dev.yml'
alias dcup='dc up --watch'
alias dcdown='dc down'
alias dcbuild='dc build'
alias dclogs='dc logs -f'
alias dcrestart='dc restart'

# Service-specific
alias dcbackend='dc logs -f backend'
alias dcfrontend='dc logs -f frontend'
alias dcdb='dc exec postgres psql -U engarde_user -d engarde'

# Maintenance
alias dcclean='dc down -v && docker system prune -f'
```

---

## Development Workflow

### 1. Making Code Changes

**Backend (Python/FastAPI):**
- Edit any file in `production-backend/app/`
- Save → Changes appear in ~500ms
- No restart needed (uvicorn auto-reloads)

**Frontend (Next.js/React):**
- Edit any file in `production-frontend/src/`
- Save → Browser updates in ~400ms
- No page reload (Fast Refresh)

### 2. Working with Dependencies

**Backend:**
```bash
# Add new dependency
echo "new-package==1.0.0" >> production-backend/requirements.txt
docker compose build backend
docker compose restart backend
```

**Frontend:**
```bash
# Add new dependency
docker compose exec frontend npm install new-package
docker compose restart frontend
```

### 3. Database Operations

```bash
# Create migration
docker compose exec backend alembic revision --autogenerate -m "Add user table"

# Apply migrations
docker compose exec backend alembic upgrade head

# Rollback migration
docker compose exec backend alembic downgrade -1

# Access database
docker compose exec postgres psql -U engarde_user -d engarde
```

### 4. Running Tests

```bash
# Backend tests
docker compose exec backend pytest -v

# Frontend tests
docker compose exec frontend npm test

# With coverage
docker compose exec backend pytest --cov=app --cov-report=html
```

---

## Troubleshooting

### Code Changes Not Appearing

**Check watch mode is active:**
```bash
docker compose ps
# Should show "Watch" indicator
```

**Force restart:**
```bash
docker compose restart backend frontend
```

### Services Won't Start

**Check port conflicts:**
```bash
lsof -i :3000  # Frontend
lsof -i :8000  # Backend
lsof -i :5432  # PostgreSQL
```

**Complete reset:**
```bash
docker compose down -v
docker system prune -f
docker compose up --build --watch
```

### Slow Performance (macOS/Windows)

**Enable VirtioFS:**
```
Docker Desktop → Settings → General → Enable VirtioFS
```

**Increase resources:**
```
Docker Desktop → Settings → Resources
CPU: 4+ cores
Memory: 8+ GB
```

### Database Issues

**Reset database:**
```bash
docker compose down -v  # WARNING: Deletes all data
docker compose up --watch
```

**Access database directly:**
```bash
docker compose exec postgres psql -U engarde_user -d engarde
\dt              # List tables
\d users         # Describe table
```

---

## Architecture Overview

### System Components

```
┌─────────────────────────────────────────────────────┐
│                 ENGARDE STACK                       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Frontend (Next.js)  :3000                         │
│       │                                             │
│       ▼                                             │
│  Backend (FastAPI)   :8000                         │
│       │                                             │
│       ├──▶ PostgreSQL   :5432                      │
│       └──▶ Redis        :6379                      │
│                                                     │
│  Langflow (optional) :7860                         │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Code Change Flow

```
1. Developer saves file (e.g., Button.tsx)
   ↓
2. Docker Watch detects change (< 50ms)
   ↓
3. File synced to container (< 200ms)
   ↓
4. Service detects change:
   - Backend: uvicorn --reload
   - Frontend: Next.js Fast Refresh
   ↓
5. Code recompiles/reloads (< 500ms)
   ↓
6. Developer sees changes immediately
```

### Volume Strategy

**Development:**
- Source code: Bind mounts (instant sync)
- Dependencies: Named volumes (performance)
- Data: Named volumes (persistence)

**Production:**
- Everything baked into image (immutable)
- Only data volumes (uploads, logs, database)

---

## Configuration Files

### Docker Compose Files

```
docker-compose.yml          # Base (production-ready)
docker-compose.dev.yml     # Development overrides
docker-compose.prod.yml    # Production hardening
docker-compose.test.yml    # Testing configuration
docker-compose.override.yml # Local customizations (gitignored)
```

### Usage Patterns

```bash
# Development (primary use case)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --watch

# Production
docker compose up

# Testing
docker compose -f docker-compose.test.yml up --abort-on-container-exit

# Custom local config
docker compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.override.yml up
```

---

## Best Practices

### Security
- Never commit .env files
- Use non-root users in containers
- Scan images regularly: `docker scan <image>`
- Keep secrets in environment variables

### Performance
- Use .dockerignore aggressively
- Leverage multi-stage builds
- Named volumes for dependencies
- Enable Docker BuildKit

### Development
- Use watch mode for instant feedback
- Keep containers running (no need to restart)
- Use bind mounts for source code only
- Monitor logs: `docker compose logs -f`

### Maintenance
- Clean up weekly: `docker system prune -a`
- Update images regularly: `docker compose pull`
- Backup databases: `docker compose exec postgres pg_dump`

---

## Common Scenarios

### Scenario 1: Backend-Only Development

```bash
# Start only backend dependencies
docker compose -f docker-compose.yml -f docker-compose.dev.yml up postgres redis backend --watch

# Frontend won't start, test API directly
curl http://localhost:8000/api/users
```

### Scenario 2: Fresh Database Reset

```bash
# Complete reset with clean database
docker compose down -v
docker compose up --build --watch
```

### Scenario 3: Dependency Update

```bash
# Update Python dependency
echo "new-package==2.0.0" >> production-backend/requirements.txt
docker compose build backend
docker compose restart backend

# Update Node dependency
docker compose exec frontend npm install new-package@latest
docker compose restart frontend
```

### Scenario 4: Production Build Test

```bash
# Build production images
docker compose build

# Start with production config
docker compose up

# Test at http://localhost:3001
```

---

## Documentation

### Comprehensive Guides

- **[DOCKER_DEVELOPMENT_ARCHITECTURE.md](./docs/DOCKER_DEVELOPMENT_ARCHITECTURE.md)** - Complete architectural design document
- **[QUICK_START_DOCKER.md](./docs/QUICK_START_DOCKER.md)** - Detailed getting started guide
- **[DOCKER_BEST_PRACTICES.md](./docs/DOCKER_BEST_PRACTICES.md)** - Team guidelines and best practices
- **[DOCKER_ARCHITECTURE_DIAGRAMS.md](./docs/DOCKER_ARCHITECTURE_DIAGRAMS.md)** - Visual architecture diagrams

### Quick References

- **Development Commands:** See "Daily Commands" section above
- **Troubleshooting:** See "Troubleshooting" section above
- **Architecture:** See "Architecture Overview" section above

---

## Key Features

### Docker Compose Watch Mode
- **Automatic file sync** without rebuilds
- **Hot Module Replacement** for instant feedback
- **Selective sync** - only source code, not dependencies

### Multi-Stage Dockerfiles
- **Development stage** with hot-reload tools
- **Production stage** optimized and secure
- **Shared base layers** for fast builds

### Health Checks
- **Service dependencies** managed automatically
- **Proper startup order** (DB → Backend → Frontend)
- **Automatic retries** on failure

### Volume Optimization
- **Bind mounts** for source code (instant sync)
- **Named volumes** for dependencies (performance)
- **Read-only mounts** where appropriate (security)

---

## Getting Help

1. **Check logs first:**
   ```bash
   docker compose logs -f
   ```

2. **Verify service health:**
   ```bash
   docker compose ps
   ```

3. **Try a restart:**
   ```bash
   docker compose restart <service>
   ```

4. **Full reset if stuck:**
   ```bash
   docker compose down -v && docker compose up --build --watch
   ```

5. **Consult documentation:**
   - [Full Architecture Guide](./docs/DOCKER_DEVELOPMENT_ARCHITECTURE.md)
   - [Troubleshooting Guide](./docs/QUICK_START_DOCKER.md#troubleshooting)

6. **Create an issue** in the project repository with:
   - Steps to reproduce
   - Full error logs (`docker compose logs`)
   - System information (`docker version`, `docker compose version`)

---

## Quick Reference Card

```
╔════════════════════════════════════════════════════════╗
║           ENGARDE DOCKER QUICK REFERENCE               ║
╠════════════════════════════════════════════════════════╣
║ Start Dev:     dc up --watch                           ║
║                (alias for full docker compose command) ║
║                                                        ║
║ Stop Dev:      docker compose down                     ║
║                                                        ║
║ View Logs:     docker compose logs -f <service>        ║
║                                                        ║
║ Rebuild:       docker compose build <service>          ║
║                                                        ║
║ Shell Access:  docker compose exec <service> bash      ║
║                                                        ║
║ Fresh Start:   docker compose down -v &&               ║
║                docker compose up --build --watch       ║
║                                                        ║
║ Run Tests:     docker compose exec backend pytest      ║
║                docker compose exec frontend npm test   ║
║                                                        ║
║ DB Access:     docker compose exec postgres psql \     ║
║                -U engarde_user -d engarde              ║
╚════════════════════════════════════════════════════════╝
```

---

## What's Next?

After getting started:

1. **Read the full architecture:** [DOCKER_DEVELOPMENT_ARCHITECTURE.md](./docs/DOCKER_DEVELOPMENT_ARCHITECTURE.md)
2. **Set up shell aliases:** See "Shell Aliases" section above
3. **Review best practices:** [DOCKER_BEST_PRACTICES.md](./docs/DOCKER_BEST_PRACTICES.md)
4. **Understand the diagrams:** [DOCKER_ARCHITECTURE_DIAGRAMS.md](./docs/DOCKER_ARCHITECTURE_DIAGRAMS.md)

---

**Last Updated:** October 29, 2025
**Version:** 1.0
**Docker Compose Version Required:** 2.22.0+
