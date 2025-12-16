# Authentication Endpoints Testing Guide

## Overview
This guide provides comprehensive instructions for testing all authentication endpoints in the EnGarde application.

## Quick Start

Run the automated test suite:
```bash
./test-auth-endpoints.sh
```

Or with custom configuration:
```bash
BACKEND_URL=http://localhost:8000 \
FRONTEND_URL=http://localhost:3001 \
TEST_EMAIL=demo@engarde.com \
TEST_PASSWORD=demo123 \
./test-auth-endpoints.sh
```

## Manual Testing Commands

### 1. Health Checks

**Backend Health:**
```bash
curl -X GET http://localhost:8000/health
```

**Frontend Health:**
```bash
curl -X GET http://localhost:3001/api/health
```

### 2. Login Endpoints

**Backend Direct Login (OAuth2 /token endpoint):**
```bash
curl -X POST http://localhost:8000/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=demo123&grant_type=password"
```

Expected response:
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "token_type": "bearer",
  "expires_in": 1800,
  "user": {
    "id": "...",
    "email": "demo@engarde.com",
    "first_name": "Demo",
    "last_name": "User",
    "user_type": "advertiser",
    "is_active": true
  }
}
```

**Backend /auth/login endpoint:**
```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=demo123"
```

**Frontend Login Proxy (JSON format):**
```bash
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo@engarde.com","password":"demo123"}'
```

### 3. Token Refresh Endpoints

**Backend Token Refresh:**
```bash
# First, save your refresh token from login
REFRESH_TOKEN="your_refresh_token_here"

curl -X POST http://localhost:8000/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refresh_token\":\"${REFRESH_TOKEN}\"}"
```

Expected response:
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "token_type": "bearer",
  "expires_in": 1800
}
```

**Frontend Token Refresh Proxy:**
```bash
curl -X POST http://localhost:3001/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refresh_token\":\"${REFRESH_TOKEN}\"}"
```

### 4. Get Current User

**Backend /me endpoint:**
```bash
# First, save your access token from login
ACCESS_TOKEN="your_access_token_here"

curl -X GET http://localhost:8000/me \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Frontend /api/me proxy:**
```bash
curl -X GET http://localhost:3001/api/me \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

Expected response:
```json
{
  "id": "demo-user-id",
  "email": "demo@engarde.com",
  "firstName": "Demo",
  "lastName": "User",
  "company": "",
  "userType": "advertiser",
  "isActive": true,
  "avatar": null,
  "preferences": {},
  "createdAt": "2025-10-06T...",
  "updatedAt": "2025-10-06T..."
}
```

### 5. Logout

**Backend Logout:**
```bash
curl -X POST http://localhost:8000/auth/logout \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

## Docker Environment Testing

If running in Docker, use the internal service names from within containers:

**From Frontend Container to Backend:**
```bash
docker exec -it engarde_frontend sh -c \
  "curl -X GET http://backend:8000/health"
```

**From Host to Docker Services:**
```bash
# Backend
curl -X GET http://localhost:8000/health

# Frontend
curl -X GET http://localhost:3001/api/health
```

## Complete Flow Test

Here's a complete authentication flow test:

```bash
#!/bin/bash

# 1. Login and capture tokens
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo@engarde.com","password":"demo123"}')

ACCESS_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.access_token')
REFRESH_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.refresh_token')

echo "Access Token: ${ACCESS_TOKEN:0:20}..."
echo "Refresh Token: ${REFRESH_TOKEN:0:20}..."

# 2. Get current user
USER_INFO=$(curl -s -X GET http://localhost:3001/api/me \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

echo "User: $(echo $USER_INFO | jq -r '.email')"

# 3. Refresh the token
REFRESH_RESPONSE=$(curl -s -X POST http://localhost:3001/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refresh_token\":\"${REFRESH_TOKEN}\"}")

NEW_ACCESS_TOKEN=$(echo $REFRESH_RESPONSE | jq -r '.access_token')

echo "New Access Token: ${NEW_ACCESS_TOKEN:0:20}..."

# 4. Use new token to get user info
USER_INFO_2=$(curl -s -X GET http://localhost:3001/api/me \
  -H "Authorization: Bearer ${NEW_ACCESS_TOKEN}")

echo "User (with new token): $(echo $USER_INFO_2 | jq -r '.email')"

# 5. Logout
LOGOUT_RESPONSE=$(curl -s -X POST http://localhost:8000/auth/logout \
  -H "Authorization: Bearer ${NEW_ACCESS_TOKEN}")

echo "Logout: $(echo $LOGOUT_RESPONSE | jq -r '.message')"
```

## Rate Limiting Tests

### Test Login Rate Limit (50 requests per 15 minutes in production)

```bash
for i in {1..55}; do
  echo "Request $i:"
  curl -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"demo@engarde.com","password":"demo123"}' \
    -w "\nHTTP Status: %{http_code}\n" \
    -s | head -n 1
  echo "---"
done
```

You should see:
- First 50 requests: HTTP 200
- Subsequent requests: HTTP 429 (Rate Limited)

Response headers will include:
```
RateLimit-Limit: 50
RateLimit-Remaining: 49
RateLimit-Reset: 2025-10-06T12:15:00.000Z
Retry-After: 900
```

### Test Refresh Rate Limit (100 requests per 15 minutes)

```bash
# Login first to get a refresh token
REFRESH_TOKEN=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo@engarde.com","password":"demo123"}' | jq -r '.refresh_token')

# Test refresh rate limit
for i in {1..105}; do
  echo "Refresh Request $i:"
  curl -X POST http://localhost:3001/api/auth/refresh \
    -H "Content-Type: application/json" \
    -d "{\"refresh_token\":\"${REFRESH_TOKEN}\"}" \
    -w "\nHTTP Status: %{http_code}\n" \
    -s | head -n 1
  echo "---"
done
```

## Error Scenarios

### Invalid Credentials
```bash
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo@engarde.com","password":"wrongpassword"}'
```
Expected: HTTP 401 Unauthorized

### Missing Refresh Token
```bash
curl -X POST http://localhost:3001/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{}'
```
Expected: HTTP 400 Bad Request

### Invalid/Expired Refresh Token
```bash
curl -X POST http://localhost:3001/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"invalid_token_here"}'
```
Expected: HTTP 401 Unauthorized

### Missing Authorization Header
```bash
curl -X GET http://localhost:3001/api/me
```
Expected: HTTP 401 Unauthorized

### Invalid Access Token
```bash
curl -X GET http://localhost:3001/api/me \
  -H "Authorization: Bearer invalid_token"
```
Expected: HTTP 401 Unauthorized

## Troubleshooting

### Issue: 404 on /api/auth/refresh
**Solution:** The refresh endpoint now exists. If you still see 404:
1. Restart the frontend server
2. Check that the route file exists at `production-frontend/app/api/auth/refresh/route.ts`
3. Verify Next.js routing is working

### Issue: 429 Too Many Requests
**Solution:** Rate limiting is working as expected. Wait 15 minutes or:
1. Use development environment (higher limits)
2. Restart the server to reset rate limiting
3. Use different IP address

### Issue: Backend connection failed
**Solution:**
1. Verify backend is running: `curl http://localhost:8000/health`
2. Check Docker networking if in containers
3. Verify CORS settings in `production-backend/app/main.py`
4. Check frontend environment variables

### Issue: CORS errors in browser
**Solution:**
1. Verify backend CORS includes `http://localhost:3001`
2. Check browser console for specific CORS error
3. Ensure credentials are being sent with requests

## Configuration Summary

### Rate Limits (Production)
- `/api/auth/login`: 50 requests per 15 minutes
- `/api/auth/refresh`: 100 requests per 15 minutes
- `/api/auth/register`: 10 requests per 15 minutes
- `/api/me`: 100 requests per 15 minutes

### Rate Limits (Development)
- `/api/auth/login`: 200 requests per 15 minutes
- `/api/auth/refresh`: 200 requests per 15 minutes
- All limits are more permissive in development

### Token Expiry
- Access Token: 30 minutes (1800 seconds)
- Refresh Token: 7 days (604800 seconds)

### CORS Origins (Backend)
- `http://localhost:3000`
- `http://localhost:3001`
- `http://127.0.0.1:3000`
- `http://127.0.0.1:3001`
- Additional origins from environment variables

### Environment Variables

**Backend:**
- `SECRET_KEY`: JWT signing secret
- `ACCESS_TOKEN_EXPIRE_MINUTES`: Access token lifetime (default: 30)
- `CORS_ORIGINS`: Additional CORS origins

**Frontend:**
- `NEXT_PUBLIC_API_URL`: Backend API URL (default: http://localhost:8000)
- `DOCKER_CONTAINER`: Set to "true" in Docker to use service names

## Logging and Debugging

All authentication requests now include:
- Request ID for tracking
- Detailed timing information
- Error codes and messages
- Request/response logging

Check logs:
```bash
# Backend logs
docker logs engarde_backend -f

# Frontend logs
docker logs engarde_frontend -f
```

Look for:
- `[refresh-xxxxx]` - Refresh endpoint request IDs
- `🔐 API ROUTE:` - Login endpoint logs
- `🔄 REFRESH API:` - Refresh endpoint logs
- `✅`, `❌`, `⚠️` - Success, error, warning indicators
