# Tenant Monitoring Quick Reference

## Quick Test Commands

### Backend Health Check
```bash
# Basic test (no auth)
curl http://localhost:8000/api/health/tenant-monitoring

# With authentication
curl http://localhost:8000/api/health/tenant-monitoring \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "X-Tenant-ID: tenant-123"
```

### Watch Backend Logs
```bash
# All tenant monitoring
tail -f logs/app.log | grep "\[TENANT-"

# Only errors/warnings
tail -f logs/app.log | grep -E "\[TENANT-(ERROR|MISSING|MISMATCH)\]"

# Only performance
tail -f logs/app.log | grep "\[TENANT-PERFORMANCE\]"
```

### Frontend Console Filters
In Chrome DevTools Console:
- Filter: `TENANT-MONITORING`
- Show only warnings: Click "Warnings" level

## Log Patterns to Look For

### ✅ Good Logs (Everything Working)

**Backend:**
```
[TENANT-MONITORING] Tenant ID present: tenant-123 | Endpoint: GET /api/audit/logs
[AUDIT-TENANT] Tenant ID extracted from X-Tenant-ID header: tenant-123
[AUDIT-SEARCH] Executing audit log search | Tenant: tenant-123
[TENANT-PERFORMANCE] Tenant: tenant-123 | Status: 200 | Duration: 0.123s
```

**Frontend Console:**
```javascript
[TENANT-MONITORING] Extracted tenant_id from JWT: tenant-123
[TENANT-MONITORING] X-Tenant-ID header set: tenant-123
[TENANT-MONITORING] ✅ Multi-tenant endpoint with X-Tenant-ID: tenant-123
```

### ⚠️ Warning Logs (Need Attention)

**Backend:**
```
[TENANT-MISSING] X-Tenant-ID header missing on protected endpoint
[AUDIT-TENANT] No tenant_id found in request
```

**Frontend Console:**
```javascript
[TENANT-MONITORING] JWT token does not contain tenant_id field
[TENANT-MONITORING] X-Tenant-ID header NOT set - tenant_id not found in JWT token
[TENANT-MONITORING] ⚠️ Multi-tenant endpoint WITHOUT X-Tenant-ID header
```

### 🚨 Error Logs (Action Required)

**Backend:**
```
[TENANT-MISMATCH] Header tenant_id 'abc' does not match token tenant_id '123'
[AUDIT-ERROR] Tenant ID missing for audit log search
```

## Common Issues & Fixes

### Issue: JWT doesn't contain tenant_id
```bash
# Fix: Update token generation to include tenant_id
# Check: /api/health/tenant-monitoring → jwt_info.has_tenant_id should be true
```

### Issue: X-Tenant-ID header not sent
```javascript
// Fix: Ensure API client getTenantIdFromToken() is called
// Check: Browser Network tab → Request Headers → X-Tenant-ID
```

### Issue: Tenant mismatch
```bash
# Fix: Refresh JWT token or clear session
# Check: Compare X-Tenant-ID header with token payload
```

## Using Monitoring Utilities in Code

### Backend (Python)

```python
from app.utils.tenant_monitoring import require_tenant_id, log_tenant_operation

@router.get("/my-endpoint")
async def my_endpoint(request: Request):
    # Require tenant_id (raises exception if missing)
    tenant_id = require_tenant_id(request, "MY_OPERATION")

    # Log tenant operation
    log_tenant_operation(
        "CUSTOM_OPERATION",
        tenant_id,
        user_id="user-123",
        details={"action": "something"}
    )
```

### Frontend (TypeScript)

The API client automatically handles tenant_id extraction and logging.
Just check console for warnings:

```typescript
// Monitoring is automatic, but you can check:
// 1. Console for [TENANT-MONITORING] logs
// 2. Network tab for X-Tenant-ID header
```

## Health Check Response Quick Decode

```json
{
  "status": "healthy | degraded | unhealthy",
  "test_results": {
    "jwt_contains_tenant_id": true/false,        // JWT has tenant_id field
    "x_tenant_id_header_sent": true/false,       // Header present
    "multi_tenant_operations_ready": true/false, // Overall status
    "middleware_functioning": true/false         // Middleware active
  },
  "issues": [],      // Empty = good, populated = problems
  "warnings": [],    // Empty = good, populated = needs attention
  "recommendations": [] // Follow these to fix issues
}
```

## Files Reference

### Backend
- **Middleware**: `/production-backend/app/middleware/tenant_monitoring.py`
- **Utils**: `/production-backend/app/utils/tenant_monitoring.py`
- **Health Endpoint**: `/production-backend/app/routers/health.py` (line 830)
- **Audit Router**: `/production-backend/app/routers/audit.py` (lines 99-201)

### Frontend
- **API Client**: `/production-frontend/lib/api/client.ts` (lines 314-425)

## Quick Verification Checklist

- [ ] Start backend server
- [ ] Check for "✅ Tenant monitoring middleware loaded" in logs
- [ ] Login to frontend
- [ ] Open browser DevTools Console
- [ ] Look for `[TENANT-MONITORING]` logs
- [ ] Make request to `/api/audit/logs`
- [ ] Check Network tab for `X-Tenant-ID` header
- [ ] Check backend logs for `[TENANT-MONITORING]` entries
- [ ] Visit `/api/health/tenant-monitoring` endpoint
- [ ] Verify `status: "healthy"`

## Support

Full documentation: `/TENANT_MONITORING_GUIDE.md`
