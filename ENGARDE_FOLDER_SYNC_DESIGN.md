# EnGarde Folder Sync - Design Document

## Overview

Implement a template synchronization system where:
- **Admin users** maintain master template flows in a shared "En Garde" folder
- **Non-admin users** receive synchronized copies in their individual "En Garde" folders
- Users can migrate to updated templates while preserving custom settings

## Architecture

### 1. Admin Template System

**Admin Folder Structure**:
```
En Garde (admin shared folder)
├── SEO Walker Agent
├── Content Walker Agent
├── Paid Ads Walker Agent
├── Audience Intelligence Walker Agent
└── [Other template flows]
```

**Template Identification**:
- Admin flows in "En Garde" folder are marked with `is_admin_template = True`
- Each template has a `version` field (semantic versioning: 1.0.0)
- Template flows have unique identifiers for tracking

### 2. Non-Admin User Folders

**User Folder Structure**:
```
En Garde (user's individual folder)
├── En Garde Flows/
│   ├── Simple Flow 1 (copy from admin template)
│   └── Simple Flow 2 (copy from admin template)
└── Walker Agents/
    ├── SEO Walker Agent (copy from admin template)
    ├── Content Walker Agent (copy from admin template)
    ├── Paid Ads Walker Agent (copy from admin template)
    └── Audience Intelligence Walker Agent (copy from admin template)
```

**Flow Metadata**:
- User flows have `is_admin_template = False`
- `template_source_id` → UUID of the admin template flow
- `template_version` → Version of template when copied (e.g., "1.0.0")
- `custom_settings` → JSON of user's custom configurations
- `last_synced_at` → Timestamp of last sync

### 3. Folder Organization

**Folder Types**:
1. **Admin "En Garde"** - Shared master templates (admin only)
2. **User "En Garde"** - Individual user folder with subfolders:
   - "En Garde Flows" - Simple Langflow-based flows
   - "Walker Agents" - EnGarde microservice-powered flows

### 4. Template Sync Flow

**On User Login**:
```
1. Check if user has "En Garde" folder
   ├─ No → Create folder with subfolders
   └─ Yes → Continue

2. Get all admin template flows (where is_admin_template = True)

3. For each admin template:
   ├─ Check if user has a copy (by template_source_id)
   ├─ No copy exists → Create copy in appropriate subfolder
   └─ Copy exists → Check version differences

4. Return sync status:
   ├─ new_flows_added: [list of newly copied flows]
   ├─ updates_available: [list of flows with newer versions]
   └─ user_flows: [list of all user's En Garde flows]
```

**Template Categorization**:
- Flows with "Walker Agent" in name → "Walker Agents" subfolder
- All other templates → "En Garde Flows" subfolder

## Database Schema Extensions

### Flow Model Additions

```python
class Flow(Base):
    # ... existing fields ...

    # Template System Fields
    is_admin_template = Column(Boolean, default=False, nullable=False)
    template_source_id = Column(UUID(as_uuid=True), nullable=True)  # References admin template
    template_version = Column(String, nullable=True)  # e.g., "1.0.0"
    custom_settings = Column(JSON, nullable=True)  # User's custom configurations
    last_synced_at = Column(DateTime(timezone=True), nullable=True)
```

### Indexes for Performance

```sql
-- Index for finding admin templates
CREATE INDEX idx_flow_is_admin_template ON flow (is_admin_template) WHERE is_admin_template = true;

-- Index for finding user flows by template source
CREATE INDEX idx_flow_template_source ON flow (template_source_id) WHERE template_source_id IS NOT NULL;
```

## API Endpoints

### 1. Sync User Templates

**Endpoint**: `POST /api/v1/engarde-templates/sync`

**Request**:
```json
{
  "user_id": "uuid",
  "force_sync": false  // Optional: force re-sync even if up-to-date
}
```

**Response**:
```json
{
  "status": "success",
  "sync_results": {
    "new_flows_added": [
      {
        "flow_id": "uuid",
        "name": "SEO Walker Agent",
        "template_version": "1.0.0",
        "folder": "Walker Agents"
      }
    ],
    "updates_available": [
      {
        "flow_id": "uuid",
        "name": "Content Walker Agent",
        "current_version": "1.0.0",
        "latest_version": "1.1.0",
        "changelog": "Added new optimization features"
      }
    ],
    "up_to_date_count": 2
  }
}
```

### 2. Get Available Updates

**Endpoint**: `GET /api/v1/engarde-templates/updates`

**Query Parameters**:
- `user_id`: UUID

**Response**:
```json
{
  "updates_available": [
    {
      "user_flow_id": "uuid",
      "template_id": "uuid",
      "flow_name": "SEO Walker Agent",
      "current_version": "1.0.0",
      "latest_version": "1.2.0",
      "changelog": "- Added keyword clustering\n- Improved confidence scoring",
      "breaking_changes": false,
      "can_auto_migrate": true
    }
  ]
}
```

### 3. Migrate Flow to New Version

**Endpoint**: `POST /api/v1/engarde-templates/migrate`

**Request**:
```json
{
  "user_flow_id": "uuid",
  "migration_strategy": "preserve_settings",  // "preserve_settings" | "reset_to_default"
  "custom_settings_to_keep": [
    "tenant_id",
    "api_keys",
    "preferences"
  ]
}
```

**Response**:
```json
{
  "status": "success",
  "migrated_flow": {
    "flow_id": "uuid",
    "name": "SEO Walker Agent",
    "new_version": "1.2.0",
    "preserved_settings": {...},
    "migration_notes": "Successfully migrated with all custom settings preserved"
  }
}
```

### 4. List Admin Templates

**Endpoint**: `GET /api/v1/engarde-templates/admin`

**Query Parameters**:
- `include_metadata`: boolean

**Response**:
```json
{
  "templates": [
    {
      "template_id": "uuid",
      "name": "SEO Walker Agent",
      "version": "1.2.0",
      "category": "walker_agents",
      "description": "Optimizes SEO campaigns",
      "user_count": 45,  // Number of users with this template
      "last_updated": "2026-01-19T10:00:00Z"
    }
  ]
}
```

## Implementation Steps

### Phase 1: Database Schema
1. Add template fields to Flow model
2. Create database migration
3. Deploy schema changes

### Phase 2: Template Sync Service
1. Create `TemplateSync` service class
2. Implement folder structure creation
3. Implement template copying logic
4. Add version comparison logic

### Phase 3: API Integration
1. Add sync endpoint to custom router
2. Integrate with SSO login flow
3. Add sync trigger on user login

### Phase 4: Migration System
1. Implement settings preservation logic
2. Create migration endpoint
3. Add version change detection

### Phase 5: Testing
1. Test admin template creation
2. Test new user sync
3. Test template updates
4. Test migration with custom settings

## Custom Settings Preservation

### Strategy

When migrating, preserve user-specific configurations while updating the flow structure:

**Preservable Settings**:
```json
{
  "tenant_id": "uuid",
  "api_keys": {...},
  "preferences": {...},
  "schedule": {...},
  "notifications": {...}
}
```

**Migration Logic**:
```python
def migrate_flow(user_flow, new_template):
    # 1. Extract user's custom settings
    custom_settings = extract_custom_settings(user_flow)

    # 2. Copy new template structure
    migrated_flow = copy_template(new_template)

    # 3. Reapply custom settings
    migrated_flow = apply_custom_settings(migrated_flow, custom_settings)

    # 4. Update metadata
    migrated_flow.template_version = new_template.version
    migrated_flow.last_synced_at = datetime.utcnow()

    return migrated_flow
```

## Version Management

### Semantic Versioning

Use semantic versioning for templates:
- **Major**: Breaking changes (e.g., 1.0.0 → 2.0.0)
- **Minor**: New features, backwards compatible (e.g., 1.0.0 → 1.1.0)
- **Patch**: Bug fixes (e.g., 1.0.0 → 1.0.1)

### Breaking Changes

When admin makes breaking changes:
1. Flag template with `breaking_changes = True`
2. User migration requires manual review
3. Show changelog and migration guide to user

## UI/UX Considerations

### User Notifications

**On Login**:
- Show badge with count of available updates
- Non-intrusive notification banner

**In Flow List**:
- Show version badge on each flow
- Highlight flows with available updates
- "Update Available" badge with version number

**Migration Modal**:
```
┌─────────────────────────────────────────┐
│ Update Available: SEO Walker Agent      │
│                                         │
│ Current Version: 1.0.0                  │
│ New Version: 1.2.0                      │
│                                         │
│ Changes:                                │
│ • Added keyword clustering              │
│ • Improved confidence scoring           │
│ • Bug fixes for API integration         │
│                                         │
│ Your custom settings will be preserved. │
│                                         │
│ [Keep Current] [Update Now]             │
└─────────────────────────────────────────┘
```

## Security Considerations

1. **Template Ownership**: Only admins can create/edit templates
2. **User Isolation**: Users can only sync their own folders
3. **Settings Validation**: Validate preserved settings before applying
4. **Audit Logging**: Log all sync and migration operations

## Performance Optimizations

1. **Lazy Sync**: Only sync on user login, not on every request
2. **Batch Operations**: Sync multiple templates in single transaction
3. **Caching**: Cache template versions to reduce DB queries
4. **Background Jobs**: Consider async sync for large numbers of templates

## Rollback Strategy

If migration fails:
1. Keep backup of previous flow version
2. Allow user to rollback to previous version
3. Log migration errors for debugging

## Future Enhancements

1. **Template Marketplace**: Share templates between organizations
2. **Custom Templates**: Allow users to create their own templates
3. **Auto-Migration**: Option for users to auto-update to new versions
4. **A/B Testing**: Compare performance of different template versions
5. **Template Analytics**: Track which templates are most used/successful
