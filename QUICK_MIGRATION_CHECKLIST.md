# Quick Migration Checklist

## ✅ Preparation Complete

All code changes have been made. Follow these steps to complete the migration:

## 📋 Step-by-Step Checklist

### 1. ⚠️ Backup Database (DO THIS FIRST!)
```bash
# Via Railway Dashboard
# PostgreSQL service > Data > Create Backup
```
- [ ] Database backup created
- [ ] Backup verified accessible

### 2. 🔧 Run SQL Migration
```bash
# Via Railway Dashboard > PostgreSQL > Query tab
# Copy and paste: production-backend/migrations/20251221_fix_default_tenant_uuid.sql
```
- [ ] Migration script executed
- [ ] Success messages appeared
- [ ] Verification queries passed

### 3. ✅ Verify Migration
Run in Railway Query tab:
```sql
SELECT id, name FROM tenants WHERE id = '550e8400-e29b-41d4-a716-446655440000';
-- Should return 1 row with your tenant

SELECT COUNT(*) FROM tenants WHERE id = 'default-tenant-001';
-- Should return 0
```
- [ ] New UUID tenant exists
- [ ] Old ID tenant does NOT exist

### 4. 🚀 Deploy Backend Code
```bash
cd production-backend
git add .
git commit -m "Fix: Migrate tenant ID to proper UUID"
git push origin main
```
- [ ] Code committed
- [ ] Code pushed
- [ ] Railway deployment started

### 5. 👀 Monitor Deployment
- [ ] Backend service restarted successfully
- [ ] No errors in Railway logs
- [ ] Health check passing

### 6. 🧪 Test Fixed Endpoint
```bash
# Should return 200 instead of 500
curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://your-backend.railway.app/api/storage/usage
```
- [ ] Endpoint returns 200
- [ ] No UUID errors in response
- [ ] Storage data loads correctly

## 🎯 Success Criteria

All of the following should be true:
- ✅ Database has tenant with UUID `550e8400-e29b-41d4-a716-446655440000`
- ✅ Old tenant ID `default-tenant-001` no longer exists
- ✅ Backend deployed successfully
- ✅ No UUID errors in logs
- ✅ `/api/storage/usage` endpoint works
- ✅ Dashboard loads without errors

## 📁 Key Files

- **Migration Script**: `production-backend/migrations/20251221_fix_default_tenant_uuid.sql`
- **UUID Constant**: `production-backend/app/constants/tenant_ids.py`
- **Full Guide**: `TENANT_UUID_MIGRATION_GUIDE.md`

## 🆘 If Something Goes Wrong

1. Check Railway logs for error details
2. Restore from backup if needed:
   ```bash
   # Via Railway Dashboard > PostgreSQL > Data > Restore from Backup
   ```
3. Revert code changes:
   ```bash
   cd production-backend
   git revert HEAD
   git push origin main
   ```

## ⏱️ Estimated Time

- Backup: 2 minutes
- Migration: 30 seconds
- Deployment: 3-5 minutes
- Testing: 2 minutes
- **Total: ~10 minutes**

---

**Ready to start?** Begin with Step 1 (Backup Database)
