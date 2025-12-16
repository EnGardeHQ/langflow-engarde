# ZeroDB 404 Error - Fix Implementation Plan

**Date:** 2025-11-17
**Status:** CRITICAL - Authentication Completely Broken
**Environment:** Railway Production Deployment

---

## Executive Summary

The ZeroDB 404 authentication error has **THREE CRITICAL ROOT CAUSES**:

1. **INVALID API KEY** - Railway's `ZERODB_API_KEY` is truncated/incomplete and returns 404 on ALL endpoints
2. **ARCHITECTURAL MISMATCH** - Code uses event-sourcing for relational tables, which ZeroDB doesn't support
3. **MISSING DATABASE** - No PostgreSQL/SQLite for relational user data

**Current Status:** 🚨 **AUTHENTICATION COMPLETELY NON-FUNCTIONAL**
- Cannot list projects → 404
- Cannot query users → 404
- Cannot authenticate anyone → System unusable

---

## Test Results Confirmation

Running `/Users/cope/EnGardeHQ/production-backend/test_railway_zerodb_config.py`:

```
1️⃣  Testing API Key Validity...
   ⚠️  Unexpected status 404: {"detail":"Not Found"}

✅ API Key Valid: False
✅ Project Exists: False
✅ Database Enabled: False
✅ Events Endpoint: False
✅ Tables Endpoint: False

ROOT CAUSE: API Key is invalid or incomplete
```

**Diagnosis:** The Railway API key `8XjG6qVuCo1pUDBFtisVGUcIYf4uXByNCAY2LgtmTAE` cannot access ANY ZeroDB endpoints, including basic project listing.

---

## Fix Plan: Three-Phase Approach

### Phase 1: IMMEDIATE - Fix API Key (Do Now)

**Critical Issue:** Railway's `ZERODB_API_KEY` is incomplete/invalid

**Fix Steps:**

1. **Get the correct API key from ZeroDB dashboard:**
   ```bash
   # Login to https://api.ainative.studio or ZeroDB dashboard
   # Navigate to API Keys section
   # Generate new API key or retrieve existing full key
   ```

2. **Update Railway environment variables:**
   ```bash
   # Set the COMPLETE API key
   railway variables set ZERODB_API_KEY="<FULL_API_KEY_FROM_DASHBOARD>"

   # Also set the alternate variable name for consistency
   railway variables set API_Key="<FULL_API_KEY_FROM_DASHBOARD>"
   railway variables set API_Base_URL="https://api.ainative.studio/api/v1"
   ```

3. **Verify the project ID:**
   ```bash
   # Using the new API key, list projects
   curl -X GET "https://api.ainative.studio/api/v1/public/projects/" \
     -H "X-API-Key: <FULL_API_KEY>"

   # If d9c00084-0185-4506-b9b5-3baa2369b813 doesn't exist:
   # Create a new project and update ZERODB_PROJECT_ID
   ```

4. **Test with corrected credentials:**
   ```bash
   cd /Users/cope/EnGardeHQ/production-backend
   python3 test_railway_zerodb_config.py

   # Expected: All tests pass (200 OK responses)
   ```

**Expected Outcome:** API key works, can access ZeroDB endpoints

**Timeline:** 30 minutes

---

### Phase 2: SHORT-TERM - Add PostgreSQL for Users (Do Today)

**Critical Issue:** ZeroDB cannot handle relational user authentication

**Fix Steps:**

1. **Add PostgreSQL to Railway:**
   ```bash
   cd /Users/cope/EnGardeHQ/production-backend
   railway add postgres

   # Railway automatically sets DATABASE_URL
   ```

2. **Update environment variables:**
   ```bash
   railway variables set USE_POSTGRES=true
   railway variables set USE_ZERODB=false  # Only for vectors/memory
   ```

3. **Create database models:**
   ```python
   # app/models/user.py
   from sqlalchemy import Column, String, Boolean, DateTime
   from sqlalchemy.sql import func
   from app.core.database import Base

   class User(Base):
       __tablename__ = "users"

       id = Column(String, primary_key=True)
       email = Column(String, unique=True, nullable=False, index=True)
       hashed_password = Column(String, nullable=False)
       first_name = Column(String)
       last_name = Column(String)
       is_active = Column(Boolean, default=True)
       is_superuser = Column(Boolean, default=False)
       tenant_id = Column(String, index=True)
       created_at = Column(DateTime(timezone=True), server_default=func.now())
       updated_at = Column(DateTime(timezone=True), onupdate=func.now())
   ```

4. **Update authentication service:**
   ```python
   # app/services/auth_service.py
   from sqlalchemy.ext.asyncio import AsyncSession
   from sqlalchemy import select
   from app.models.user import User

   class AuthService:
       async def get_user_by_email(
           self,
           email: str,
           db: AsyncSession
       ) -> Optional[User]:
           """Get user from PostgreSQL"""
           result = await db.execute(
               select(User).where(User.email == email)
           )
           return result.scalar_one_or_none()
   ```

5. **Run database migrations:**
   ```bash
   # Create migration
   alembic revision --autogenerate -m "Add users table"

   # Apply to Railway database
   railway run alembic upgrade head
   ```

6. **Migrate existing users (if any):**
   ```python
   # scripts/migrate_users_from_zerodb.py
   # Read from ZeroDB memory/events
   # Write to PostgreSQL
   # Verify all users migrated
   ```

**Expected Outcome:** User authentication works via PostgreSQL

**Timeline:** 2-4 hours

---

### Phase 3: MEDIUM-TERM - Refactor ZeroDB Usage (Do This Week)

**Goal:** Use ZeroDB only for its strengths (vectors, memory, events)

**Architecture:**

```
┌─────────────────────────────────────────────────┐
│                 EnGarde Platform                │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌─────────────┐         ┌──────────────┐      │
│  │ PostgreSQL  │         │   ZeroDB     │      │
│  ├─────────────┤         ├──────────────┤      │
│  │ Users       │         │ Vectors      │      │
│  │ Tenants     │         │ Embeddings   │      │
│  │ Campaigns   │         │ Semantic     │      │
│  │ Brands      │         │ Search       │      │
│  │ Workflows   │         ├──────────────┤      │
│  │ Audit Logs  │         │ Memory       │      │
│  │ ...         │         │ Agent State  │      │
│  └─────────────┘         │ Conversation │      │
│                          ├──────────────┤      │
│                          │ Events       │      │
│                          │ Pub/Sub      │      │
│                          │ Webhooks     │      │
│                          └──────────────┘      │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Refactoring Steps:**

1. **Remove event-sourcing pattern from zerodb_service.py:**
   ```python
   # DELETE these methods:
   - insert_record() using events
   - update_record() using events
   - query_records() using events
   - delete_record() using events

   # KEEP these methods:
   - store_vector() / search_vectors()
   - store_memory() / search_memory()
   - publish_event() / stream_events()
   ```

2. **Update table schemas to use PostgreSQL:**
   ```python
   # app/models/
   - user.py (already done in Phase 2)
   - tenant.py
   - campaign.py
   - brand.py
   - workflow.py
   - audit_log.py
   ```

3. **Create database service layer:**
   ```python
   # app/services/database_service.py
   class DatabaseService:
       def __init__(self, db: AsyncSession):
           self.db = db

       async def get_user_by_email(self, email: str) -> Optional[User]:
           # PostgreSQL query

       async def create_campaign(self, data: dict) -> Campaign:
           # PostgreSQL insert

       # ... all relational operations
   ```

4. **Update routers to use DatabaseService:**
   ```python
   # app/routers/auth.py
   from app.services.database_service import DatabaseService

   @router.post("/login")
   async def login(
       credentials: LoginRequest,
       db: AsyncSession = Depends(get_db)
   ):
       db_service = DatabaseService(db)
       user = await db_service.get_user_by_email(credentials.email)
       # ... authentication logic
   ```

5. **Keep ZeroDB for AI features only:**
   ```python
   # app/services/ai_service.py
   from app.services.zerodb_service import zerodb_service

   class AIService:
       async def semantic_search(self, query: str):
           # Generate embedding
           embedding = await self.get_embedding(query)

           # Search in ZeroDB
           results = await zerodb_service.search_vectors(
               query_vector=embedding,
               namespace="knowledge_base",
               top_k=10
           )
           return results

       async def store_agent_memory(self, agent_id: str, content: str):
           # Store in ZeroDB memory
           await zerodb_service.store_memory(
               content=content,
               agent_id=agent_id,
               session_id=session_id
           )
   ```

**Expected Outcome:** Clean separation of concerns, each database used for its strengths

**Timeline:** 1-2 days

---

## File Changes Required

### Files to Modify:

1. **`/Users/cope/EnGardeHQ/production-backend/app/services/zerodb_service.py`**
   - Remove: `insert_record()`, `update_record()`, `query_records()`, `delete_record()`
   - Keep: Vector and memory operations only
   - Remove: `ENGARDE_TABLE_SCHEMAS` (move to SQLAlchemy models)

2. **`/Users/cope/EnGardeHQ/production-backend/app/services/zerodb_auth.py`**
   - Replace with PostgreSQL-based authentication
   - Remove dependency on `query_users()` from ZeroDB

3. **`/Users/cope/EnGardeHQ/production-backend/app/core/database.py`**
   - Add PostgreSQL connection
   - Add SQLAlchemy session management
   - Add `get_db()` dependency

4. **`/Users/cope/EnGardeHQ/production-backend/app/main.py`**
   - Remove `setup_engarde_tables()` call
   - Add database migration on startup
   - Add health checks for both databases

5. **`/Users/cope/EnGardeHQ/production-backend/alembic/`**
   - Create migrations for all tables
   - Ensure Railway runs migrations on deploy

### Files to Create:

1. **`app/models/user.py`** - User SQLAlchemy model
2. **`app/models/tenant.py`** - Tenant SQLAlchemy model
3. **`app/models/campaign.py`** - Campaign SQLAlchemy model
4. **`app/services/database_service.py`** - PostgreSQL CRUD operations
5. **`app/services/auth_service.py`** - PostgreSQL-based authentication
6. **`scripts/migrate_users_from_zerodb.py`** - Data migration script

### Files to Delete:

1. **Event-sourcing related code in `zerodb_service.py`**
2. **`zerodb_auth.py`** (replace with `auth_service.py`)

---

## Environment Variables Updates

### Railway Production (Add These):

```bash
# PostgreSQL (automatically added by Railway)
DATABASE_URL=postgresql://...  # Auto-set by Railway

# ZeroDB (fix existing)
ZERODB_API_KEY=<FULL_API_KEY_FROM_DASHBOARD>  # FIX THIS
ZERODB_PROJECT_ID=d9c00084-0185-4506-b9b5-3baa2369b813  # Verify exists
ZERODB_API_URL=https://api.ainative.studio/api/v1

# For consistency with code
API_Key=<FULL_API_KEY_FROM_DASHBOARD>  # Same as ZERODB_API_KEY
API_Base_URL=https://api.ainative.studio/api/v1  # Same as ZERODB_API_URL

# Database configuration
USE_POSTGRES=true
USE_ZERODB=false  # Only for vectors/memory, not tables
DATABASE_TYPE=postgresql

# Remove these (no longer needed)
# FORCE_ZERODB=true  # DELETE
# DISABLE_POSTGRES=true  # DELETE
```

### Local Development (.env.zerodb - Update):

```bash
# Match Railway configuration
ZERODB_PROJECT_ID=d9c00084-0185-4506-b9b5-3baa2369b813  # Use same project
ZERODB_API_KEY=<FULL_API_KEY>
ZERODB_API_URL=https://api.ainative.studio/api/v1

# Remove duplicate variables
# API_Key=  # DELETE (redundant)
# API_Base_URL=  # DELETE (redundant)
```

---

## Testing Plan

### Test 1: Verify API Key Fix

```bash
# After updating Railway API key
python3 /Users/cope/EnGardeHQ/production-backend/test_railway_zerodb_config.py

# Expected output:
# ✅ API Key Valid: True
# ✅ Project Exists: True
# ✅ Database Enabled: True
# ✅ Events Endpoint: True (or False, that's OK)
# ✅ Tables Endpoint: True (or False, that's OK)
```

### Test 2: PostgreSQL Connection

```bash
# Test PostgreSQL connection
railway run python3 -c "
from app.core.database import engine
import asyncio

async def test():
    async with engine.connect() as conn:
        print('✅ PostgreSQL connected')

asyncio.run(test())
"
```

### Test 3: User Authentication

```bash
# Create test user
railway run python3 scripts/create_test_user.py

# Test login endpoint
curl -X POST https://your-railway-app.railway.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@engarde.com","password":"demo123"}'

# Expected: 200 OK with JWT token
```

### Test 4: End-to-End

```bash
# Full authentication flow
1. Register new user → PostgreSQL
2. Login → PostgreSQL auth → JWT token
3. Access protected endpoint → JWT validation
4. User data stored in PostgreSQL
5. AI features use ZeroDB (vectors/memory)
```

---

## Rollback Plan

If Phase 2/3 fail, rollback to Phase 1:

1. **Keep ZeroDB with fixed API key**
2. **Create demo user manually in ZeroDB memory:**
   ```python
   # Quick workaround - store user in ZeroDB memory
   await zerodb_service.store_memory(
       content=json.dumps({
           "email": "demo@engarde.com",
           "hashed_password": bcrypt_hash,
           "is_active": True
       }),
       agent_id="system",
       session_id="users",
       role="system",
       metadata={"type": "user", "email": "demo@engarde.com"}
   )
   ```
3. **Update `get_user_by_email()` to search memory instead of events**

**This is NOT recommended long-term, but works as emergency fallback.**

---

## Success Criteria

### Phase 1 (API Key Fix):
- ✅ Railway API key works
- ✅ Can list ZeroDB projects
- ✅ Can access project d9c00084-0185-4506-b9b5-3baa2369b813
- ✅ Test script passes

### Phase 2 (PostgreSQL):
- ✅ Railway PostgreSQL deployed
- ✅ Database migrations run successfully
- ✅ Users table created and indexed
- ✅ Test user can login via PostgreSQL
- ✅ Authentication endpoints work

### Phase 3 (Refactor):
- ✅ All relational data in PostgreSQL
- ✅ ZeroDB used only for vectors/memory/events
- ✅ No event-sourcing code remaining
- ✅ All tests pass
- ✅ Performance improved (no event reconstruction)

---

## Next Steps (Priority Order)

1. **URGENT:** Get correct ZeroDB API key from dashboard
2. **URGENT:** Update Railway `ZERODB_API_KEY` variable
3. **URGENT:** Run test script to verify fix
4. **HIGH:** Add PostgreSQL to Railway
5. **HIGH:** Create User model and migrations
6. **HIGH:** Implement PostgreSQL authentication
7. **MEDIUM:** Migrate existing users (if any)
8. **MEDIUM:** Refactor ZeroDB service
9. **MEDIUM:** Update all routers to use PostgreSQL
10. **LOW:** Clean up old event-sourcing code
11. **LOW:** Update documentation

---

## Contact Information

**For ZeroDB API Key Issues:**
- Dashboard: https://api.ainative.studio
- Support: Check ZeroDB documentation for support channels

**For Railway Issues:**
- Dashboard: https://railway.app
- CLI: `railway logs` for real-time debugging

---

## Appendix: Code Snippets

### A. Quick PostgreSQL Auth Fix

```python
# app/services/auth_service.py
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from passlib.context import CryptContext
from app.models.user import User

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class AuthService:
    async def get_user_by_email(
        self,
        email: str,
        db: AsyncSession
    ) -> Optional[User]:
        result = await db.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()

    async def authenticate_user(
        self,
        email: str,
        password: str,
        db: AsyncSession
    ) -> Optional[User]:
        user = await self.get_user_by_email(email, db)

        if not user:
            return None

        if not user.is_active:
            return None

        if not pwd_context.verify(password, user.hashed_password):
            return None

        return user
```

### B. Database Dependency

```python
# app/core/database.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

engine = create_async_engine(
    os.getenv("DATABASE_URL"),
    echo=False,
    pool_pre_ping=True
)

AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session
```

### C. Updated Auth Endpoint

```python
# app/routers/auth.py
from app.services.auth_service import AuthService
from app.core.database import get_db

@router.post("/login")
async def login(
    credentials: LoginRequest,
    db: AsyncSession = Depends(get_db)
):
    auth_service = AuthService()

    user = await auth_service.authenticate_user(
        email=credentials.email,
        password=credentials.password,
        db=db
    )

    if not user:
        raise HTTPException(
            status_code=401,
            detail="Incorrect email or password"
        )

    # Create JWT token
    access_token = create_access_token(
        data={"sub": user.email, "user_id": user.id}
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "first_name": user.first_name,
            "last_name": user.last_name
        }
    }
```

---

## Timeline Summary

| Phase | Task | Duration | Priority |
|-------|------|----------|----------|
| 1 | Fix API Key | 30 min | URGENT |
| 1 | Test API Access | 15 min | URGENT |
| 2 | Add PostgreSQL | 1 hour | HIGH |
| 2 | Create Models | 2 hours | HIGH |
| 2 | Implement Auth | 1 hour | HIGH |
| 2 | Run Migrations | 30 min | HIGH |
| 3 | Refactor ZeroDB | 4 hours | MEDIUM |
| 3 | Update Routers | 3 hours | MEDIUM |
| 3 | Testing | 2 hours | MEDIUM |
| 3 | Documentation | 1 hour | LOW |
| **TOTAL** | | **~15 hours** | |

**Realistic Timeline:** 2-3 days for complete fix

---

**Status:** Ready for implementation
**Reviewed:** 2025-11-17
**Next Action:** Get correct ZeroDB API key from dashboard
