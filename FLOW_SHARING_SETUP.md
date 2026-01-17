# Flow Sharing Setup Guide

## Overview

Admin-created flows in Langflow can now be shared with all users by setting their `access_type` to `PUBLIC`.

## What Changed

1. **Modified Flow Query Logic** (langflow-custom/src/backend/base/langflow/api/v1/flows.py:336-344)
   - Users now see flows they own OR flows marked as PUBLIC
   - This allows admin flows to be visible to all users without duplication

2. **Flow Access Types**
   - `PRIVATE`: Only visible to the flow owner (default)
   - `PUBLIC`: Visible to all users in the Langflow instance

## How to Set Admin Flows to PUBLIC

### Option 1: Via Langflow UI (Recommended)

1. Log in to Langflow as admin at https://langflow.engarde.media
2. For each flow you want to share:
   - Click on the flow
   - Click the settings/gear icon
   - Find "Access Type" dropdown
   - Change from "PRIVATE" to "PUBLIC"
   - Save the flow

### Option 2: Via Database Script

The `set_admin_flows_public.py` script is included in the Docker image but requires direct database access.

To run it manually via SQL:

```sql
-- Connect to the PostgreSQL database

-- 1. Find the admin user ID
SELECT id, username FROM "user" WHERE is_superuser = true;

-- 2. List admin flows and their current access types
SELECT id, name, access_type
FROM flow
WHERE user_id = '<admin-user-id>'
ORDER BY name;

-- 3. Update all admin flows to PUBLIC
UPDATE flow
SET access_type = 'PUBLIC'
WHERE user_id = '<admin-user-id>'
AND access_type != 'PUBLIC';

-- 4. Verify the update
SELECT COUNT(*)
FROM flow
WHERE user_id = '<admin-user-id>'
AND access_type = 'PUBLIC';
```

### Option 3: Via Langflow API

```bash
# Get admin auth token first
TOKEN=$(curl -X POST https://langflow.engarde.media/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin@engarde.com","password":"<admin-password>"}' | jq -r '.access_token')

# List all admin flows
curl -X GET https://langflow.engarde.media/api/v1/flows/ \
  -H "Authorization: Bearer $TOKEN" | jq '.[] | {id, name, access_type}'

# Update a specific flow to PUBLIC
curl -X PATCH https://langflow.engarde.media/api/v1/flows/<flow-id> \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"access_type":"PUBLIC"}'
```

## Verification

After setting flows to PUBLIC, verify by:

1. Log out of admin account
2. Log in as demo@engarde.com
3. Check the flows list - admin PUBLIC flows should now appear
4. PUBLIC flows will show the original owner's username

## Current Admin Flows

Based on the Walker Agent setup, the following flows should be set to PUBLIC:

1. **SEO Walker Agent Flow** - Optimizes SEO campaigns
2. **Content Walker Agent Flow** - Suggests content improvements
3. **Paid Ads Walker Agent Flow** - Optimizes paid advertising
4. **Audience Intelligence Walker Agent Flow** - Analyzes audience data

## Important Notes

- **Flow Ownership**: PUBLIC flows remain owned by admin, other users can view/use but not edit
- **Deployment Safety**: The code changes preserve all existing flows during deployments
- **Database Persistence**: All flows are stored in PostgreSQL and persist across deployments
- **No Duplication**: With PUBLIC access, flows don't need to be copied per user

## Technical Details

### Flow Model Schema
```python
class Flow:
    id: UUID
    name: str
    user_id: UUID  # Owner of the flow
    access_type: AccessTypeEnum  # PRIVATE or PUBLIC
    data: dict  # Flow definition
    # ... other fields
```

### Query Logic
```python
# Users see flows they own OR flows marked PUBLIC
stmt = select(Flow).where(
    (Flow.user_id == current_user.id) | (Flow.access_type == AccessTypeEnum.PUBLIC)
)
```

## Troubleshooting

**Issue**: demo@engarde.com doesn't see admin flows

**Solutions**:
1. Verify flows are set to PUBLIC (check via SQL or API)
2. Clear browser cache and reload Langflow UI
3. Check that demo@engarde.com is logged in correctly
4. Verify the deployment is using the latest code (commit 7553187f0 or later)

**Issue**: PUBLIC flows show as editable for non-admin users

**Note**: Langflow's default behavior allows PUBLIC flows to be viewed and executed by all users. Edit permissions are controlled separately. If needed, additional permission checks can be added to the update flow endpoint.
