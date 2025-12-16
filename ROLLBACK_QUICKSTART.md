# Docker Rollback Quick Start

**Issue:** Authentication broken after Oct 29, 2025 12:44 AM changes
**Status:** 🔴 CRITICAL
**Recovery Time:** 30-45 minutes

---

## TL;DR - Execute This Now

### Option 1: Automated Rollback Script (FASTEST)

```bash
cd /Users/cope/EnGardeHQ
./scripts/rollback-auth-fix.sh
```

Then follow prompts and manual code changes.

---

## Option 2: Manual Step-by-Step (RECOMMENDED)

### Step 1: Backup Current State (2 minutes)

```bash
cd /Users/cope/EnGardeHQ

# Tag broken images
docker tag engarde-backend:dev engarde-backend:dev-broken-20251029
docker tag engarde-frontend:dev engarde-frontend:dev-broken-20251029

# Backup broken files
mkdir -p backups/auth-broken-20251029
cp production-frontend/lib/api/client.ts backups/auth-broken-20251029/
cp production-frontend/contexts/AuthContext.tsx backups/auth-broken-20251029/
```

### Step 2: Rollback Backend (5 minutes)

```bash
# Stop and rollback backend to stable image (Oct 10, 2025)
docker compose -f docker-compose.dev.yml stop backend
docker tag engardehq-backend:latest engarde-backend:dev
docker compose -f docker-compose.dev.yml up -d backend

# Verify backend health
sleep 10
curl http://localhost:8000/health
```

### Step 3: Revert Frontend Auth Code (10-15 minutes)

**Edit File 1:** `/Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts`

Find the 401 error handler (around line 396-420) and add login success check:

```typescript
// Handle authentication errors
if (response.status === 401) {
  console.log('🔒 API CLIENT: 401 Unauthorized error received');

  // ADD THIS CHECK:
  const loginSuccess = typeof window !== 'undefined' &&
    sessionStorage.getItem('engarde_login_success') === 'true';

  if (loginSuccess) {
    console.warn('⚠️ API CLIENT: Got 401 right after login, ignoring redirect to prevent loop');
    return error;
  }
  // END OF ADDED CODE

  this.clearTokens();
  if (typeof window !== 'undefined') {
    localStorage.removeItem('engarde_user');
    if (window.location.pathname !== '/login') {
      window.location.href = '/login';
    }
  }
}
```

**Edit File 2:** `/Users/cope/EnGardeHQ/production-frontend/contexts/AuthContext.tsx`

Find the login success section (after dispatch, around line 620-650) and add:

```typescript
// After LOGIN_SUCCESS dispatch and localStorage.setItem
// ADD THIS CODE:
if (typeof window !== 'undefined') {
  sessionStorage.setItem('engarde_login_success', 'true');
  console.log('✅ AUTH CONTEXT: Set login success flag (10 second grace period)');

  setTimeout(() => {
    sessionStorage.removeItem('engarde_login_success');
    console.log('🧹 AUTH CONTEXT: Cleared login success flag');
  }, 10000);
}
// END OF ADDED CODE
```

### Step 4: Rebuild Frontend (5 minutes)

```bash
cd /Users/cope/EnGardeHQ

# Rebuild frontend with changes
docker compose -f docker-compose.dev.yml build frontend
docker compose -f docker-compose.dev.yml up -d frontend

# Watch logs
docker logs -f engarde_frontend_dev
```

### Step 5: Test Authentication (10 minutes)

```bash
# 1. Open browser to http://localhost:3000/login
# 2. Open DevTools (F12) → Console tab
# 3. Clear storage:
#    localStorage.clear(); sessionStorage.clear();
# 4. Login with test credentials
# 5. Verify you see: "✅ AUTH CONTEXT: Set login success flag"
# 6. Verify dashboard loads without 401 errors
# 7. Check Network tab - /api/brands should return 200
```

**Test with curl:**
```bash
# Get token
TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}' \
  | jq -r '.access_token')

# Test authenticated endpoint
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/brands/current
```

---

## Option 3: Full Image Rollback (LAST RESORT)

Use if code changes are too complex or risky.

```bash
cd /Users/cope/EnGardeHQ

# Roll back to 6-week-old images (Sep 15, 2025)
docker compose -f docker-compose.dev.yml down
docker tag engarde-backend-dev:latest engarde-backend:dev
docker tag engarde-frontend-dev:latest engarde-frontend:dev
docker compose -f docker-compose.dev.yml up -d

# Wait for startup
sleep 30

# Test
curl http://localhost:8000/health
curl http://localhost:3000/
```

**Warning:** This loses 6 weeks of changes. Only use if Options 1-2 fail.

---

## Verification Checklist

After rollback, verify:

- [ ] Backend health: `curl http://localhost:8000/health`
- [ ] Frontend loads: `curl http://localhost:3000/`
- [ ] Login works without redirect loop
- [ ] Dashboard loads after login
- [ ] No 401 errors in browser console
- [ ] Network tab shows 200 responses for /api/brands
- [ ] Page refresh keeps user logged in
- [ ] Logout clears tokens properly

---

## If Issues Persist

### Check Backend Logs
```bash
docker logs engarde_backend_dev --tail=100 -f
```

### Check Frontend Logs
```bash
docker logs engarde_frontend_dev --tail=100 -f
```

### Check Container Status
```bash
docker compose -f docker-compose.dev.yml ps
```

### Verify Database
```bash
docker exec -it engarde_postgres_dev psql -U engarde_user -d engarde -c "SELECT email FROM users LIMIT 5;"
```

### Full Restart
```bash
cd /Users/cope/EnGardeHQ
docker compose -f docker-compose.dev.yml down
docker compose -f docker-compose.dev.yml up -d
sleep 30
docker compose -f docker-compose.dev.yml ps
```

---

## Available Docker Images

**Current (Broken):**
- `engarde-backend:dev` (cd5a40c6bd03) - Oct 29, 2025 14:06:39
- `engarde-frontend:dev` (61ece084bc41) - Oct 29, 2025 14:04:01

**Stable Rollback Options:**
- `engardehq-backend:latest` (1d3e67ff3743) - Oct 10, 2025 (19 days old) ✅ RECOMMENDED
- `engardehq-frontend:latest` (d39777ee41ce) - Oct 29, 2025 12:31:38 (6 hours old)
- `engarde-backend-dev:latest` (6badd16aa63d) - Sep 15, 2025 (6 weeks old)
- `engarde-frontend-dev:latest` (a6ce60ce652d) - Sep 15, 2025 (6 weeks old)

---

## Key Files Changed (Oct 29, 2025 12:44-12:45 AM)

1. `/Users/cope/EnGardeHQ/production-frontend/contexts/AuthContext.tsx` (12:44 AM)
2. `/Users/cope/EnGardeHQ/production-frontend/lib/api/client.ts` (12:45 AM)

**What broke:** Removed login success flag mechanism
**Fix:** Restore the flag logic (see code changes above)

---

## Detailed Documentation

- **Full Strategy:** `/Users/cope/EnGardeHQ/DOCKER_ROLLBACK_STRATEGY.md`
- **Code Changes:** `/Users/cope/EnGardeHQ/AUTH_CODE_ROLLBACK_GUIDE.md`
- **Original Fix:** `/Users/cope/EnGardeHQ/401_AUTHENTICATION_FIX.md`
- **Auth Analysis:** `/Users/cope/EnGardeHQ/AUTH_ISSUE_SUMMARY.md`

---

## After Successful Rollback

### 1. Initialize Git Repository (CRITICAL)

```bash
cd /Users/cope/EnGardeHQ

git init
cat > .gitignore << 'EOF'
node_modules/
.next/
.env
.env.local
*.log
.DS_Store
__pycache__/
*.pyc
postgres_data/
redis_data/
uploads/
logs/
EOF

git add .
git commit -m "Working state after auth rollback"
git tag -a v1.0.0-working-auth -m "Working authentication - post rollback"
```

### 2. Create Image Backups

```bash
cd /Users/cope/EnGardeHQ

# Tag working images
docker tag engarde-backend:dev engarde-backend:v1.0.0-working
docker tag engarde-frontend:dev engarde-frontend:v1.0.0-working

# Save to files (optional but recommended)
mkdir -p docker-backups
docker save engarde-backend:dev | gzip > docker-backups/backend-working-$(date +%Y%m%d).tar.gz
docker save engarde-frontend:dev | gzip > docker-backups/frontend-working-$(date +%Y%m%d).tar.gz
```

### 3. Document Root Cause

Update `/Users/cope/EnGardeHQ/401_AUTHENTICATION_FIX.md` with:
- Why the fix failed
- What was learned
- Correct approach for future fixes

---

## Emergency Contacts

**Issue Tracker:** Check `/Users/cope/EnGardeHQ/docs/` for issue templates

**Logs Location:**
- Backend: `docker logs engarde_backend_dev`
- Frontend: `docker logs engarde_frontend_dev`
- All: `docker compose -f docker-compose.dev.yml logs`

**Config Files:**
- Docker Compose: `/Users/cope/EnGardeHQ/docker-compose.dev.yml`
- Backend Dockerfile: `/Users/cope/EnGardeHQ/production-backend/Dockerfile`
- Frontend Dockerfile: `/Users/cope/EnGardeHQ/production-frontend/Dockerfile`
- Environment: `/Users/cope/EnGardeHQ/.env`

---

**Created:** 2025-10-29
**Priority:** 🔴 CRITICAL
**Estimated Recovery Time:** 30-45 minutes
**Recommended Approach:** Option 2 (Manual Step-by-Step)
