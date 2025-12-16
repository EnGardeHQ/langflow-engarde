# Login Fix Report - 401 Unauthorized Issue

**Date:** 2025-10-09
**Issue:** Login failing with 401 Unauthorized for demo@engarde.com
**Status:** RESOLVED

---

## Problem Summary

The backend login endpoint at `/api/auth/login` was returning 401 Unauthorized errors when attempting to authenticate with the demo user credentials:
- Email: `demo@engarde.com`
- Password: `demo123`

## Root Cause Analysis

### Investigation Steps

1. **Backend Logs Check:**
   - Logs showed: "Authentication failed: Invalid password for - demo@engarde.com"
   - User was found in database
   - User was active
   - Password verification was failing

2. **Database Verification:**
   ```sql
   SELECT email, hashed_password, is_active FROM users WHERE email = 'demo@engarde.com';
   ```
   - User existed: `demo@engarde.com`
   - Was active: `true`
   - Had password hash: `$2b$12$NKdRzsPk5BVdaXA.1k5YbuS7DOl7JqWhWUiWPvUw2IOLNQySXmaqS`

3. **Password Verification Test:**
   ```python
   from passlib.context import CryptContext
   pwd_context = CryptContext(schemes=['bcrypt'], deprecated='auto')
   hashed = '$2b$12$NKdRzsPk5BVdaXA.1k5YbuS7DOl7JqWhWUiWPvUw2IOLNQySXmaqS'
   print(pwd_context.verify("demo123", hashed))  # Result: False
   ```

   **ISSUE IDENTIFIED:** The password hash in the database was incorrect - it did not correspond to "demo123"

### Root Cause

The database contained an incorrect bcrypt hash for the demo user's password. This could have been caused by:
- Database migration issues
- Manual database updates with wrong password
- Previous seeding scripts using different passwords
- Hash corruption during database operations

## Solution Implemented

### 1. Generated Correct Password Hash

```python
from passlib.context import CryptContext
pwd_context = CryptContext(schemes=['bcrypt'], deprecated='auto')
new_hash = pwd_context.hash('demo123')
# Result: $2b$12$vNYe9AGe3wYbXxheVS2tveNRJLb87R71FlaPoyiUIuthULFocivRm
```

### 2. Updated Database

```sql
UPDATE users
SET hashed_password = '$2b$12$vNYe9AGe3wYbXxheVS2tveNRJLb87R71FlaPoyiUIuthULFocivRm'
WHERE email = 'demo@engarde.com';
```

### 3. Verification

**Successful Login Test:**
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=demo123&grant_type=password"
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 1800,
  "user": {
    "id": "42c69860-b6d3-4d45-b202-4485966d0731",
    "email": "demo@engarde.com",
    "first_name": "Demo",
    "last_name": "User",
    "is_active": true,
    "user_type": "brand",
    "created_at": "2025-09-16T20:01:01.110600",
    "updated_at": "2025-10-09T00:50:16.604179"
  }
}
```

**Backend Logs:**
```
2025-10-09 01:00:58,425 - app.routers.auth - INFO - Login endpoint called for user: demo@engarde.com
2025-10-09 01:00:58,425 - app.routers.auth - INFO - Authentication attempt for: demo@engarde.com
2025-10-09 01:00:58,468 - app.routers.auth - INFO - User found: demo@engarde.com
2025-10-09 01:00:58,800 - app.routers.auth - INFO - Authentication successful for: demo@engarde.com
2025-10-09 01:00:58,801 - app.routers.auth - INFO - Login successful for: demo@engarde.com
2025-10-09 01:00:58,812 - app.main - INFO - Request completed: POST http://localhost:8000/api/auth/login - Status: 200 - Time: 0.508s
```

## Backend Authentication Architecture

### Current Implementation

**File:** `/Users/cope/EnGardeHQ/production-backend/app/routers/auth.py`

#### Key Components:

1. **Password Hashing:**
   ```python
   pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

   def verify_password(plain_password, hashed_password):
       return pwd_context.verify(plain_password, hashed_password)

   def get_password_hash(password):
       return pwd_context.hash(password)
   ```

2. **Authentication Flow:**
   ```python
   def authenticate_user(db: Session, email_or_username: str, password: str):
       user = get_user(db, email_or_username)
       if not user:
           return False
       if not verify_password(password, user.hashed_password):
           return False
       return user
   ```

3. **Login Endpoint:**
   ```python
   @router.post("/api/auth/login")
   async def login(
       form_data: OAuth2PasswordRequestForm = Depends(),
       db: Session = Depends(get_db)
   ):
       user = authenticate_user(db, form_data.username, form_data.password)
       if not user:
           raise HTTPException(
               status_code=status.HTTP_401_UNAUTHORIZED,
               detail="Incorrect username or password",
               headers={"WWW-Authenticate": "Bearer"},
           )
       return create_auth_response(user)
   ```

### Authentication Endpoints

1. **POST /api/auth/login** - Main login endpoint (OAuth2 form data)
2. **POST /token** - OAuth2 token endpoint (alternative)
3. **POST /api/auth/email-login** - Email-based login (JSON)
4. **POST /api/auth/refresh** - Refresh token endpoint
5. **POST /api/auth/logout** - Logout endpoint

### Important Notes

- **Content-Type:** The `/api/auth/login` endpoint expects `application/x-www-form-urlencoded`
- **Request Format:** `username=demo@engarde.com&password=demo123&grant_type=password`
- **NOT JSON:** The endpoint does NOT accept JSON format (returns 422 if JSON is sent)
- **Token Expiry:** Access tokens expire in 30 minutes (configurable via `ACCESS_TOKEN_EXPIRE_MINUTES`)
- **Refresh Tokens:** Valid for 7 days

## Additional Users in Database

Current users in the database:
- `demo@engarde.ai` (active)
- `admin@engarde.ai` (active)
- `test@engarde.ai` (active)
- `test@example.com` (active)
- `demo@engarde.com` (active) - FIXED
- `demo@engarde.local` (active)

**Recommendation:** Verify password hashes for other demo/test users if login issues occur.

## Prevention & Best Practices

### 1. Database Initialization Script

The `/Users/cope/EnGardeHQ/production-backend/app/init_db.py` script correctly generates password hashes:

```python
sample_user = User(
    email="demo@engarde.com",
    hashed_password=get_password_hash("demo123"),  # Correct
    first_name="Demo",
    last_name="User",
    is_active=True,
    is_superuser=False
)
```

### 2. Testing Password Verification

Always verify password hashes after database operations:

```python
# Verify hash works
pwd_context = CryptContext(schemes=['bcrypt'], deprecated='auto')
test_password = "demo123"
new_hash = pwd_context.hash(test_password)
assert pwd_context.verify(test_password, new_hash) == True
```

### 3. Manual Database Updates

When manually updating passwords, always:
1. Generate hash using the application's password hashing function
2. Test verification before applying to production
3. Verify login works after update

### 4. Password Reset Script

Consider creating a password reset utility script:

```python
#!/usr/bin/env python3
from app.database import SessionLocal
from app.models import User
from passlib.context import CryptContext

def reset_user_password(email: str, new_password: str):
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            print(f"User {email} not found")
            return False

        new_hash = pwd_context.hash(new_password)
        user.hashed_password = new_hash
        db.commit()

        # Verify
        if pwd_context.verify(new_password, new_hash):
            print(f"✅ Password reset successful for {email}")
            return True
        else:
            print(f"❌ Password verification failed for {email}")
            return False
    finally:
        db.close()
```

## Demo Credentials (Working)

```
Email: demo@engarde.com
Password: demo123
User Type: brand
Status: Active
```

## Testing Commands

### 1. Test Login (Form-Urlencoded)
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=demo123&grant_type=password"
```

### 2. Test Invalid Password
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=wrongpassword&grant_type=password"
```

### 3. Check User in Database
```bash
PGPASSWORD=engarde_password psql -h localhost -U engarde_user -d engarde \
  -c "SELECT email, is_active, created_at FROM users WHERE email = 'demo@engarde.com';"
```

### 4. Check Backend Logs
```bash
docker logs engarde_backend --tail 50 | grep -A5 "Authentication\|Login"
```

## Resolution Summary

- **Issue:** Password hash mismatch in database
- **Impact:** Login failing with 401 Unauthorized
- **Resolution:** Updated password hash to correct bcrypt hash for "demo123"
- **Verification:** Login successful, access token generated, user authenticated
- **Status:** RESOLVED - Login endpoint working correctly

## Next Steps

1. **Frontend Testing:** Verify frontend login form works with fixed backend
2. **User Audit:** Check other test/demo user password hashes if needed
3. **Documentation:** Update any setup guides with correct credentials
4. **Monitoring:** Watch for similar authentication issues in production logs

---

**Resolution Confirmed:** 2025-10-09 01:00:58 UTC
