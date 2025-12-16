# Quick Fix Guide: Analytics Router Issue

## Problem
The `/api/analytics/performance` endpoint returns 404 because the analytics router failed to load due to duplicate `PredictiveModel` class definitions.

## Root Cause
The `PredictiveModel` class is defined **3 times**:
1. `/Users/cope/EnGardeHQ/production-backend/app/models.py` (line 690)
2. `/Users/cope/EnGardeHQ/production-backend/app/models/core.py` (line 903)
3. `/Users/cope/EnGardeHQ/production-backend/app/models/analytics_models.py` (line 191) ← **KEEP THIS ONE**

## Solution

### Step 1: Remove Duplicate from models/core.py

**File:** `/Users/cope/EnGardeHQ/production-backend/app/models/core.py`

Find and DELETE the entire `PredictiveModel` class definition (approximately lines 903-930).

Look for:
```python
class PredictiveModel(Base):
    """ML model definitions and predictions"""
    __tablename__ = "predictive_models"
    # ... rest of class
```

### Step 2: Remove Duplicate from models.py

**File:** `/Users/cope/EnGardeHQ/production-backend/app/models.py`

Find and DELETE the entire `PredictiveModel` class definition (approximately lines 690-717).

Look for:
```python
class PredictiveModel(Base):
    """ML model definitions and predictions"""
    __tablename__ = "predictive_models"
    # ... rest of class
```

### Step 3: Verify Import

**File:** `/Users/cope/EnGardeHQ/production-backend/app/models/__init__.py`

Ensure the import uses the analytics_models version:
```python
from app.models.analytics_models import PredictiveModel
```

If this import doesn't exist, add it.

### Step 4: Restart Backend

```bash
# If using Docker
docker-compose restart backend

# If running directly
# Stop the current process (Ctrl+C) and restart:
cd /Users/cope/EnGardeHQ/production-backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Step 5: Verify Fix

Check startup logs for:
```
✅ Successfully loaded router: analytics
```

Instead of:
```
⚠️ Failed to load router analytics: Table 'predictive_models' is already defined...
```

### Step 6: Test Endpoint

```bash
# Test the endpoint (replace with your actual auth token)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8000/api/analytics/performance
```

Expected: 200 OK with analytics data
NOT: 404 Not Found

## Expected Results

After the fix:
- ✅ Analytics router loads successfully
- ✅ `/api/analytics/performance` endpoint available
- ✅ All advanced analytics endpoints accessible
- ✅ Router load rate increases from 51.5% to 53.0%

## Rollback Plan

If something goes wrong:
1. The original models are still in git history
2. Use: `git checkout HEAD -- app/models/core.py app/models.py`
3. Restart backend

## Additional Fixes (Optional)

### Fix OAuth Manager Error (Restores 6 Routers)

Check `/Users/cope/EnGardeHQ/production-backend/app/services/oauth_manager.py` line 404 for syntax errors.

This will restore:
- platform_integrations
- pos_integrations
- pos_production_api
- shopify_payments
- oauth
- webhooks

### Install Missing Dependencies (Restores 8 Routers)

```bash
pip install dagger-io prometheus-client bleach opentelemetry-exporter-prometheus
```

This will restore:
- ai_creative_studio
- langflow_workflows
- workflow_execution
- csv_import
- marketplace_monitoring
- audience_intelligence
- security_management
- security_utilities

## Verification Checklist

- [ ] Removed PredictiveModel from models/core.py
- [ ] Removed PredictiveModel from models.py
- [ ] Verified import in models/__init__.py
- [ ] Restarted backend
- [ ] Checked logs for analytics router success
- [ ] Tested /api/analytics/performance endpoint
- [ ] Endpoint returns 200 (not 404)
- [ ] Advanced analytics features working

## Need Help?

If the fix doesn't work:
1. Check the backend logs for new errors
2. Verify all three model files were modified correctly
3. Ensure no other files import PredictiveModel from the wrong location
4. Run: `grep -r "from.*models.*import.*PredictiveModel" app/`

## Estimated Time
**5-10 minutes** to complete all steps and verify.
