**Diagnosis Report**

**Problem:**
The application is throwing 500 errors on the `/api/agents/installed` and `/api/agents/config` endpoints. This is because these endpoints rely on the user's active brand, and the brand switching functionality is broken.

**Root Cause:**
The `switch_brand` function in `production-backend/app/routers/brands.py` is attempting to save a Python list of strings into the `recent_brand_ids` column of the `user_active_brands` table. The `recent_brand_ids` column is of type `jsonb`, but the application is providing a `text[]` array. This causes a `psycopg2.errors.DatatypeMismatch` error, which rolls back the transaction and prevents the brand switch from being saved.

**Evidence:**
The Railway logs clearly show the following error:
`ERROR: column "recent_brand_ids" is of type jsonb but expression is of type text[] at character 97`

The relevant code in `production-backend/app/routers/brands.py` is:
```python
            # With ARRAY(String) column type, SQLAlchemy handles Python lists correctly
            active_brand_setting.recent_brand_ids = recent[:5]
```
The comment is incorrect. The `recent_brand_ids` column is `jsonb` not `ARRAY(String)`.
