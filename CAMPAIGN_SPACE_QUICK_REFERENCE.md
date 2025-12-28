# Campaign Space Backend - Quick Reference

## Deployment Checklist

- [x] Database migration created
- [x] Service layer implemented
- [x] API routers created
- [x] Routes registered in main.py
- [ ] **Run SQL migration on Railway database**
- [ ] Deploy backend to Railway
- [ ] Test endpoints

## Quick Deployment

### Step 1: Create Tables on Railway

```bash
# Connect to Railway PostgreSQL
railway run psql

# Or use the Railway dashboard SQL console
# Copy and paste contents of: create_campaign_spaces_tables.sql
```

### Step 2: Commit and Deploy

```bash
git add .
git commit -m "Add campaign space import backend"
git push origin main
```

## All 17 API Endpoints

### Campaign Spaces (9 endpoints)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/campaign-spaces` | Create campaign space |
| GET | `/api/campaign-spaces` | List campaign spaces |
| GET | `/api/campaign-spaces/templates` | List templates |
| GET | `/api/campaign-spaces/{id}` | Get single space |
| PUT | `/api/campaign-spaces/{id}` | Update space |
| DELETE | `/api/campaign-spaces/{id}` | Delete space |
| POST | `/api/campaign-spaces/{id}/mark-as-template` | Mark as template |
| GET | `/api/campaign-spaces/{id}/stats` | Get statistics |
| POST | `/api/campaign-spaces/{id}/update-performance` | Update metrics |

### Campaign Assets (8 endpoints)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/campaign-assets/campaign-spaces/{space_id}/assets` | Upload asset |
| POST | `/api/campaign-assets/campaign-spaces/{space_id}/assets/import` | Import from platform |
| GET | `/api/campaign-assets/campaign-spaces/{space_id}/assets` | List assets for space |
| GET | `/api/campaign-assets/assets` | List all assets |
| GET | `/api/campaign-assets/{id}` | Get single asset |
| PUT | `/api/campaign-assets/{id}` | Update asset |
| DELETE | `/api/campaign-assets/{id}` | Delete asset |
| POST | `/api/campaign-assets/{id}/reuse` | Track reuse |

## Supported Platforms

- `google_ads` - Google Ads
- `meta` - Facebook/Instagram
- `linkedin` - LinkedIn
- `twitter` - Twitter/X
- `tiktok` - TikTok
- `snapchat` - Snapchat
- `pinterest` - Pinterest
- `reddit` - Reddit
- `amazon_ads` - Amazon Advertising
- `microsoft_ads` - Microsoft Advertising
- `youtube` - YouTube
- `other` - Other platforms

## Asset Types

- `image` - Images (PNG, JPG, etc.)
- `video` - Videos (MP4, MOV, etc.)
- `ad_copy` - Ad copy text
- `headline` - Headlines
- `description` - Descriptions
- `call_to_action` - CTA text
- `document` - Documents (PDF, etc.)
- `performance_data` - Performance reports
- `other` - Other types

## Import Sources

- `manual_upload` - Manual file upload
- `platform_api` - API integration (future)
- `csv_import` - CSV import
- `bulk_import` - Bulk import

## Common Query Parameters

- `tenant_id` - Required for multi-tenancy
- `user_id` - Optional user filter
- `brand_id` - Optional brand filter
- `platform` - Filter by platform
- `tags` - Comma-separated tags
- `search` - Full-text search
- `limit` - Results per page (1-100)
- `offset` - Pagination offset
- `order_by` - Sort field
- `order_desc` - Sort direction

## Quick Test Commands

### Create Campaign Space
```bash
curl -X POST "http://localhost:8000/api/campaign-spaces?tenant_id=abc123&user_id=user456" \
  -H "Content-Type: application/json" \
  -d '{"campaign_name":"Test Campaign","platform":"google_ads","import_source":"manual_upload"}'
```

### List Campaign Spaces
```bash
curl "http://localhost:8000/api/campaign-spaces?tenant_id=abc123"
```

### Upload Asset
```bash
curl -X POST "http://localhost:8000/api/campaign-assets/campaign-spaces/{space_id}/assets" \
  -F "file=@test.jpg" \
  -F "asset_name=Test Image" \
  -F "asset_type=image" \
  -F "tenant_id=abc123" \
  -F "user_id=user456"
```

## File Locations

```
production-backend/
├── alembic/versions/
│   └── 20251220_create_campaign_spaces_tables.py  (Migration)
├── create_campaign_spaces_tables.sql              (Direct SQL)
├── app/
│   ├── models/
│   │   └── campaign_space_models.py               (Already exists)
│   ├── services/
│   │   ├── campaign_space_service.py              (NEW)
│   │   ├── campaign_asset_service.py              (NEW)
│   │   └── cloud_storage_service.py               (Already exists)
│   ├── routers/
│   │   ├── campaign_spaces.py                     (NEW)
│   │   └── campaign_assets.py                     (NEW)
│   └── main.py                                    (Modified)
└── CAMPAIGN_SPACE_BACKEND_IMPLEMENTATION.md       (Docs)
```

## Key Features

- Multi-tenant isolation
- Cloud storage integration (GCS)
- Asset deduplication (SHA-256)
- Performance tracking (BigQuery)
- Template system
- Soft delete support
- Asset reuse tracking
- Advanced filtering
- Full-text search
- Pagination

## Architecture

```
Frontend → API Router → Service Layer → Database
                ↓
          Cloud Storage (GCS)
                ↓
          BigQuery (Performance)
```

## Database Tables

- `campaign_spaces` - Campaign containers
- `campaign_assets` - Individual assets
- Related to: `tenants`, `brands`, `users`

## Security

- Multi-tenant scoping on all queries
- User authorization checks
- Input validation (Pydantic)
- SQL injection prevention
- Soft delete for audit trails

## Next Steps After Deployment

1. Test all 17 endpoints
2. Integrate with frontend
3. Implement platform OAuth flows
4. Set up BigQuery sync jobs
5. Add asset variant generation
6. Implement bulk operations

## Support

See full documentation: `CAMPAIGN_SPACE_BACKEND_IMPLEMENTATION.md`
