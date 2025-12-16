# BUG REPORT: Brands API Endpoint Failure

## Executive Summary

**Critical Bug Identified:** Database schema mismatch causing HTTP 500 error on `/api/brands/` endpoint

**Status:** PRODUCTION BLOCKER
**Severity:** HIGH
**Test Date:** 2025-11-03
**Environment:** Local Development (localhost:8000)

---

## Test Results Summary

| Endpoint | HTTP Status | Result | Error Message |
|----------|-------------|--------|---------------|
| `/api/token` | 200 OK | SUCCESS | Authentication working |
| `/api/brands/` | 500 Internal Server Error | FAILED | "Failed to retrieve brands" |
| `/api/brands/current` | 200 OK | SUCCESS | Returns brand data correctly |

---

## Root Cause Analysis

### Primary Issue: Database Schema Mismatch

The `brand_onboarding` table is **missing 7 required columns** that are defined in the SQLAlchemy model but do not exist in the actual PostgreSQL database.

### Missing Columns in `brand_onboarding` Table:

```
1. step_basic_info_data (JSONB)
2. step_industry_data (JSONB)
3. step_contact_data (JSONB)
4. step_settings_data (JSONB)
5. step_confirmation_data (JSONB)
6. onboarding_metadata (JSONB)
7. started_at (TIMESTAMP)
```

### Current Database Schema (Actual):
```
id                                       VARCHAR(36)
brand_id                                 VARCHAR(36)
tenant_id                                VARCHAR(36)
current_step                             INTEGER
total_steps                              INTEGER
progress_percentage                      INTEGER
is_completed                             BOOLEAN
completed_at                             TIMESTAMP
step_basic_info_status                   VARCHAR(50)
step_basic_info_completed_at             TIMESTAMP
step_industry_status                     VARCHAR(50)
step_industry_completed_at               TIMESTAMP
step_contact_status                      VARCHAR(50)
step_contact_completed_at                TIMESTAMP
step_settings_status                     VARCHAR(50)
step_settings_completed_at               TIMESTAMP
step_confirmation_status                 VARCHAR(50)
step_confirmation_completed_at           TIMESTAMP
created_at                               TIMESTAMP
updated_at                               TIMESTAMP
```

### Expected Database Schema (From Model):
Should include all of the above PLUS:
```
step_basic_info_data                     JSONB
step_industry_data                       JSONB
step_contact_data                        JSONB
step_settings_data                       JSONB
step_confirmation_data                   JSONB
onboarding_metadata                      JSONB
started_at                               TIMESTAMP
```

---

## Technical Details

### Error Stacktrace

**PostgreSQL Error:**
```
psycopg2.errors.UndefinedColumn: column brand_onboarding_1.step_basic_info_data does not exist
LINE 1: ... brand_onboarding_1_step_basic_info_completed_at, brand_onbo...
```

**SQLAlchemy Error:**
```python
sqlalchemy.exc.ProgrammingError: (psycopg2.errors.UndefinedColumn)
column brand_onboarding_1.step_basic_info_data does not exist
```

### Failing Code Location

**File:** `/Users/cope/EnGardeHQ/production-backend/app/routers/brands.py`
**Function:** `list_brands()`
**Lines:** 318-321

```python
brands = query.options(
    joinedload(brand_models.Brand.members),
    joinedload(brand_models.Brand.onboarding_progress)  # ← THIS CAUSES THE ERROR
).order_by(desc(brand_models.Brand.created_at)).offset(offset).limit(page_size).all()
```

### Why `/api/brands/current` Works

The `/current` endpoint (lines 384-493) does NOT use eager loading with `joinedload()` for the onboarding_progress relationship. It queries brands and onboarding data separately, avoiding the schema mismatch issue.

### Database Query That Fails

SQLAlchemy generates a LEFT OUTER JOIN that tries to select all columns from `brand_onboarding`, including the missing ones:

```sql
SELECT ...
    brand_onboarding_1.step_basic_info_data AS brand_onboarding_1_step_basic_info_data,
    brand_onboarding_1.step_industry_data AS brand_onboarding_1_step_industry_data,
    -- ... other missing columns ...
FROM (
    SELECT brands.*
    FROM brands
    JOIN brand_members ON ...
) AS anon_1
LEFT OUTER JOIN brand_onboarding AS brand_onboarding_1
    ON anon_1.brands_id = brand_onboarding_1.brand_id
```

---

## Verification Steps Performed

### 1. Authentication Test
```bash
curl -s -X POST "http://localhost:8000/api/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=demo123"
```

**Result:** SUCCESS - Token obtained
```json
{
  "access_token": "eyJhbGci...",
  "token_type": "bearer",
  "user": {
    "id": "demo-user-id",
    "email": "demo@engarde.com",
    "user_type": "brand"
  }
}
```

### 2. List Brands Endpoint Test
```bash
curl -v -X GET "http://localhost:8000/api/brands/" \
  -H "Authorization: Bearer <token>"
```

**Result:** FAILED
- HTTP Status: 500 Internal Server Error
- Response: `{"detail":"Failed to retrieve brands"}`

### 3. Current Brand Endpoint Test
```bash
curl -v -X GET "http://localhost:8000/api/brands/current" \
  -H "Authorization: Bearer <token>"
```

**Result:** SUCCESS
- HTTP Status: 200 OK
- Response: Full brand data with 4 brands returned

### 4. Database Schema Verification
```python
# Python script to inspect database schema
from sqlalchemy import inspect
inspector = inspect(engine)
columns = inspector.get_columns('brand_onboarding')
```

**Result:** Confirmed missing columns

### 5. Direct Database Query Test
```python
# Test without eager loading
query = db.query(brand_models.Brand).join(brand_models.BrandMember, ...)
brands = query.all()  # Works fine
```

**Result:** SUCCESS - Returns 4 brands

### 6. Test with Eager Loading
```python
# Test with eager loading (replicates endpoint behavior)
brands = query.options(
    joinedload(brand_models.Brand.onboarding_progress)
).all()
```

**Result:** FAILED - Same PostgreSQL error

---

## Migration Status

### Alembic Migration Exists
**File:** `/Users/cope/EnGardeHQ/production-backend/alembic/versions/brand_management_system.py`
**Revision:** `brand_mgmt_001`
**Migration Includes:** All 7 missing columns (lines 162-176)

The migration was created with proper schema including:
```python
step_basic_info_data JSONB DEFAULT '{}',
step_industry_data JSONB DEFAULT '{}',
step_contact_data JSONB DEFAULT '{}',
step_settings_data JSONB DEFAULT '{}',
step_confirmation_data JSONB DEFAULT '{}',
onboarding_metadata JSONB DEFAULT '{}',
started_at TIMESTAMP DEFAULT NOW(),
```

### Migration Was NOT Applied
**Evidence:**
1. `alembic_version` table does not exist in database
2. Database schema does not match migration definition
3. Tables were likely created manually or via direct SQL `CREATE TABLE IF NOT EXISTS`

---

## Impact Assessment

### Affected Functionality
1. **List Brands API** - Completely broken (HTTP 500)
2. **Brand Management UI** - Cannot load brand list
3. **Brand Switching** - Partially impacted (can still switch via /current)
4. **Create Brand** - May fail when trying to create onboarding records

### User Impact
- **HIGH:** Users cannot view their list of brands
- **MEDIUM:** Brand management features degraded
- **LOW:** Current brand still accessible via workaround endpoint

### Data Integrity
- **GOOD:** No data loss or corruption
- **CONCERN:** If users try to create brands, onboarding records will fail to save `*_data` fields

---

## Recommended Solutions

### Option 1: Run Database Migration (RECOMMENDED)

**Priority:** HIGH
**Complexity:** LOW
**Risk:** LOW

Fix the Alembic migration chain and apply pending migrations:

```bash
cd /Users/cope/EnGardeHQ/production-backend

# Fix migration dependencies
# Then run migrations
python3 -m alembic upgrade head
```

**Pros:**
- Proper migration tracking
- Reversible with downgrade
- Follows best practices
- Future migrations will work correctly

**Cons:**
- Need to fix broken Alembic chain first
- Requires database access

### Option 2: Manual ALTER TABLE (QUICK FIX)

**Priority:** MEDIUM
**Complexity:** LOW
**Risk:** MEDIUM

Directly add missing columns to database:

```sql
ALTER TABLE brand_onboarding
ADD COLUMN IF NOT EXISTS step_basic_info_data JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS step_industry_data JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS step_contact_data JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS step_settings_data JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS step_confirmation_data JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS onboarding_metadata JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS started_at TIMESTAMP DEFAULT NOW();
```

**Pros:**
- Immediate fix
- No Alembic dependencies
- Simple to execute

**Cons:**
- Bypasses migration system
- No migration history
- Not reversible via Alembic

### Option 3: Remove Eager Loading (TEMPORARY WORKAROUND)

**Priority:** LOW
**Complexity:** LOW
**Risk:** LOW

Modify `/api/brands/` endpoint to not use `joinedload(brand_models.Brand.onboarding_progress)`:

```python
# Remove this line:
# joinedload(brand_models.Brand.onboarding_progress)

# Or query onboarding separately like /current endpoint does
```

**Pros:**
- Quick code fix
- No database changes needed
- Low risk

**Cons:**
- Doesn't fix root cause
- Potential N+1 query performance issue
- Other endpoints may have same problem

---

## Immediate Action Items

### Priority 1: Emergency Hotfix
1. Apply manual ALTER TABLE statement to add missing columns
2. Verify `/api/brands/` endpoint returns 200 OK
3. Test brand creation still works

### Priority 2: Proper Fix
1. Investigate Alembic migration chain issues
2. Fix broken migration dependencies
3. Create new migration to add columns if needed
4. Document migration process

### Priority 3: Prevention
1. Add database schema validation tests
2. Implement pre-deployment migration checks
3. Add monitoring for database schema drift
4. Document database setup procedures

---

## Testing Checklist

After applying fix, verify:

- [ ] `GET /api/brands/` returns 200 OK
- [ ] `GET /api/brands/` returns list of brands with correct data
- [ ] `GET /api/brands/current` still works (no regression)
- [ ] `POST /api/brands/` can create new brands
- [ ] Brand onboarding data saves correctly
- [ ] All brand JSONB fields serialize properly
- [ ] No PostgreSQL errors in backend logs

---

## Related Files

### Backend Code
- `/Users/cope/EnGardeHQ/production-backend/app/routers/brands.py` (line 318-321)
- `/Users/cope/EnGardeHQ/production-backend/app/models/brand_models.py` (BrandOnboarding model)

### Database Migration
- `/Users/cope/EnGardeHQ/production-backend/alembic/versions/brand_management_system.py`

### Configuration
- `/Users/cope/EnGardeHQ/production-backend/alembic.ini`
- `/Users/cope/EnGardeHQ/production-backend/alembic/env.py`

---

## Additional Notes

### Why This Happened
The database was likely initialized using `CREATE TABLE IF NOT EXISTS` statements that ran before the complete model definition was finalized. The brand_onboarding table was created with a subset of columns, and later model updates added new fields that were never migrated to the database.

### Future Prevention
1. Always use Alembic migrations for schema changes
2. Never use `CREATE TABLE IF NOT EXISTS` in production migrations
3. Add CI/CD checks to compare model definitions with database schema
4. Implement database schema validation in startup scripts

---

## Test Report Generated By
**QA Engineer:** Claude Code (Quality Assurance Mode)
**Test Date:** 2025-11-03
**Test Environment:** MacOS, PostgreSQL, FastAPI/Python 3.9
**Methodology:** API endpoint testing, database schema inspection, code review, root cause analysis
