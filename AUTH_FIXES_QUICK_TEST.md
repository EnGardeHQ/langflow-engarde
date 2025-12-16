# Quick Authentication Testing Guide

**Status**: All Fixes Verified and Ready for Testing
**Date**: October 6, 2025

---

## Quick Start Testing (5 Minutes)

### 1. Start Services
```bash
cd /Users/cope/EnGardeHQ
docker-compose down -v  # Optional: fresh start
docker-compose up -d postgres redis
sleep 15
docker-compose up -d backend
sleep 30
docker-compose up -d frontend
```

### 2. Check Seeding Logs
```bash
# Should see "🌱 Seeding demo users and brands..."
docker logs engarde_backend | grep -i seed
```

### 3. Test Login Flow
```bash
# Open browser: http://localhost:3001/login
# Login with: demo@engarde.com / demo123
# Expected: Dashboard loads with "Demo Brand" selected
# Expected: NO "Create Your First Brand" modal
```

### 4. Check Console for Hydration Errors
```bash
# Open DevTools (F12)
# Check Console tab
# Expected: ZERO React hydration errors (#418, #423, #425)
```

---

## Quick API Tests (2 Minutes)

### Test Login Endpoint
```bash
curl -X POST http://localhost:8000/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=demo123&grant_type=password" \
  | jq
```

**Expected**: 200 OK with `access_token` and `refresh_token`

### Test Brands Endpoint
```bash
TOKEN=$(curl -s -X POST http://localhost:8000/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=demo123&grant_type=password" \
  | jq -r '.access_token')

curl -X GET http://localhost:8000/api/brands/ \
  -H "Authorization: Bearer $TOKEN" | jq '.total'
```

**Expected**: `2` (demo@engarde.com has 2 brands)

### Test Refresh Endpoint
```bash
TOKEN=$(curl -s -X POST http://localhost:8000/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=demo123&grant_type=password" \
  | jq -r '.access_token')

REFRESH_TOKEN=$(curl -s -X POST http://localhost:8000/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=demo123&grant_type=password" \
  | jq -r '.refresh_token')

curl -X POST http://localhost:8000/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refresh_token\":\"$REFRESH_TOKEN\"}" | jq
```

**Expected**: 200 OK with new `access_token` and `refresh_token`

---

## What Was Fixed

### Frontend Hydration Errors (All Fixed ✅)
1. **app/layout.tsx** - Removed browser APIs from GA script
2. **app/login/page.tsx** - Moved console.log to useEffect
3. **components/brands/BrandGuard.tsx** - Uses usePathname() hook
4. **middleware.ts** - CSP allows GTM when analytics enabled

### Backend API Endpoints (All Fixed ✅)
1. **app/api/auth/login/route.ts** - Login proxy created
2. **app/api/auth/refresh/route.ts** - Refresh endpoint created (was missing!)
3. **app/routers/auth.py** - Proper refresh token implementation
4. **middleware.ts** - Rate limiting: 50/15min (was 20/15min)

### Database & Configuration (All Fixed ✅)
1. **docker-compose.yml** - CORS includes localhost:3001
2. **docker-compose.yml** - SEED_DEMO_DATA enabled
3. **app/routers/brands.py** - Uses database (not mock data!)
4. **scripts/seed_demo_users_brands.py** - demo@engarde.com gets 2 brands

---

## Success Criteria Checklist

### Hydration Errors
- [ ] No Error #418 in console
- [ ] No Error #423 in console
- [ ] No Error #425 in console
- [ ] Pages load without visual flashing

### Login Flow
- [ ] Login succeeds with demo@engarde.com
- [ ] No 429 rate limiting errors
- [ ] No 404 on /api/auth/login
- [ ] No 404 on /api/auth/refresh

### Brand Modal
- [ ] Dashboard loads after login
- [ ] "Demo Brand" is selected
- [ ] NO "Create Your First Brand" modal appears
- [ ] Brand selector shows 2 brands

### API Endpoints
- [ ] POST /token returns access_token and refresh_token
- [ ] GET /api/brands/ returns 2 brands
- [ ] POST /auth/refresh returns new tokens
- [ ] Rate limiting allows 50 requests/15min

---

## Demo Credentials

```
Email: demo@engarde.com
Password: demo123
Expected Brands: Demo Brand, Demo E-commerce

Email: test@engarde.com
Password: test123
Expected Brands: Test Brand

Email: admin@engarde.com
Password: admin123
Expected Brands: EnGarde Platform
```

---

## Troubleshooting

### If brands endpoint returns empty list
```bash
# Check seeding logs
docker logs engarde_backend | grep -i seed

# Check database directly
docker exec -it engarde_postgres psql -U engarde_user -d engarde -c \
  "SELECT u.email, b.name FROM users u
   JOIN brand_members bm ON u.id = bm.user_id
   JOIN brands b ON bm.brand_id = b.id
   WHERE u.email = 'demo@engarde.com';"

# Expected: 2 rows (Demo Brand, Demo E-commerce)
```

### If hydration errors appear
```bash
# Check these files have the fixes:
# 1. app/layout.tsx - Google Analytics script should be SSR-safe
# 2. app/login/page.tsx - console.log should be in useEffect
# 3. components/brands/BrandGuard.tsx - should use usePathname()
# 4. middleware.ts - CSP should allow GTM when NEXT_PUBLIC_ENABLE_ANALYTICS=true
```

### If login returns 429
```bash
# Rate limit is 50/15min in production
# Check if you're hitting the limit
# Wait 15 minutes or restart containers

docker-compose restart frontend backend
```

---

## Full Report

For comprehensive details, see:
`/Users/cope/EnGardeHQ/COMPREHENSIVE_AUTH_VERIFICATION_REPORT.md`

---

**Status**: ✅ ALL FIXES VERIFIED - READY FOR TESTING
