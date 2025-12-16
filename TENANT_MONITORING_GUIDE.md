# Tenant ID Monitoring and Logging Guide

## Overview

This guide explains the comprehensive monitoring and logging system implemented for tracking X-Tenant-ID headers across the EnGarde application to ensure multi-tenant operations work correctly.

## Implementation Summary

### 1. Backend Middleware Logging

**File**: `/production-backend/app/middleware/tenant_monitoring.py`

A custom FastAPI middleware that monitors all requests for X-Tenant-ID headers:

- **Logs when X-Tenant-ID is present** on protected endpoints
- **Warns when X-Tenant-ID is missing** on endpoints that require it
- **Detects mismatches** between header tenant_id and JWT token tenant_id
- **Tracks performance metrics** per tenant
- **Adds monitoring headers** to responses for debugging

#### Key Features:
- Automatically monitors endpoints matching patterns like `/api/audit`, `/api/campaigns`, `/api/analytics`
- Excludes public endpoints like `/health`, `/docs`, `/api/auth/login`
- Stores tenant information in `request.state` for downstream handlers
- Logs with standardized `[TENANT-MONITORING]` prefix for easy filtering

**Integration**: Added to `/production-backend/app/main.py` (lines 217-223)

```python
from app.middleware.tenant_monitoring import TenantMonitoringMiddleware
app.add_middleware(TenantMonitoringMiddleware)
```

### 2. Enhanced Audit Router Logging

**File**: `/production-backend/app/routers/audit.py`

Enhanced the audit endpoints with detailed tenant_id logging:

#### Changes:
- **Line 99-122**: Enhanced `get_current_tenant_from_request()` function with debug logging
  - Logs when tenant_id is extracted from request.state
  - Logs when tenant_id is extracted from X-Tenant-ID header
  - **Warns with full context** when tenant_id is missing (includes path, method, headers)

- **Lines 160-169**: Enhanced error messages in `search_audit_logs` endpoint
  - Logs error with request context (path, user, IP) when tenant_id is missing
  - Returns helpful error message: "Tenant ID is required. Please ensure X-Tenant-ID header is sent or JWT token contains tenant_id."

- **Lines 181-201**: Added execution logging for audit searches
  - Logs before search with tenant, user, filters info
  - Logs after search with result counts

### 3. Frontend Logging

**File**: `/production-frontend/lib/api/client.ts`

Enhanced the API client with comprehensive tenant monitoring:

#### Changes:
- **Lines 314-348**: Enhanced `getTenantIdFromToken()` method
  - Logs when no access token is available
  - **Warns when JWT format is invalid**
  - **Warns when JWT token doesn't contain tenant_id field** (shows available fields)
  - Logs successfully extracted tenant_id

- **Lines 371-383**: Enhanced `createHeaders()` method
  - Logs when X-Tenant-ID header is set
  - **Warns when X-Tenant-ID header is NOT set** despite authentication

- **Lines 388-425**: Enhanced `logRequest()` method
  - Adds `tenantMonitoring` section to request logs with `hasTenantHeader` and `tenantId`
  - **Highlights multi-tenant endpoints** (`/audit`, `/campaigns`, `/analytics`)
  - **Warns visibly when multi-tenant endpoint called without X-Tenant-ID header**

### 4. Monitoring Utilities Module

**File**: `/production-backend/app/utils/tenant_monitoring.py`

Comprehensive utility module with reusable monitoring functions:

#### Classes and Functions:

##### `TenantMonitor` class:
- `extract_tenant_id(request)` - Extract tenant_id from any source (header, state, JWT)
- `check_tenant_presence(request)` - Return detailed status dict with source, mismatch detection
- `log_tenant_operation()` - Standardized logging for tenant operations
- `log_missing_tenant()` - Log when tenant_id is missing with full context
- `validate_tenant_access()` - Validate user has access to requested tenant
- `get_monitoring_metadata()` - Get comprehensive monitoring data for request

##### `TenantMetrics` class:
- `track_tenant_request()` - Track tenant request for metrics (ready for Redis/Prometheus)
- `track_missing_tenant()` - Track missing tenant_id incidents
- `track_tenant_mismatch()` - Track tenant_id mismatches (security alert)

##### Convenience Functions:
- `require_tenant_id(request)` - Require tenant_id, raise exception if missing
- `log_tenant_operation()` - Quick logging helper

**Integration**: Module is registered in `/production-backend/app/utils/__init__.py` for easy imports

### 5. Health Check Endpoint

**File**: `/production-backend/app/routers/health.py`

Added new endpoint: `GET /api/health/tenant-monitoring`

This endpoint provides comprehensive diagnostics for tenant monitoring:

#### What It Tests:
1. **JWT Token Validation**
   - Checks if JWT token is present
   - Validates JWT format
   - Verifies tenant_id field exists in token
   - Extracts tenant_id value and user_id

2. **X-Tenant-ID Header**
   - Checks if X-Tenant-ID header is sent
   - Compares header value with JWT token value
   - Detects mismatches

3. **Middleware Status**
   - Verifies tenant monitoring middleware is active
   - Checks request.state for tenant information
   - Returns middleware monitoring data

4. **Overall Health Status**
   - `healthy` - All checks pass
   - `degraded` - Warnings present (e.g., no auth header on test)
   - `unhealthy` - Issues detected (missing tenant_id, mismatches, etc.)

#### Response Format:
```json
{
  "status": "healthy",
  "timestamp": "2025-11-03T12:00:00Z",
  "tenant_monitoring": {
    "enabled": true,
    "features": ["Header presence logging", "Mismatch detection", ...],
    "required_patterns": ["/api/audit", "/api/campaigns", ...],
    "excluded_patterns": ["/health", "/docs", ...]
  },
  "current_request": {
    "path": "/api/health/tenant-monitoring",
    "method": "GET",
    "tenant_status": {
      "present": true,
      "source": "header",
      "tenant_id": "tenant-123",
      "has_mismatch": false
    },
    "jwt_info": {
      "has_auth_header": true,
      "token_valid": true,
      "has_tenant_id": true,
      "tenant_id_value": "tenant-123",
      "user_id": "user-456"
    },
    "middleware_status": {
      "tenant_monitoring_active": true,
      "has_tenant_id_header": true,
      "has_tenant_id_token": true
    }
  },
  "test_results": {
    "jwt_contains_tenant_id": true,
    "x_tenant_id_header_sent": true,
    "multi_tenant_operations_ready": true,
    "middleware_functioning": true
  },
  "issues": [],
  "warnings": [],
  "recommendations": []
}
```

## How to Verify Monitoring is Working

### Backend Verification

#### 1. Check Server Logs

Start the backend server and watch for monitoring logs:

```bash
cd production-backend
uvicorn app.main:app --reload
```

Look for these log patterns:

**Middleware Loaded:**
```
✅ Tenant monitoring middleware loaded
```

**Request Monitoring (when tenant_id is present):**
```
[TENANT-MONITORING] Tenant ID present: tenant-123 | Endpoint: GET /api/audit/logs | Token Tenant: tenant-123
[TENANT-PERFORMANCE] Tenant: tenant-123 | Endpoint: GET /api/audit/logs | Status: 200 | Duration: 0.123s
```

**Missing Tenant Warning:**
```
[TENANT-MISSING] X-Tenant-ID header missing on protected endpoint | Endpoint: GET /api/audit/logs | Token Tenant: tenant-123 | Has Auth: True
```

**Mismatch Alert:**
```
[TENANT-MISMATCH] Header tenant_id 'tenant-abc' does not match token tenant_id 'tenant-123' | Endpoint: GET /api/audit/logs
```

#### 2. Test Health Check Endpoint

Call the tenant monitoring health check endpoint:

```bash
# Without authentication (will show warnings)
curl http://localhost:8000/api/health/tenant-monitoring

# With authentication (replace with real token)
curl http://localhost:8000/api/health/tenant-monitoring \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "X-Tenant-ID: tenant-123"
```

Expected response shows `status: "healthy"` when all checks pass.

#### 3. Test Audit Endpoints

Test audit endpoint to verify tenant logging:

```bash
# This should log TENANT-ERROR and return 400
curl http://localhost:8000/api/audit/logs \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# This should log TENANT-MONITORING and AUDIT-SEARCH
curl http://localhost:8000/api/audit/logs \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "X-Tenant-ID: tenant-123"
```

Watch server logs for:
- `[AUDIT-TENANT] Tenant ID extracted from X-Tenant-ID header: tenant-123`
- `[AUDIT-SEARCH] Executing audit log search | Tenant: tenant-123 | ...`

### Frontend Verification

#### 1. Open Browser DevTools

1. Open your application in a browser
2. Open DevTools (F12 or Cmd+Option+I)
3. Go to Console tab
4. Log in to the application

#### 2. Check Console Logs

Look for these console log patterns:

**JWT Token Extraction:**
```javascript
[TENANT-MONITORING] Extracted tenant_id from JWT: tenant-123
```

**Missing Tenant Warning:**
```javascript
[TENANT-MONITORING] JWT token does not contain tenant_id field
{
  availableFields: ['sub', 'exp', 'iat', 'email'],
  payload: {...}
}
```

**Header Set:**
```javascript
[TENANT-MONITORING] X-Tenant-ID header set: tenant-123
```

**Request Logging:**
```javascript
API Request: GET http://localhost:8000/api/audit/logs
{
  headers: {...},
  body: null,
  tenantMonitoring: {
    hasTenantHeader: true,
    tenantId: "tenant-123"
  }
}
```

**Multi-tenant Endpoint Detection:**
```javascript
[TENANT-MONITORING] ✅ Multi-tenant endpoint with X-Tenant-ID: tenant-123
```

**Missing Header Warning:**
```javascript
[TENANT-MONITORING] ⚠️ Multi-tenant endpoint WITHOUT X-Tenant-ID header: /api/audit/logs
```

#### 3. Check Network Tab

1. Go to Network tab in DevTools
2. Make a request to `/api/audit/logs` or similar endpoint
3. Click on the request
4. Check Headers section
5. Verify `X-Tenant-ID` header is present in Request Headers

### End-to-End Verification Script

Create a test script to verify the entire flow:

```python
# test_tenant_monitoring.py
import requests
import json

BASE_URL = "http://localhost:8000"

def test_tenant_monitoring():
    print("Testing Tenant Monitoring System\n")

    # 1. Test health check endpoint
    print("1. Testing /api/health/tenant-monitoring (no auth)...")
    response = requests.get(f"{BASE_URL}/api/health/tenant-monitoring")
    data = response.json()
    print(f"   Status: {data['status']}")
    print(f"   Warnings: {data.get('warnings', [])}\n")

    # 2. Login and get token
    print("2. Logging in to get JWT token...")
    login_response = requests.post(
        f"{BASE_URL}/api/auth/login",
        json={"email": "your-email@example.com", "password": "your-password"}
    )
    token = login_response.json()["access_token"]
    print(f"   Token obtained: {token[:20]}...\n")

    # 3. Test with authentication
    print("3. Testing /api/health/tenant-monitoring (with auth)...")
    response = requests.get(
        f"{BASE_URL}/api/health/tenant-monitoring",
        headers={"Authorization": f"Bearer {token}"}
    )
    data = response.json()
    print(f"   Status: {data['status']}")
    print(f"   JWT contains tenant_id: {data['test_results']['jwt_contains_tenant_id']}")
    print(f"   X-Tenant-ID header sent: {data['test_results']['x_tenant_id_header_sent']}")
    print(f"   Issues: {data.get('issues', [])}\n")

    # 4. Test audit endpoint without X-Tenant-ID
    print("4. Testing /api/audit/logs (no X-Tenant-ID header)...")
    response = requests.get(
        f"{BASE_URL}/api/audit/logs",
        headers={"Authorization": f"Bearer {token}"}
    )
    print(f"   Status Code: {response.status_code}")
    if response.status_code == 400:
        print(f"   Error (expected): {response.json()['detail']}\n")

    # 5. Test audit endpoint with X-Tenant-ID
    print("5. Testing /api/audit/logs (with X-Tenant-ID header)...")
    # Extract tenant_id from token
    import base64
    payload = json.loads(base64.urlsafe_b64decode(token.split('.')[1] + '=='))
    tenant_id = payload.get('tenant_id', 'unknown')

    response = requests.get(
        f"{BASE_URL}/api/audit/logs",
        headers={
            "Authorization": f"Bearer {token}",
            "X-Tenant-ID": tenant_id
        }
    )
    print(f"   Status Code: {response.status_code}")
    print(f"   Success: {response.status_code == 200}\n")

    print("✅ Tenant monitoring verification complete!")

if __name__ == "__main__":
    test_tenant_monitoring()
```

Run the script:
```bash
pip install requests
python test_tenant_monitoring.py
```

## Log Filtering Tips

### Backend Logs

Filter logs by monitoring category:

```bash
# All tenant monitoring logs
tail -f logs/app.log | grep "\[TENANT-"

# Only middleware logs
tail -f logs/app.log | grep "\[TENANT-MONITORING\]"

# Only audit logs
tail -f logs/app.log | grep "\[AUDIT-"

# Only errors and warnings
tail -f logs/app.log | grep -E "\[TENANT-(ERROR|MISSING|MISMATCH)\]"

# Performance logs
tail -f logs/app.log | grep "\[TENANT-PERFORMANCE\]"
```

### Browser Console

Filter console in DevTools:

- Type `TENANT-MONITORING` in the filter box to see only tenant-related logs
- Use `-TENANT-MONITORING` to exclude tenant logs
- Click the log levels to show only warnings/errors

## Troubleshooting

### Issue: No tenant monitoring logs in backend

**Solution:**
1. Check if middleware is loaded: `grep "Tenant monitoring middleware" logs/app.log`
2. Verify middleware file exists: `ls production-backend/app/middleware/tenant_monitoring.py`
3. Check main.py for middleware import errors

### Issue: Frontend not sending X-Tenant-ID header

**Solution:**
1. Check console for `[TENANT-MONITORING]` warnings
2. Verify JWT token contains tenant_id: Check payload in `/api/health/tenant-monitoring`
3. Check Network tab to confirm header is missing
4. Verify `getTenantIdFromToken()` is extracting correctly

### Issue: Tenant ID mismatch warnings

**Solution:**
1. This indicates JWT token has different tenant_id than X-Tenant-ID header
2. Check if user switched tenants without refreshing token
3. Verify token generation includes correct tenant_id
4. May indicate security issue - investigate immediately

### Issue: Health check shows "unhealthy"

**Solution:**
1. Check the `issues` array in response for specific problems
2. Common issues:
   - JWT token doesn't contain tenant_id → Update token generation
   - Token invalid → Re-authenticate
   - Middleware not active → Check server startup logs

## Monitoring in Production

### Recommended Setup

1. **Log Aggregation**: Send logs to centralized system (ELK, Datadog, etc.)
   - Create alerts for `[TENANT-MISMATCH]` and `[TENANT-ERROR]`
   - Dashboard for `[TENANT-PERFORMANCE]` metrics

2. **Metrics Tracking**: Extend `TenantMetrics` class to write to:
   - Redis for real-time counters
   - Prometheus for time-series metrics
   - CloudWatch for AWS deployments

3. **Alerting Rules**:
   - Alert on >10 tenant mismatch errors/hour (potential security issue)
   - Alert on >100 missing tenant_id warnings/hour (integration problem)
   - Alert on tenant operations >5s (performance degradation)

4. **Regular Health Checks**:
   - Add `/api/health/tenant-monitoring` to monitoring system
   - Alert if status changes to "unhealthy"
   - Create daily report of warnings

## File Summary

### Backend Files Created/Modified:
- ✅ `/production-backend/app/middleware/tenant_monitoring.py` - **CREATED** (220 lines)
- ✅ `/production-backend/app/utils/tenant_monitoring.py` - **CREATED** (310 lines)
- ✅ `/production-backend/app/utils/__init__.py` - **CREATED** (15 lines)
- ✅ `/production-backend/app/main.py` - **MODIFIED** (added middleware, lines 217-223)
- ✅ `/production-backend/app/routers/audit.py` - **MODIFIED** (enhanced logging, lines 99-201)
- ✅ `/production-backend/app/routers/health.py` - **MODIFIED** (added endpoint, lines 830-964)

### Frontend Files Modified:
- ✅ `/production-frontend/lib/api/client.ts` - **MODIFIED** (enhanced logging, lines 314-425)

### Line Numbers Reference:

**Middleware**: `/production-backend/app/middleware/tenant_monitoring.py`
- Lines 1-220: Complete middleware implementation

**Main.py Integration**: `/production-backend/app/main.py`
- Lines 217-223: Middleware loading

**Audit Router**: `/production-backend/app/routers/audit.py`
- Lines 99-122: Enhanced `get_current_tenant_from_request()` with logging
- Lines 160-169: Enhanced error messages in `search_audit_logs`
- Lines 181-201: Added execution logging

**Health Check**: `/production-backend/app/routers/health.py`
- Lines 830-964: New `/tenant-monitoring` endpoint

**Frontend Client**: `/production-frontend/lib/api/client.ts`
- Lines 314-348: Enhanced `getTenantIdFromToken()` with logging
- Lines 371-383: Enhanced `createHeaders()` with logging
- Lines 388-425: Enhanced `logRequest()` with tenant monitoring

## Next Steps

1. **Test in Development**: Follow verification steps above
2. **Monitor Logs**: Ensure logs are being written correctly
3. **Test Edge Cases**: Try requests without auth, with wrong tenant_id, etc.
4. **Production Rollout**: Deploy with log aggregation configured
5. **Create Dashboards**: Build monitoring dashboards for tenant operations
6. **Set Up Alerts**: Configure alerts for security and performance issues

## Support

If you encounter issues:
1. Check this guide's Troubleshooting section
2. Review server logs for error messages
3. Test with the health check endpoint
4. Use the verification script to isolate problems
