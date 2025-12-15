# EnGarde Docker Architecture Visual Diagrams

This document provides visual representations of the EnGarde Docker architecture, helping developers understand the system's structure, data flow, and component interactions.

## Table of Contents

1. [System Overview](#system-overview)
2. [Development Workflow](#development-workflow)
3. [Network Architecture](#network-architecture)
4. [Volume Strategy](#volume-strategy)
5. [Service Lifecycle](#service-lifecycle)
6. [Code Change Propagation](#code-change-propagation)
7. [Production vs Development](#production-vs-development)

---

## System Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           ENGARDE APPLICATION                            │
│                         Microservices Architecture                       │
└─────────────────────────────────────────────────────────────────────────┘

┌────────────────────┐         ┌────────────────────┐
│     Developer      │         │       User         │
│     (localhost)    │         │     (browser)      │
└─────────┬──────────┘         └─────────┬──────────┘
          │                               │
          │ docker compose up             │ https://
          │                               │
          ▼                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          DOCKER ENGINE                                   │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     engarde_network                              │   │
│  │                                                                   │   │
│  │  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐    │   │
│  │  │  nginx   │   │ frontend │   │ backend  │   │ langflow │    │   │
│  │  │  :80     │◀──│  :3000   │◀──│  :8000   │◀──│  :7860   │    │   │
│  │  │  :443    │   │ (Next.js)│   │(FastAPI) │   │ (Python) │    │   │
│  │  └──────────┘   └──────────┘   └────┬─────┘   └──────────┘    │   │
│  │                                      │                          │   │
│  │                     ┌────────────────┴────────────────┐        │   │
│  │                     │                                  │        │   │
│  │                     ▼                                  ▼        │   │
│  │              ┌──────────┐                      ┌──────────┐    │   │
│  │              │ postgres │                      │  redis   │    │   │
│  │              │  :5432   │                      │  :6379   │    │   │
│  │              │(Database)│                      │ (Cache)  │    │   │
│  │              └──────────┘                      └──────────┘    │   │
│  │                                                                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  VOLUMES:                                                               │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │ postgres_data    redis_data    cached_logos    langflow_data   │   │
│  │ uploads          logs           frontend_node_modules          │   │
│  └────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

```
┌─────────────────────────────────────────────────────────────────┐
│                        SERVICE MATRIX                            │
├──────────┬────────────┬─────────────┬──────────────┬────────────┤
│ Service  │ Technology │ Port        │ Purpose      │ Depends On │
├──────────┼────────────┼─────────────┼──────────────┼────────────┤
│ frontend │ Next.js 13 │ 3000        │ UI/UX        │ backend    │
│ backend  │ FastAPI    │ 8000        │ API/Logic    │ DB, Redis  │
│ postgres │ PostgreSQL │ 5432        │ Data Storage │ None       │
│ redis    │ Redis 7    │ 6379        │ Caching      │ None       │
│ langflow │ Langflow   │ 7860        │ AI Flows     │ DB, Redis  │
│ nginx    │ Nginx      │ 80, 443     │ Proxy/SSL    │ All        │
└──────────┴────────────┴─────────────┴──────────────┴────────────┘
```

---

## Development Workflow

### Developer Day-in-the-Life

```
┌────────────────────────────────────────────────────────────────────┐
│                    TYPICAL DEVELOPMENT DAY                          │
└────────────────────────────────────────────────────────────────────┘

09:00 - Start Work
  │
  ├─ $ docker compose -f docker-compose.yml -f docker-compose.dev.yml up --watch
  │  │
  │  ├─ postgres starts (30s)
  │  ├─ redis starts (10s)
  │  ├─ backend starts (40s) ─── waits for DB + Redis ─── runs migrations
  │  └─ frontend starts (60s) ─── waits for backend ───── dev server ready
  │
  ▼
09:02 - All Services Ready
  │
  ├─ Browser: http://localhost:3000 (frontend)
  └─ Browser: http://localhost:8000/docs (API docs)

09:05 - Start Coding
  │
  ├─ Edit: production-backend/app/api/users.py
  │  │
  │  ├─ Watch detects change (< 500ms)
  │  ├─ File synced to container
  │  ├─ Uvicorn reloads module
  │  └─ Test: curl http://localhost:8000/api/users ✓
  │
  ├─ Edit: production-frontend/src/components/UserList.tsx
  │  │
  │  ├─ Watch detects change (< 200ms)
  │  ├─ File synced to container
  │  ├─ Next.js Fast Refresh
  │  └─ Browser updates automatically (no page reload) ✓
  │
  └─ Edit: production-backend/requirements.txt
     │
     ├─ Watch detects change
     ├─ Container rebuilds (2-3 min)
     └─ Service restarts with new dependencies ✓

12:00 - Lunch Break
  │
  └─ Services keep running (no action needed)

13:00 - Resume Coding
  │
  └─ Services still ready (no startup delay)

17:00 - Run Tests
  │
  ├─ $ docker compose exec backend pytest -v
  ├─ $ docker compose exec frontend npm test
  └─ All tests pass ✓

17:30 - Commit Changes
  │
  ├─ $ git add .
  ├─ $ git commit -m "Add user preferences feature"
  └─ $ git push

17:35 - End of Day
  │
  ├─ $ docker compose down
  └─ Containers stopped, volumes preserved
```

### Code-to-Container Flow

```
┌────────────────────────────────────────────────────────────────────┐
│              HOW CODE CHANGES REACH THE BROWSER                     │
└────────────────────────────────────────────────────────────────────┘

STEP 1: Developer Edits File
┌─────────────────────────────────────────────────────┐
│  Developer Machine                                   │
│  ┌────────────────────────────────────────────────┐ │
│  │ VS Code / Editor                                │ │
│  │ production-frontend/src/components/Button.tsx  │ │
│  │                                                 │ │
│  │ export const Button = () => {                  │ │
│  │   return <button>Click Me</button>  [SAVE]    │ │
│  │ }                                              │ │
│  └────────────────────────────────────────────────┘ │
└──────────────────────┬──────────────────────────────┘
                       │ File saved to disk
                       │ Timestamp: T+0ms
                       ▼

STEP 2: File System Detects Change
┌─────────────────────────────────────────────────────┐
│  Host File System                                   │
│  /Users/dev/EnGardeHQ/production-frontend/src/      │
│  components/Button.tsx [MODIFIED]                   │
│                                                     │
│  inotify / FSEvents: File change detected          │
└──────────────────────┬──────────────────────────────┘
                       │ Watch event triggered
                       │ Timestamp: T+50ms
                       ▼

STEP 3: Docker Watch Syncs File
┌─────────────────────────────────────────────────────┐
│  Docker Compose Watch                               │
│  ┌────────────────────────────────────────────────┐│
│  │ Watch Configuration:                           ││
│  │ - action: sync                                 ││
│  │   path: ./production-frontend/src              ││
│  │   target: /app/src                             ││
│  │                                                 ││
│  │ Syncing: Button.tsx → Container [IN PROGRESS] ││
│  └────────────────────────────────────────────────┘│
└──────────────────────┬──────────────────────────────┘
                       │ File copied to container
                       │ Timestamp: T+200ms
                       ▼

STEP 4: Container Receives Updated File
┌─────────────────────────────────────────────────────┐
│  Docker Container: engarde_frontend_dev             │
│  ┌────────────────────────────────────────────────┐│
│  │ /app/src/components/Button.tsx [UPDATED]      ││
│  │                                                 ││
│  │ export const Button = () => {                  ││
│  │   return <button>Click Me</button>             ││
│  │ }                                              ││
│  └────────────────────────────────────────────────┘│
└──────────────────────┬──────────────────────────────┘
                       │ File inode changed
                       │ Timestamp: T+250ms
                       ▼

STEP 5: Next.js Detects Change
┌─────────────────────────────────────────────────────┐
│  Next.js Dev Server (inside container)              │
│  ┌────────────────────────────────────────────────┐│
│  │ Webpack watching for changes...                ││
│  │ [DETECTED] src/components/Button.tsx          ││
│  │                                                 ││
│  │ [Compiling] Button.tsx                         ││
│  │ [Compiled] Successfully in 84ms                ││
│  │ [HMR] Sending update to client                 ││
│  └────────────────────────────────────────────────┘│
└──────────────────────┬──────────────────────────────┘
                       │ WebSocket message sent
                       │ Timestamp: T+400ms
                       ▼

STEP 6: Browser Receives HMR Update
┌─────────────────────────────────────────────────────┐
│  Browser: http://localhost:3000                     │
│  ┌────────────────────────────────────────────────┐│
│  │ [HMR] Update received                          ││
│  │ [Fast Refresh] Patching Button component      ││
│  │ [Success] Component updated                    ││
│  │                                                 ││
│  │ ┌────────────────┐                             ││
│  │ │ [Click Me]     │ ← Updated button renders   ││
│  │ └────────────────┘                             ││
│  │                                                 ││
│  │ Component state preserved ✓                    ││
│  │ No page reload ✓                               ││
│  └────────────────────────────────────────────────┘│
└──────────────────────┬──────────────────────────────┘
                       │ UI updated
                       │ Total Time: 500ms
                       ▼
                   Developer sees change!

TOTAL TIME FROM SAVE TO BROWSER: ~500ms
```

---

## Network Architecture

### Network Topology

```
┌────────────────────────────────────────────────────────────────────┐
│                    DOCKER NETWORK TOPOLOGY                          │
└────────────────────────────────────────────────────────────────────┘

┌───────────────────── HOST MACHINE ─────────────────────────────────┐
│                                                                     │
│  localhost:3000 ──┐                                                │
│  localhost:8000 ──┤                                                │
│  localhost:5432 ──┤  Port Mappings (Development)                  │
│  localhost:6379 ──┤                                                │
│  localhost:7860 ──┘                                                │
│                                                                     │
│  ┌────────────────── DOCKER NETWORK: engarde_network ───────────┐ │
│  │  Type: bridge                                                 │ │
│  │  Driver: bridge                                               │ │
│  │  Subnet: 172.18.0.0/16 (auto-assigned)                        │ │
│  │                                                                │ │
│  │  ┌──────────────────────────────────────────────────────────┐│ │
│  │  │                     SERVICE MESH                          ││ │
│  │  │                                                            ││ │
│  │  │  frontend:3000 ◀────┐                                    ││ │
│  │  │    (172.18.0.5)      │                                    ││ │
│  │  │         │            │                                    ││ │
│  │  │         │ HTTP       │ Reverse Proxy                      ││ │
│  │  │         ▼            │                                    ││ │
│  │  │  backend:8000 ◀─────┤                                    ││ │
│  │  │    (172.18.0.4)      │                                    ││ │
│  │  │         │            │                                    ││ │
│  │  │         │            │                                    ││ │
│  │  │  ┌──────┴──────┐     │                                    ││ │
│  │  │  │             │     │                                    ││ │
│  │  │  ▼             ▼     │                                    ││ │
│  │  │  postgres:5432     redis:6379                             ││ │
│  │  │  (172.18.0.2)      (172.18.0.3)                           ││ │
│  │  │                                                            ││ │
│  │  │  langflow:7860 ◀────┘                                    ││ │
│  │  │    (172.18.0.6)                                           ││ │
│  │  │         │                                                  ││ │
│  │  │         └────┬─────┐                                      ││ │
│  │  │              ▼     ▼                                      ││ │
│  │  │         postgres  redis                                   ││ │
│  │  └──────────────────────────────────────────────────────────┘│ │
│  │                                                                │ │
│  │  INTERNAL COMMUNICATION:                                      │ │
│  │  - Services use service names as hostnames                    │ │
│  │  - DNS resolution by Docker                                   │ │
│  │  - Example: backend connects to "postgres:5432"              │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘

SERVICE COMMUNICATION MATRIX:
┌──────────┬──────────┬──────────┬──────────┬──────────┐
│ From →   │ postgres │ redis    │ backend  │ frontend │
├──────────┼──────────┼──────────┼──────────┼──────────┤
│ postgres │    -     │    ✗     │    ✗     │    ✗     │
│ redis    │    ✗     │    -     │    ✗     │    ✗     │
│ backend  │    ✓     │    ✓     │    -     │    ✗     │
│ frontend │    ✗     │    ✗     │    ✓     │    -     │
│ langflow │    ✓     │    ✓     │    ✗     │    ✗     │
└──────────┴──────────┴──────────┴──────────┴──────────┘
```

### Request Flow

```
┌────────────────────────────────────────────────────────────────────┐
│                      REQUEST FLOW DIAGRAM                           │
└────────────────────────────────────────────────────────────────────┘

USER REQUEST: GET /api/users
│
├─ Browser → http://localhost:3000/api/users
│
▼
┌─────────────────────────────────────────┐
│ Frontend Container (Next.js)            │
│ Port: 3000                               │
├─────────────────────────────────────────┤
│ 1. Next.js receives request              │
│ 2. API route: /api/users                 │
│ 3. Proxies to backend                    │
│ 4. URL: http://backend:8000/api/users   │
└────────────┬────────────────────────────┘
             │ Internal Docker network
             │ Service name: "backend"
             ▼
┌─────────────────────────────────────────┐
│ Backend Container (FastAPI)             │
│ Port: 8000                               │
├─────────────────────────────────────────┤
│ 1. FastAPI receives request              │
│ 2. Route: @app.get("/api/users")        │
│ 3. Authenticate user (check JWT)         │
│ 4. Query database                        │
└────────────┬────────────────────────────┘
             │ Database query
             │ Connection string: postgresql://...@postgres:5432/engarde
             ▼
┌─────────────────────────────────────────┐
│ PostgreSQL Container                     │
│ Port: 5432                               │
├─────────────────────────────────────────┤
│ 1. Execute: SELECT * FROM users          │
│ 2. Return rows                           │
└────────────┬────────────────────────────┘
             │ Result set
             ▼
┌─────────────────────────────────────────┐
│ Backend: Process Results                 │
├─────────────────────────────────────────┤
│ 1. Serialize to JSON                     │
│ 2. Check cache (Redis)                   │
│ 3. Return response                       │
└────────────┬────────────────────────────┘
             │ HTTP response
             ▼
┌─────────────────────────────────────────┐
│ Frontend: Receive Response               │
├─────────────────────────────────────────┤
│ 1. Parse JSON                            │
│ 2. Update React state                    │
│ 3. Re-render component                   │
└────────────┬────────────────────────────┘
             │ Rendered HTML
             ▼
         Browser displays user list

TOTAL LATENCY: ~100-300ms (development)
```

---

## Volume Strategy

### Volume Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                        VOLUME STRATEGY                              │
└────────────────────────────────────────────────────────────────────┘

┌───── HOST FILESYSTEM ─────────────────────────────────────────────┐
│                                                                     │
│  /Users/dev/EnGardeHQ/                                             │
│  ├── production-backend/                                           │
│  │   ├── app/              ─────┐  Bind Mount (Development)       │
│  │   ├── uploads/          ─────┤  ↓ Synced continuously          │
│  │   └── logs/             ─────┤                                 │
│  └── production-frontend/        │                                 │
│      ├── src/              ─────┤                                  │
│      ├── public/           ─────┘                                  │
│      └── node_modules/  ← NOT mounted (named volume)              │
│                                                                     │
└──────────────────────┬────────────────────────────────────────────┘
                       │ Bind Mounts
                       ▼
┌───── DOCKER VOLUMES ───────────────────────────────────────────────┐
│                                                                     │
│  BIND MOUNTS (Development):                                        │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Host Path → Container Path                                  │  │
│  │ ./production-backend/app → /app/app                         │  │
│  │ ./production-backend/uploads → /app/uploads                 │  │
│  │ ./production-backend/logs → /app/logs                       │  │
│  │ ./production-frontend/src → /app/src                        │  │
│  │ ./production-frontend/public → /app/public                  │  │
│  │                                                              │  │
│  │ Mode: rw (read-write) or ro (read-only)                    │  │
│  │ Performance: Slower on macOS/Windows (use :cached)          │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  NAMED VOLUMES (Managed by Docker):                                │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Volume Name → Container Path → Purpose                      │  │
│  │ postgres_data → /var/lib/postgresql/data → Database        │  │
│  │ redis_data → /data → Cache persistence                      │  │
│  │ frontend_node_modules → /app/node_modules → Dependencies   │  │
│  │ frontend_next_cache → /app/.next → Build cache             │  │
│  │ backend_pycache → /app/__pycache__ → Python bytecode       │  │
│  │ backend_ml_cache → /home/engarde/.cache → ML models        │  │
│  │                                                              │  │
│  │ Performance: Fast (native Docker storage)                   │  │
│  │ Persistence: Survives container restarts                    │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

VOLUME ACCESS PATTERNS:
┌─────────────────────────────────────────────────────────────────────┐
│                                                                      │
│  ┌──────────┐    Bind Mount    ┌───────────────┐                  │
│  │Developer │◀─────────────────▶│ Source Code   │                  │
│  │  Edits   │   (bidirectional) │  in Container │                  │
│  └──────────┘    sync < 500ms   └───────────────┘                  │
│                                                                      │
│  ┌──────────┐  Named Volume     ┌───────────────┐                  │
│  │Container │────────────────▶  │ Dependencies  │                  │
│  │  Writes  │  (unidirectional) │ (isolated)    │                  │
│  └──────────┘                    └───────────────┘                  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Development vs Production Volumes

```
┌────────────────────────────────────────────────────────────────────┐
│                  VOLUME STRATEGY COMPARISON                         │
└────────────────────────────────────────────────────────────────────┘

DEVELOPMENT ENVIRONMENT:
┌─────────────────────────────────────────────────────────────────┐
│  Backend Container                                               │
│  ┌────────────────────────────────────────────────────────────┐│
│  │ /app/app/                  ← Bind Mount (code changes)     ││
│  │ /app/uploads/              ← Bind Mount (user files)       ││
│  │ /app/logs/                 ← Bind Mount (debug logs)       ││
│  │ /app/__pycache__/          ← Named Volume (performance)    ││
│  │ /home/engarde/.cache/      ← Named Volume (ML models)      ││
│  └────────────────────────────────────────────────────────────┘│
│                                                                  │
│  Frontend Container                                              │
│  ┌────────────────────────────────────────────────────────────┐│
│  │ /app/src/                  ← Bind Mount (code changes)     ││
│  │ /app/public/               ← Bind Mount (assets)           ││
│  │ /app/node_modules/         ← Named Volume (dependencies)   ││
│  │ /app/.next/                ← Named Volume (build cache)    ││
│  └────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘

PRODUCTION ENVIRONMENT:
┌─────────────────────────────────────────────────────────────────┐
│  Backend Container                                               │
│  ┌────────────────────────────────────────────────────────────┐│
│  │ /app/app/                  ← Baked into image (immutable)  ││
│  │ /app/uploads/              ← Named Volume (persistence)    ││
│  │ /app/logs/                 ← Named Volume (logging)        ││
│  │ /app/static/cached_logos/  ← Named Volume (cache)          ││
│  └────────────────────────────────────────────────────────────┘│
│                                                                  │
│  Frontend Container                                              │
│  ┌────────────────────────────────────────────────────────────┐│
│  │ /app/                      ← Baked into image (immutable)  ││
│  │ (No volumes - everything in image)                         ││
│  └────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘

KEY DIFFERENCES:
┌───────────────┬──────────────────────┬──────────────────────┐
│ Aspect        │ Development          │ Production           │
├───────────────┼──────────────────────┼──────────────────────┤
│ Source Code   │ Bind Mount (sync)    │ Baked in (immutable) │
│ Dependencies  │ Named Volume (fast)  │ Baked in (immutable) │
│ User Data     │ Bind Mount (access)  │ Named Volume         │
│ Logs          │ Bind Mount (debug)   │ Named Volume         │
│ Performance   │ Medium (bind mounts) │ Fast (no mounts)     │
│ Flexibility   │ High (instant edits) │ Low (rebuild needed) │
└───────────────┴──────────────────────┴──────────────────────┘
```

---

## Service Lifecycle

### Startup Sequence

```
┌────────────────────────────────────────────────────────────────────┐
│                     SERVICE STARTUP TIMELINE                        │
└────────────────────────────────────────────────────────────────────┘

T+0s    $ docker compose up
        │
        ├─ Read docker-compose.yml
        ├─ Read docker-compose.dev.yml
        ├─ Merge configurations
        └─ Create network: engarde_network

T+2s    PostgreSQL Container Starts
        │
        ├─ Pull image (if needed)
        ├─ Create container
        ├─ Start PostgreSQL process
        │
        ├─ Initialize database (first run only):
        │  ├─ Execute: 01-init-schemas.sql
        │  ├─ Execute: 02-init-db.sql
        │  └─ Execute: 03-init-langflow-schema.sql
        │
        └─ Health check: pg_isready
           ├─ Attempt 1 (T+12s): ✗ not ready
           ├─ Attempt 2 (T+22s): ✗ not ready
           └─ Attempt 3 (T+32s): ✓ HEALTHY

T+2s    Redis Container Starts (parallel with postgres)
        │
        ├─ Pull image (if needed)
        ├─ Create container
        ├─ Start Redis process
        │
        └─ Health check: redis-cli ping
           ├─ Attempt 1 (T+12s): ✓ HEALTHY

T+32s   Backend Container Starts (waits for DB + Redis)
        │
        ├─ depends_on: postgres (healthy) ✓
        ├─ depends_on: redis (healthy) ✓
        │
        ├─ Build/Pull image (if needed)
        ├─ Create container
        ├─ Mount volumes:
        │  ├─ Bind mount: ./production-backend/app → /app/app
        │  └─ Named volume: backend_pycache → /app/__pycache__
        │
        ├─ Execute entrypoint.sh:
        │  ├─ Wait for database (redundant, but safe)
        │  ├─ Run migrations: alembic upgrade head
        │  └─ Seed demo data (if SEED_DEMO_DATA=true)
        │
        ├─ Start Uvicorn server (--reload mode)
        │  └─ Listening on 0.0.0.0:8000
        │
        └─ Health check: curl http://localhost:8000/health
           ├─ Attempt 1 (T+42s): ✗ not ready
           ├─ Attempt 2 (T+52s): ✗ not ready
           └─ Attempt 3 (T+72s): ✓ HEALTHY

T+72s   Frontend Container Starts (waits for backend)
        │
        ├─ depends_on: backend (healthy) ✓
        │
        ├─ Build/Pull image (if needed)
        ├─ Create container
        ├─ Mount volumes:
        │  ├─ Bind mount: ./production-frontend/src → /app/src
        │  └─ Named volume: frontend_node_modules → /app/node_modules
        │
        ├─ Start Next.js dev server
        │  ├─ Compile pages
        │  ├─ Build cache (.next/)
        │  └─ Ready on port 3000
        │
        └─ Health check: curl http://localhost:3000/
           ├─ Attempt 1 (T+102s): ✗ not ready
           └─ Attempt 2 (T+132s): ✓ HEALTHY

T+72s   Langflow Container Starts (parallel with frontend)
        │
        ├─ depends_on: postgres (healthy) ✓
        ├─ depends_on: redis (healthy) ✓
        │
        ├─ Build/Pull image
        ├─ Initialize Langflow
        ├─ Connect to database (langflow schema)
        │
        └─ Health check: curl http://localhost:7860/health
           └─ Attempt 1 (T+112s): ✓ HEALTHY

T+132s  ALL SERVICES HEALTHY
        │
        ├─ Docker Compose Watch Mode Active
        │  ├─ Monitoring ./production-backend/app
        │  └─ Monitoring ./production-frontend/src
        │
        └─ System Ready for Development
           ├─ Frontend: http://localhost:3000
           ├─ Backend:  http://localhost:8000
           ├─ API Docs: http://localhost:8000/docs
           └─ Langflow: http://localhost:7860

TOTAL STARTUP TIME: ~2 minutes (first run: 5-10 min with image builds)
```

### Shutdown Sequence

```
T+0s    $ docker compose down
        │
        ├─ Send SIGTERM to all containers
        │
        ├─ Frontend receives SIGTERM
        │  ├─ Next.js gracefully shuts down
        │  └─ Container exits (T+2s)
        │
        ├─ Backend receives SIGTERM
        │  ├─ Uvicorn finishes current requests
        │  ├─ Closes database connections
        │  └─ Container exits (T+5s)
        │
        ├─ Langflow receives SIGTERM
        │  ├─ Langflow shuts down
        │  └─ Container exits (T+5s)
        │
        ├─ PostgreSQL receives SIGTERM
        │  ├─ PostgreSQL checkpoint
        │  ├─ Flush buffers to disk
        │  └─ Container exits (T+10s)
        │
        └─ Redis receives SIGTERM
           ├─ Redis saves RDB snapshot
           └─ Container exits (T+3s)

T+10s   All containers stopped
        │
        ├─ Remove containers
        ├─ Volumes preserved (unless -v flag)
        └─ Network removed

TOTAL SHUTDOWN TIME: ~10 seconds
```

---

## Code Change Propagation

### Backend (Python) Change Flow

```
┌────────────────────────────────────────────────────────────────────┐
│                BACKEND CODE CHANGE PROPAGATION                      │
└────────────────────────────────────────────────────────────────────┘

T+0ms   Developer edits: production-backend/app/api/users.py
        │
        ├─ File saved to disk
        └─ Timestamp updated

T+50ms  Host file system detects change
        │
        ├─ inotify / FSEvents event triggered
        └─ Docker Watch notified

T+200ms Docker Watch syncs file
        │
        ├─ Copy: production-backend/app/api/users.py
        │    → Container: /app/app/api/users.py
        │
        └─ File appears in container

T+250ms Uvicorn detects file change
        │
        ├─ Watchfiles library detects inode change
        ├─ Log: "WatchFiles detected changes in 'app/api/users.py'"
        │
        └─ Trigger reload

T+300ms Python module reload
        │
        ├─ Unload: app.api.users module
        ├─ Clear import cache
        ├─ Reload: app.api.users module
        ├─ Re-apply route decorators
        │
        └─ Log: "Reloading..."

T+500ms Server ready with new code
        │
        ├─ All routes updated
        ├─ Accepting requests
        │
        └─ Log: "Application startup complete"

T+600ms Developer tests endpoint
        │
        ├─ $ curl http://localhost:8000/api/users
        │
        └─ ✓ New code executes successfully

TOTAL TIME: 600ms (from save to test)
```

### Frontend (React) Change Flow

```
┌────────────────────────────────────────────────────────────────────┐
│                FRONTEND CODE CHANGE PROPAGATION                     │
└────────────────────────────────────────────────────────────────────┘

T+0ms   Developer edits: production-frontend/src/components/Button.tsx
        │
        ├─ File saved to disk
        └─ Timestamp updated

T+50ms  Host file system detects change
        │
        ├─ File watch event triggered
        └─ Docker Watch notified

T+150ms Docker Watch syncs file
        │
        ├─ Copy: production-frontend/src/components/Button.tsx
        │    → Container: /app/src/components/Button.tsx
        │
        └─ File appears in container

T+200ms Next.js detects file change
        │
        ├─ Webpack file watcher detects change
        ├─ Log: "Compiling /components/Button..."
        │
        └─ Trigger Fast Refresh

T+250ms Webpack recompiles
        │
        ├─ Parse TypeScript: Button.tsx
        ├─ Type checking (if enabled)
        ├─ Transform JSX → JavaScript
        ├─ Bundle update (only changed module)
        │
        └─ Log: "Compiled successfully in 84ms"

T+300ms HMR update sent to browser
        │
        ├─ WebSocket connection: /_next/webpack-hmr
        ├─ Send HMR payload:
        │  ├─ Module ID: ./src/components/Button.tsx
        │  ├─ Updated code
        │  └─ Source map
        │
        └─ Browser receives update

T+350ms Browser applies update
        │
        ├─ Fast Refresh detects React component
        ├─ Preserve component state (if possible)
        ├─ Re-render component with new code
        │  ├─ Unmount old component (cleanup)
        │  ├─ Mount new component
        │  └─ Restore state
        │
        └─ DOM updated

T+400ms User sees updated UI
        │
        ├─ Button displays new text/style
        ├─ No page reload
        ├─ Form data preserved
        │
        └─ Console: "[Fast Refresh] Component updated"

TOTAL TIME: 400ms (from save to visual update)

NO PAGE RELOAD ✓
STATE PRESERVED ✓
INSTANT FEEDBACK ✓
```

---

## Production vs Development

### Configuration Comparison

```
┌────────────────────────────────────────────────────────────────────┐
│            DEVELOPMENT VS PRODUCTION COMPARISON                     │
└────────────────────────────────────────────────────────────────────┘

┌──────────────────┬──────────────────────┬───────────────────────┐
│ Feature          │ Development          │ Production            │
├──────────────────┼──────────────────────┼───────────────────────┤
│ Dockerfile       │                      │                       │
│ Target           │ development          │ production            │
├──────────────────┼──────────────────────┼───────────────────────┤
│ Source Code      │ Bind Mount           │ Baked into image      │
│                  │ (instant changes)    │ (immutable)           │
├──────────────────┼──────────────────────┼───────────────────────┤
│ Dependencies     │ Named Volume         │ Baked into image      │
│                  │ (node_modules)       │                       │
├──────────────────┼──────────────────────┼───────────────────────┤
│ Hot Reload       │ Enabled              │ Disabled              │
│                  │ (uvicorn --reload)   │ (gunicorn)            │
├──────────────────┼──────────────────────┼───────────────────────┤
│ Debug Mode       │ DEBUG=true           │ DEBUG=false           │
│                  │ LOG_LEVEL=debug      │ LOG_LEVEL=info        │
├──────────────────┼──────────────────────┼───────────────────────┤
│ CORS             │ Permissive           │ Restrictive           │
│                  │ ["*"]                │ ["https://app.com"]   │
├──────────────────┼──────────────────────┼───────────────────────┤
│ Image Size       │ Larger               │ Smaller               │
│                  │ (~800MB)             │ (~300MB)              │
├──────────────────┼──────────────────────┼───────────────────────┤
│ Security         │ Relaxed              │ Hardened              │
│                  │ (exposed ports)      │ (minimal exposure)    │
├──────────────────┼──────────────────────┼───────────────────────┤
│ Performance      │ Medium               │ Optimized             │
│                  │ (more logging)       │ (less overhead)       │
├──────────────────┼──────────────────────┼───────────────────────┤
│ Resource Limits  │ None or generous     │ Strict limits         │
│                  │                      │ (CPU, memory)         │
├──────────────────┼──────────────────────┼───────────────────────┤
│ Restart Policy   │ unless-stopped       │ always                │
├──────────────────┼──────────────────────┼───────────────────────┤
│ Telemetry        │ Disabled             │ Enabled               │
│                  │                      │ (monitoring)          │
└──────────────────┴──────────────────────┴───────────────────────┘
```

### Migration Path

```
┌────────────────────────────────────────────────────────────────────┐
│              LOCAL DEV → PRODUCTION DEPLOYMENT                      │
└────────────────────────────────────────────────────────────────────┘

┌────────── LOCAL DEVELOPMENT ──────────┐
│                                        │
│  $ docker compose -f docker-compose.yml \
│    -f docker-compose.dev.yml up --watch
│                                        │
│  Features:                             │
│  - Hot reload                          │
│  - Debug logging                       │
│  - Bind mounts                         │
│  - Exposed ports                       │
└────────────────┬───────────────────────┘
                 │
                 │ git commit & push
                 ▼
┌────────── CI/CD TESTING ──────────────┐
│                                        │
│  $ docker compose -f docker-compose.test.yml up
│                                        │
│  Actions:                              │
│  - Build production images             │
│  - Run test suite                      │
│  - Security scan                       │
│  - Push to registry                    │
└────────────────┬───────────────────────┘
                 │
                 │ Tests pass
                 ▼
┌────────── STAGING DEPLOYMENT ─────────┐
│                                        │
│  $ docker compose -f docker-compose.yml \
│    -f docker-compose.prod.yml up -d
│                                        │
│  Environment:                          │
│  - Production images                   │
│  - Production config                   │
│  - Staging database                    │
│  - Monitoring enabled                  │
└────────────────┬───────────────────────┘
                 │
                 │ Manual QA pass
                 ▼
┌────────── PRODUCTION DEPLOYMENT ──────┐
│                                        │
│  $ docker compose -f docker-compose.yml \
│    -f docker-compose.prod.yml up -d
│                                        │
│  Environment:                          │
│  - Production images (tagged)          │
│  - Production secrets                  │
│  - Production database                 │
│  - Full monitoring                     │
│  - Backups enabled                     │
└────────────────────────────────────────┘

ROLLBACK PLAN:
If issues detected → Pull previous image version → Restart services
```

---

## Conclusion

These diagrams provide a visual understanding of the EnGarde Docker architecture. Use them as reference when:

- Onboarding new developers
- Debugging issues
- Planning architectural changes
- Understanding system behavior
- Optimizing performance

For detailed implementation instructions, see:
- [DOCKER_DEVELOPMENT_ARCHITECTURE.md](./DOCKER_DEVELOPMENT_ARCHITECTURE.md)
- [QUICK_START_DOCKER.md](./QUICK_START_DOCKER.md)
- [DOCKER_BEST_PRACTICES.md](./DOCKER_BEST_PRACTICES.md)

---

**Last Updated:** October 29, 2025
**Version:** 1.0
