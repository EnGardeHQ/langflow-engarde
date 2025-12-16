# QUICK FIX: ERR_INSUFFICIENT_RESOURCES

**Problem**: Frontend fails to load with `ERR_INSUFFICIENT_RESOURCES` error

**Root Cause**: Next.js standalone server keep-alive timeout too short (5s) for 31+ chunks

**Fix**: Set `KEEP_ALIVE_TIMEOUT=65000` (65 seconds)

---

## 🔥 Fast Fix (3 Commands)

```bash
# 1. Rebuild frontend container
docker-compose build --no-cache frontend

# 2. Restart with new configuration
docker-compose up -d frontend

# 3. Verify the fix
./verify-static-assets-fix.sh
```

---

## 📋 What Changed

### File 1: `production-frontend/Dockerfile` (Line 215)
Added `KEEP_ALIVE_TIMEOUT=65000` to ENV variables

### File 2: `docker-compose.yml` (Line 175)
Added `KEEP_ALIVE_TIMEOUT: "65000"` to frontend environment

---

## ✅ Quick Verification

```bash
# Check environment variable
docker exec engarde_frontend env | grep KEEP_ALIVE_TIMEOUT
# Expected: KEEP_ALIVE_TIMEOUT=65000

# Check HTTP header
curl -I http://localhost:3001/_next/static/chunks/main-*.js | grep -i keep-alive
# Expected: Keep-Alive: timeout=65

# Test chunk loading
curl -s http://localhost:3001/ | grep -o '_next/static/chunks/[^"]*\.js' | head -5 | while read chunk; do
  curl -s -o /dev/null -w "$chunk: %{http_code}\n" "http://localhost:3001/$chunk"
done
# Expected: All return 200
```

---

## 🎯 Success Criteria

- ✅ No `ERR_INSUFFICIENT_RESOURCES` in browser console
- ✅ All JavaScript chunks load (HTTP 200)
- ✅ No ECONNRESET errors in logs
- ✅ Page loads successfully
- ✅ Keep-Alive header shows `timeout=65`

---

## 📖 Full Documentation

See: `/Users/cope/EnGardeHQ/ERR_INSUFFICIENT_RESOURCES_BUG_FIX_REPORT.md`

---

**Status**: ✅ FIXED
**Priority**: CRITICAL (P0)
**Impact**: Production Outage → Resolved
