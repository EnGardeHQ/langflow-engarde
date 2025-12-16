# EnGarde Test Users Guide

This document provides information about test users for local development and testing.

## Quick Start

### Prerequisites

1. Backend must be running on `http://localhost:8000`
2. Frontend must be running on `http://localhost:3000`
3. Database must be initialized with test users

### Test User Credentials

#### Default Test User (Brand)
```
Email: test@engarde.com
Password: test123
User Type: Brand
Description: Standard brand user for testing brand dashboard features
```

#### Publisher Test User
```
Email: publisher@engarde.com
Password: test123
User Type: Publisher
Description: Publisher user for testing publisher dashboard features
```

#### Admin Test User
```
Email: admin@engarde.com
Password: admin123
User Type: Admin
Description: Admin user with full platform access
```

## Setting Up Test Users

### Method 1: Using the Backend Script (Recommended)

1. Navigate to the backend directory:
```bash
cd /Users/cope/EnGardeHQ/production-backend
```

2. Run the test user creation script:
```bash
python3 create_test_user_simple.py
```

3. Verify the user was created successfully in the output

### Method 2: Using API Endpoints

If user registration is enabled, you can create users via the API:

```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@engarde.com",
    "password": "securePassword123!",
    "firstName": "Test",
    "lastName": "User",
    "userType": "brand"
  }'
```

### Method 3: Direct Database Insert (Development Only)

For development purposes, you can directly insert test users:

```python
# Run this in the backend Python environment
import asyncio
from app.services.zerodb_service import zerodb_service
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

async def create_user():
    user_data = {
        "id": "test-brand-user",
        "email": "test@engarde.com",
        "first_name": "Test",
        "last_name": "User",
        "hashed_password": pwd_context.hash("test123"),
        "is_active": True,
        "is_superuser": False,
        "user_type": "brand",
        "tenant_id": "default-tenant"
    }
    result = await zerodb_service.insert_record("users", user_data)
    print(f"Created user: {result}")

asyncio.run(create_user())
```

## How to Login

### Using the Web Interface

1. Navigate to `http://localhost:3000/login`
2. Select user type (Brand or Publisher) using the tabs
3. Enter credentials:
   - Email: `test@engarde.com`
   - Password: `test123`
4. Click "Sign In"
5. You will be redirected to the dashboard upon successful login

### Using cURL (API Testing)

```bash
# Login to get access token
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=test@engarde.com&password=test123"

# Response includes:
# - access_token: JWT token for authenticated requests
# - token_type: "bearer"
# - expires_in: Token expiration time in seconds
# - user: User object with profile information
```

### Using the Frontend API Route

The frontend provides a proxy API route that handles authentication:

```javascript
// JavaScript/TypeScript example
const response = await fetch('/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    username: 'test@engarde.com',
    password: 'test123'
  })
});

const data = await response.json();
console.log('Access Token:', data.access_token);
```

## User Capabilities by Type

### Brand Users
- Access to brand dashboard
- Campaign management (create, edit, delete)
- Integration management (Google Ads, Meta, LinkedIn)
- Analytics and reporting
- Brand settings and preferences
- Team member management (if enabled)

### Publisher Users
- Access to publisher dashboard
- Content management
- Monetization tracking
- Audience analytics
- Publisher-specific integrations
- Revenue reporting

### Admin Users
- Full platform access
- User management
- System configuration
- Platform-wide analytics
- Integration management
- Audit logs and monitoring

## Switching Between Brands

If a user has access to multiple brands:

1. After login, you may see a brand selection screen
2. Select the brand you want to work with
3. The selected brand is stored in the session
4. To switch brands:
   - Navigate to user menu (top right)
   - Click "Switch Brand"
   - Select a different brand from the list

## Common Issues and Troubleshooting

### "Incorrect username or password" Error

**Possible Causes:**
1. Test user not created in database
2. Wrong credentials entered
3. Backend not running
4. Database connection issues

**Solutions:**
1. Run the user creation script: `python3 create_test_user_simple.py`
2. Verify credentials match exactly (case-sensitive)
3. Check backend is running: `curl http://localhost:8000/health`
4. Check database service is running

### Login Succeeds but Redirects to Login Again

**Possible Causes:**
1. Token storage issues
2. Browser blocking localStorage
3. Authentication context not properly initialized

**Solutions:**
1. Clear browser cache and cookies
2. Check browser console for errors
3. Ensure JavaScript is enabled
4. Try in incognito/private mode

### "User account is inactive" Error

**Possible Causes:**
1. User's `is_active` field set to `false`
2. Account was deactivated

**Solutions:**
1. Update user record to set `is_active: true`
2. Contact admin to reactivate account

### Cannot Access Dashboard After Login

**Possible Causes:**
1. User doesn't have a brand associated
2. Brand selection required
3. Routing issues

**Solutions:**
1. Create a brand for the user in the onboarding flow
2. Check that BrandGuard is allowing access
3. Verify user type matches the required permissions

## Testing Different Scenarios

### Test Login Flow
```bash
# 1. Start with logged-out state
# Visit: http://localhost:3000/login

# 2. Try invalid credentials (should show error)
Email: wrong@email.com
Password: wrongpass

# 3. Try valid credentials (should redirect to dashboard)
Email: test@engarde.com
Password: test123

# 4. Verify token is stored (check browser DevTools > Application > LocalStorage)
# Look for: engarde_access_token, engarde_refresh_token, engarde_user
```

### Test Token Expiration
```javascript
// In browser console after login
// Wait for token to expire (or manually clear it)
localStorage.removeItem('engarde_access_token');

// Try to access a protected route
// Should redirect to login
```

### Test Brand Selection
```bash
# 1. Login with user that has multiple brands
# 2. Should see brand selection screen
# 3. Select a brand
# 4. Verify correct brand context is loaded in dashboard
```

## API Reference

### Login Endpoint
```
POST /auth/login
Content-Type: application/x-www-form-urlencoded

Body:
  username: string (email address)
  password: string

Response:
  {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "token_type": "bearer",
    "expires_in": 3600,
    "user": {
      "id": "uuid",
      "email": "test@engarde.com",
      "first_name": "Test",
      "last_name": "User",
      "user_type": "brand",
      "is_active": true,
      "created_at": "2025-01-01T00:00:00Z",
      "updated_at": "2025-01-01T00:00:00Z"
    }
  }
```

### Logout Endpoint
```
POST /auth/logout
Authorization: Bearer <access_token>

Response:
  {
    "message": "Successfully logged out"
  }
```

### Get Current User
```
GET /api/me
Authorization: Bearer <access_token>

Response:
  {
    "id": "uuid",
    "email": "test@engarde.com",
    "first_name": "Test",
    "last_name": "User",
    "user_type": "brand",
    "is_active": true,
    ...
  }
```

## Environment Variables

Ensure these are set in your `.env.local` file:

```bash
# Frontend
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXTAUTH_SECRET=<your-secret-key>

# Backend
DATABASE_URL=<your-database-url>
JWT_SECRET_KEY=<your-jwt-secret>
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

## Security Notes

1. **Never use test credentials in production**
2. **Change default passwords before deploying**
3. **Test users should only exist in development/staging environments**
4. **Rotate JWT secrets regularly**
5. **Use strong passwords for all non-test users**
6. **Enable rate limiting on authentication endpoints**

## Development Tips

### Quick Login for Testing
During development, you can add a "Quick Login" button that auto-fills credentials:

```typescript
// Add to login page for development only
{process.env.NODE_ENV === 'development' && (
  <Button onClick={() => {
    setFormData({
      email: 'test@engarde.com',
      password: 'test123'
    });
  }}>
    Quick Fill (Dev Only)
  </Button>
)}
```

### Mock Authentication for Frontend Testing
You can bypass backend authentication for pure frontend testing:

```typescript
// In AuthContext.tsx (development only)
if (process.env.NEXT_PUBLIC_MOCK_AUTH === 'true') {
  // Return mock user data
  return mockUser;
}
```

## Additional Resources

- [Backend API Documentation](/Users/cope/EnGardeHQ/production-backend/README.md)
- [Frontend Documentation](/Users/cope/EnGardeHQ/production-frontend/README.md)
- [Authentication Flow Diagram](./docs/auth-flow.md)
- [Security Best Practices](./docs/security.md)

## Contact

For issues or questions:
- Check the browser console for detailed error messages
- Check backend logs: `docker logs engarde-backend`
- Review the auth service logs in the frontend console

## Last Updated
2025-10-05
