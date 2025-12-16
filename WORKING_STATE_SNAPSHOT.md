# EnGarde Working State Snapshot

**Date**: 2025-11-03
**Status**: ✅ FULLY OPERATIONAL
**Verified By**: Claude Code Agent Swarm (backend-api-architect + qa-bug-hunter)

---

## Current Working Configuration

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Browser (Client)                      │
│                    http://localhost:3000                     │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ HTTP Requests to /api/*
                        │ (Relative URLs)
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              Next.js Frontend (Docker Container)             │
│                  engarde_frontend_dev:3000                   │
│                                                              │
│  Environment:                                                │
│  ├─ NEXT_PUBLIC_API_URL=/api          (Client-side)        │
│  ├─ BACKEND_URL=http://backend:8000   (Server-side)        │
│  └─ DOCKER_CONTAINER=true                                   │
│                                                              │
│  Middleware Proxy:                                           │
│  ├─ /api/* → http://backend:8000/api/*                     │
│  ├─ Adds CSRF protection                                    │
│  ├─ Handles authentication                                   │
│  └─ Uses Docker internal network                            │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ Docker Internal Network
                        │ http://backend:8000
                        ▼
┌─────────────────────────────────────────────────────────────┐
│               FastAPI Backend (Docker Container)             │
│                   engarde_backend_dev:8000                   │
│                                                              │
│  Environment:                                                │
│  ├─ DATABASE_URL=postgresql://...@postgres:5432/engarde    │
│  ├─ REDIS_URL=redis://redis:6379/0                         │
│  ├─ CORS_ORIGINS=["http://localhost:3000",...]             │
│  └─ DEBUG=true                                              │
│                                                              │
│  Available Endpoints:                                        │
│  ├─ POST /api/auth/email-login                              │
│  ├─ GET  /api/brands/                                       │
│  ├─ GET  /api/brands/current                                │
│  ├─ GET  /api/brands/{id}                                   │
│  └─ GET  /api/health                                        │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ PostgreSQL Connection
                        ▼
┌─────────────────────────────────────────────────────────────┐
│             PostgreSQL Database (Docker Container)           │
│                  engarde_postgres_dev:5432                   │
│                                                              │
│  Database: engarde                                           │
│  User: engarde_user                                          │
│  Tables: 12 (users, brands, tenants, tenant_users, etc.)   │
└─────────────────────────────────────────────────────────────┘
```

---

## Database State

### Demo User
```sql
SELECT * FROM users WHERE email='demo@engarde.com';
```

| Field | Value |
|-------|-------|
| id | demo-user-id |
| email | demo@engarde.com |
| password | demo123 (hashed) |
| first_name | Demo |
| last_name | User |
| is_active | true |
| user_type | brand |

**Important**: Users table does NOT have a `tenant_id` column. User.tenant_id is a **computed property** from the TenantUser relationship.

---

### Tenant Associations

Demo user belongs to **3 tenants**:

```sql
SELECT tenant_id, role, is_active
FROM tenant_users
WHERE user_id = 'demo-user-id';
```

| tenant_id | role | is_active |
|-----------|------|-----------|
| default-tenant | owner | true |
| tenant-demo-main | owner | true |
| tenant-shared | admin | true |

**Architecture Note**: The `User.tenant_id` property returns the **first tenant** in the list (`default-tenant`).

---

### Brand Memberships

Demo user is a member of **9 brands** across 3 tenants:

```sql
SELECT b.id, b.name, b.tenant_id, bm.role
FROM brand_members bm
JOIN brands b ON bm.brand_id = b.id
WHERE bm.user_id = 'demo-user-id'
ORDER BY b.name;
```

| Brand ID | Brand Name | Tenant ID | Role |
|----------|------------|-----------|------|
| demo-brand-1 | EnGarde Demo Brand | default-tenant | owner |
| demo-brand-2 | Demo Retail Co | default-tenant | owner |
| demo-brand-3 | Demo Tech Startup | default-tenant | owner |
| demo-brand-4 | Demo Health & Wellness | default-tenant | owner |
| brand-demo-main | EnGarde Demo Brand | tenant-demo-main | owner |
| brand-demo-main-retail | Demo Retail Co | tenant-demo-main | owner |
| brand-demo-main-tech | Demo Tech Startup | tenant-demo-main | owner |
| brand-demo-main-health | Demo Health & Wellness | tenant-demo-main | owner |
| brand-shared | Team Testing Brand | tenant-shared | admin |

---

### Relationship Structure

```
User (demo-user-id)
  │
  ├─────── tenant_users (junction table) ─────────┐
  │        ├─ default-tenant                      │
  │        ├─ tenant-demo-main                    │
  │        └─ tenant-shared                       │
  │                                                ▼
  │                                           Tenant
  │                                                │
  │                                                │ (has many brands)
  │                                                ▼
  │                                           Brand
  │                                           ├─ demo-brand-1 (default-tenant)
  │                                           ├─ demo-brand-2 (default-tenant)
  │                                           ├─ brand-demo-main (tenant-demo-main)
  │                                           └─ brand-shared (tenant-shared)
  │                                                │
  └─────── brand_members (junction table) ─────────┘
           ├─ demo-user-id → demo-brand-1 (owner)
           ├─ demo-user-id → demo-brand-2 (owner)
           ├─ demo-user-id → brand-demo-main (owner)
           └─ demo-user-id → brand-shared (admin)
```

**Foreign Keys**:
- `tenant_users.user_id` → `users.id`
- `tenant_users.tenant_id` → `tenants.id`
- `brands.tenant_id` → `tenants.id`
- `brand_members.user_id` → `users.id`
- `brand_members.brand_id` → `brands.id`

All foreign keys are properly established ✅

---

## API Test Results

### 1. Authentication

**Request**:
```bash
curl -X POST "http://localhost:8000/api/auth/email-login" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@engarde.com","password":"demo123"}'
```

**Response** (200 OK):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 1800,
  "user": {
    "id": "demo-user-id",
    "email": "demo@engarde.com",
    "first_name": "Demo",
    "last_name": "User",
    "is_active": true,
    "user_type": "brand",
    "tenant_id": "default-tenant"
  }
}
```

**JWT Token Claims**:
```json
{
  "sub": "demo@engarde.com",
  "tenant_id": "default-tenant",
  "exp": 1762224698,
  "type": "access"
}
```

---

### 2. Get All Brands

**Request**:
```bash
TOKEN="..."
curl -X GET "http://localhost:8000/api/brands/" \
  -H "Authorization: Bearer $TOKEN"
```

**Response** (200 OK):
```json
{
  "items": [
    {
      "id": "demo-brand-1",
      "name": "EnGarde Demo Brand",
      "tenant_id": "default-tenant",
      "slug": "engarde-demo",
      "website": "https://demo.engarde.com",
      "industry": "technology"
    },
    // ... 8 more brands
  ],
  "total": 9,
  "page": 1,
  "page_size": 20,
  "has_next": false,
  "has_previous": false
}
```

**Important**: Returns brands from **all tenants** where user is a member (not filtered by tenant_id).

---

### 3. Get Current Brand

**Request**:
```bash
curl -X GET "http://localhost:8000/api/brands/current" \
  -H "Authorization: Bearer $TOKEN"
```

**Response** (200 OK):
```json
{
  "brand": {
    "id": "demo-brand-1",
    "name": "EnGarde Demo Brand",
    "tenant_id": "default-tenant",
    "is_member": true,
    "member_role": "owner"
  },
  "recent_brands": [
    {"id": "demo-brand-1", "name": "EnGarde Demo Brand"},
    {"id": "demo-brand-2", "name": "Demo Retail Co"},
    {"id": "demo-brand-3", "name": "Demo Tech Startup"},
    {"id": "demo-brand-4", "name": "Demo Health & Wellness"}
  ],
  "total_brands": 9
}
```

---

## Critical Configuration Files

### 1. Docker Compose Configuration

**File**: `/Users/cope/EnGardeHQ/docker-compose.dev.yml`

**Critical Frontend Environment Variables** (lines 197-204):
```yaml
environment:
  # CRITICAL: Use middleware proxy for Docker deployment
  NEXT_PUBLIC_API_URL: /api              # Client-side: relative URLs
  BACKEND_URL: http://backend:8000       # Server-side: Docker network
  DOCKER_CONTAINER: "true"               # Enable Docker detection
```

**Why This Matters**:
- `NEXT_PUBLIC_API_URL=/api` → Browser makes requests to `/api/*` (relative)
- `BACKEND_URL=http://backend:8000` → Server-side middleware proxies to Docker internal network
- Prevents ERR_NAME_NOT_RESOLVED errors in browser

---

### 2. Environment Detection Logic

**File**: `/Users/cope/EnGardeHQ/production-frontend/lib/config/environment.ts`

**Key Functions**:

**getEnvironmentConfig()** (lines 20-147):
- Detects whether running in browser or server
- Returns different backend URLs based on context:
  - Server-side: `http://backend:8000` (Docker internal)
  - Client-side: `/api` (relative paths for browser)

**getApiBaseUrl()** (lines 157-177):
- **Always returns `/api`** for browser requests (line 165)
- Middleware handles proxying to backend

**getBackendUrl()** (lines 193-209):
- Prioritizes `BACKEND_URL` for server-side operations
- Used by middleware to connect to Docker backend

---

### 3. Next.js Configuration

**File**: `/Users/cope/EnGardeHQ/production-frontend/next.config.js`

**Rewrites Disabled** (lines 90-138):
- When `NEXT_PUBLIC_API_URL=/api`, rewrites are disabled
- Middleware proxy handles all `/api/*` routing
- Prevents double-proxying issues

---

### 4. Backend Models

**User Model** (`/Users/cope/EnGardeHQ/production-backend/app/models/user.py`):

**Critical Property** (lines 177-182):
```python
@property
def tenant_id(self) -> Optional[str]:
    """Get the first tenant ID for the user."""
    if self.tenants and len(self.tenants) > 0:
        return self.tenants[0].tenant_id
    return None
```

**Why This Matters**:
- Users table does NOT have a `tenant_id` column
- `tenant_id` is computed from the `tenants` relationship
- Returns only the **first tenant** (arbitrary order)
- Multi-tenant users may have different `tenant_id` values across sessions

---

## How to Restore This Working State

### Quick Validation

```bash
# Run automated validation script
./scripts/validate-auth-system.sh
```

**Expected Output**:
```
Test 1: Authentication Flow...
✓ PASS - Authentication working (token received)

Test 2: Brands Endpoint...
✓ PASS - Brands endpoint working (9 brands returned)

Test 3: Current Brand Endpoint...
✓ PASS - Current brand: EnGarde Demo Brand

...

✓ ALL TESTS PASSED - System is operational
```

---

### If Authentication Breaks

**Option 1: Re-seed Database**
```bash
bash scripts/seed-database.sh
docker-compose restart backend
```

**Option 2: Manual Database Repair**
```bash
# Fix tenant associations
docker-compose exec postgres psql -U engarde_user -d engarde << EOF
INSERT INTO tenant_users (tenant_id, user_id, role, is_active, joined_at)
VALUES
  ('default-tenant', 'demo-user-id', 'owner', true, NOW()),
  ('tenant-demo-main', 'demo-user-id', 'owner', true, NOW()),
  ('tenant-shared', 'demo-user-id', 'admin', true, NOW())
ON CONFLICT (tenant_id, user_id) DO NOTHING;
EOF

# Fix brand memberships
docker-compose exec postgres psql -U engarde_user -d engarde << EOF
INSERT INTO brand_members (brand_id, user_id, role, is_active, joined_at)
SELECT b.id, 'demo-user-id', 'owner', true, NOW()
FROM brands b
WHERE b.tenant_id IN ('default-tenant', 'tenant-demo-main')
AND NOT EXISTS (SELECT 1 FROM brand_members WHERE brand_id = b.id AND user_id = 'demo-user-id');
EOF

docker-compose restart backend
```

---

### If Frontend Environment Breaks

**Symptom**: ERR_NAME_NOT_RESOLVED, requests to `http://backend:8000` from browser

**Fix**:
```bash
# 1. Edit docker-compose.dev.yml (lines 197-204)
# Ensure:
#   NEXT_PUBLIC_API_URL: /api
#   BACKEND_URL: http://backend:8000
#   DOCKER_CONTAINER: "true"

# 2. Rebuild frontend container (required to clear webpack cache)
docker-compose stop frontend
docker-compose rm -f frontend
docker-compose build --no-cache frontend
docker-compose up -d frontend

# 3. Verify
docker-compose exec frontend printenv | grep -E "NEXT_PUBLIC_API_URL|BACKEND_URL"
```

---

### Complete System Reset

**Use only if all else fails**:
```bash
# WARNING: Deletes all data
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
sleep 30
docker-compose exec backend alembic upgrade head
bash scripts/seed-database.sh
./scripts/validate-auth-system.sh
```

---

## Known Working Versions

### Docker Images
- PostgreSQL: `postgres:15-alpine`
- Redis: `redis:7-alpine`
- Node.js: `20-alpine` (for frontend build)
- Python: `3.11-slim` (for backend)

### Package Versions
- Next.js: 13+ (App Router)
- FastAPI: Latest
- SQLAlchemy: Latest
- Uvicorn: Latest

### Docker Compose
- Version: 3.8
- Compose file: `docker-compose.dev.yml`

---

## Testing Checklist

Before considering the system "working", verify:

- [ ] POST /api/auth/email-login returns 200 with token
- [ ] GET /api/brands/ returns 200 with at least 9 brands
- [ ] GET /api/brands/current returns 200 with current brand
- [ ] User has 3 tenant associations in database
- [ ] User has 9 brand memberships in database
- [ ] Frontend environment: NEXT_PUBLIC_API_URL=/api
- [ ] Frontend environment: BACKEND_URL=http://backend:8000
- [ ] All Docker containers healthy
- [ ] No CORS errors in browser console
- [ ] No ERR_NAME_NOT_RESOLVED errors in browser console
- [ ] Backend logs show no SQL errors

---

## Maintenance

**Daily**:
- Run `./scripts/validate-auth-system.sh`
- Check Docker container health: `docker-compose ps`

**Weekly**:
- Review backend logs: `docker-compose logs backend --tail=100`
- Check database size: `docker-compose exec postgres du -sh /var/lib/postgresql/data`

**Monthly**:
- Update dependencies
- Run full test suite
- Backup database

---

**Document Created**: 2025-11-03
**Last Verified**: 2025-11-03
**Next Verification**: 2025-11-04
**Maintained By**: Claude Code
