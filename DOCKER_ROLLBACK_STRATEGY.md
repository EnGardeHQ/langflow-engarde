# Docker Build Rollback Strategy - EnGarde Authentication Issue

**Date:** 2025-10-29
**Issue:** Authentication broken - frontend can log in but subsequent API requests fail with 401 errors
**Current Build:** engarde-backend:dev (cd5a40c6bd03) and engarde-frontend:dev (61ece084bc41)
**Created:** 2025-10-29 14:06:39 EDT (backend) and 14:04:01 EDT (frontend)

---

## Executive Summary

**Git Status:** No git repository exists in `/Users/cope/EnGardeHQ` - manual version control required

**Available Rollback Options:**
1. **Docker Image Rollback** - Roll back to older Docker images from 6 weeks ago
2. **File-Level Rollback** - Revert recent authentication changes from today (Oct 29, 00:44 AM)
3. **Hybrid Approach** - Use stable backend image + revert frontend auth changes

**Recommendation:** Option 3 (Hybrid Approach) - Most reliable and fastest recovery

---

## Problem Analysis

### Timeline of Changes

**Most Recent Changes (Oct 29, 2025 12:44-12:45 AM):**
- Modified: `/Users/cope/EnGardeHQ/production-frontend/contexts/AuthContext.tsx`
- Modified: `/Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts`
- Changes documented in: `401_AUTHENTICATION_FIX.md`

**What Changed:**
1. Removed `engarde_login_success` flag logic from API client
2. Removed 10-second grace period for 401 error handling
3. Simplified authentication flow in AuthContext
4. Made 401 errors immediately clear tokens and redirect

**Why It's Broken:**
The authentication fix removed safety mechanisms that may have been compensating for timing issues. The changes were well-intentioned (documented in `401_AUTHENTICATION_FIX.md`) but appear to have introduced a regression where:
- Login succeeds and tokens are stored
- Subsequent API requests fail with 401
- Frontend doesn't properly handle the authentication state

### Docker Image History

**Current Development Images (Created today):**
```
engarde-backend:dev          cd5a40c6bd03    2025-10-29 14:06:39 EDT    3.68GB
engarde-frontend:dev         61ece084bc41    2025-10-29 14:04:01 EDT    2.22GB
```

**Previous Stable Images:**
```
engardehq-frontend:latest    d39777ee41ce    2025-10-29 12:31:38 EDT    (6 hours ago)
engardehq-backend:latest     1d3e67ff3743    2025-10-10 18:11:52 EDT    (19 days ago)
engarde-backend-dev:latest   6badd16aa63d    2025-09-15 20:44:11 EDT    (6 weeks ago)
engarde-frontend-dev:latest  a6ce60ce652d    2025-09-15 20:43:40 EDT    (6 weeks ago)
```

---

## Rollback Options

### Option 1: Docker Image Rollback (Low Confidence)

**Roll back to 6-week-old images:**

```bash
# Stop current containers
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml down

# Tag old images as current dev images
docker tag engarde-backend-dev:latest engarde-backend:dev-backup-20251029
docker tag engarde-frontend-dev:latest engarde-frontend:dev-backup-20251029
docker tag engarde-backend-dev:latest engarde-backend:dev
docker tag engarde-frontend-dev:latest engarde-frontend:dev

# Restart with old images
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml up -d
```

**Pros:**
- Complete rollback of both frontend and backend
- No code changes needed

**Cons:**
- Images are 6 weeks old - may be missing recent features
- Loses all changes made in the last 6 weeks
- Database schema may be incompatible

**Confidence Level:** 🟡 LOW - Too much lost functionality

---

### Option 2: File-Level Rollback of Auth Changes (Medium Confidence)

**Revert authentication changes from today:**

The authentication fix made specific changes documented in `401_AUTHENTICATION_FIX.md`. We need to restore the previous behavior.

**Key Changes to Revert:**

#### 2.1: Restore Login Success Flag in API Client

**File:** `/Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts`

**Current Code (lines ~396-406):**
```typescript
// Handle authentication errors
if (response.status === 401) {
  console.log('🔒 API CLIENT: 401 Unauthorized error received');

  this.clearTokens();
  // Clear user data from localStorage as well
  if (typeof window !== 'undefined') {
    localStorage.removeItem('engarde_user');
    // Clear any stale login flags
    sessionStorage.removeItem('engarde_login_success');

    // Only redirect if we're not already on the login page
    if (window.location.pathname !== '/login') {
      console.log('🔄 API CLIENT: 401 error, redirecting to login');
      window.location.href = '/login';
    }
  }
}
```

**Restore Previous Logic:**
```typescript
// Handle authentication errors
if (response.status === 401) {
  console.log('🔒 API CLIENT: 401 Unauthorized error received');

  // Check if we just completed a login (within last 10 seconds)
  const loginSuccess = typeof window !== 'undefined' &&
    sessionStorage.getItem('engarde_login_success') === 'true';

  if (loginSuccess) {
    console.warn('⚠️ API CLIENT: Got 401 right after login, ignoring redirect to prevent loop');
    // Don't clear tokens or redirect - the login just succeeded
    return error;
  }

  this.clearTokens();
  // Clear user data from localStorage as well
  if (typeof window !== 'undefined') {
    localStorage.removeItem('engarde_user');

    // Only redirect if we're not already on the login page
    if (window.location.pathname !== '/login') {
      console.log('🔄 API CLIENT: 401 error, redirecting to login');
      window.location.href = '/login';
    }
  }
}
```

#### 2.2: Restore Login Success Flag in AuthContext

**File:** `/Users/cope/EnGardeHQ/production-frontend/contexts/AuthContext.tsx`

**Find the login success section and restore:**
```typescript
// After successful login, set flag to prevent auth loop
sessionStorage.setItem('engarde_login_success', 'true');

// Clear the flag after 10 seconds
setTimeout(() => {
  sessionStorage.removeItem('engarde_login_success');
  console.log('🧹 AUTH CONTEXT: Cleared login success flag');
}, 10000);
```

**Commands:**
```bash
# Create backup of current broken files
cp /Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts \
   /Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts.broken-20251029

cp /Users/cope/EnGardeHQ/production-frontend/contexts/AuthContext.tsx \
   /Users/cope/EnGardeHQ/production-frontend/contexts/AuthContext.tsx.broken-20251029

# Manual edit required - see above code blocks
# Then rebuild frontend container
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml build frontend
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml up -d frontend
```

**Pros:**
- Surgical fix - only changes what broke
- Keeps all other recent improvements
- Backend remains untouched
- Fast to implement

**Cons:**
- Manual code editing required
- No git history to reference exact previous state
- May need to find exact previous code logic

**Confidence Level:** 🟢 MEDIUM-HIGH - Targeted fix of known issue

---

### Option 3: Hybrid Approach (RECOMMENDED)

**Use stable backend image + revert frontend auth changes:**

This combines the best of both approaches:
1. Use the stable backend image from Oct 10 (engardehq-backend:latest)
2. Revert frontend authentication changes (Option 2)
3. Keep frontend container for other non-auth features

**Implementation:**

```bash
# 1. Backup current state
docker tag engarde-backend:dev engarde-backend:dev-broken-20251029
docker tag engarde-frontend:dev engarde-frontend:dev-broken-20251029

# 2. Use stable backend image
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml down
docker tag engardehq-backend:latest engarde-backend:dev

# 3. Revert frontend auth changes (see Option 2 code changes above)
# Manual edit of:
#   - /Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts
#   - /Users/cope/EnGardeHQ/production-frontend/contexts/AuthContext.tsx

# 4. Rebuild only frontend
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml build frontend

# 5. Restart all services
docker compose -f /Users/cope/EnGardeHQ/docker-compose.dev.yml up -d

# 6. Verify authentication
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'
```

**Pros:**
- Most reliable - uses proven stable backend
- Targeted frontend fix
- Minimal disruption
- Can verify backend separately from frontend

**Cons:**
- Backend loses changes from last 19 days
- Manual code editing required

**Confidence Level:** 🟢 HIGH - Best balance of stability and recency

---

## Recommended Recovery Plan

### Phase 1: Immediate Rollback (15-30 minutes)

1. **Backup current state:**
```bash
cd /Users/cope/EnGardeHQ

# Tag current broken images
docker tag engarde-backend:dev engarde-backend:dev-broken-20251029
docker tag engarde-frontend:dev engarde-frontend:dev-broken-20251029

# Backup broken auth files
cp production-frontend/lib/api/client.ts \
   production-frontend/lib/api/client.ts.broken-20251029
cp production-frontend/contexts/AuthContext.tsx \
   production-frontend/contexts/AuthContext.tsx.broken-20251029
```

2. **Roll back backend to stable image:**
```bash
docker compose -f docker-compose.dev.yml stop backend
docker tag engardehq-backend:latest engarde-backend:dev
docker compose -f docker-compose.dev.yml up -d backend
```

3. **Revert frontend authentication code:**
   - Restore login success flag logic in `client.ts` (see Option 2.1 above)
   - Restore login success flag in `AuthContext.tsx` (see Option 2.2 above)

4. **Rebuild and restart frontend:**
```bash
docker compose -f docker-compose.dev.yml build frontend
docker compose -f docker-compose.dev.yml up -d frontend
```

### Phase 2: Verification (10-15 minutes)

1. **Test backend authentication:**
```bash
# Test login endpoint
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Store token from response
TOKEN="<access_token_from_response>"

# Test authenticated endpoint
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/brands/current
```

2. **Test frontend authentication:**
   - Open http://localhost:3000
   - Clear browser storage (console: `localStorage.clear(); sessionStorage.clear();`)
   - Login with test credentials
   - Verify dashboard loads without 401 errors
   - Check browser Network tab for API requests

3. **Monitor logs:**
```bash
# Watch backend logs
docker logs -f engarde_backend_dev --tail=100

# Watch frontend logs
docker logs -f engarde_frontend_dev --tail=100
```

### Phase 3: Root Cause Investigation (1-2 hours)

After restoring functionality, investigate why the authentication fix failed:

1. **Compare working vs broken code:**
```bash
# If restoration worked, compare files
diff production-frontend/lib/api/client.ts \
     production-frontend/lib/api/client.ts.broken-20251029

diff production-frontend/contexts/AuthContext.tsx \
     production-frontend/contexts/AuthContext.tsx.broken-20251029
```

2. **Review authentication flow:**
   - Check if token storage timing changed
   - Verify JWT token expiration settings
   - Review backend authentication middleware
   - Check CORS configuration

3. **Document findings:**
   - Update `401_AUTHENTICATION_FIX.md` with lessons learned
   - Create rollback documentation
   - Update testing procedures

---

## Prevention Strategies

### 1. Implement Git Version Control

**Critical: No git repository exists!**

```bash
cd /Users/cope/EnGardeHQ

# Initialize git repository
git init

# Create .gitignore
cat > .gitignore << 'EOF'
node_modules/
.next/
.env
.env.local
*.log
.DS_Store
__pycache__/
*.pyc
.pytest_cache/
dist/
build/
*.egg-info/
.venv/
venv/
postgres_data/
redis_data/
uploads/
logs/
EOF

# Initial commit
git add .
git commit -m "Initial commit - current working state"

# Create rollback tag
git tag -a working-pre-auth-fix -m "Working state before authentication changes"
```

### 2. Docker Image Tagging Strategy

**Implement semantic versioning for images:**

```bash
# Tag images with version and date
docker tag engarde-backend:dev engarde-backend:v1.0.0-20251029
docker tag engarde-frontend:dev engarde-frontend:v1.0.0-20251029

# Keep last 5 tagged versions
# Delete older untagged images regularly
docker image prune -a --filter "until=168h" --filter "dangling=true"
```

### 3. Automated Backup Script

**Create backup script:**

```bash
cat > /Users/cope/EnGardeHQ/scripts/backup-docker-images.sh << 'EOF'
#!/bin/bash
# Docker Image Backup Script

BACKUP_DIR="/Users/cope/EnGardeHQ/docker-backups"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "Backing up Docker images..."

# Save backend image
docker save engarde-backend:dev | gzip > "$BACKUP_DIR/backend-dev-$DATE.tar.gz"

# Save frontend image
docker save engarde-frontend:dev | gzip > "$BACKUP_DIR/frontend-dev-$DATE.tar.gz"

# Keep only last 5 backups
ls -t "$BACKUP_DIR"/backend-dev-*.tar.gz | tail -n +6 | xargs -r rm
ls -t "$BACKUP_DIR"/frontend-dev-*.tar.gz | tail -n +6 | xargs -r rm

echo "Backup complete: $BACKUP_DIR"
EOF

chmod +x /Users/cope/EnGardeHQ/scripts/backup-docker-images.sh
```

### 4. Pre-Deployment Testing Checklist

**Create testing checklist before each build:**

```markdown
## Pre-Deployment Testing Checklist

- [ ] Backend health check: `curl http://localhost:8000/health`
- [ ] Frontend health check: `curl http://localhost:3000/`
- [ ] Login functionality: Manual test with test credentials
- [ ] API authentication: Test with curl + JWT token
- [ ] Token persistence: Refresh page after login
- [ ] Logout functionality: Verify tokens cleared
- [ ] 401 error handling: Test with expired/invalid token
- [ ] Brand API endpoints: Test `/api/brands/current`
- [ ] Database connectivity: Check logs for connection errors
- [ ] Redis connectivity: Check cache operations
```

### 5. Staged Rollout Process

**For future authentication changes:**

1. **Feature flag approach** (already partially implemented):
   - Use `NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX` flag
   - Enable for 10% of users initially
   - Monitor error rates and metrics
   - Gradually increase rollout percentage

2. **Blue-Green Deployment:**
   - Run old and new versions simultaneously
   - Switch traffic gradually
   - Quick rollback if issues detected

3. **Canary Testing:**
   - Deploy to single test environment first
   - Run automated integration tests
   - Deploy to production only after passing

---

## Emergency Rollback Commands (Quick Reference)

### Full Rollback to 6-Week-Old Images
```bash
cd /Users/cope/EnGardeHQ
docker compose -f docker-compose.dev.yml down
docker tag engarde-backend-dev:latest engarde-backend:dev
docker tag engarde-frontend-dev:latest engarde-frontend:dev
docker compose -f docker-compose.dev.yml up -d
```

### Backend Only Rollback
```bash
cd /Users/cope/EnGardeHQ
docker compose -f docker-compose.dev.yml stop backend
docker tag engardehq-backend:latest engarde-backend:dev
docker compose -f docker-compose.dev.yml up -d backend
```

### Frontend Only Rebuild
```bash
cd /Users/cope/EnGardeHQ
docker compose -f docker-compose.dev.yml build frontend
docker compose -f docker-compose.dev.yml up -d frontend
```

### Restore from Backup Image
```bash
# Load from backup file
docker load -i /Users/cope/EnGardeHQ/docker-backups/backend-dev-YYYYMMDD-HHMMSS.tar.gz
docker load -i /Users/cope/EnGardeHQ/docker-backups/frontend-dev-YYYYMMDD-HHMMSS.tar.gz

# Restart containers
cd /Users/cope/EnGardeHQ
docker compose -f docker-compose.dev.yml down
docker compose -f docker-compose.dev.yml up -d
```

---

## Next Steps

1. **Execute Recommended Recovery Plan (Option 3)**
2. **Verify authentication works end-to-end**
3. **Initialize git repository immediately**
4. **Implement Docker image tagging strategy**
5. **Document root cause analysis**
6. **Update deployment procedures**
7. **Create automated backup script**

---

## Files Reference

**Key Configuration Files:**
- `/Users/cope/EnGardeHQ/docker-compose.dev.yml` - Development environment
- `/Users/cope/EnGardeHQ/docker-compose.yml` - Production environment
- `/Users/cope/EnGardeHQ/production-frontend/Dockerfile` - Frontend build
- `/Users/cope/EnGardeHQ/production-backend/Dockerfile` - Backend build

**Authentication Files:**
- `/Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts`
- `/Users/cope/EnGardeHQ/production-frontend/contexts/AuthContext.tsx`
- `/Users/cope/EnGardeHQ/production-frontend/components/auth/ProtectedRoute.tsx`

**Documentation:**
- `/Users/cope/EnGardeHQ/401_AUTHENTICATION_FIX.md` - Recent fix documentation
- `/Users/cope/EnGardeHQ/AUTH_ISSUE_SUMMARY.md` - Previous auth issue summary
- `/Users/cope/EnGardeHQ/AUTH_FLOW_ANALYSIS.md` - Authentication flow analysis

---

**Created:** 2025-10-29
**Author:** DevOps Orchestrator (Claude)
**Status:** Ready for Implementation
**Priority:** 🔴 CRITICAL
