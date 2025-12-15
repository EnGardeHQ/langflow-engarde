# EnGarde Docker Best Practices & Team Guidelines

This document outlines the best practices, conventions, and guidelines for working with Docker in the EnGarde project. All team members should follow these practices to ensure consistency, performance, and maintainability.

## Table of Contents

1. [File Structure Standards](#file-structure-standards)
2. [Dockerfile Guidelines](#dockerfile-guidelines)
3. [Docker Compose Guidelines](#docker-compose-guidelines)
4. [Environment Variable Management](#environment-variable-management)
5. [Volume Management](#volume-management)
6. [Security Guidelines](#security-guidelines)
7. [Performance Guidelines](#performance-guidelines)
8. [Development Workflow](#development-workflow)
9. [Testing Guidelines](#testing-guidelines)
10. [Production Deployment](#production-deployment)

---

## File Structure Standards

### Naming Conventions

**Docker Compose Files:**
```
docker-compose.yml                # Base/production configuration
docker-compose.dev.yml           # Development overrides
docker-compose.prod.yml          # Production-specific overrides
docker-compose.test.yml          # Testing configuration
docker-compose.override.yml      # Local overrides (gitignored)
```

**Dockerfiles:**
```
Dockerfile                       # Multi-stage: development + production
Dockerfile.dev                   # Legacy/specialized development (avoid)
Dockerfile.test                  # Testing-specific (if needed)
```

### Directory Structure

```
project-root/
├── .env.example                 # Template (committed)
├── .env                         # Local config (gitignored)
├── docker-compose.yml           # Base configuration
├── docker-compose.dev.yml       # Development overrides
├── docker-compose.prod.yml      # Production overrides
├── production-backend/
│   ├── Dockerfile               # Multi-stage backend
│   ├── .dockerignore            # Build context exclusions
│   ├── requirements.txt         # Production dependencies
│   ├── requirements.dev.txt     # Development dependencies
│   └── scripts/
│       ├── entrypoint.sh        # Container initialization
│       └── init-db.sql          # Database initialization
├── production-frontend/
│   ├── Dockerfile               # Multi-stage frontend
│   ├── .dockerignore            # Build context exclusions
│   └── package.json             # Dependencies
└── docs/
    ├── DOCKER_DEVELOPMENT_ARCHITECTURE.md
    ├── QUICK_START_DOCKER.md
    └── DOCKER_BEST_PRACTICES.md  # This file
```

---

## Dockerfile Guidelines

### Multi-Stage Build Pattern

**ALWAYS use multi-stage builds** to separate development and production:

```dockerfile
# Stage 1: Base (shared dependencies)
FROM python:3.11-slim as base
RUN apt-get update && apt-get install -y curl postgresql-client

# Stage 2: Dependencies (cached separately from code)
FROM base as dependencies
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Stage 3: Development (with hot-reload tools)
FROM dependencies as development
WORKDIR /app
RUN pip install --no-cache-dir watchfiles ipython ipdb
COPY . /app/
CMD ["uvicorn", "app.main:app", "--reload"]

# Stage 4: Production (optimized and secure)
FROM dependencies as production
WORKDIR /app
COPY app/ /app/app/
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser
CMD ["gunicorn", "app.main:app"]
```

### Layer Optimization

**Order layers from least to most frequently changed:**

1. Base image
2. System dependencies (apt-get, apk)
3. Application dependencies (pip, npm)
4. Application code
5. Configuration files
6. Runtime commands

**Example:**
```dockerfile
# ✓ Good: Dependencies cached separately
FROM python:3.11-slim
RUN apt-get update && apt-get install -y curl  # Rarely changes
COPY requirements.txt /tmp/                     # Changes occasionally
RUN pip install -r /tmp/requirements.txt        # Cached until requirements.txt changes
COPY app/ /app/app/                            # Changes frequently

# ✗ Bad: Dependencies reinstall on every code change
FROM python:3.11-slim
COPY . /app/                                   # Changes frequently
RUN pip install -r requirements.txt            # Reinstalls every time!
```

### Security Best Practices

**1. Always run as non-root user:**
```dockerfile
# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set ownership
RUN chown -R appuser:appuser /app

# Switch to non-root
USER appuser
```

**2. Use minimal base images:**
```dockerfile
FROM python:3.11-slim  # ✓ Good: 50MB
FROM python:3.11       # ✗ Bad: 900MB
```

**3. Don't expose secrets:**
```dockerfile
# ✗ Bad: Secret baked into image
ENV SECRET_KEY=my-secret-key

# ✓ Good: Secret passed at runtime
ENV SECRET_KEY=${SECRET_KEY}
```

**4. Scan images regularly:**
```bash
docker scan engarde-backend:latest
```

### .dockerignore Configuration

**Be aggressive with exclusions:**

```
# Version control
.git/
.gitignore

# Dependencies (installed during build)
node_modules/
__pycache__/
*.pyc
.venv/
venv/

# Build artifacts
.next/
dist/
build/
*.egg-info/

# Environment files
.env*
!.env.example

# Documentation
*.md
docs/

# CI/CD
.github/
.gitlab-ci.yml

# IDE
.vscode/
.idea/

# Logs
*.log
logs/

# OS files
.DS_Store
Thumbs.db
```

---

## Docker Compose Guidelines

### Service Definition Standards

**Complete service definition template:**
```yaml
services:
  service_name:
    # Build configuration
    build:
      context: ./service-directory
      dockerfile: Dockerfile
      target: development              # Specify stage
      cache_from:
        - service_name:dev-cache       # Leverage cache
      shm_size: '1gb'                  # For memory-intensive builds

    # Image naming
    image: engarde-service:dev

    # Container naming (for easy reference)
    container_name: engarde_service_dev

    # Environment files (in order of precedence)
    env_file:
      - ./.env                         # Root level
      - ./service-directory/.env       # Service level

    # Environment variables (override env_file)
    environment:
      NODE_ENV: development
      DEBUG: "true"

    # Port mapping (host:container)
    ports:
      - "3000:3000"

    # Service dependencies
    depends_on:
      postgres:
        condition: service_healthy     # Wait for health check
      redis:
        condition: service_started     # Just wait for start

    # Network configuration
    networks:
      - engarde_network

    # Volume mounts
    volumes:
      - ./service-directory/src:/app/src:rw
      - service_node_modules:/app/node_modules

    # Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

    # Restart policy
    restart: unless-stopped

    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M

    # Docker Compose Watch (v2.22+)
    develop:
      watch:
        - action: sync
          path: ./service-directory/src
          target: /app/src
        - action: rebuild
          path: ./service-directory/package.json
```

### Configuration Layering

**Use the base + override pattern:**

1. **docker-compose.yml** - Base configuration (production-ready)
2. **docker-compose.dev.yml** - Development overrides
3. **docker-compose.prod.yml** - Production hardening

**Example override:**
```yaml
# docker-compose.yml (base)
services:
  backend:
    image: engarde-backend:latest
    build:
      target: production
    volumes: []  # No mounts

# docker-compose.dev.yml (development override)
services:
  backend:
    build:
      target: development              # Override target
    environment:
      DEBUG: "true"                    # Add debug mode
    volumes:
      - ./production-backend/app:/app/app:rw  # Add code mount
```

### Health Check Best Practices

**1. Use appropriate test commands:**
```yaml
# HTTP health check
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/health"]

# Database health check
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U user -d database"]

# Redis health check
healthcheck:
  test: ["CMD", "redis-cli", "ping"]

# TCP health check (no HTTP)
healthcheck:
  test: ["CMD-SHELL", "nc -z localhost 5432"]
```

**2. Set appropriate timings:**
```yaml
healthcheck:
  interval: 30s      # Check every 30 seconds
  timeout: 10s       # Fail if check takes > 10s
  retries: 3         # Try 3 times before marking unhealthy
  start_period: 40s  # Grace period for slow starts
```

**3. Implement proper health check endpoints:**
```python
# Backend health check endpoint
@app.get("/health")
async def health_check():
    try:
        # Test database connection
        await database.execute("SELECT 1")
        db_status = "connected"
    except Exception:
        db_status = "disconnected"
        raise HTTPException(status_code=503)

    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "database": db_status,
        "redis": "connected",  # Add Redis check
    }
```

---

## Environment Variable Management

### Hierarchy (in order of precedence)

1. **docker-compose.yml environment:** - Highest priority
2. **env_file:** - Service-specific .env files
3. **.env file:** - Root-level .env
4. **Shell environment:** - Host machine variables

### Best Practices

**1. Never commit secrets:**
```bash
# .gitignore
.env
.env.local
.env.*.local
```

**2. Provide templates:**
```bash
# .env.example (committed)
DATABASE_URL=postgresql://user:password@localhost:5432/db
SECRET_KEY=change-me-in-production
OPENAI_API_KEY=your-key-here

# .env (gitignored, developer customizes)
DATABASE_URL=postgresql://myuser:mypass@localhost:5432/engarde_dev
SECRET_KEY=my-local-secret-123
OPENAI_API_KEY=sk-...actual-key...
```

**3. Use meaningful defaults:**
```yaml
environment:
  DEBUG: ${DEBUG:-false}                    # Default to false
  LOG_LEVEL: ${LOG_LEVEL:-info}            # Default to info
  WORKERS: ${WORKERS:-4}                    # Default to 4
```

**4. Document environment variables:**
```bash
# .env.example with comments
# Database Configuration
DATABASE_URL=postgresql://user:password@localhost:5432/db  # PostgreSQL connection string

# Application Settings
DEBUG=false              # Enable debug mode (true/false)
SECRET_KEY=changeme      # Application secret key (generate with: openssl rand -hex 32)
LOG_LEVEL=info          # Logging level (debug/info/warning/error)

# Feature Flags
FEATURE_MARKETPLACE=true     # Enable marketplace features
FEATURE_ANALYTICS=false      # Enable analytics tracking
```

**5. Separate development and production:**
```yaml
# docker-compose.dev.yml
environment:
  DEBUG: "true"
  LOG_LEVEL: "debug"
  CORS_ORIGINS: '["*"]'  # Permissive

# docker-compose.prod.yml
environment:
  DEBUG: "false"
  LOG_LEVEL: "info"
  CORS_ORIGINS: '["https://app.example.com"]'  # Restrictive
```

---

## Volume Management

### Types and Use Cases

**1. Named Volumes (Managed by Docker)**
- **Use for:** Dependencies, caches, persistent data
- **Performance:** Fast
- **Examples:** node_modules, __pycache__, database data

```yaml
volumes:
  # Named volumes
  - frontend_node_modules:/app/node_modules
  - backend_pycache:/app/__pycache__
  - postgres_data:/var/lib/postgresql/data
```

**2. Bind Mounts (Host filesystem)**
- **Use for:** Source code in development
- **Performance:** Slower on macOS/Windows
- **Examples:** src/, app/, public/

```yaml
volumes:
  # Bind mounts
  - ./production-frontend/src:/app/src:rw
  - ./production-backend/app:/app/app:ro  # Read-only for safety
```

**3. tmpfs Mounts (Memory)**
- **Use for:** Temporary data, build artifacts
- **Performance:** Fastest
- **Examples:** /tmp, build cache

```yaml
volumes:
  # tmpfs mount
  - type: tmpfs
    target: /tmp
    tmpfs:
      size: 100M
```

### Development Volume Strategy

**Best practice: Selective bind mounts + named volumes**

```yaml
volumes:
  # Bind mount source code (changes frequently)
  - ./production-frontend/src:/app/src:rw
  - ./production-frontend/public:/app/public:rw

  # Named volumes for dependencies (rarely change, slow to sync)
  - frontend_node_modules:/app/node_modules
  - frontend_next_cache:/app/.next

  # Bind mount for configuration (occasional changes)
  - ./production-frontend/next.config.js:/app/next.config.js:ro
```

### Production Volume Strategy

**Best practice: No source code mounts, only persistent data**

```yaml
volumes:
  # Only persistent data
  - uploads:/app/uploads
  - logs:/app/logs
  - postgres_data:/var/lib/postgresql/data
  - redis_data:/data
```

### Performance Optimization (macOS/Windows)

**1. Use :cached flag:**
```yaml
volumes:
  - ./production-frontend/src:/app/src:cached
```

**2. Exclude heavy directories:**
```yaml
volumes:
  - ./production-frontend:/app
  - /app/node_modules  # Exclude (use container's copy)
  - /app/.next         # Exclude (build artifacts)
```

**3. Enable VirtioFS (Docker Desktop 4.6+):**
```
Settings → Experimental Features → Enable VirtioFS
```

---

## Security Guidelines

### Container Security

**1. Run as non-root:**
```dockerfile
# Create user
RUN useradd -m -u 1001 appuser

# Set ownership
RUN chown -R appuser:appuser /app

# Switch user
USER appuser
```

**2. Use minimal images:**
```dockerfile
FROM python:3.11-slim    # ✓ Minimal
FROM python:3.11-alpine  # ✓ Even smaller
FROM python:3.11         # ✗ Too large
```

**3. Don't run unnecessary services:**
```dockerfile
# ✗ Bad: SSH in container
RUN apt-get install -y openssh-server

# ✓ Good: Use docker exec for access
# docker compose exec backend bash
```

**4. Scan for vulnerabilities:**
```bash
docker scan engarde-backend:latest
docker scan engarde-frontend:latest
```

### Secret Management

**1. Never commit secrets:**
```bash
# .gitignore
.env
.env.local
*.pem
*.key
credentials.json
```

**2. Use environment variables:**
```yaml
environment:
  SECRET_KEY: ${SECRET_KEY}  # ✓ From .env
  # NOT: SECRET_KEY: "hardcoded-secret"  # ✗ Never do this
```

**3. Use Docker secrets (Swarm/Compose v3.5+):**
```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt

services:
  backend:
    secrets:
      - db_password
```

**4. Rotate secrets regularly:**
```bash
# Generate new secret
openssl rand -hex 32 > SECRET_KEY

# Update .env
echo "SECRET_KEY=$(cat SECRET_KEY)" >> .env

# Restart services
docker compose restart backend
```

### Network Security

**1. Use internal networks:**
```yaml
networks:
  # Internal network (no external access)
  backend:
    driver: bridge
    internal: true

services:
  postgres:
    networks:
      - backend  # Only accessible within backend network
```

**2. Only expose necessary ports:**
```yaml
services:
  postgres:
    expose:
      - "5432"  # ✓ Only within Docker network
    # NOT ports: - "5432:5432"  # ✗ Exposes to host
```

**3. Use CORS restrictions:**
```python
# Backend CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://app.example.com"],  # Specific origins
    # NOT allow_origins=["*"]  # Too permissive for production
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)
```

---

## Performance Guidelines

### Build Performance

**1. Optimize layer caching:**
```dockerfile
# ✓ Good: Dependencies cached separately
COPY requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt
COPY app/ /app/app/

# ✗ Bad: Everything rebuilds on code change
COPY . /app/
RUN pip install -r requirements.txt
```

**2. Use .dockerignore aggressively:**
```
# Exclude everything not needed for build
node_modules/
.git/
*.log
coverage/
test-results/
```

**3. Enable BuildKit:**
```bash
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

docker compose build
```

**4. Use cache_from:**
```yaml
build:
  cache_from:
    - engarde-backend:dev-cache
    - engarde-backend:latest
```

### Runtime Performance

**1. Set resource limits:**
```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 2G
    reservations:
      cpus: '0.5'
      memory: 512M
```

**2. Configure connection pooling:**
```python
# Database connection pool
engine = create_engine(
    DATABASE_URL,
    pool_size=20,
    max_overflow=40,
    pool_pre_ping=True,
)
```

**3. Use production servers:**
```dockerfile
# ✗ Bad: Development server in production
CMD ["uvicorn", "app.main:app"]

# ✓ Good: Production server (gunicorn)
CMD ["gunicorn", "app.main:app", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker"]
```

**4. Monitor resource usage:**
```bash
docker stats
docker compose top
```

---

## Development Workflow

### Daily Workflow

```bash
# Morning: Start services
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --watch

# During development: View logs
docker compose logs -f backend frontend

# Need to run commands: Use exec
docker compose exec backend python manage.py migrate
docker compose exec frontend npm run test

# End of day: Stop services (keeps volumes)
docker compose down

# Weekly: Clean up
docker system prune -a
```

### Working with Branches

```bash
# Switching branches
git checkout feature/new-feature

# Rebuild services if dependencies changed
docker compose build

# Restart with fresh containers
docker compose up --watch
```

### Debugging

**1. View logs:**
```bash
docker compose logs -f backend
docker compose logs --tail=100 backend
```

**2. Access container shell:**
```bash
docker compose exec backend bash
docker compose exec frontend sh
```

**3. Attach debugger:**
```yaml
# docker-compose.dev.yml
services:
  backend:
    command: python -m debugpy --listen 0.0.0.0:5678 -m uvicorn app.main:app --reload
    ports:
      - "5678:5678"
```

**4. Run tests:**
```bash
docker compose exec backend pytest -v
docker compose exec frontend npm test
```

---

## Testing Guidelines

### Test Configuration

```yaml
# docker-compose.test.yml
services:
  backend:
    build:
      target: testing
    command: pytest -v --cov=app
    environment:
      TESTING: "true"
      DATABASE_URL: postgresql://test_user:test_pass@postgres:5432/test_db
```

### Running Tests

```bash
# Run all tests
docker compose -f docker-compose.test.yml up --abort-on-container-exit

# Run specific tests
docker compose exec backend pytest tests/test_users.py -v

# Run with coverage
docker compose exec backend pytest --cov=app --cov-report=html
```

### CI/CD Integration

```yaml
# .github/workflows/docker-test.yml
name: Docker Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build images
        run: docker compose build

      - name: Run tests
        run: docker compose -f docker-compose.test.yml up --abort-on-container-exit

      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

---

## Production Deployment

### Pre-Deployment Checklist

- [ ] All tests passing
- [ ] Security scan completed (`docker scan`)
- [ ] Environment variables configured in production
- [ ] Secrets properly managed (not in code)
- [ ] Resource limits defined
- [ ] Health checks configured
- [ ] Logging configured
- [ ] Backup strategy in place
- [ ] Rollback plan documented

### Production Build

```bash
# Build production images
docker compose -f docker-compose.yml build

# Tag for registry
docker tag engarde-backend:latest registry.example.com/engarde-backend:v1.0.0
docker tag engarde-frontend:latest registry.example.com/engarde-frontend:v1.0.0

# Push to registry
docker push registry.example.com/engarde-backend:v1.0.0
docker push registry.example.com/engarde-frontend:v1.0.0
```

### Production Deployment

```bash
# Pull latest images
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull

# Start services with production config
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Verify health
docker compose ps
curl http://localhost:8000/health

# Monitor logs
docker compose logs -f
```

### Rollback Procedure

```bash
# Stop current version
docker compose down

# Pull previous version
docker pull registry.example.com/engarde-backend:v0.9.0
docker pull registry.example.com/engarde-frontend:v0.9.0

# Start previous version
docker compose up -d

# Verify health
curl http://localhost:8000/health
```

---

## Maintenance Tasks

### Daily

```bash
# Monitor container health
docker compose ps

# Check resource usage
docker stats

# Review logs for errors
docker compose logs --since 24h | grep ERROR
```

### Weekly

```bash
# Clean up unused resources
docker system prune -a

# Update images
docker compose pull
docker compose up -d

# Backup databases
docker compose exec postgres pg_dump -U user database > backup.sql
```

### Monthly

```bash
# Security scan
docker scan engarde-backend:latest
docker scan engarde-frontend:latest

# Review resource usage trends
docker stats --no-stream > monthly-stats.txt

# Update dependencies
# - Backend: Update requirements.txt
# - Frontend: Update package.json
docker compose build
docker compose up -d
```

---

## Summary Checklist

Use this checklist for code reviews and deployments:

### Development
- [ ] Multi-stage Dockerfile with development and production stages
- [ ] .dockerignore configured to exclude unnecessary files
- [ ] Environment variables in .env (not committed)
- [ ] Source code mounted with bind mounts
- [ ] Dependencies in named volumes
- [ ] Health checks configured
- [ ] Watch mode enabled for hot-reload

### Production
- [ ] Running as non-root user
- [ ] Minimal base images used
- [ ] No source code bind mounts
- [ ] Secrets managed via environment variables
- [ ] Resource limits defined
- [ ] Restart policies configured
- [ ] Logging configured (json-file with rotation)
- [ ] Health checks with appropriate timings
- [ ] Images scanned for vulnerabilities

### Testing
- [ ] Test configuration in docker-compose.test.yml
- [ ] Tests run in isolated environment
- [ ] CI/CD pipeline configured
- [ ] Coverage reports generated

---

**Last Updated:** October 29, 2025
**Version:** 1.0
**Review Cycle:** Quarterly
