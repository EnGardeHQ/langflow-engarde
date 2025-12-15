# EnGarde Docker Development Workflow Architecture
## Comprehensive Architecture & Best Practices Guide

**Document Version:** 1.0
**Last Updated:** October 29, 2025
**Status:** Architectural Design Document

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current State Analysis](#current-state-analysis)
3. [Architectural Principles](#architectural-principles)
4. [Development Workflow Architecture](#development-workflow-architecture)
5. [File Organization Strategy](#file-organization-strategy)
6. [Docker Compose Layering Strategy](#docker-compose-layering-strategy)
7. [Volume Strategy & Code Synchronization](#volume-strategy--code-synchronization)
8. [Service Orchestration & Dependencies](#service-orchestration--dependencies)
9. [Developer Workflows](#developer-workflows)
10. [Performance Optimization](#performance-optimization)
11. [Troubleshooting Guide](#troubleshooting-guide)
12. [Migration Path](#migration-path)
13. [Best Practices & Guidelines](#best-practices--guidelines)

---

## Executive Summary

This document outlines the optimal Docker development workflow architecture for the EnGarde application, a microservices-based system with Next.js frontend and FastAPI backend services. The architecture is designed to solve the critical problem of production builds not reflecting code changes without full rebuilds, while following 2025 industry best practices.

### Key Solutions

1. **Docker Compose Watch Mode** - Automatic file synchronization without container rebuilds
2. **Multi-stage Dockerfiles** - Separate development and production stages with optimized caching
3. **Layered Configuration** - Base + environment-specific overrides for maximum flexibility
4. **Hot Module Replacement** - Instant code updates in containers for both frontend and backend
5. **Intelligent Volume Strategy** - Bind mounts for source code, named volumes for dependencies

### Primary Goals Achieved

- **Zero-friction development**: `docker compose up` and start coding
- **Instant code reflection**: Changes appear immediately without rebuilds
- **Production parity**: Development environment mirrors production closely
- **Performance**: Fast startup times with intelligent caching
- **Developer experience**: Clear logs, easy debugging, predictable behavior

---

## Current State Analysis

### Existing Infrastructure

Your current setup includes:

```
EnGardeHQ/
├── docker-compose.yml              # Base production configuration
├── docker-compose.dev.yml          # Development overrides
├── docker-compose.local.yml        # Local development overrides
├── docker-compose.prod.yml         # Production-specific overrides
├── production-backend/
│   ├── Dockerfile                  # Multi-stage: base → dependencies → development → production
│   ├── Dockerfile.dev              # Simplified development image
│   └── requirements*.txt           # Multiple dependency files
└── production-frontend/
    ├── Dockerfile                  # Multi-stage: base → deps → builder → development → production
    ├── Dockerfile.dev              # Simplified development image
    └── package.json                # Node.js dependencies
```

### Identified Issues

1. **Volume Configuration Inconsistency**
   - Main `docker-compose.yml` has volumes commented out for frontend (lines 245-249)
   - This causes production builds to be immutable - code changes require full rebuilds
   - Backend has volumes mounted but excludes cache directories properly

2. **Configuration Overlap**
   - Three separate development compose files (dev, local, full-stack) with overlapping configs
   - Unclear which file to use for which scenario
   - Duplication of environment variables and settings

3. **Missing Watch Mode**
   - Current dev setup has basic watch configuration (lines 118-124, 183-190 in docker-compose.dev.yml)
   - Not leveraging Docker Compose v2.22+ watch mode for optimal performance
   - No clear documentation on how file changes propagate

4. **Build Stage Confusion**
   - Production Dockerfile has 5 stages (base, dependencies, development, production, testing, migration)
   - Development Dockerfile is separate, leading to drift between environments
   - Unclear when to use which Dockerfile

---

## Architectural Principles

### 1. Separation of Concerns

**Development vs Production**
- Development: Optimize for fast iteration, verbose logging, hot-reload
- Production: Optimize for security, performance, minimal image size

**Configuration Layering**
- Base configuration (docker-compose.yml): Common services and networks
- Environment overlays (docker-compose.{env}.yml): Environment-specific overrides
- Local customization (.env files): Developer-specific secrets and settings

### 2. Developer Experience First

**Minimal Commands**
```bash
# Start everything
docker compose up

# Start specific services
docker compose up frontend backend

# View logs
docker compose logs -f backend
```

**Instant Feedback**
- Code changes appear in < 500ms
- No manual rebuild steps
- Clear error messages

### 3. Production Parity

**What Should Match**
- Service topology (same services, same network architecture)
- Application behavior (same API endpoints, same routing)
- Dependency versions (lockfiles ensure consistency)

**What Should Differ**
- Optimization level (development is verbose, production is optimized)
- Volume strategy (development mounts source, production bakes it in)
- Security posture (development is permissive, production is strict)

### 4. Performance Optimization

**Build Time**
- Multi-stage builds with aggressive layer caching
- .dockerignore files to minimize build context
- Dependency layers cached separately from application code

**Runtime**
- Named volumes for node_modules and Python cache directories
- Bind mounts with appropriate ignore patterns
- Health checks to ensure service readiness

---

## Development Workflow Architecture

### High-Level Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        DEVELOPER MACHINE                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────┐         ┌─────────────┐        ┌─────────────┐ │
│  │   Editor   │         │  Terminal   │        │   Browser   │ │
│  │  (VS Code) │         │  (commands) │        │ (localhost) │ │
│  └──────┬─────┘         └──────┬──────┘        └──────┬──────┘ │
│         │                      │                       │         │
│         │ Save file            │ docker compose up     │ HTTP    │
│         ▼                      ▼                       ▼         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                     File System                           │  │
│  │  production-frontend/src/**/*.tsx  (source code)         │  │
│  │  production-backend/app/**/*.py    (source code)         │  │
│  └──────────────────┬───────────────────────────────────────┘  │
│                     │                                            │
└─────────────────────┼────────────────────────────────────────────┘
                      │
                      │ Bind Mount (read-only)
                      │ Docker Watch (sync)
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                     DOCKER ENGINE                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ engarde_network (bridge network)                          │  │
│  │                                                            │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │  │
│  │  │          │  │          │  │          │  │          │ │  │
│  │  │ postgres │  │  redis   │  │ backend  │  │ frontend │ │  │
│  │  │  :5432   │  │  :6379   │  │  :8000   │  │  :3000   │ │  │
│  │  │          │  │          │  │          │  │          │ │  │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘ │  │
│  │       │             │             │             │        │  │
│  │       │  health     │  health     │  health     │ health │  │
│  │       │  check      │  check      │  check      │ check  │  │
│  │       ▼             ▼             ▼             ▼        │  │
│  │  [Ready after      [Ready        [Ready after   [Ready  │  │
│  │   30s with         after 10s]    DB/Redis +     after   │  │
│  │   DB init]                        40s]          backend  │  │
│  │                                                  + 30s]  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  VOLUMES:                                                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Named Volumes (persist between restarts):                 │  │
│  │  - postgres_data       (database state)                   │  │
│  │  - redis_data          (cache state)                      │  │
│  │  - frontend_node_modules (npm dependencies)               │  │
│  │  - frontend_next        (.next build cache)               │  │
│  │  - backend_pycache      (Python bytecode)                 │  │
│  │                                                            │  │
│  │ Bind Mounts (sync with host filesystem):                  │  │
│  │  - ./production-frontend/src → /app/src                   │  │
│  │  - ./production-frontend/public → /app/public             │  │
│  │  - ./production-backend/app → /app/app                    │  │
│  │  - ./production-backend/uploads → /app/uploads            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

### Code Change Flow

```
1. Developer saves file (backend/app/api/users.py)
   │
   ▼
2. Docker Watch detects change
   │
   ▼
3. File synced to container (/app/app/api/users.py)
   │
   ├─ Backend (uvicorn --reload)
   │  │
   │  ▼
   │  Python auto-reloads module
   │  │
   │  ▼
   │  API endpoint updated (< 500ms)
   │
   └─ Frontend (next dev)
      │
      ▼
      Fast Refresh detects change
      │
      ▼
      React components hot-reload
      │
      ▼
      Browser updates without page reload (< 200ms)
```

### Service Dependency Chain

```
Startup Order:
1. postgres (30s startup, health check: pg_isready)
   │
   ├─ Initializes schemas (init_schemas.sql)
   ├─ Runs migrations (init-db.sql)
   └─ Creates Langflow schema (init-langflow-schema.sql)
   │
   ▼
2. redis (10s startup, health check: redis-cli ping)
   │
   ▼
3. backend (depends_on: postgres + redis)
   │
   ├─ Waits for DB health (PostgreSQL)
   ├─ Waits for cache health (Redis)
   ├─ Runs Alembic migrations (if needed)
   ├─ Seeds demo data (if SEED_DEMO_DATA=true)
   └─ Starts uvicorn server (8000)
   │
   ▼ (health check: curl localhost:8000/health)
   │
   ▼
4. frontend (depends_on: backend)
   │
   ├─ Waits for backend health
   ├─ Starts Next.js dev server (3000)
   └─ Connects to backend API (/api → backend:8000)
   │
   ▼ (health check: curl localhost:3000/)
   │
   ▼
5. langflow (optional, depends_on: postgres + redis)
   │
   ├─ Uses separate Langflow schema
   ├─ Auto-login enabled (admin/admin)
   └─ Starts Langflow server (7860)
```

---

## File Organization Strategy

### Recommended Structure

```
EnGardeHQ/
│
├── docker/                          # NEW: Centralized Docker configurations
│   ├── compose/
│   │   ├── base.yml                # Base services (DB, Redis, Network)
│   │   ├── backend.yml             # Backend service definition
│   │   ├── frontend.yml            # Frontend service definition
│   │   ├── langflow.yml            # Langflow service definition
│   │   └── nginx.yml               # Nginx proxy (production only)
│   │
│   ├── env/
│   │   ├── .env.development        # Development environment variables
│   │   ├── .env.staging            # Staging environment variables
│   │   └── .env.production         # Production environment variables
│   │
│   └── scripts/
│       ├── health-check.sh         # Unified health check script
│       ├── wait-for-service.sh     # Service dependency waiter
│       └── seed-data.sh            # Demo data seeding script
│
├── docker-compose.yml               # Base configuration (shared services)
├── docker-compose.dev.yml          # Development overrides
├── docker-compose.prod.yml         # Production overrides
├── docker-compose.test.yml         # Testing overrides (CI/CD)
│
├── .env                            # Local developer overrides (gitignored)
├── .env.example                    # Template for .env
│
├── production-backend/
│   ├── Dockerfile                  # Multi-stage: development + production
│   ├── .dockerignore              # Build context exclusions
│   ├── requirements.txt           # Production dependencies
│   ├── requirements.dev.txt       # Development dependencies
│   ├── app/                       # Application code (bind mounted in dev)
│   ├── scripts/
│   │   ├── entrypoint.sh         # Container initialization script
│   │   └── init-db.sql           # Database initialization
│   └── uploads/                  # User uploads (bind mounted)
│
├── production-frontend/
│   ├── Dockerfile                  # Multi-stage: development + production
│   ├── .dockerignore              # Build context exclusions
│   ├── package.json               # Dependencies
│   ├── package-lock.json          # Lockfile (required for npm ci)
│   ├── next.config.js             # Next.js configuration
│   ├── src/                       # Application code (bind mounted in dev)
│   └── public/                    # Static assets (bind mounted in dev)
│
└── docs/
    ├── DOCKER_DEVELOPMENT_ARCHITECTURE.md  # This document
    ├── QUICK_START_DOCKER.md               # Getting started guide
    └── TROUBLESHOOTING_DOCKER.md           # Common issues and solutions
```

### Current vs Recommended

**Current Issues:**
- Root-level compose files without clear naming convention
- No centralized docker configuration directory
- Environment variables scattered across multiple .env files
- Scripts mixed with application code

**Recommended Changes:**
1. Keep root-level compose files for easy access: `docker compose up`
2. Use clear naming: `docker-compose.{environment}.yml`
3. Centralize docker-specific configs in `docker/` directory (optional enhancement)
4. Single `.env` file for local overrides, environment-specific files in `docker/env/`

---

## Docker Compose Layering Strategy

### Philosophy: Base + Override Pattern

Docker Compose supports merging multiple files using the `-f` flag or automatic file detection. The order matters: later files override earlier ones.

### Layering Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    LAYER 1: Base Configuration                   │
│                     docker-compose.yml                           │
├─────────────────────────────────────────────────────────────────┤
│ Purpose: Production-ready base configuration                     │
│ Contains: All services with production defaults                  │
│ Volume Strategy: NO source code mounts, baked-in builds         │
│ Build Target: production                                        │
│                                                                   │
│ services:                                                        │
│   postgres: [production settings]                               │
│   redis: [production settings]                                  │
│   backend:                                                      │
│     build:                                                      │
│       target: production                                        │
│     volumes: []  # No source code mounts                        │
│   frontend:                                                     │
│     build:                                                      │
│       target: production                                        │
│     volumes: []  # No source code mounts                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Merged with
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                LAYER 2: Development Overrides                    │
│                   docker-compose.dev.yml                         │
├─────────────────────────────────────────────────────────────────┤
│ Purpose: Development-specific enhancements                       │
│ Overrides: Build targets, volumes, environment variables        │
│ Volume Strategy: Bind mounts for source code                    │
│ Build Target: development                                       │
│                                                                   │
│ services:                                                        │
│   backend:                                                      │
│     build:                                                      │
│       target: development  # Override                           │
│     environment:                                                │
│       DEBUG: "true"        # Override                           │
│       LOG_LEVEL: "debug"   # Override                           │
│     volumes:                                                    │
│       - ./production-backend/app:/app/app  # Add bind mount    │
│     develop:  # Docker Compose Watch                            │
│       watch:                                                    │
│         - action: sync                                          │
│           path: ./production-backend/app                        │
│           target: /app/app                                      │
│   frontend:                                                     │
│     build:                                                      │
│       target: development  # Override                           │
│     environment:                                                │
│       NODE_ENV: development  # Override                         │
│     volumes:                                                    │
│       - ./production-frontend/src:/app/src  # Add bind mount   │
│       - ./production-frontend/public:/app/public               │
│     develop:  # Docker Compose Watch                            │
│       watch:                                                    │
│         - action: sync                                          │
│           path: ./production-frontend/src                       │
│           target: /app/src                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Optionally merged with
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                LAYER 3: Production Overrides                     │
│                   docker-compose.prod.yml                        │
├─────────────────────────────────────────────────────────────────┤
│ Purpose: Production-specific hardening                           │
│ Overrides: Resource limits, restart policies, logging           │
│                                                                   │
│ services:                                                        │
│   backend:                                                      │
│     deploy:                                                     │
│       resources:                                                │
│         limits:                                                 │
│           cpus: '2.0'                                           │
│           memory: 2G                                            │
│     restart: always                                             │
│     logging:                                                    │
│       driver: json-file                                         │
│       options:                                                  │
│         max-size: "10m"                                         │
└─────────────────────────────────────────────────────────────────┘
```

### Usage Patterns

**Development (Primary Use Case)**
```bash
# Automatic file detection (docker-compose.yml + docker-compose.override.yml)
# For EnGarde, we explicitly specify:
docker compose -f docker-compose.yml -f docker-compose.dev.yml up

# Short alias (add to ~/.bashrc or ~/.zshrc)
alias dc-dev='docker compose -f docker-compose.yml -f docker-compose.dev.yml'
dc-dev up
```

**Production**
```bash
# Base only (already configured for production)
docker compose up

# Or explicitly with production overrides
docker compose -f docker-compose.yml -f docker-compose.prod.yml up
```

**Local Customization**
```bash
# Developer adds personal overrides (gitignored)
docker compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.override.yml up
```

### Configuration Inheritance Example

**Base (docker-compose.yml)**
```yaml
services:
  backend:
    image: engarde-backend:latest
    build:
      context: ./production-backend
      target: production
    environment:
      DEBUG: "false"
      LOG_LEVEL: "info"
    volumes: []  # No mounts in production
```

**Development Override (docker-compose.dev.yml)**
```yaml
services:
  backend:
    build:
      target: development  # Change build target
    environment:
      DEBUG: "true"        # Override to debug mode
      LOG_LEVEL: "debug"   # Override to verbose logging
    volumes:
      # Add source code mounts for hot-reload
      - ./production-backend/app:/app/app:ro
      - ./production-backend/uploads:/app/uploads
    develop:
      watch:
        - action: sync
          path: ./production-backend/app
          target: /app/app
        - action: rebuild
          path: ./production-backend/requirements.txt
```

**Merged Result** (what Docker Compose sees):
```yaml
services:
  backend:
    image: engarde-backend:latest
    build:
      context: ./production-backend
      target: development      # From dev override
    environment:
      DEBUG: "true"           # From dev override
      LOG_LEVEL: "debug"      # From dev override
    volumes:
      # From dev override
      - ./production-backend/app:/app/app:ro
      - ./production-backend/uploads:/app/uploads
    develop:
      watch:
        - action: sync
          path: ./production-backend/app
          target: /app/app
        - action: rebuild
          path: ./production-backend/requirements.txt
```

---

## Volume Strategy & Code Synchronization

### Volume Types

**1. Named Volumes** (Managed by Docker)
- **Purpose**: Persist data that should survive container restarts but doesn't need host access
- **Performance**: Fast (native Docker storage)
- **Use Cases**:
  - Database data (postgres_data)
  - Cache data (redis_data)
  - Node modules (frontend_node_modules)
  - Python cache (__pycache__, .pytest_cache)

**2. Bind Mounts** (Host filesystem)
- **Purpose**: Sync code between host and container for development
- **Performance**: Slower on macOS/Windows (use optimizations)
- **Use Cases**:
  - Source code (app/, src/)
  - Static assets (public/)
  - Configuration files (next.config.js)

**3. tmpfs Mounts** (Memory)
- **Purpose**: Temporary data that doesn't need persistence
- **Performance**: Fastest (RAM)
- **Use Cases**:
  - Build artifacts during compilation
  - Temporary cache files

### Development Volume Strategy

**Backend (FastAPI/Python)**
```yaml
volumes:
  # Source code - read-only for safety (prevent container writes)
  - ./production-backend/app:/app/app:ro

  # Configuration and scripts - read-only
  - ./production-backend/alembic:/app/alembic:ro
  - ./production-backend/scripts:/app/scripts:ro

  # Data directories - read-write (user uploads, logs)
  - ./production-backend/uploads:/app/uploads
  - ./production-backend/logs:/app/logs
  - ./production-backend/marketplace:/app/marketplace

  # Exclude Python cache (use named volume for performance)
  - backend_pycache:/app/app/__pycache__
  - backend_pytest_cache:/app/.pytest_cache
```

**Frontend (Next.js/React)**
```yaml
volumes:
  # Source code - read-only for safety
  - ./production-frontend/src:/app/src:ro
  - ./production-frontend/public:/app/public:ro

  # Configuration files - read-only
  - ./production-frontend/next.config.js:/app/next.config.js:ro
  - ./production-frontend/tailwind.config.js:/app/tailwind.config.js:ro
  - ./production-frontend/postcss.config.js:/app/postcss.config.js:ro
  - ./production-frontend/tsconfig.json:/app/tsconfig.json:ro

  # Exclude dependencies and build cache (use named volumes)
  - frontend_node_modules:/app/node_modules
  - frontend_next_cache:/app/.next
```

### Docker Compose Watch Mode (v2.22+)

**What is Watch Mode?**
Docker Compose Watch is a modern feature that enables automatic file synchronization without manual rebuilds. It supersedes older patterns like `volumes-from` and manual `docker cp` commands.

**Three Watch Actions:**

1. **sync**: Copy files to container on change (no restart)
   - Best for: Source code with hot-reload
   - Speed: Fast (< 500ms)
   - Example: Python modules, React components

2. **rebuild**: Rebuild container on change (full restart)
   - Best for: Dependency files, Dockerfile changes
   - Speed: Slow (30s - 5min depending on cache)
   - Example: requirements.txt, package.json

3. **sync+restart**: Copy files and restart service
   - Best for: Configuration files that require service restart
   - Speed: Medium (2-10s)
   - Example: nginx.conf, gunicorn config

**Implementation Example**

```yaml
services:
  backend:
    # ... other config ...
    develop:
      watch:
        # Sync Python source code without restart (uvicorn --reload handles it)
        - action: sync
          path: ./production-backend/app
          target: /app/app
          ignore:
            - __pycache__/
            - "*.pyc"
            - ".pytest_cache/"

        # Rebuild container if dependencies change
        - action: rebuild
          path: ./production-backend/requirements.txt

        # Sync+restart for configuration changes
        - action: sync+restart
          path: ./production-backend/alembic.ini
          target: /app/alembic.ini

  frontend:
    # ... other config ...
    develop:
      watch:
        # Sync frontend source code (Next.js Fast Refresh handles updates)
        - action: sync
          path: ./production-frontend/src
          target: /app/src
          ignore:
            - "*.test.tsx"
            - "*.spec.ts"

        # Sync public assets
        - action: sync
          path: ./production-frontend/public
          target: /app/public

        # Rebuild if package.json changes
        - action: rebuild
          path: ./production-frontend/package.json

        # Sync configuration (Next.js auto-restarts on config change)
        - action: sync
          path: ./production-frontend/next.config.js
          target: /app/next.config.js
```

**Starting Watch Mode**
```bash
# Standard mode (default)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up

# Watch mode (automatic sync)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --watch

# Detached with watch
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --watch
```

### Performance Optimization for macOS/Windows

**Problem**: Docker Desktop on macOS/Windows uses VM-based file sharing, which is slower than Linux.

**Solutions:**

1. **Use :cached or :delegated flags** (deprecated but still works)
```yaml
volumes:
  - ./production-backend/app:/app/app:cached  # Host is authoritative
  - ./production-frontend/src:/app/src:cached
```

2. **Exclude heavy directories with named volumes**
```yaml
volumes:
  - ./production-frontend:/app
  - /app/node_modules          # Exclude (use container's copy)
  - /app/.next                 # Exclude (build artifacts)
```

3. **Enable VirtioFS (Docker Desktop 4.6+)**
```bash
# In Docker Desktop Settings:
# Settings → Experimental Features → Enable VirtioFS
```

4. **Use .dockerignore aggressively**
```
# .dockerignore
node_modules/
.next/
.git/
*.log
coverage/
```

---

## Service Orchestration & Dependencies

### Dependency Management

**Problem**: Services start in parallel by default, but some services require others to be ready first.

**Solution**: `depends_on` with health checks

### Health Check Strategy

**PostgreSQL**
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U engarde_user -d engarde"]
  interval: 10s      # Check every 10 seconds
  timeout: 5s        # Fail if check takes > 5 seconds
  retries: 5         # Try 5 times before marking unhealthy
  start_period: 30s  # Grace period for slow starts
```

**Redis**
```yaml
healthcheck:
  test: ["CMD", "redis-cli", "ping"]
  interval: 10s
  timeout: 5s
  retries: 5
```

**Backend (FastAPI)**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s  # Wait for DB migrations and data seeding
```

**Frontend (Next.js)**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/"]
  interval: 30s
  timeout: 10s
  retries: 5
  start_period: 30s
```

### Service Dependency Chain

```yaml
services:
  postgres:
    # No dependencies
    healthcheck: [pg_isready check]

  redis:
    # No dependencies
    healthcheck: [redis-cli ping]

  backend:
    depends_on:
      postgres:
        condition: service_healthy  # Wait for DB to be ready
      redis:
        condition: service_healthy  # Wait for Redis to be ready
    healthcheck: [curl /health]

  frontend:
    depends_on:
      backend:
        condition: service_started  # Don't need to wait for health, starts faster
    healthcheck: [curl /]

  langflow:
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck: [curl /health]
```

### Startup Timing

**Expected Timeline:**
```
T+0s:   docker compose up (command issued)
T+2s:   postgres container starts
T+2s:   redis container starts
T+12s:  redis healthy (passes health check)
T+32s:  postgres healthy (DB initialized, schemas created)
T+33s:  backend starts (dependencies met)
T+73s:  backend healthy (migrations run, demo data seeded, API ready)
T+74s:  frontend starts (backend started)
T+104s: frontend healthy (Next.js dev server ready)
T+110s: All services healthy and ready for development
```

### Initialization Scripts

**Database Initialization Order** (`/docker-entrypoint-initdb.d/`):
```
01-init-schemas.sql     # Create schemas and users
02-init-db.sql          # Create tables and initial data
03-init-langflow-schema.sql  # Langflow-specific schema
```

**Why This Order Matters:**
- PostgreSQL executes scripts in alphanumeric order
- Each script must be idempotent (safe to run multiple times)
- Scripts only run on first initialization (when database volume is empty)

**Backend Entrypoint Script** (`scripts/entrypoint.sh`):
```bash
#!/bin/bash
set -e

# Wait for database to be ready (if health check not enough)
while ! pg_isready -h postgres -p 5432 -U engarde_user; do
  echo "Waiting for database..."
  sleep 2
done

# Run database migrations
echo "Running database migrations..."
alembic upgrade head

# Seed demo data (if enabled)
if [ "$SEED_DEMO_DATA" = "true" ]; then
  echo "Seeding demo data..."
  python -m app.scripts.seed_data
fi

# Execute main command (uvicorn or gunicorn)
exec "$@"
```

---

## Developer Workflows

### Scenario 1: Full Stack Development

**Goal**: Work on both frontend and backend simultaneously

**Commands:**
```bash
# Start all services
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --watch

# In separate terminal, view logs
docker compose logs -f backend frontend
```

**What Happens:**
1. All services start (DB, Redis, backend, frontend)
2. Watch mode monitors file changes
3. Developer edits `production-backend/app/api/users.py`
   - File synced to container in < 500ms
   - Uvicorn detects change and reloads module
   - API endpoint updated, logs show: "Reloading..."
4. Developer edits `production-frontend/src/components/UserList.tsx`
   - File synced to container in < 200ms
   - Next.js Fast Refresh updates browser
   - No page reload, component state preserved

**Debugging:**
```bash
# Attach to backend for Python debugging
docker compose exec backend python -m pdb -m uvicorn app.main:app --reload

# View real-time backend logs
docker compose logs -f backend

# View frontend build output
docker compose logs -f frontend

# Execute commands inside containers
docker compose exec backend bash
docker compose exec frontend sh
```

### Scenario 2: Frontend-Only Development

**Goal**: Work on frontend while using stable backend

**Commands:**
```bash
# Start only required services
docker compose -f docker-compose.yml -f docker-compose.dev.yml up postgres redis backend frontend --watch
```

**Optimization**: Use production backend build (no backend code sync)
```bash
# Modify docker-compose.dev.yml temporarily to use production backend
docker compose -f docker-compose.yml up postgres redis backend
docker compose -f docker-compose.yml -f docker-compose.dev.yml up frontend --watch
```

### Scenario 3: Backend-Only Development

**Goal**: Work on backend APIs, use pre-built frontend

**Commands:**
```bash
# Start backend with dependencies
docker compose -f docker-compose.yml -f docker-compose.dev.yml up postgres redis backend --watch

# Optional: Start production frontend for testing
docker compose -f docker-compose.yml up frontend
```

**API Testing:**
```bash
# Test API directly with curl
curl http://localhost:8000/health
curl http://localhost:8000/api/users -H "Authorization: Bearer TOKEN"

# Or use tools like Postman, Insomnia, HTTPie
http GET http://localhost:8000/api/users Authorization:"Bearer TOKEN"
```

### Scenario 4: Database Schema Changes

**Goal**: Modify database schema and test migrations

**Commands:**
```bash
# Create new migration
docker compose exec backend alembic revision --autogenerate -m "Add user preferences table"

# Apply migration
docker compose exec backend alembic upgrade head

# Rollback migration (if needed)
docker compose exec backend alembic downgrade -1

# View migration history
docker compose exec backend alembic history
```

### Scenario 5: Fresh Database Reset

**Goal**: Reset database to clean state

**Commands:**
```bash
# Stop all services
docker compose down

# Remove database volume (WARNING: Deletes all data)
docker volume rm engardehq_postgres_data

# Restart services (DB will reinitialize)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --watch
```

### Scenario 6: Production Build Testing

**Goal**: Test production builds locally before deployment

**Commands:**
```bash
# Build production images
docker compose -f docker-compose.yml build

# Start with production configuration
docker compose -f docker-compose.yml up

# Or with production overrides
docker compose -f docker-compose.yml -f docker-compose.prod.yml up
```

### Scenario 7: Individual Service Rebuild

**Goal**: Rebuild single service after Dockerfile changes

**Commands:**
```bash
# Rebuild backend only
docker compose -f docker-compose.yml -f docker-compose.dev.yml build backend

# Rebuild and restart backend
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build backend

# View logs after rebuild
docker compose logs -f backend
```

### Scenario 8: Performance Profiling

**Goal**: Profile application performance in containerized environment

**Backend (Python):**
```bash
# Install profiling tools in container
docker compose exec backend pip install py-spy

# Profile running process
docker compose exec backend py-spy record -o profile.svg --pid 1

# Or use cProfile
docker compose exec backend python -m cProfile -o output.pstats -m uvicorn app.main:app
```

**Frontend (Next.js):**
```bash
# Enable Next.js profiling
docker compose exec frontend npm run build -- --profile

# Analyze bundle
docker compose exec frontend npm run analyze
```

---

## Performance Optimization

### Build Performance

**1. Leverage Build Cache**

**Multi-Stage Dockerfile Strategy:**
```dockerfile
# Stage 1: Base (rarely changes)
FROM python:3.11-slim as base
RUN apt-get update && apt-get install -y postgresql-client curl

# Stage 2: Dependencies (changes when requirements.txt changes)
FROM base as dependencies
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Stage 3: Development (changes frequently)
FROM dependencies as development
WORKDIR /app
COPY . /app/
CMD ["uvicorn", "app.main:app", "--reload"]

# Stage 4: Production (optimized for size and security)
FROM dependencies as production
WORKDIR /app
COPY app/ /app/app/
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser
CMD ["gunicorn", "app.main:app"]
```

**Why This Works:**
- Base layer cached until base image updates
- Dependencies layer cached until requirements.txt changes
- Only application code layer rebuilds frequently
- Result: 30s rebuild vs 5min full rebuild

**2. Optimize .dockerignore**

**Bad (slow):**
```
# Too permissive, includes unnecessary files
.git/
```

**Good (fast):**
```
# Aggressive exclusion
.git/
node_modules/
__pycache__/
*.pyc
.next/
coverage/
.pytest_cache/
logs/
*.log
.env*
!.env.example
README.md
docs/
```

**Impact**:
- Build context: 500MB → 50MB
- Upload time: 30s → 3s

**3. Use BuildKit**

```bash
# Enable BuildKit (faster, better caching)
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Or set in docker-compose.yml
DOCKER_BUILDKIT: 1
```

**Features:**
- Parallel stage execution
- Improved layer caching
- Faster dependency resolution

### Runtime Performance

**1. Resource Limits**

```yaml
services:
  frontend:
    deploy:
      resources:
        limits:
          cpus: '2.0'      # Max 2 CPU cores
          memory: 1.5G     # Max 1.5GB RAM
        reservations:
          cpus: '0.5'      # Guaranteed 0.5 cores
          memory: 512M     # Guaranteed 512MB RAM
```

**Why:**
- Prevents one service from starving others
- Predictable performance
- Matches production environment

**2. Connection Pooling**

**Backend (SQLAlchemy):**
```python
# app/database.py
engine = create_engine(
    DATABASE_URL,
    pool_size=20,          # Default connections
    max_overflow=40,       # Additional connections under load
    pool_pre_ping=True,    # Verify connections before use
    pool_recycle=3600      # Recycle connections every hour
)
```

**Frontend (Next.js API Routes):**
```typescript
// lib/api.ts
const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  timeout: 10000,
  maxRedirects: 5,
  // Keep-alive connection reuse
  httpAgent: new http.Agent({ keepAlive: true, keepAliveMsecs: 65000 }),
});
```

**Why:**
- Reduces connection overhead
- Improves throughput
- Matches backend keep-alive timeout (65s)

**3. Volume Performance (macOS/Windows)**

**Problem:**
```yaml
# Slow: Full project bind mount
volumes:
  - ./production-frontend:/app
```

**Solution:**
```yaml
# Fast: Selective bind mounts + named volumes for dependencies
volumes:
  - ./production-frontend/src:/app/src:cached
  - ./production-frontend/public:/app/public:cached
  - frontend_node_modules:/app/node_modules      # Exclude
  - frontend_next_cache:/app/.next               # Exclude
```

**Impact:**
- File watch latency: 2-5s → 200-500ms
- Build time: 2min → 30s

**4. Next.js Optimizations**

**next.config.js:**
```javascript
module.exports = {
  // Disable telemetry in Docker
  telemetry: false,

  // Optimize development server
  reactStrictMode: true,
  swcMinify: true,  // Use SWC instead of Terser (faster)

  // Reduce memory usage
  experimental: {
    workerThreads: false,
    cpus: 2,
  },

  // Faster Docker builds
  output: 'standalone',  // Includes only necessary files

  // Disable source maps in production (faster builds)
  productionBrowserSourceMaps: false,
};
```

**5. Python Optimizations**

**Dockerfile:**
```dockerfile
# Use Python bytecode cache for faster imports
ENV PYTHONOPTIMIZE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Use faster JSON library
RUN pip install --no-cache-dir orjson

# Precompile Python files
RUN python -m compileall /app
```

---

## Troubleshooting Guide

### Issue 1: Code Changes Not Reflected

**Symptoms:**
- Edit file, save, but container doesn't show changes
- No logs showing file detection

**Diagnosis:**
```bash
# Check if watch mode is enabled
docker compose ps
# Look for "Watch" column

# Check volume mounts
docker compose exec backend ls -la /app/app
docker compose exec frontend ls -la /app/src

# Verify file timestamps
docker compose exec backend stat /app/app/main.py
stat production-backend/app/main.py
# Timestamps should match
```

**Solutions:**

1. **Watch mode not enabled:**
```bash
# Add --watch flag
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --watch
```

2. **Volume mount not configured:**
```yaml
# Ensure volumes are defined in docker-compose.dev.yml
services:
  backend:
    volumes:
      - ./production-backend/app:/app/app
```

3. **File sync delay (macOS/Windows):**
```yaml
# Add :cached flag
volumes:
  - ./production-backend/app:/app/app:cached
```

4. **Docker Desktop file sharing settings:**
```
Docker Desktop → Preferences → Resources → File Sharing
Ensure project directory is listed
```

### Issue 2: Container Fails to Start

**Symptoms:**
- Container exits immediately
- Health check fails
- Error logs in `docker compose logs`

**Diagnosis:**
```bash
# View container logs
docker compose logs backend

# Check container status
docker compose ps

# Inspect container
docker compose exec backend bash
# If container is not running:
docker compose run --rm backend bash
```

**Common Causes:**

1. **Database not ready:**
```
Error: psycopg2.OperationalError: could not connect to server
```
**Solution:** Check health check and depends_on:
```yaml
backend:
  depends_on:
    postgres:
      condition: service_healthy  # Not just service_started
```

2. **Port already in use:**
```
Error: Bind for 0.0.0.0:8000 failed: port is already allocated
```
**Solution:** Change port or stop conflicting service:
```bash
# Find process using port
lsof -i :8000
# Kill process
kill -9 PID

# Or change port in docker-compose.yml
ports:
  - "8001:8000"
```

3. **Missing environment variables:**
```
Error: DATABASE_URL is not set
```
**Solution:** Check .env file and docker-compose.yml:
```bash
# Verify environment variables
docker compose config | grep DATABASE_URL

# Ensure .env file exists
cp .env.example .env
```

4. **Dockerfile syntax error:**
```
Error: failed to solve with frontend dockerfile.v0
```
**Solution:** Validate Dockerfile:
```bash
docker build -f production-backend/Dockerfile production-backend/
# Fix syntax errors
```

### Issue 3: Slow Performance

**Symptoms:**
- File changes take 10+ seconds to reflect
- High CPU usage
- Container restarts frequently

**Diagnosis:**
```bash
# Check resource usage
docker stats

# Check volume performance
time docker compose exec frontend ls -R /app/node_modules

# Check Docker Desktop resources
Docker Desktop → Preferences → Resources
```

**Solutions:**

1. **Increase Docker resources:**
```
Docker Desktop → Preferences → Resources
CPU: 4+ cores
Memory: 8+ GB
Swap: 2GB
```

2. **Optimize volumes:**
```yaml
# Use named volumes for node_modules
volumes:
  - ./production-frontend:/app
  - /app/node_modules  # Exclude (use container's copy)
```

3. **Enable file system optimizations:**
```yaml
# Use :cached flag for better performance
volumes:
  - ./production-frontend/src:/app/src:cached
```

4. **Reduce watch scope:**
```yaml
develop:
  watch:
    - action: sync
      path: ./production-frontend/src
      target: /app/src
      ignore:
        - "*.test.tsx"
        - "*.spec.ts"
        - "__tests__/"
```

### Issue 4: Database Connection Errors

**Symptoms:**
- Backend can't connect to database
- Connection timeout errors

**Diagnosis:**
```bash
# Check if PostgreSQL is running
docker compose ps postgres

# Check PostgreSQL logs
docker compose logs postgres

# Test connection from backend container
docker compose exec backend psql -h postgres -U engarde_user -d engarde
```

**Solutions:**

1. **Database not initialized:**
```bash
# Check database volume
docker volume inspect engardehq_postgres_data

# If corrupt, recreate:
docker compose down
docker volume rm engardehq_postgres_data
docker compose up
```

2. **Wrong connection string:**
```yaml
# Correct format
DATABASE_URL: postgresql://user:password@host:port/database

# Inside Docker network, use service name as host
DATABASE_URL: postgresql://engarde_user:engarde_password@postgres:5432/engarde
```

3. **Network issues:**
```bash
# Verify network exists
docker network ls | grep engarde

# Recreate network
docker compose down
docker network rm engarde_network
docker compose up
```

### Issue 5: Build Failures

**Symptoms:**
- `docker compose build` fails
- Dependency installation errors

**Diagnosis:**
```bash
# Build with verbose output
docker compose build --progress=plain backend

# Check build context
docker compose build --no-cache backend
```

**Solutions:**

1. **Network issues during build:**
```dockerfile
# Add retry logic to Dockerfile
RUN for i in 1 2 3; do \
      pip install -r requirements.txt && break || sleep 10; \
    done
```

2. **Build cache corruption:**
```bash
# Clear build cache
docker builder prune -a

# Rebuild without cache
docker compose build --no-cache
```

3. **Invalid .dockerignore:**
```bash
# Verify required files are not excluded
cat production-backend/.dockerignore

# Ensure requirements.txt is NOT in .dockerignore
```

### Issue 6: Frontend HMR Not Working

**Symptoms:**
- Code changes require manual browser refresh
- No "Compiling..." message in console

**Diagnosis:**
```bash
# Check Next.js dev server logs
docker compose logs frontend

# Verify HMR environment variables
docker compose exec frontend env | grep WATCH
```

**Solutions:**

1. **Enable file polling:**
```yaml
environment:
  WATCHPACK_POLLING: "true"
  CHOKIDAR_USEPOLLING: "true"
```

2. **Check browser console:**
```javascript
// Look for WebSocket connection errors
// Next.js HMR uses WebSocket on /_next/webpack-hmr
```

3. **Disable Fast Refresh temporarily:**
```javascript
// next.config.js
module.exports = {
  reactStrictMode: false,  // Try disabling
};
```

---

## Migration Path

### Current State → Optimal Development Workflow

This section provides a step-by-step migration plan from your current setup to the optimal development workflow.

### Phase 1: Consolidate Configurations (Week 1)

**Goal:** Simplify multiple compose files into clear base + override pattern

**Steps:**

1. **Backup current configuration:**
```bash
mkdir backup-docker-configs
cp docker-compose*.yml backup-docker-configs/
```

2. **Decide on primary development configuration:**
```bash
# Option A: Use docker-compose.dev.yml as primary override
docker compose -f docker-compose.yml -f docker-compose.dev.yml up

# Option B: Rename for clarity
mv docker-compose.dev.yml docker-compose.development.yml
```

3. **Remove redundant configurations:**
```bash
# Archive unused compose files
mkdir archive
mv docker-compose.full-stack.yml archive/
# Keep: docker-compose.yml, docker-compose.dev.yml, docker-compose.prod.yml
```

4. **Update documentation:**
```bash
# Create QUICK_START_DOCKER.md
echo "## Development: docker compose -f docker-compose.yml -f docker-compose.dev.yml up --watch" > QUICK_START_DOCKER.md
```

### Phase 2: Implement Watch Mode (Week 1)

**Goal:** Enable automatic file synchronization without rebuilds

**Steps:**

1. **Update docker-compose.dev.yml to add watch configuration:**
```yaml
services:
  backend:
    develop:
      watch:
        - action: sync
          path: ./production-backend/app
          target: /app/app
          ignore:
            - __pycache__/
            - "*.pyc"
        - action: rebuild
          path: ./production-backend/requirements.txt

  frontend:
    develop:
      watch:
        - action: sync
          path: ./production-frontend/src
          target: /app/src
        - action: sync
          path: ./production-frontend/public
          target: /app/public
        - action: rebuild
          path: ./production-frontend/package.json
```

2. **Verify Docker Compose version supports watch:**
```bash
docker compose version
# Ensure version >= 2.22.0

# If not, update Docker Desktop or Docker CLI
```

3. **Test watch mode:**
```bash
# Start with watch
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --watch

# In another terminal, edit a file
echo "# Test change" >> production-backend/app/main.py

# Verify logs show file sync
docker compose logs -f backend
# Should see: "Reloading..."
```

### Phase 3: Optimize Volume Strategy (Week 2)

**Goal:** Improve performance and fix immutable production builds

**Steps:**

1. **Uncomment development volumes in docker-compose.dev.yml:**
```yaml
# Already configured, just verify:
services:
  backend:
    volumes:
      - ./production-backend/app:/app/app:ro
      - ./production-backend/uploads:/app/uploads

  frontend:
    volumes:
      - ./production-frontend/src:/app/src:ro
      - ./production-frontend/public:/app/public:ro
      - frontend_node_modules:/app/node_modules
      - frontend_next_cache:/app/.next
```

2. **Ensure production config has NO volumes:**
```yaml
# docker-compose.yml (base/production)
services:
  backend:
    volumes: []  # Or remove volumes key entirely

  frontend:
    volumes: []  # Or remove volumes key entirely
```

3. **Add performance optimizations for macOS/Windows:**
```yaml
volumes:
  - ./production-frontend/src:/app/src:cached
  - ./production-frontend/public:/app/public:cached
```

### Phase 4: Enhance Health Checks (Week 2)

**Goal:** Ensure services start in correct order and are truly ready

**Steps:**

1. **Add/verify health checks in docker-compose.yml:**
```yaml
services:
  postgres:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U engarde_user -d engarde"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  backend:
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
```

2. **Create health check endpoint in backend (if missing):**
```python
# app/main.py
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "database": "connected",  # Add DB ping
        "redis": "connected",     # Add Redis ping
    }
```

3. **Test service startup order:**
```bash
docker compose down
docker compose -f docker-compose.yml -f docker-compose.dev.yml up

# Verify order:
# 1. postgres (30s)
# 2. redis (10s)
# 3. backend (after DB+Redis healthy)
# 4. frontend (after backend starts)
```

### Phase 5: Documentation & Developer Onboarding (Week 3)

**Goal:** Make it easy for new developers to start working

**Steps:**

1. **Create developer onboarding guide:**
```markdown
# QUICK_START.md

## Prerequisites
- Docker Desktop 4.20+ (includes Compose v2.22+)
- Git

## Setup (< 5 minutes)
1. Clone repo: `git clone ...`
2. Copy env file: `cp .env.example .env`
3. Start services: `docker compose -f docker-compose.yml -f docker-compose.dev.yml up --watch`
4. Open browser: http://localhost:3001

## Development Workflow
- Edit code, save → Changes appear automatically (< 500ms)
- View logs: `docker compose logs -f backend`
- Restart service: `docker compose restart backend`
- Rebuild after dependency change: `docker compose build backend`
```

2. **Add shell aliases to project README:**
```bash
# .bash_aliases or .zshrc
alias dc='docker compose -f docker-compose.yml -f docker-compose.dev.yml'
alias dcup='dc up --watch'
alias dcdown='dc down'
alias dcbuild='dc build'
alias dclogs='dc logs -f'
```

3. **Create troubleshooting guide (see Troubleshooting section above)**

### Phase 6: Production Validation (Week 3)

**Goal:** Ensure production builds work correctly without development mounts

**Steps:**

1. **Test production build locally:**
```bash
# Build production images
docker compose build

# Start with production config
docker compose up

# Verify:
# - No source code changes reflect (expected)
# - Services start correctly
# - Application works normally
```

2. **Verify image sizes:**
```bash
docker images | grep engarde
# Production images should be smaller (no dev dependencies)
```

3. **Test production deployment scenario:**
```bash
# Simulate production deployment
docker compose -f docker-compose.yml -f docker-compose.prod.yml up

# Verify:
# - Resource limits applied
# - Restart policies work
# - Logging configured correctly
```

### Phase 7: CI/CD Integration (Week 4)

**Goal:** Automate testing and deployment

**Steps:**

1. **Add CI/CD pipeline (GitHub Actions example):**
```yaml
# .github/workflows/docker-build.yml
name: Docker Build and Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build images
        run: docker compose build
      - name: Start services
        run: docker compose up -d
      - name: Wait for services
        run: docker compose exec -T backend curl --retry 10 --retry-delay 5 http://localhost:8000/health
      - name: Run tests
        run: docker compose exec -T backend pytest
```

2. **Add docker-compose.test.yml:**
```yaml
services:
  backend:
    command: pytest -v --cov=app
    environment:
      DATABASE_URL: postgresql://test_user:test_pass@postgres:5432/test_db
```

---

## Best Practices & Guidelines

### 1. Configuration Management

**Environment Variables**
- **Rule:** Never commit secrets to version control
- **Pattern:** Use .env.example as template, .env for local overrides (gitignored)
- **Example:**
```bash
# .env.example (committed)
DATABASE_URL=postgresql://user:password@localhost:5432/engarde
SECRET_KEY=change-me-in-production

# .env (gitignored, developer customizes)
DATABASE_URL=postgresql://myuser:mypass@localhost:5432/engarde_dev
SECRET_KEY=my-local-secret-key-123
```

**Docker Compose Files**
- **Rule:** Base config for production, overrides for environments
- **Pattern:**
  - `docker-compose.yml` → Production-ready base
  - `docker-compose.dev.yml` → Development overrides
  - `docker-compose.prod.yml` → Production hardening
  - `docker-compose.test.yml` → Testing configuration
  - `docker-compose.override.yml` → Local developer customizations (gitignored)

### 2. Dockerfile Design

**Multi-Stage Builds**
- **Rule:** Separate stages for different purposes
- **Stages:**
  1. `base` → OS dependencies, base image config
  2. `dependencies` → Install dependencies (cached separately)
  3. `development` → Development tools, hot-reload setup
  4. `production` → Optimized, minimal, secure

**Layer Ordering (for optimal caching)**
```dockerfile
# 1. Base image (rarely changes)
FROM python:3.11-slim as base

# 2. System dependencies (rarely changes)
RUN apt-get update && apt-get install -y curl postgresql-client

# 3. Python dependencies (changes when requirements.txt changes)
COPY requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt

# 4. Application code (changes frequently)
COPY app/ /app/app/

# 5. Runtime configuration (changes rarely)
CMD ["uvicorn", "app.main:app"]
```

### 3. Volume Strategy

**Development**
- **Rule:** Bind mount source code, use named volumes for dependencies
- **Example:**
```yaml
volumes:
  # Source code → bind mount (reflect changes)
  - ./production-backend/app:/app/app:ro

  # Dependencies → named volume (faster, isolated)
  - backend_venv:/app/.venv
  - backend_pycache:/app/__pycache__
```

**Production**
- **Rule:** NO bind mounts, only named volumes for persistent data
- **Example:**
```yaml
volumes:
  # Only persistent data (uploads, logs, database)
  - uploads:/app/uploads
  - logs:/app/logs
  - postgres_data:/var/lib/postgresql/data
```

### 4. Networking

**Service Communication**
- **Rule:** Use service names as hostnames within Docker network
- **Example:**
```yaml
# Backend connects to database
DATABASE_URL: postgresql://user:pass@postgres:5432/db
# ⬆ "postgres" is the service name

# Frontend connects to backend
NEXT_PUBLIC_API_URL: http://backend:8000
# ⬆ "backend" is the service name
```

**Port Exposure**
- **Rule:** Only expose necessary ports to host
- **Example:**
```yaml
# Development (expose all for debugging)
postgres:
  ports:
    - "5432:5432"  # Accessible on host

# Production (internal only)
postgres:
  expose:
    - "5432"  # Only accessible within Docker network
```

### 5. Security

**Non-Root Users**
```dockerfile
# Create non-root user
RUN useradd -m -u 1001 appuser

# Change ownership
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Now container runs as unprivileged user
```

**Secret Management**
- **Rule:** Never hardcode secrets in Dockerfiles or compose files
- **Pattern:** Use environment variables or Docker secrets
```yaml
services:
  backend:
    environment:
      # Reference from .env file
      SECRET_KEY: ${SECRET_KEY}
      DATABASE_URL: ${DATABASE_URL}
```

**Image Scanning**
```bash
# Scan for vulnerabilities
docker scan engarde-backend:latest

# Use minimal base images
FROM python:3.11-slim  # ✓ Good
FROM python:3.11        # ✗ Larger, more attack surface
```

### 6. Performance

**Build Performance**
- Optimize .dockerignore (exclude unnecessary files)
- Use multi-stage builds (reduce final image size)
- Cache dependencies separately from source code
- Enable BuildKit (`DOCKER_BUILDKIT=1`)

**Runtime Performance**
- Set resource limits (prevent resource starvation)
- Use health checks (ensure service readiness)
- Configure connection pooling (reduce overhead)
- Use production-grade servers (gunicorn for Python, not uvicorn)

### 7. Logging

**Structured Logging**
```yaml
services:
  backend:
    logging:
      driver: json-file
      options:
        max-size: "10m"      # Rotate at 10MB
        max-file: "3"        # Keep 3 files
        labels: "service=backend,environment=dev"
```

**Log Viewing**
```bash
# View logs for specific service
docker compose logs -f backend

# View logs with timestamps
docker compose logs -f --timestamps backend

# View last 100 lines
docker compose logs --tail=100 backend

# Follow logs from multiple services
docker compose logs -f backend frontend
```

### 8. Testing

**Test Configuration**
```yaml
# docker-compose.test.yml
services:
  backend:
    build:
      target: testing
    command: pytest -v --cov=app
    environment:
      DATABASE_URL: postgresql://test_user:test_pass@postgres:5432/test_db
      TESTING: "true"
```

**Running Tests**
```bash
# Run tests in isolated environment
docker compose -f docker-compose.test.yml up --abort-on-container-exit

# Run specific test file
docker compose exec backend pytest tests/test_users.py -v

# Run with coverage
docker compose exec backend pytest --cov=app --cov-report=html
```

### 9. Debugging

**Attach Debugger**
```yaml
# docker-compose.dev.yml
services:
  backend:
    command: python -m debugpy --listen 0.0.0.0:5678 -m uvicorn app.main:app --reload
    ports:
      - "5678:5678"  # Debugger port
```

**VS Code Configuration**
```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: Remote Attach",
      "type": "python",
      "request": "attach",
      "connect": {
        "host": "localhost",
        "port": 5678
      },
      "pathMappings": [
        {
          "localRoot": "${workspaceFolder}/production-backend",
          "remoteRoot": "/app"
        }
      ]
    }
  ]
}
```

**Interactive Shell**
```bash
# Open shell in running container
docker compose exec backend bash
docker compose exec frontend sh

# Or start one-off container
docker compose run --rm backend bash
```

### 10. Maintenance

**Cleanup Commands**
```bash
# Remove stopped containers
docker compose down

# Remove containers and volumes
docker compose down -v

# Remove containers, volumes, and images
docker compose down -v --rmi all

# Clean up Docker system (careful!)
docker system prune -a --volumes
```

**Update Workflow**
```bash
# Pull latest images
docker compose pull

# Rebuild with latest dependencies
docker compose build --no-cache

# Restart services
docker compose up -d
```

**Health Monitoring**
```bash
# Check service status
docker compose ps

# Check resource usage
docker stats

# Verify health checks
docker compose ps | grep "healthy"
```

---

## Conclusion

This architecture document provides a comprehensive guide to implementing an optimal Docker development workflow for the EnGarde application. The key principles are:

1. **Separation of Concerns**: Development and production configurations are separate but share a common base
2. **Developer Experience**: Minimal commands, instant feedback, clear logs
3. **Performance**: Intelligent caching, optimized volumes, resource management
4. **Production Parity**: Development environment closely mirrors production
5. **Maintainability**: Clear structure, good documentation, easy onboarding

### Quick Reference

**Start Development:**
```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --watch
```

**Test Production Build:**
```bash
docker compose build && docker compose up
```

**Debug Backend:**
```bash
docker compose logs -f backend
docker compose exec backend bash
```

**Reset Database:**
```bash
docker compose down -v && docker compose up
```

### Next Steps

1. **Immediate (Week 1):**
   - Implement watch mode in docker-compose.dev.yml
   - Add source code volumes to development configuration
   - Test end-to-end developer workflow

2. **Short-term (Weeks 2-3):**
   - Optimize .dockerignore files
   - Enhance health checks
   - Document developer workflows

3. **Medium-term (Week 4):**
   - Integrate with CI/CD
   - Add automated testing in Docker
   - Create developer onboarding guide

4. **Long-term (Ongoing):**
   - Monitor performance metrics
   - Iterate based on developer feedback
   - Keep Docker configurations up to date with application changes

---

**Document Metadata:**
- Version: 1.0
- Last Updated: October 29, 2025
- Author: System Architect
- Status: Architectural Design Document
- Review Cycle: Quarterly

For questions or clarifications, refer to the troubleshooting guide or create an issue in the project repository.
