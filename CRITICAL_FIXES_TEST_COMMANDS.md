# Critical Backend Fixes - Test Commands

## Summary of Fixes

### Issue 1: Login 504 Timeout (FIXED)
**Root Cause**: Missing indexes on `tenant_users` table causing slow JOIN queries during login
**Fix Applied**:
- Added indexes to `tenant_users.user_id` and `tenant_users.tenant_id`
- Added compound index `idx_tenant_user_lookup` on `(user_id, tenant_id)`
- Optimized `get_user()` function to use `joinedload` instead of `selectinload`
- Files modified:
  - `/Users/cope/EnGardeHQ/production-backend/app/models.py` (lines 44-60)
  - `/Users/cope/EnGardeHQ/production-backend/app/routers/auth.py` (lines 67-87)
  - Created migration: `/Users/cope/EnGardeHQ/production-backend/migrations/add_tenant_user_indexes.sql`

### Issue 2: Health API Not Working (FIXED)
**Root Cause**: Frontend calling `/api/health` expecting detailed response
**Fix Applied**:
- Made `/api/health/` return detailed health check by default
- Moved simple health check to `/api/health/basic`
- File modified: `/Users/cope/EnGardeHQ/production-backend/app/routers/health.py` (lines 400-433)

### Issue 3: Audit API Tenant ID Extraction (FIXED)
**Root Cause**: Missing fallback to extract tenant_id from JWT token
**Fix Applied**:
- Added JWT token parsing to extract tenant_id when X-Tenant-ID header is missing
- Enhanced logging for tenant ID extraction diagnostics
- File modified: `/Users/cope/EnGardeHQ/production-backend/app/routers/audit.py` (lines 99-150)

### Issue 4: Attribution API Authentication (FIXED)
**Root Cause**: Type mismatch - `get_current_user` returns `User` model, not `schemas.UserResponse`
**Fix Applied**:
- Created `get_user_context()` helper to convert User model to dict
- Updated all attribution endpoints to use new helper
- File modified: `/Users/cope/EnGardeHQ/production-backend/app/routers/attribution.py` (lines 20-37, all endpoints)

---

## CRITICAL: Apply Database Migration First

Before testing, apply the database migration to add indexes:

```bash
# Connect to your database and run:
psql $DATABASE_URL -f /Users/cope/EnGardeHQ/production-backend/migrations/add_tenant_user_indexes.sql

# Or if using docker:
docker exec -i <postgres_container> psql -U <username> -d <database> < /Users/cope/EnGardeHQ/production-backend/migrations/add_tenant_user_indexes.sql
```

**IMPORTANT**: After applying the migration, restart your backend server for changes to take effect.

---

## Test Commands

### Prerequisites

First, obtain an access token by logging in:

```bash
# Login and capture the token
TOKEN=$(curl -s -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=YOUR_EMAIL@example.com&password=YOUR_PASSWORD" \
  | jq -r '.access_token')

# Verify token was captured
echo "Token: $TOKEN"

# Extract tenant_id from token (if it exists)
TENANT_ID=$(echo $TOKEN | cut -d'.' -f2 | base64 -d 2>/dev/null | jq -r '.tenant_id // empty')
echo "Tenant ID: $TENANT_ID"
```

---

### Test 1: Login Endpoint (Should complete in <1 second now)

```bash
# Test login performance
echo "Testing login performance..."
time curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=YOUR_EMAIL@example.com&password=YOUR_PASSWORD" \
  -w "\nHTTP Status: %{http_code}\nTime Total: %{time_total}s\n"

# Expected:
# - HTTP 200 OK
# - Time total < 1 second (was 51 seconds before)
# - Response includes access_token, refresh_token, and user data
```

---

### Test 2: Health API Endpoint

```bash
# Test basic health endpoint
curl -X GET "http://localhost:8000/api/health/basic" \
  -H "Accept: application/json" | jq '.'

# Expected:
# {
#   "status": "healthy",
#   "timestamp": "...",
#   "version": "1.0.0",
#   "uptime_seconds": ...
# }

# Test detailed health endpoint (main endpoint)
curl -X GET "http://localhost:8000/api/health/" \
  -H "Accept: application/json" | jq '.status, .components[] | {name, status}'

# Expected:
# - Overall status: "healthy", "degraded", or "unhealthy"
# - Components array with database, redis, ai_services, external_integrations
# - Each component has: name, status, response_time_ms, message
```

---

### Test 3: Audit API Endpoint

```bash
# Test audit logs endpoint with X-Tenant-ID header
curl -X GET "http://localhost:8000/api/audit/logs?page=1&page_size=10" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant-ID: $TENANT_ID" \
  -H "Accept: application/json" | jq '.total, .results[] | .event_type'

# Expected:
# - HTTP 200 OK
# - Response includes: results[], total, page, page_size
# - Results contain audit log entries

# Test WITHOUT X-Tenant-ID header (should extract from JWT)
curl -X GET "http://localhost:8000/api/audit/logs?page=1&page_size=10" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" | jq '.total, .results[] | .event_type'

# Expected:
# - HTTP 200 OK (tenant_id extracted from JWT token)
# - Same response format as above
# - Check server logs for: "[AUDIT-TENANT] Tenant ID extracted from JWT token"
```

---

### Test 4: Attribution API Endpoint

```bash
# Test attribution overview
curl -X GET "http://localhost:8000/api/attribution/overview" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" | jq '.'

# Expected:
# {
#   "total_conversions": 1850,
#   "attribution_revenue": 48630.25,
#   "avg_touchpoints": 4.2,
#   "avg_journey_length_days": 7.5,
#   ...
# }

# Test attribution models
curl -X GET "http://localhost:8000/api/attribution/models/linear" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" | jq '.model, .conversions, .revenue'

# Expected:
# {
#   "model": "linear",
#   "conversions": 1850,
#   "revenue": 48630.25,
#   ...
# }

# Test customer journeys
curl -X GET "http://localhost:8000/api/attribution/journeys?page=1&page_size=5" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" | jq '.total, .page, .data | length'

# Expected:
# - total: 150
# - page: 1
# - data array with 5 journey objects
```

---

## Performance Benchmarks

### Login Endpoint Performance

```bash
# Run multiple login tests to verify consistent performance
for i in {1..5}; do
  echo "Test $i:"
  time curl -s -X POST "http://localhost:8000/api/auth/login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=YOUR_EMAIL@example.com&password=YOUR_PASSWORD" \
    -o /dev/null -w "HTTP: %{http_code}, Time: %{time_total}s\n"
  sleep 1
done

# Expected: All requests complete in < 1 second
# Before fix: ~51 seconds
# After fix: < 1 second
```

---

## Troubleshooting

### If Login Still Slow

1. **Verify indexes were created**:
   ```sql
   SELECT indexname, tablename
   FROM pg_indexes
   WHERE tablename = 'tenant_users';
   ```
   You should see: `idx_tenant_users_tenant_id`, `idx_tenant_users_user_id`, `idx_tenant_user_lookup`

2. **Check query performance**:
   ```sql
   EXPLAIN ANALYZE
   SELECT * FROM users
   LEFT JOIN tenant_users ON users.id = tenant_users.user_id
   WHERE users.email = 'YOUR_EMAIL@example.com';
   ```
   Look for "Index Scan" instead of "Seq Scan"

3. **Restart backend server** to ensure code changes are loaded

### If Health API Returns 503

- Check if database is running: `psql $DATABASE_URL -c "SELECT 1"`
- Check Redis (if configured): `redis-cli ping`
- Review health check logs in server output

### If Audit API Returns 400 "Tenant ID Required"

1. **Verify JWT contains tenant_id**:
   ```bash
   echo $TOKEN | cut -d'.' -f2 | base64 -d 2>/dev/null | jq '.tenant_id'
   ```

2. **Check server logs** for tenant extraction:
   ```
   [AUDIT-TENANT] Tenant ID extracted from JWT token: <tenant_id>
   ```

3. **Try with explicit X-Tenant-ID header** if JWT doesn't contain it

### If Attribution API Returns 500

- Check server logs for authentication errors
- Verify token is valid: `curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/me`
- Ensure user has associated tenant in database

---

## Expected Results Summary

| Endpoint | Before Fix | After Fix | Test Command |
|----------|-----------|-----------|--------------|
| `/api/auth/login` | 504 timeout (51s) | 200 OK (<1s) | Test 1 |
| `/api/health` | 404 or incorrect data | 200 OK with detailed health | Test 2 |
| `/api/audit/logs` | 400 "Tenant ID required" | 200 OK with audit logs | Test 3 |
| `/api/attribution/overview` | 500 or type error | 200 OK with attribution data | Test 4 |

---

## Additional Verification

### Check Server Logs

After running tests, check server logs for:

```bash
# Look for successful operations
grep "Login successful" <server_log_file>
grep "Tenant ID extracted" <server_log_file>
grep "Attribution.*requested by user" <server_log_file>

# Look for performance improvements
grep "Request completed.*api/auth/login" <server_log_file>
# Should show Time: < 1.0s (was > 50s before)
```

### Database Query Analysis

```sql
-- Check index usage statistics
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE tablename = 'tenant_users'
ORDER BY idx_scan DESC;

-- After running login tests, idx_scan should increase for new indexes
```

---

## Files Modified

1. `/Users/cope/EnGardeHQ/production-backend/app/models.py`
   - Added indexes to TenantUser model (lines 47-56)

2. `/Users/cope/EnGardeHQ/production-backend/app/routers/auth.py`
   - Optimized get_user() function (lines 67-87)

3. `/Users/cope/EnGardeHQ/production-backend/app/routers/health.py`
   - Updated root endpoint to return detailed health (lines 400-433)

4. `/Users/cope/EnGardeHQ/production-backend/app/routers/audit.py`
   - Added JWT tenant_id extraction (lines 99-150)

5. `/Users/cope/EnGardeHQ/production-backend/app/routers/attribution.py`
   - Added get_user_context() helper (lines 20-37)
   - Updated all endpoints to use helper

6. `/Users/cope/EnGardeHQ/production-backend/migrations/add_tenant_user_indexes.sql`
   - Created migration script for database indexes

---

## Next Steps

1. **Apply database migration** (CRITICAL - must be done first)
2. **Restart backend server**
3. **Run all test commands above**
4. **Monitor server logs** for performance improvements
5. **Verify frontend pages now load correctly**:
   - Login page should complete in < 1 second
   - System Health page should display health data
   - Audit Logs page should load audit entries
   - Attribution page should display analytics

---

## Contact

If issues persist after applying fixes, check:
- Database migration was applied successfully
- Backend server was restarted
- Environment variables are configured correctly
- JWT tokens contain tenant_id field
