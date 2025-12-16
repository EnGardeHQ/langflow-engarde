# EnGarde Local Development Environment Setup Guide

## 🚨 Critical Analysis: Authentication Flow Issues

Based on comprehensive analysis of your codebase, here are the key issues causing 401 errors on `/api/auth/login`:

### Primary Issue: Environment Configuration Mismatch

**Problem**: The frontend and backend have mismatched URL configurations that cause authentication requests to fail in Docker environments.

**Root Cause Analysis**:
1. **Frontend API URL Configuration**: In Docker, frontend is configured with `NEXT_PUBLIC_API_URL=http://backend:8000` but this only works for server-side requests
2. **Client-side vs Server-side Requests**: Browser-based requests cannot reach `http://backend:8000` (Docker internal network)
3. **Middleware Proxy Logic**: The middleware proxy should handle this but has environment detection issues

## 📋 Complete Authentication Endpoint Mapping

### Frontend → Backend Authentication Flow

| Frontend Endpoint | Frontend File | Backend Endpoint | Backend File | Purpose |
|-------------------|---------------|------------------|--------------|---------|
| `/api/auth/login` | `/production-frontend/app/api/auth/login/route.ts` | `/token` | `/production-backend/app/routers/auth.py:126` | OAuth2 login |
| `/api/auth/login` | Same | `/auth/login` | `/production-backend/app/routers/auth.py:142` | Alternative login |
| `/auth/logout` | API Client | `/auth/logout` | `/production-backend/app/routers/auth.py:214` | Logout |
| `/auth/refresh` | API Client | `/auth/refresh` | `/production-backend/app/routers/auth.py:219` | Token refresh |
| `/me` | API Client | `/me` | `/production-backend/app/routers/me.py` | Current user |

### Backend Authentication Endpoints Available

✅ **Available Endpoints** (confirmed via health check):
- `POST /token` - OAuth2 password flow (primary)
- `POST /auth/login` - Alternative login endpoint
- `POST /auth/email-login` - Email-specific login
- `POST /auth/logout` - Logout
- `POST /auth/refresh` - Token refresh
- `GET /me` - Current user profile
- `GET /api/me` - Alternative user profile endpoint

## 🔧 Docker Service Configuration

### Current Docker Compose Setup

```yaml
# Root docker-compose.yml
services:
  postgres:
    ports: ["5432:5432"]
    networks: [engarde_network]

  redis:
    ports: ["6379:6379"]
    networks: [engarde_network]

  backend:
    container_name: engarde_backend
    ports: ["8000:8000"]
    environment:
      DATABASE_URL: postgresql://engarde_user:engarde_password@postgres:5432/engarde
      CORS_ORIGINS: '["http://localhost:3001","http://frontend:3000","http://127.0.0.1:3001"]'
    networks: [engarde_network]

  frontend:
    container_name: engarde_frontend
    ports: ["3001:3000"]  # 🚨 HOST:CONTAINER
    environment:
      NEXT_PUBLIC_API_URL: http://backend:8000  # 🚨 ISSUE: Only works server-side
      DOCKER_CONTAINER: "true"
    networks: [engarde_network]
```

### 🚨 Identified Configuration Issues

1. **Frontend Port Mapping**: `3001:3000` means frontend runs on port 3000 inside container but accessible on host port 3001
2. **API URL Mismatch**: `NEXT_PUBLIC_API_URL=http://backend:8000` won't work for browser requests
3. **CORS Configuration**: Backend allows `http://frontend:3000` but frontend runs on host port 3001

## 🔧 Fixed Environment Configuration

### Method 1: Docker with Middleware Proxy (Recommended)

**Frontend Environment** (`.env` or `docker-compose.yml`):
```bash
# For Docker deployment
NEXT_PUBLIC_API_URL=/api                    # Use relative URLs for middleware proxy
DOCKER_CONTAINER=true                       # Enables middleware proxy
DOCKER_ENVIRONMENT=development              # Environment detection
```

**Backend CORS** (in `docker-compose.yml`):
```yaml
environment:
  CORS_ORIGINS: '["http://localhost:3001","http://127.0.0.1:3001","http://frontend:3000"]'
```

### Method 2: Local Development (No Docker)

**Frontend Environment**:
```bash
NEXT_PUBLIC_API_URL=http://localhost:8000   # Direct backend access
DOCKER_CONTAINER=false                      # Disables middleware proxy
NODE_ENV=development
```

**Backend**: Run on `localhost:8000`

## 🚀 Startup Instructions

### Option A: Full Stack Docker (Recommended for Testing)

```bash
# 1. Navigate to project root
cd /Users/cope/EnGardeHQ

# 2. Build and start all services
docker-compose up --build

# 3. Verify services are running
curl http://localhost:8000/health          # Backend health
curl http://localhost:3001                 # Frontend (should proxy to backend)

# 4. Test authentication endpoint
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=demo123"
```

### Option B: Local Development (Frontend + Backend Separate)

```bash
# Terminal 1: Start Backend
cd /Users/cope/EnGardeHQ/production-backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Terminal 2: Start Frontend
cd /Users/cope/EnGardeHQ/production-frontend
# Update .env to use localhost backend
echo "NEXT_PUBLIC_API_URL=http://localhost:8000" > .env.local
npm run dev

# Terminal 3: Test
curl http://localhost:3000/api/auth/login \
  -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=demo123"
```

### Option C: Backend Only Docker + Local Frontend

```bash
# Terminal 1: Start backend services in Docker
cd /Users/cope/EnGardeHQ
docker-compose up postgres redis backend

# Terminal 2: Start frontend locally
cd /Users/cope/EnGardeHQ/production-frontend
echo "NEXT_PUBLIC_API_URL=http://localhost:8000" > .env.local
echo "DOCKER_CONTAINER=false" >> .env.local
npm run dev
```

## 🔍 Debugging Authentication Issues

### Environment Detection Debug

The frontend has comprehensive environment detection logic. Check these debug outputs:

```javascript
// Frontend console logs to watch for:
console.log('🔍 Environment Detection Debug:', {
  nodeEnv,
  apiUrl,
  dockerEnv,
  dockerContainer,
  isBrowser
});

console.log('🔧 Final Environment Config:', {
  environment,
  frontendUrl,
  backendUrl,
  useMiddlewareProxy,
  useNextRewrite
});
```

### Authentication Flow Debug

Monitor these logs during login:

**Frontend Auth Service** (`/production-frontend/services/auth.service.ts`):
```javascript
// Look for these log patterns:
"🔐 AUTH SERVICE: Starting login process..."
"🔐 AUTH SERVICE: Sending login request to API route..."
"🔐 AUTH SERVICE: API response received:"
"✅ AUTH SERVICE: Login completed successfully"
```

**Frontend API Route** (`/production-frontend/app/api/auth/login/route.ts`):
```javascript
// Look for these log patterns:
"🔐 Proxying login request to backend:"
"🔐 Backend response:"
"🧪 Using test mode for demo login"  // Development only
```

**Backend Auth Router** (`/production-backend/app/routers/auth.py`):
```python
# Backend FastAPI auto-logs:
"POST /token HTTP/1.1" 200
"POST /auth/login HTTP/1.1" 200
```

### Common Error Patterns

#### 1. 401 Unauthorized - "Incorrect username or password"
**Cause**: Credential validation failure
**Solutions**:
- Use test credentials: `demo@engarde.com` / `demo123` (development mode)
- Check if user exists in database
- Verify password hashing

#### 2. 401 Unauthorized - Network/CORS Error
**Cause**: Environment configuration mismatch
**Solutions**:
- Check `NEXT_PUBLIC_API_URL` setting
- Verify CORS origins in backend
- Ensure Docker network connectivity

#### 3. 502 Bad Gateway
**Cause**: Frontend can't reach backend
**Solutions**:
- Check if backend is running (`curl http://localhost:8000/health`)
- Verify Docker network configuration
- Check middleware proxy logic

#### 4. 404 Not Found
**Cause**: Endpoint mapping issue
**Solutions**:
- Verify backend router is loaded
- Check URL mapping in environment config
- Ensure middleware proxy is working

## 🧪 Test Credentials

### Development Mode Test User
```
Email: demo@engarde.com
Password: demo123
```

This user is hardcoded in the frontend API route for development testing and bypasses backend authentication.

### Database Users
Check actual users with:
```sql
-- Connect to postgres container
docker exec -it engarde_postgres psql -U engarde_user -d engarde

-- List users
SELECT id, email, first_name, last_name, is_active, user_type FROM users;
```

## 🔒 Security Configuration

### CORS Settings
Backend automatically configures CORS for:
- `http://localhost:3000-3006`
- `http://127.0.0.1:3000-3006`
- `http://frontend:3000` (Docker internal)
- Plus additional origins from environment

### CSP (Content Security Policy)
Frontend middleware automatically configures CSP with environment-specific rules.

### Rate Limiting
- Authentication endpoints: 100 requests/5 minutes (development)
- General API: Based on endpoint type
- Configurable in middleware

## 🐛 Troubleshooting Quick Commands

```bash
# Check all services status
docker-compose ps

# View backend logs
docker-compose logs backend

# View frontend logs
docker-compose logs frontend

# Restart specific service
docker-compose restart backend

# Test backend directly
curl http://localhost:8000/health

# Test authentication directly on backend
curl -X POST http://localhost:8000/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=demo123"

# Test frontend API route
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=demo123"

# Check network connectivity
docker exec -it engarde_frontend ping backend
docker exec -it engarde_backend ping postgres
```

## 📋 Pre-flight Checklist

Before starting the application:

- [ ] **Environment Files**: Check `.env` files are properly configured
- [ ] **Docker**: Ensure Docker and Docker Compose are running
- [ ] **Ports**: Verify ports 3001, 8000, 5432, 6379 are available
- [ ] **Database**: Ensure PostgreSQL container starts successfully
- [ ] **Dependencies**: Run `npm install` in frontend if needed
- [ ] **Build**: Consider `docker-compose build` if there are code changes

## 🎯 Recommended Fix for Current Issue

Based on the analysis, here's the immediate fix:

1. **Update Frontend Environment** (in Docker):
```bash
# In docker-compose.yml frontend service environment:
NEXT_PUBLIC_API_URL: /api  # Use relative URL for middleware proxy
DOCKER_CONTAINER: "true"   # Ensure middleware proxy is enabled
```

2. **Verify Backend CORS**:
```bash
# Ensure backend accepts requests from host port 3001
CORS_ORIGINS: '["http://localhost:3001","http://127.0.0.1:3001","http://frontend:3000"]'
```

3. **Test the Fix**:
```bash
# Restart services
docker-compose down && docker-compose up --build

# Test authentication
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=demo123"
```

## 🔮 Future Improvements

1. **Environment Auto-Detection**: Improve middleware logic to better detect Docker vs local
2. **Health Checks**: Add comprehensive health checks for all services
3. **Logging**: Implement structured logging for better debugging
4. **Testing**: Add integration tests for authentication flow
5. **Documentation**: Create API documentation with proper examples

---

**Last Updated**: 2025-01-19
**Version**: 1.0
**Author**: System Architecture Analysis