# Migration Execution Steps - DO THIS NOW

## ⚠️ STEP 1: Create Database Backup (5 minutes)

### Via Railway Dashboard:
1. Go to https://railway.app
2. Open **EnGarde Suite** project
3. Click on your **PostgreSQL** service
4. Go to **Data** tab → **Backups**
5. Click **"Create Backup"** button
6. ✅ **Wait for "Backup created successfully" message**

---

## 🔧 STEP 2: Execute Migration Script (2 minutes)

### Via Railway Query Interface:

1. In the same PostgreSQL service, click **"Query"** tab
2. **Copy the ENTIRE contents** of this file:
   ```
   /Users/cope/EnGardeHQ/production-backend/migrations/20251221_fix_default_tenant_uuid.sql
   ```

3. **Paste** into the Query editor
4. Click **"Run"** or press **Cmd+Enter**
5. ✅ **Look for SUCCESS messages** like:
   ```
   NOTICE: Starting migration of tenant...
   NOTICE: Updating usage_metrics...
   NOTICE: ✓ Migration completed successfully!
   ```

---

## ✅ STEP 3: Verify Migration (1 minute)

### Run these verification queries in Railway Query tab:

```sql
-- Should return 1 row with new UUID
SELECT id, name, slug
FROM tenants
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Should return 0 rows (old ID gone)
SELECT COUNT(*) as should_be_zero
FROM tenants
WHERE id = 'default-tenant-001';

-- Check migrated records
SELECT COUNT(*) as migrated_count
FROM usage_metrics
WHERE tenant_id = '550e8400-e29b-41d4-a716-446655440000';
```

✅ **Expected Results:**
- First query: 1 row with your tenant name
- Second query: 0 rows
- Third query: Number of migrated usage metrics

---

## 🚨 What to Do After Completing Above Steps

**Once you confirm the migration succeeded, let me know and I will:**
1. Commit the code changes
2. Push to trigger Railway deployment
3. Monitor the deployment
4. Test the fixed endpoint

---

## ⏸️ PAUSE HERE

**Do not proceed until:**
- ✅ Backup is created
- ✅ Migration script has run successfully
- ✅ Verification queries show correct results

**Then respond with:** "Migration completed successfully" or share any error messages.

---

## 🆘 If You See Errors

Share the exact error message and I'll help troubleshoot immediately.

**Common issues:**
- "Tenant does not exist" → Migration not needed (already UUID)
- "Permission denied" → May need superuser access
- "Syntax error" → Copy/paste issue, try again

