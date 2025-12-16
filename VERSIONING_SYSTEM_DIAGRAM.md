# En Garde Versioning System - Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         EN GARDE VERSIONING SYSTEM                          │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           VERSION SOURCE FILES                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  📄 production-frontend/version.json        📄 production-backend/version.json│
│  ┌──────────────────────────────────┐      ┌──────────────────────────────┐│
│  │ {                                │      │ {                            ││
│  │   "version": "1.0.0",            │      │   "version": "1.0.0",        ││
│  │   "build_date": "unknown",       │      │   "build_date": "unknown",   ││
│  │   "git_commit": "unknown",       │      │   "git_commit": "unknown",   ││
│  │   "environment": "production"    │      │   "environment": "production"││
│  │ }                                │      │ }                            ││
│  └──────────────────────────────────┘      └──────────────────────────────┘│
│                                                                             │
│  Single source of truth for version numbers                                │
│  Manually updated by developers or scripts                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ⬇
┌─────────────────────────────────────────────────────────────────────────────┐
│                          BUILD TIME WORKFLOW                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1️⃣  Developer updates version                                              │
│      └─> ./update-version.sh 1.2.0                                         │
│           ├─> Updates production-frontend/version.json                     │
│           └─> Updates production-backend/version.json                      │
│                                                                             │
│  2️⃣  Developer runs build script                                            │
│      └─> ./build.sh                                                        │
│                                                                             │
│  3️⃣  Build script extracts information                                      │
│      ├─> VERSION=$(read from version.json)                                 │
│      ├─> GIT_COMMIT=$(git rev-parse HEAD)                                  │
│      └─> BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")                       │
│                                                                             │
│  4️⃣  Build script exports environment variables                             │
│      ├─> export VERSION="1.2.0"                                            │
│      ├─> export GIT_COMMIT="abc123def456789"                               │
│      └─> export BUILD_DATE="2025-10-10T17:00:00Z"                          │
│                                                                             │
│  5️⃣  Docker Compose receives build arguments                                │
│      └─> docker-compose build                                              │
│           ├─> Backend: --build-arg VERSION=$VERSION \                      │
│           │            --build-arg GIT_COMMIT=$GIT_COMMIT \                │
│           │            --build-arg BUILD_DATE=$BUILD_DATE                  │
│           └─> Frontend: --build-arg VERSION=$VERSION \                     │
│                         --build-arg GIT_COMMIT=$GIT_COMMIT \               │
│                         --build-arg BUILD_DATE=$BUILD_DATE                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ⬇
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DOCKER BUILD STAGE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  🐳 Backend Dockerfile                    🐳 Frontend Dockerfile            │
│  ┌───────────────────────────────┐       ┌──────────────────────────────┐ │
│  │ ARG VERSION=1.0.0             │       │ ARG VERSION=1.0.0            │ │
│  │ ARG GIT_COMMIT=unknown        │       │ ARG GIT_COMMIT=unknown       │ │
│  │ ARG BUILD_DATE=unknown        │       │ ARG BUILD_DATE=unknown       │ │
│  │                               │       │                              │ │
│  │ RUN echo '{                   │       │ RUN echo '{                  │ │
│  │   "version":"$VERSION",       │       │   "version":"$VERSION",      │ │
│  │   "build_date":"$BUILD_DATE", │       │   "build_date":"$BUILD_DATE",│ │
│  │   "git_commit":"$GIT_COMMIT", │       │   "git_commit":"$GIT_COMMIT",│ │
│  │   "environment":"production"  │       │   "environment":"production" │ │
│  │ }' > /app/version.json        │       │ }' > /app/public/version.json│ │
│  └───────────────────────────────┘       └──────────────────────────────┘ │
│                                                                             │
│  ⚙️  Version information baked into Docker images                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ⬇
┌─────────────────────────────────────────────────────────────────────────────┐
│                        RUNTIME ARCHITECTURE                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────────────────┐  ┌─────────────────────────────────┐│
│  │      BACKEND CONTAINER           │  │     FRONTEND CONTAINER          ││
│  │  (engarde_backend)               │  │  (engarde_frontend)             ││
│  ├──────────────────────────────────┤  ├─────────────────────────────────┤│
│  │                                  │  │                                 ││
│  │  📄 /app/version.json            │  │  📄 /app/public/version.json    ││
│  │  {                               │  │  {                              ││
│  │    "version": "1.2.0",           │  │    "version": "1.2.0",          ││
│  │    "build_date": "2025-10-...", │  │    "build_date": "2025-10-...", ││
│  │    "git_commit": "abc123...",   │  │    "git_commit": "abc123...",   ││
│  │    "environment": "production"   │  │    "environment": "production"  ││
│  │  }                               │  │  }                              ││
│  │                                  │  │                                 ││
│  │  🔌 API Endpoints:               │  │  🎨 UI Components:              ││
│  │  ├─ GET /api/system/version     │  │  ├─ FooterVersionDisplay        ││
│  │  ├─ GET /api/system/status      │  │  ├─ SidebarVersionDisplay       ││
│  │  └─ GET /api/system/health      │  │  ├─ CornerVersionDisplay        ││
│  │                                  │  │  └─ CompactVersionDisplay       ││
│  │  📂 app/routers/system.py       │  │                                 ││
│  │  ├─ Loads version.json          │  │  📂 components/layout/          ││
│  │  ├─ Caches version info         │  │     version-display.tsx         ││
│  │  ├─ Returns comprehensive data  │  │  ├─ Fetches /version.json       ││
│  │  └─ Includes frontend version   │  │  ├─ Optionally fetches API      ││
│  │                                  │  │  └─ Displays in UI              ││
│  └──────────────────────────────────┘  └─────────────────────────────────┘│
│           ⬆                                         ⬆                      │
│           │                                         │                      │
│           └─────────────────┬───────────────────────┘                      │
│                             │                                              │
└─────────────────────────────┼──────────────────────────────────────────────┘
                              │
                              ⬇
┌─────────────────────────────────────────────────────────────────────────────┐
│                        USER/CLIENT ACCESS                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  👤 End Users (Web UI)                                                      │
│  ├─> Visit application in browser                                          │
│  ├─> See version in footer: "En Garde v1.2.0 (Build: abc1234)"            │
│  ├─> Click "Show details" for full info                                    │
│  └─> View: Frontend v1.2.0, Backend v1.2.0, Git commit, Build date        │
│                                                                             │
│  🔧 Developers/Admins (API)                                                 │
│  ├─> curl http://localhost:8000/api/system/version                         │
│  ├─> curl http://localhost:3001/version.json                               │
│  └─> docker exec engarde_backend cat /app/version.json                     │
│                                                                             │
│  🤖 Monitoring Systems (Health Checks)                                      │
│  ├─> GET /api/system/health (Simple health check)                          │
│  ├─> GET /api/system/status (System status with version)                   │
│  └─> GET /api/system/version (Full version information)                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Version Flow Diagram

```
Developer Workflow:
──────────────────

┌─────────────┐
│   Update    │  ./update-version.sh 1.2.0
│   Version   │  ├─> Updates frontend/version.json
└──────┬──────┘  └─> Updates backend/version.json
       │
       ⬇
┌─────────────┐
│    Build    │  ./build.sh
│   Docker    │  ├─> Reads version files
└──────┬──────┘  ├─> Gets git commit
       │         └─> Generates timestamp
       ⬇
┌─────────────┐
│   Docker    │  docker-compose build
│   Images    │  ├─> Backend image with version.json
└──────┬──────┘  └─> Frontend image with version.json
       │
       ⬇
┌─────────────┐
│   Deploy    │  docker-compose up -d
│ Containers  │  ├─> Backend container running
└──────┬──────┘  └─> Frontend container running
       │
       ⬇
┌─────────────┐
│   Users     │  ├─> Visit web UI
│   Access    │  ├─> Call API endpoints
└─────────────┘  └─> Monitor health checks


API Data Flow:
──────────────

User Request                Backend Processing              Response
─────────────              ───────────────────              ─────────

GET /api/system/version  ─>  system.py router          ─>  {
                              ├─ Load /app/version.json      "backend_version": "1.2.0",
                              ├─ Cache version data          "frontend_version": "1.2.0",
                              ├─ Try load frontend ver       "git_commit": "abc123...",
                              └─ Return comprehensive        "build_date": "2025-10-10...",
                                                             "build_info": {...}
                                                           }


UI Data Flow:
─────────────

Component Mount          Data Fetching                    Display
────────────────        ──────────────                   ─────────

VersionDisplay loads  ─> fetch('/version.json')      ─>  "En Garde v1.2.0
                         ├─ Get frontend version           (Build: abc1234)"
                         └─ Optional: fetch API
                            /api/system/version            [Show details ▼]
                            ├─ Get backend version
                            └─ Get build info


Git Tag Workflow:
─────────────────

Version Update ──> Build ──> Test ──> Commit ──> Tag ──> Push
      │              │         │         │        │       │
      v              v         v         v        v       v
  1.2.0 in      Docker      Verify   git add  git tag  git push
version.json    images    endpoints  files   v1.2.0   origin
                          working              -m      v1.2.0
                                            "Release
                                              1.2.0"
```

## Component Integration Map

```
Application Layouts:
────────────────────

Dashboard Layout                 Marketing Layout              Admin Layout
────────────────                 ────────────────              ────────────

┌───────────────────┐           ┌───────────────────┐         ┌───────────────────┐
│      Header       │           │      Header       │         │   Admin Header    │
├───────┬───────────┤           ├───────────────────┤         ├───────────────────┤
│       │           │           │                   │         │                   │
│ Side  │   Main    │           │      Main         │         │      Main         │
│ bar   │  Content  │           │     Content       │         │     Content       │
│       │           │           │                   │         │                   │
│ [v]   │           │           │                   │         │                   │
└───────┴───────────┘           ├───────────────────┤         └───────────────────┘
                                │     Footer        │         ┌─────────────┐
SidebarVersionDisplay           │  [Show details]   │         │  [v1.2.0]   │ ← Corner
in sidebar                      └───────────────────┘         │  [Details]  │
                                FooterVersionDisplay          └─────────────┘
                                in footer                     CornerVersionDisplay


Component Hierarchy:
────────────────────

VersionDisplay (Base Component)
├── position: "footer" | "sidebar" | "corner"
├── showBuildInfo: boolean
└── className: string
    │
    ├─> FooterVersionDisplay
    │   ├─ position="footer"
    │   └─ showBuildInfo=true
    │
    ├─> SidebarVersionDisplay
    │   ├─ position="sidebar"
    │   └─ showBuildInfo=false
    │
    ├─> CornerVersionDisplay
    │   ├─ position="corner"
    │   └─ showBuildInfo=true
    │
    └─> CompactVersionDisplay
        └─ Minimal "v1.0.0" only
```

## File System Structure

```
/Users/cope/EnGardeHQ/
│
├── 📄 build.sh                                    (Build automation)
├── 📄 update-version.sh                           (Version update helper)
├── 📄 docker-compose.yml                          (With build args)
│
├── 📁 production-backend/
│   ├── 📄 version.json                            (Backend version source)
│   ├── 📄 Dockerfile                              (With version ARGs)
│   └── 📁 app/
│       ├── 📄 main.py                             (Registers system router)
│       └── 📁 routers/
│           └── 📄 system.py                       (Version API endpoints)
│
├── 📁 production-frontend/
│   ├── 📄 version.json                            (Frontend version source)
│   ├── 📄 Dockerfile                              (With version ARGs)
│   ├── 📄 INTEGRATION_EXAMPLE.md                  (UI integration guide)
│   └── 📁 components/
│       └── 📁 layout/
│           └── 📄 version-display.tsx             (UI components)
│
└── 📁 Documentation/
    ├── 📄 VERSION_MANAGEMENT.md                   (Complete guide)
    ├── 📄 VERSIONING_IMPLEMENTATION_SUMMARY.md    (Implementation details)
    └── 📄 VERSIONING_SYSTEM_DIAGRAM.md           (This file)
```

## Build Artifact Flow

```
Build Time                          Runtime
──────────                         ─────────

version.json files       ──────>   Docker Images
(Source of truth)                  (Immutable)
    │                                  │
    ├─ Frontend: 1.2.0                ├─ Frontend Image
    └─ Backend: 1.2.0                 │  └─ /app/public/version.json
                                      │     ├─ version: 1.2.0
    ⬇                                 │     ├─ git_commit: abc123...
                                      │     ├─ build_date: 2025-10-10
build.sh reads files                  │     └─ environment: production
    │                                 │
    ├─ VERSION=1.2.0                  └─ Backend Image
    ├─ GIT_COMMIT=abc123...              └─ /app/version.json
    └─ BUILD_DATE=2025-10-10                ├─ version: 1.2.0
                                            ├─ git_commit: abc123...
    ⬇                                       ├─ build_date: 2025-10-10
                                            └─ environment: production
Docker build args
    │                              ──────>   Running Containers
    ├─ --build-arg VERSION                  (Serve version info)
    ├─ --build-arg GIT_COMMIT                   │
    └─ --build-arg BUILD_DATE                   ├─ API: /api/system/version
                                                ├─ File: /version.json
                                                └─ UI: Version components
```

## Version Consistency Check

```
Verification Points:
────────────────────

1. Source Files           2. Build Arguments      3. Docker Images
   ──────────               ────────────────        ──────────────
   frontend/version.json    VERSION=1.2.0           frontend image
   "version": "1.2.0"       GIT_COMMIT=abc123       /app/public/version.json
                            BUILD_DATE=2025-10-10   "version": "1.2.0"
   backend/version.json
   "version": "1.2.0"                               backend image
                                                    /app/version.json
                                                    "version": "1.2.0"

4. Running Containers    5. API Responses        6. UI Display
   ──────────────────      ──────────────          ──────────
   docker exec...          GET /api/system/        Browser shows:
   cat version.json        version                 "En Garde v1.2.0
   "version": "1.2.0"      returns: {              (Build: abc1234)"
                           "backend_version":
                           "1.2.0",
                           "frontend_version":
                           "1.2.0"
                           }

All should match! ✅
```

## Monitoring and Observability

```
Health Check Flow:
──────────────────

Load Balancer              Application              Response
─────────────             ───────────              ────────

GET /api/system/health ─>  Backend Container   ─>  { "status": "healthy" }
   (Every 30s)              ├─ No DB check
                            └─ Fast response

GET /api/system/status ─>  Backend Container   ─>  { "version": "1.2.0",
   (Monitoring)              ├─ Load version.json    "status": "operational" }
                             └─ System info

GET /api/system/version ─> Backend Container   ─>  { Full version details }
   (Deploy verification)     ├─ Load backend ver
                             ├─ Load frontend ver
                             └─ Build metadata


Deployment Verification:
────────────────────────

After deployment, verify version:

1. API Check:
   curl http://localhost:8000/api/system/version
   ├─ Verify backend_version matches expected
   ├─ Verify frontend_version matches expected
   └─ Check git_commit matches deployment

2. UI Check:
   ├─ Open browser
   ├─ Check footer version display
   └─ Click "Show details" to verify build info

3. Container Check:
   ├─ docker exec engarde_backend cat /app/version.json
   └─ docker exec engarde_frontend cat /app/public/version.json
```

## Summary

This versioning system provides:

✅ **Single Source of Truth**: `version.json` files
✅ **Automated Injection**: Build script handles all version data
✅ **Immutable Artifacts**: Version baked into Docker images
✅ **Multiple Access Points**: UI, API, files, containers
✅ **Developer Friendly**: Simple update and build process
✅ **Production Ready**: Proper semantic versioning
✅ **Monitoring Support**: Health checks and status endpoints
✅ **Full Traceability**: Git commit and build timestamp
✅ **Consistent Display**: Unified UI components
✅ **Easy Verification**: Multiple check points

---

**Last Updated:** 2025-10-10
**Diagram Version:** 1.0.0
