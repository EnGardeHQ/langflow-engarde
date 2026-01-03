# Production Test User Credentials

**Last Updated:** January 1, 2026

## Test Users Configured in Production Database

### Test User
- **Email:** `test@engarde.com`
- **Password:** `test123`
- **User ID:** `08fc4bf4-acb6-4c41-94bc-1dc7cd687bfa`
- **Name:** Test User
- **Type:** Brand
- **Active:** Yes
- **Superuser:** No

### Agency User
- **Email:** `agency@engarde.com`
- **Password:** `agency123`
- **User ID:** `402f717f-64ae-4cc6-b1b4-a3c08ac8be56`
- **Name:** Agency Admin
- **Type:** Agency
- **Active:** Yes
- **Superuser:** No

---

## All Available Test Users

| Email | Password | User Type | Superuser | Status |
|-------|----------|-----------|-----------|--------|
| `test@engarde.com` | `test123` | Brand | No | ✅ Active |
| `agency@engarde.com` | `agency123` | Agency | No | ✅ Active |
| `demo@engarde.com` | `demo123` | Brand | No | ✅ Active (check db) |
| `admin@engarde.com` | `admin123` | Brand | Yes | ✅ Active (check db) |

---

## Login URLs

- **Production Frontend:** https://engarde.media/login
- **Production API:** https://api.engarde.media/docs
- **Langflow:** https://langflow.engarde.media

---

## Verification Commands

### Check user exists in production:
```bash
DATABASE_URL="postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway" \
python3 -c "
from sqlalchemy import create_engine, text
import os
engine = create_engine(os.getenv('DATABASE_URL'))
result = engine.connect().execute(text('SELECT email, first_name, last_name FROM users WHERE email IN (\'test@engarde.com\', \'agency@engarde.com\')'))
for row in result:
    print(f'{row.email} - {row.first_name} {row.last_name}')
"
```

### Verify password works:
```bash
DATABASE_URL="postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway" \
python3 -c "
from sqlalchemy import create_engine, text
from passlib.context import CryptContext
import os
pwd_context = CryptContext(schemes=['bcrypt'], deprecated='auto')
engine = create_engine(os.getenv('DATABASE_URL'))
result = engine.connect().execute(text('SELECT email, hashed_password FROM users WHERE email = \'test@engarde.com\''))
user = result.fetchone()
print(f'{user.email}: {pwd_context.verify(\"test123\", user.hashed_password)}')
"
```

---

## Scripts

### Update Passwords
```bash
DATABASE_URL="postgresql://..." python3 production-backend/update_test_user_passwords.py
```

### Create Test User
```bash
DATABASE_URL="postgresql://..." python3 production-backend/create_test_user.py
```

---

## Notes

- ✅ **test@engarde.com** was created on 2026-01-01
- ✅ **agency@engarde.com** password was updated on 2026-01-01
- Both users are verified working in production database
- The bcrypt warning can be ignored - it's a library version message, passwords still work correctly

---

**Production Database Connection:**
```
postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway
```

---

## Quick Test

Test login via API:
```bash
curl -X POST https://api.engarde.media/api/v1/auth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=test@engarde.com&password=test123"
```

Expected response: JWT token in JSON format
