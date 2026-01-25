# Content Storage Architecture - Executive Summary

## Quick Reference Guide

### Storage Layer Responsibilities

```
┌─────────────────────────────────────────────────────────────────┐
│                    STORAGE ARCHITECTURE                          │
├────────────────┬──────────────────────┬─────────────────────────┤
│  PostgreSQL    │      ZeroDB          │      BigQuery           │
│  (Metadata)    │  (Primary Content)   │  (DR + Analytics)       │
├────────────────┼──────────────────────┼─────────────────────────┤
│ • Relationships│ • Full content bodies│ • Disaster recovery     │
│ • Permissions  │ • Media references   │ • Performance metrics   │
│ • Quota usage  │ • Version history    │ • Historical analysis   │
│ • Status/flags │ • Fast retrieval     │ • Long-term storage     │
│ • Timestamps   │ • Search/query       │ • Cost-optimized        │
└────────────────┴──────────────────────┴─────────────────────────┘
```

## Critical Design Decisions

### 1. Why ZeroDB as Primary?
- **Fast Reads**: Optimized for content retrieval (< 100ms)
- **Scalability**: Handles 10,000+ content items per tenant
- **Search**: Built-in full-text search
- **Hybrid**: Vector + relational in one database

### 2. Why BigQuery as Secondary?
- **Cost**: $0.02/GB/month vs ZeroDB's operational costs
- **Analytics**: Time-series queries without impacting production
- **DR**: Complete snapshots for recovery
- **Compliance**: Long-term retention requirements

### 3. Why PostgreSQL for Metadata Only?
- **Small Footprint**: Only stores references (~100 bytes per item)
- **RLS**: Row-level security already implemented
- **ACID**: Critical for permissions and quotas
- **Relationships**: Foreign keys to brands, campaigns, users

## Data Flow Summary

### Upload Flow (3 Steps)
```
1. User Upload → Check Quota (PostgreSQL)
2. Store Content → ZeroDB (full body)
3. Store Metadata → PostgreSQL (reference)
   ↓ (async)
4. Backup → BigQuery (disaster recovery)
```

### Retrieval Flow (2 Steps)
```
1. Query Metadata → PostgreSQL (fast index lookup)
2. Fetch Content → ZeroDB (batch fetch)
   ↓
3. Merge & Return → Frontend
```

### AI Generation Flow (Batch-Optimized)
```
1. Check Quota → PostgreSQL (total projected size)
2. Generate 100 items → LLM API (parallel)
3. Batch Insert → ZeroDB (50 at a time)
4. Bulk Metadata → PostgreSQL (single transaction)
   ↓ (background)
5. Async Backup → BigQuery (non-blocking)
```

## Schema Changes Required

### PostgreSQL Additions
```sql
-- Add to content_items table
ALTER TABLE content_items ADD COLUMN zerodb_id VARCHAR(36);
ALTER TABLE content_items ADD COLUMN bigquery_backed_up BOOLEAN DEFAULT FALSE;
ALTER TABLE content_items ADD COLUMN storage_size_bytes INTEGER DEFAULT 0;

-- New tables
CREATE TABLE content_storage_usage (...);  -- Quota tracking
CREATE TABLE content_generation_jobs (...);  -- Batch job tracking
```

### ZeroDB Collections
```
- content_items (primary content storage)
- content_media_files (media metadata)
- content_versions (version history)
```

### BigQuery Tables
```
- content_snapshots (disaster recovery)
- content_media_snapshots (media backup)
- content_analytics (performance metrics)
```

## Migration Path

### Phase 1: Foundation (Week 1)
```
✓ Run PostgreSQL migrations
✓ Create ZeroDB collections
✓ Create BigQuery tables
✓ Deploy ContentQuotaService
```

### Phase 2: Data Migration (Week 2)
```
✓ Migrate existing campaign_assets → ZeroDB
✓ Migrate existing content_items → ZeroDB
✓ Backfill storage usage metrics
✓ Verify data integrity
```

### Phase 3: API Updates (Week 3)
```
✓ Update POST /api/content (add quota check + ZeroDB storage)
✓ Update GET /api/content (fetch from ZeroDB)
✓ Update PATCH /api/content (version control)
✓ Implement batch generation endpoints
```

### Phase 4: Background Jobs (Week 4)
```
✓ Deploy BigQuery sync worker
✓ Test disaster recovery
✓ Set up monitoring
✓ Performance optimization
```

## Quota Management

### Storage Limits
| Tier         | Limit    | Quota Counted Against |
|--------------|----------|------------------------|
| Free         | 1 GB     | ZeroDB content only    |
| Starter      | 10 GB    | ZeroDB content only    |
| Professional | 100 GB   | ZeroDB content only    |
| Business     | 500 GB   | ZeroDB content only    |
| Enterprise   | Unlimited| No limit               |

**Important:** BigQuery backup does NOT count toward quota (it's disaster recovery).

### Quota Check Flow
```
Before Content Upload:
1. Calculate content size (bytes)
2. Query current usage (content_storage_usage table)
3. Get plan tier limit (storage_tiers.py)
4. projected_usage = current + new_content
5. IF projected_usage > limit THEN REJECT
6. ELSE ALLOW and increment usage
```

## API Changes Summary

### New Endpoints
```
POST /api/content/generate-batch
  → Generate multiple content items with AI

GET /api/content/generation-jobs/{job_id}
  → Check batch generation status

POST /api/content/generation-jobs/{job_id}/cancel
  → Cancel running batch job

GET /api/content/quota
  → Get storage usage and limits
```

### Modified Endpoints
```
POST /api/content
  + Add quota check before creation
  + Store in ZeroDB first
  + Store metadata in PostgreSQL

GET /api/content
  + Fetch from ZeroDB in batch
  + Merge with PostgreSQL metadata

PATCH /api/content/{id}
  + Create version snapshot
  + Update in ZeroDB

DELETE /api/content/{id}
  + Soft delete (keep in ZeroDB/BigQuery)
  + Decrement quota
```

## Error Handling & Fallbacks

### ZeroDB Unavailable
```
Scenario: ZeroDB service down

1. GET /api/content
   → Fallback to PostgreSQL content_body (if not cleared)
   → Or return metadata only with error message
   → Or failover to BigQuery (slower)

2. POST /api/content
   → Return 503 Service Unavailable
   → Queue for retry when ZeroDB recovers
```

### BigQuery Unavailable
```
Scenario: BigQuery sync fails

1. Content still stored in ZeroDB (primary)
2. PostgreSQL flag: bigquery_backed_up = FALSE
3. Retry sync in background worker
4. Alert admin if sync fails > 24 hours
```

### Quota Exceeded
```
Scenario: User hits storage limit

1. POST /api/content → 403 Forbidden
   Response: {
     "error": "Storage limit exceeded",
     "current_usage_gb": 9.8,
     "limit_gb": 10.0,
     "plan_tier": "starter",
     "upgrade_url": "/settings/subscription"
   }

2. Show upgrade prompt in UI
```

## Performance Targets

### Latency
- Content list (20 items): < 200ms
- Single content fetch: < 100ms
- Content create: < 300ms
- Batch generation (100 items): < 2 minutes

### Throughput
- Content reads: 1000 req/sec
- Content writes: 100 req/sec
- Concurrent batch jobs: 10 per tenant

### Storage
- ZeroDB: < 1GB per 10,000 content items
- PostgreSQL metadata: < 10MB per 10,000 items
- BigQuery: < 2GB per 10,000 items (with snapshots)

## Monitoring & Alerts

### Key Metrics
```
1. Storage Usage per Tenant
   - Track: content_storage_usage.total_storage_bytes
   - Alert: > 85% of limit

2. ZeroDB Health
   - Track: Response time, error rate
   - Alert: > 500ms latency or > 1% errors

3. BigQuery Sync Lag
   - Track: Unsynced content count
   - Alert: > 1000 items unsynced for > 1 hour

4. Quota Rejections
   - Track: 403 responses on content creation
   - Alert: > 10 rejections per tenant per day
```

### Dashboard Widgets
```
- Storage usage by tenant (top 10)
- Content creation rate (last 7 days)
- ZeroDB performance (latency percentiles)
- BigQuery sync status (% synced)
- Quota rejection rate (by plan tier)
```

## Security Considerations

### Multi-Tenancy
- All ZeroDB queries filter by tenant_id
- PostgreSQL RLS policies enforce tenant isolation
- BigQuery data partitioned by tenant_id

### Data Privacy
- Content encrypted in transit (TLS)
- ZeroDB supports encryption at rest
- BigQuery data encrypted by default
- Soft deletes allow recovery without exposing data

### Access Control
- Content ownership tied to brand_id
- Brand membership validated in API layer
- User permissions checked before content access
- API keys for LLM generation stored securely (BYOK)

## Cost Implications

### Storage Costs
```
ZeroDB: $X per GB/month (operational)
BigQuery: $0.02 per GB/month (storage)
PostgreSQL: Negligible (metadata only)

Example (Professional tier - 100 GB):
- ZeroDB: $X * 100 GB = $Y/month
- BigQuery: $0.02 * 100 GB = $2/month
- PostgreSQL: < $1/month
```

### Query Costs
```
ZeroDB: Operational costs (fixed)
BigQuery: $5 per TB scanned (analytics only)
PostgreSQL: Operational costs (fixed)
```

### Optimization Tips
- Use BigQuery partitioning to reduce scan costs
- Compress content in ZeroDB (50% reduction)
- Clear content_body from PostgreSQL after migration
- Implement content retention policies

## Testing Strategy

### Unit Tests
- ContentQuotaService.check_quota()
- ZeroDB CRUD operations
- BigQuery sync worker

### Integration Tests
- End-to-end content creation flow
- Batch generation with quota enforcement
- ZeroDB → BigQuery sync

### Load Tests
- 1000 concurrent content reads
- 100 concurrent batch generations
- 10,000 content items per tenant

### Disaster Recovery Tests
- Simulate ZeroDB failure
- Restore from BigQuery
- Verify data integrity

## Rollback Plan

### If Issues Arise
```
Phase 1 Rollback:
- Revert PostgreSQL migrations
- Keep existing content_body in PostgreSQL
- Disable ZeroDB writes

Phase 2 Rollback:
- Restore PostgreSQL content_body from ZeroDB
- Clear zerodb_id references
- Delete ZeroDB collections

Phase 3 Rollback:
- Revert API changes
- Use old content router
- Disable quota checks

Phase 4 Rollback:
- Stop BigQuery sync worker
- No data loss (ZeroDB still primary)
```

## Success Criteria

### Phase 1 Success
- [x] All tables/collections created
- [x] Quota checks functional
- [x] No production impact

### Phase 2 Success
- [x] All content migrated (100%)
- [x] Storage usage accurate
- [x] Content Studio shows data

### Phase 3 Success
- [x] API tests passing (100%)
- [x] Content creation < 300ms
- [x] Batch generation working

### Phase 4 Success
- [x] BigQuery sync < 1 hour lag
- [x] DR recovery tested
- [x] Monitoring live

---

## Quick Command Reference

### Run Migrations
```bash
cd /Users/cope/EnGardeHQ/production-backend
alembic upgrade head
```

### Setup ZeroDB Collections
```bash
python -c "
import asyncio
from app.services.content_storage_service import setup_content_storage_collections
asyncio.run(setup_content_storage_collections())
"
```

### Migrate Content
```bash
python scripts/migrate_campaign_assets_to_zerodb.py
python scripts/migrate_content_items_to_zerodb.py
```

### Start Sync Worker
```bash
python -m app.workers.content_bigquery_sync
```

### Check Quota
```bash
curl -X GET "http://localhost:8000/api/content/quota" \
  -H "Authorization: Bearer {token}"
```

---

**Document Location:** `/Users/cope/EnGardeHQ/CONTENT_STORAGE_ARCHITECTURE.md`
**Summary Location:** `/Users/cope/EnGardeHQ/CONTENT_STORAGE_ARCHITECTURE_SUMMARY.md`
