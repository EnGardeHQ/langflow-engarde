# Brand Switch 500 Error Fix

## Root Cause

The brand switch endpoint was returning a 500 Internal Server Error due to a PostgreSQL type mismatch:

```
psycopg2.errors.DatatypeMismatch: column "recent_brand_ids" is of type json but expression is of type text[]
```

### Problem Analysis

1. **Column Type**: The `recent_brand_ids` column in `user_active_brands` table was defined as `JSON` type
2. **Data Assignment**: When updating the column with a Python list, PostgreSQL was interpreting it as a PostgreSQL array type (`text[]`) instead of JSON
3. **Type Mismatch**: PostgreSQL's `JSON` type expects JSON-formatted strings, not array literals

## Solution

### 1. Changed Column Type to JSONB

**File**: `app/models/brand_models.py`
- Changed `recent_brand_ids` column from `JSON` to `JSONB`
- JSONB is PostgreSQL's binary JSON format which:
  - Better handles Python list/dict assignments
  - Provides better indexing and query performance
  - More compatible with SQLAlchemy's JSON type

### 2. Updated Code to Ensure String Format

**File**: `app/routers/brands.py`
- Ensured all brand IDs in the list are converted to strings
- Added explicit string conversion: `[str(bid) for bid in recent[:5]]`
- This ensures compatibility with JSON/JSONB serialization

### 3. Database Migration

**Script**: `scripts/migrations/fix_recent_brand_ids_jsonb.py`
- Converts existing `JSON` column to `JSONB`
- Handles existing data safely
- Can be run multiple times safely (idempotent)

## Changes Made

### Backend Model (`app/models/brand_models.py`)
```python
# Before
from sqlalchemy import Column, String, ForeignKey, JSON, ...

recent_brand_ids = Column(JSON, default=[])

# After
from sqlalchemy import Column, String, ForeignKey, JSON, ...
from sqlalchemy.dialects.postgresql import JSONB

recent_brand_ids = Column(JSONB, default=[])
```

### Backend Router (`app/routers/brands.py`)
```python
# Ensure brand IDs are strings for JSON compatibility
recent_list = [str(bid) for bid in recent[:5]]
active_brand_setting.recent_brand_ids = recent_list
```

### Database Migration
- Column type changed from `JSON` to `JSONB` in production database
- Existing data preserved and converted automatically

## Testing

After deployment, test brand switching:
1. Switch to a brand → Should succeed without 500 error
2. Switch multiple times → Recent brands list should update correctly
3. Check database → `recent_brand_ids` should be stored as JSONB

## Why JSONB Instead of JSON?

1. **Better Type Handling**: JSONB properly handles Python lists/dicts without type conversion issues
2. **Performance**: JSONB is stored in binary format, faster for queries
3. **Indexing**: JSONB supports GIN indexes for efficient JSON queries
4. **SQLAlchemy Compatibility**: Better integration with SQLAlchemy's ORM

## Prevention

To prevent similar issues in the future:
1. Use JSONB instead of JSON for new columns that store structured data
2. Always convert UUIDs to strings before storing in JSON/JSONB columns
3. Test database migrations in staging before production
4. Monitor logs for type mismatch errors

## Status

✅ **Fixed**: Column type migrated to JSONB
✅ **Deployed**: Changes pushed to production
✅ **Tested**: Migration script executed successfully

The brand switch functionality should now work correctly without 500 errors.
