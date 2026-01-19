# EnGarde Template Synchronization - Deployment Guide

## Overview

The EnGarde template synchronization system has been fully implemented. This system allows:
- **Admin users** to maintain master template flows in a shared "En Garde" folder
- **Non-admin users** to receive synchronized copies in their individual "En Garde" folders
- Users to migrate to updated templates while preserving custom settings

## What Was Implemented

### 1. Database Schema Extensions

**Migration File**: `src/backend/base/langflow/alembic/versions/engarde_add_template_fields.py`

**New Columns Added to `flow` Table**:
- `is_admin_template` (Boolean, indexed) - Marks admin master templates
- `template_source_id` (UUID, indexed) - References the admin template this flow was copied from
- `template_version` (String) - Semantic version (e.g., "1.0.0")
- `custom_settings` (JSON) - Stores user's custom configurations
- `last_synced_at` (DateTime) - Timestamp of last synchronization

### 2. Template Sync Service

**File**: `src/backend/base/langflow/services/engarde_template_sync.py`

**Class**: `TemplateSyncService`

**Key Methods**:
- `sync_user_templates()` - Main synchronization method
- `_ensure_folder_structure()` - Creates "En Garde" → "Walker Agents" + "En Garde Flows"
- `_get_admin_templates()` - Queries admin template flows
- `_get_user_templates()` - Queries user's existing template copies
- `_perform_sync()` - Compares versions and creates/updates user flows
- `_copy_template_to_user()` - Copies admin template to user folder
- `get_available_updates()` - Returns templates with newer versions available

### 3. API Endpoints

**File**: `src/backend/base/langflow/api/v1/custom.py`

All endpoints are under `/api/v1/custom/` prefix:

#### **GET /engarde-templates/updates**
Get list of available template updates for the current user.

**Response**:
```json
{
  "status": "success",
  "updates_available": [
    {
      "user_flow_id": "uuid",
      "flow_name": "SEO Walker Agent",
      "current_version": "1.0.0",
      "latest_version": "1.2.0",
      "template_id": "uuid",
      "template_updated_at": "2026-01-19T10:00:00Z"
    }
  ],
  "count": 1
}
```

#### **POST /engarde-templates/sync**
Manually trigger template synchronization for the current user.

**Response**:
```json
{
  "status": "success",
  "sync_results": {
    "new_flows_added": [
      {
        "flow_id": "uuid",
        "name": "Content Walker Agent",
        "template_version": "1.0.0",
        "folder": "Walker Agents"
      }
    ],
    "updates_available": [...],
    "up_to_date_count": 2,
    "total_templates": 4
  }
}
```

#### **POST /engarde-templates/migrate**
Migrate a user's flow to the latest template version.

**Query Parameters**:
- `user_flow_id` (string, required) - UUID of the user's flow to migrate
- `preserve_settings` (boolean, optional, default: true) - Whether to preserve custom settings

**Response**:
```json
{
  "status": "success",
  "message": "Flow migrated successfully",
  "flow_id": "uuid",
  "flow_name": "SEO Walker Agent",
  "previous_version": "1.0.0",
  "new_version": "1.2.0",
  "settings_preserved": true
}
```

#### **GET /engarde-templates/admin**
List all admin template flows (admin only).

**Response**:
```json
{
  "status": "success",
  "templates": [
    {
      "template_id": "uuid",
      "name": "SEO Walker Agent",
      "description": "Optimizes SEO campaigns",
      "version": "1.2.0",
      "category": "walker_agents",
      "user_count": 45,
      "last_updated": "2026-01-19T10:00:00Z"
    }
  ],
  "total_count": 4
}
```

### 4. SSO Integration

Template sync is automatically triggered on user login via the SSO endpoint (`/api/v1/custom/sso_login`).

**What Happens on Login**:
1. User authenticates via SSO
2. User account is created/updated in Langflow
3. Template sync service is called
4. User's "En Garde" folder structure is created if needed
5. New admin templates are copied to user's folder
6. Sync results are logged (non-blocking - login succeeds even if sync fails)

## Deployment Steps

### Step 1: Deploy Updated Code

Push the changes to Railway. The following files have been modified/created:

**Modified**:
- `src/backend/base/langflow/api/v1/custom.py`

**Created**:
- `src/backend/base/langflow/services/engarde_template_sync.py`
- `src/backend/base/langflow/alembic/versions/engarde_add_template_fields.py`
- `ENGARDE_FOLDER_SYNC_DESIGN.md` (documentation)

### Step 2: Run Database Migration

Once deployed, connect to the langflow-server service and run the Alembic migration:

```bash
# Connect to Railway service
railway shell --service langflow-server

# Run migration
cd /app/src/backend/base
alembic upgrade head
```

**Expected Output**:
```
INFO  [alembic.runtime.migration] Running upgrade 182e5471b900 -> engarde_template_001, add engarde template synchronization fields
✓ Added is_admin_template column with index
✓ Added template_source_id column with index
✓ Added template_version column
✓ Added custom_settings column
✓ Added last_synced_at column
```

**Alternative: Check if migration is auto-applied**

If Langflow has auto-migrations enabled, the migration may run automatically on startup. Check the logs:

```bash
railway logs --service langflow-server | grep "engarde_template"
```

### Step 3: Verify Deployment

**Check Langflow is Running**:
```bash
curl -I https://your-langflow-url.up.railway.app/health
```

**Expected**: HTTP 200 OK

**Check Database Columns Were Added**:
```bash
railway shell --service En-Garde-FlowDB

psql $DATABASE_URL -c "\d flow" | grep -E "(is_admin_template|template_source_id|template_version|custom_settings|last_synced_at)"
```

**Expected Output**:
```
 is_admin_template     | boolean                  |           | not null | false
 template_source_id    | uuid                     |           |          |
 template_version      | character varying        |           |          |
 custom_settings       | json                     |           |          |
 last_synced_at        | timestamp with time zone |           |          |
```

## Testing the Implementation

### Test 1: Create Admin Template (Admin User)

1. **Login as Admin User** (e.g., admin@engarde.com)
2. **Navigate to "En Garde" folder** in Langflow UI
3. **Create a new flow** named "Test Walker Agent"
4. **Mark as Admin Template**:
   - Currently requires direct database update (UI will be added later)
   ```sql
   UPDATE flow
   SET is_admin_template = true,
       template_version = '1.0.0'
   WHERE name = 'Test Walker Agent';
   ```

### Test 2: Non-Admin User First Login

1. **Login as Non-Admin User** (e.g., user@test.com) via SSO
2. **Check Langflow Logs**:
   ```bash
   railway logs --service langflow-server --tail 50
   ```
3. **Expected Log Messages**:
   ```
   INFO: Template sync completed for user@test.com: 1 new flows, 0 updates available
   INFO: Created En Garde folder for user <uuid>
   INFO: Created subfolder 'Walker Agents' for user <uuid>
   INFO: Created subfolder 'En Garde Flows' for user <uuid>
   INFO: Copied template 'Test Walker Agent' to user <uuid>
   ```
4. **Verify in UI**:
   - User should see "En Garde" folder
   - Inside: "Walker Agents" and "En Garde Flows" subfolders
   - "Test Walker Agent" should be in "Walker Agents" folder

### Test 3: Template Update and Migration

1. **As Admin**: Update the "Test Walker Agent" flow
2. **Update Version**:
   ```sql
   UPDATE flow
   SET template_version = '1.1.0'
   WHERE name = 'Test Walker Agent' AND is_admin_template = true;
   ```
3. **As Non-Admin User**: Call the updates endpoint
   ```bash
   curl -X GET "https://your-langflow-url.up.railway.app/api/v1/custom/engarde-templates/updates" \
     -H "Authorization: Bearer <user-token>"
   ```
4. **Expected Response**: Should show "Test Walker Agent" has update available
5. **Migrate to New Version**:
   ```bash
   curl -X POST "https://your-langflow-url.up.railway.app/api/v1/custom/engarde-templates/migrate?user_flow_id=<flow-uuid>&preserve_settings=true" \
     -H "Authorization: Bearer <user-token>"
   ```
6. **Verify**: User's flow should now be at version 1.1.0

### Test 4: Manual Sync

1. **As Non-Admin User**: Trigger manual sync
   ```bash
   curl -X POST "https://your-langflow-url.up.railway.app/api/v1/custom/engarde-templates/sync" \
     -H "Authorization: Bearer <user-token>"
   ```
2. **Expected Response**: Sync results with any new templates or updates

### Test 5: List Admin Templates

1. **As Admin User**: List all templates
   ```bash
   curl -X GET "https://your-langflow-url.up.railway.app/api/v1/custom/engarde-templates/admin" \
     -H "Authorization: Bearer <admin-token>"
   ```
2. **Expected Response**: List of all admin templates with usage statistics

## Folder Structure

### Admin User:
```
En Garde (shared admin folder)
├── SEO Walker Agent
├── Content Walker Agent
├── Paid Ads Walker Agent
├── Audience Intelligence Walker Agent
└── [Other template flows]
```

### Non-Admin User:
```
En Garde (user's individual folder)
├── En Garde Flows/
│   └── [Simple flows built on Langflow]
└── Walker Agents/
    ├── SEO Walker Agent (copy from admin template)
    ├── Content Walker Agent (copy from admin template)
    ├── Paid Ads Walker Agent (copy from admin template)
    └── Audience Intelligence Walker Agent (copy from admin template)
```

## Template Categorization Rules

Flows are automatically placed in the correct subfolder based on their name:

- **Name contains "Walker Agent"** → "Walker Agents" subfolder
- **All other templates** → "En Garde Flows" subfolder

## Known Limitations and Future Enhancements

### Current Limitations:

1. **No UI for Marking Templates**: Admin must use SQL to mark flows as templates
2. **No UI for Version Management**: Version updates require SQL
3. **Basic Authentication Check**: Endpoints expect `request.state.user_id` (needs proper JWT middleware)
4. **Custom Settings Merge**: Migration preserves settings but doesn't merge them into flow data yet

### Planned Enhancements:

1. **Admin UI**: Add Langflow UI controls for template management
2. **Version Comparison**: Visual diff showing changes between versions
3. **Migration Preview**: Show users what will change before migrating
4. **Rollback Feature**: Allow users to revert to previous version
5. **Auto-Migration Option**: Let users opt-in to automatic updates
6. **Template Analytics**: Track usage and performance of templates

## Troubleshooting

### Issue: "Template fields already exist" during migration

**Solution**: Migration is idempotent - it's safe to run multiple times. If columns already exist, they're skipped.

### Issue: "Template sync failed" in logs

**Cause**: Non-blocking error during login sync

**Solution**:
1. Check logs for specific error
2. User can manually trigger sync via `/engarde-templates/sync` endpoint
3. Verify database connection and permissions

### Issue: Admin templates not appearing for non-admin users

**Checklist**:
1. Verify admin flow has `is_admin_template = true`
2. Verify admin user has `is_superuser = true`
3. Check non-admin user has `is_superuser = false`
4. Trigger manual sync via API
5. Check Langflow logs for sync errors

### Issue: Migration endpoint returns "Authentication required"

**Cause**: Request middleware not setting `request.state.user_id`

**Solution**: Ensure authentication middleware is properly configured. For testing, you can temporarily modify the endpoints to accept user_id as a parameter.

## Next Steps

1. ✅ **Deploy and test template sync** (current phase)
2. 🔄 **Implement Walker Agent Setup Wizard API Integration**
   - Connect setup wizard to template sync system
   - Enable user configuration of Walker Agent templates from wizard
3. 🔜 **Add Admin UI Controls**
   - Template creation/editing interface
   - Version management controls
   - Template analytics dashboard
4. 🔜 **Enhanced Migration System**
   - Visual diff between versions
   - Migration preview and confirmation
   - Rollback capabilities

## Support

For issues or questions:
- Check logs: `railway logs --service langflow-server`
- Review design document: `ENGARDE_FOLDER_SYNC_DESIGN.md`
- Database architecture: `DATABASE_ARCHITECTURE.md`
