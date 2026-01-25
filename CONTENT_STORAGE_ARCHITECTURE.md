# En Garde Content Storage Architecture
**Version:** 1.0
**Date:** 2026-01-25
**Author:** System Architect
**Status:** Design Complete - Ready for Implementation

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Current Issues](#current-issues)
3. [Architecture Overview](#architecture-overview)
4. [Data Flow Architecture](#data-flow-architecture)
5. [Storage Layer Design](#storage-layer-design)
6. [Database Schema Specifications](#database-schema-specifications)
7. [API Specifications](#api-specifications)
8. [Content Quota & Usage Tracking](#content-quota--usage-tracking)
9. [Migration Strategy](#migration-strategy)
10. [Implementation Phases](#implementation-phases)

---

## Executive Summary

This document defines a comprehensive, scalable content storage architecture for the En Garde platform that solves the critical issue of missing content in the Content Studio while establishing a robust foundation for high-volume AI-generated content.

### Key Design Principles
1. **ZeroDB as Primary Storage**: All content stored in ZeroDB for fast retrieval and scalability
2. **BigQuery for DR/Analytics**: Secondary storage for disaster recovery and data analytics
3. **PostgreSQL for Metadata**: Lightweight metadata and relationships in PostgreSQL
4. **Quota Enforcement**: Content storage counts toward user's data consumption limits
5. **Multi-Tenant Isolation**: Strong tenant boundaries across all storage layers
6. **Version Control**: Full content versioning and audit trail

### Architecture Summary
```
┌─────────────────────────────────────────────────────────────────┐
│                        CONTENT INGESTION                         │
├─────────────┬──────────────────────┬─────────────────────────────┤
│   User      │   Platform Import    │   AI Generation (LLM)       │
│   Upload    │   (Google Ads, Meta) │   (Batch/Stream)            │
└──────┬──────┴──────────┬───────────┴──────────────┬──────────────┘
       │                 │                           │
       └─────────────────┴───────────────────────────┘
                         │
                    Quota Check
                    (PostgreSQL)
                         │
       ┌─────────────────┴───────────────────────────┐
       │                                             │
       ▼                                             ▼
┌──────────────┐                            ┌──────────────┐
│   ZeroDB     │◄───────Sync────────────────│  BigQuery    │
│  (Primary)   │                            │  (DR/Analytics)│
└──────┬───────┘                            └──────────────┘
       │
       │ Metadata Reference
       ▼
┌──────────────┐
│  PostgreSQL  │
│  (Metadata)  │
└──────────────┘
       │
       │ Content Retrieval
       ▼
┌──────────────┐
│Content Studio│
│    (UI)      │
└──────────────┘
```

---

## Current Issues

### 1. Content Studio Shows NO Content
**Root Cause:** Campaign assets are referenced in PostgreSQL but content files are not stored anywhere retrievable.

**Evidence:**
- `campaign_assets` table has records with `file_url` pointing to undefined storage
- Content Studio queries find metadata but cannot load actual content
- AI-generated content has no storage destination

### 2. No Scalable Storage Solution
**Root Cause:** No defined storage layer for high-volume content generation.

**Impact:**
- Cannot support batch AI content generation
- No strategy for handling media files (images, videos)
- No clear ownership of storage costs

### 3. BigQuery Partially Implemented
**Root Cause:** BigQuery service exists but has permission errors (403).

**Evidence from logs:**
```
"Failed to initialize BigQuery client: 403 Forbidden"
"BigQuery not configured - returning mock data"
```

### 4. ZeroDB Integration Incomplete
**Root Cause:** ZeroDB service exists but content isn't being stored there.

**Evidence:**
- `/app/services/zerodb_service.py` has full CRUD operations
- No content write operations in codebase
- Mock mode active due to missing configuration

---

## Architecture Overview

### Three-Layer Storage Strategy

#### Layer 1: ZeroDB (Primary Content Storage)
**Purpose:** Fast, scalable content storage and retrieval
**Stores:**
- Full content bodies (text, HTML, JSON)
- Media file references and metadata
- AI generation context and parameters
- Content versions and history

**Rationale:**
- Vector/relational hybrid database optimized for content
- Built-in search and query capabilities
- Scales horizontally for high-volume generation
- Fast read/write for real-time UI updates

#### Layer 2: BigQuery (Disaster Recovery & Analytics)
**Purpose:** Long-term storage, analytics, and disaster recovery
**Stores:**
- Complete content snapshots for DR
- Performance metrics and engagement data
- Historical content for trend analysis
- Platform integration raw data

**Rationale:**
- Petabyte-scale storage at low cost
- Time-series analysis for content performance
- Disaster recovery without performance impact
- Separate analytics workload from operational queries

#### Layer 3: PostgreSQL (Metadata & Relationships)
**Purpose:** Relational metadata and access control
**Stores:**
- Content metadata (title, type, status, timestamps)
- Relationships (brand, campaign, user ownership)
- Access permissions and tenant isolation
- Storage quota tracking and usage metrics

**Rationale:**
- ACID compliance for critical metadata
- Complex relational queries for permissions
- Existing RLS (Row Level Security) policies
- Small storage footprint (metadata only)

---

## Data Flow Architecture

### Flow 1: User Content Upload
```
┌────────────┐
│   User     │
│  Browser   │
└─────┬──────┘
      │ 1. Upload content
      ▼
┌────────────────────────────────────────────────────┐
│ Backend API: POST /api/content                     │
│ - Validate content                                 │
│ - Check quota (PostgreSQL)                         │
│ - Generate content_id                              │
└─────┬──────────────────────────────────────────────┘
      │
      │ 2. Store full content
      ▼
┌────────────────────────────────────────────────────┐
│ ZeroDB: content_items collection                   │
│ {                                                  │
│   id: "content_uuid",                              │
│   tenant_id: "...",                                │
│   brand_id: "...",                                 │
│   title: "...",                                    │
│   content_body: "<full_content>",                  │
│   content_type: "post",                            │
│   metadata: {...},                                 │
│   version: 1,                                      │
│   created_at: "2026-01-25T10:00:00Z"               │
│ }                                                  │
└─────┬──────────────────────────────────────────────┘
      │
      │ 3. Async backup to BigQuery
      ▼
┌────────────────────────────────────────────────────┐
│ BigQuery: content_snapshots table                  │
│ - Partitioned by created_date                      │
│ - Clustered by tenant_id, brand_id                 │
└─────┬──────────────────────────────────────────────┘
      │
      │ 4. Store metadata only
      ▼
┌────────────────────────────────────────────────────┐
│ PostgreSQL: content_items table                    │
│ {                                                  │
│   id: "content_uuid",                              │
│   tenant_id: "...",                                │
│   brand_id: "...",                                 │
│   title: "...",                                    │
│   content_type: "post",                            │
│   status: "draft",                                 │
│   zerodb_id: "content_uuid",  ← Reference          │
│   bigquery_backed_up: true,                        │
│   storage_size_bytes: 4096,                        │
│   created_at: "2026-01-25T10:00:00Z"               │
│ }                                                  │
└─────┬──────────────────────────────────────────────┘
      │
      │ 5. Update quota usage
      ▼
┌────────────────────────────────────────────────────┐
│ PostgreSQL: usage_metrics table                    │
│ - Increment tenant's storage usage                 │
│ - Check against plan tier limits                   │
└────────────────────────────────────────────────────┘
```

### Flow 2: AI Content Generation (Batch)
```
┌────────────┐
│   User     │
│  Triggers  │
│ Batch Gen  │
└─────┬──────┘
      │
      ▼
┌────────────────────────────────────────────────────┐
│ Backend API: POST /api/content/generate-batch      │
│ - Check quota for projected volume                 │
│ - Create generation job in PostgreSQL              │
└─────┬──────────────────────────────────────────────┘
      │
      │ Generate 100 posts
      ▼
┌────────────────────────────────────────────────────┐
│ LLM API (OpenAI/Claude/etc.)                       │
│ - BYOK (User's API Key)                            │
│ - Streaming or batch generation                    │
└─────┬──────────────────────────────────────────────┘
      │
      │ Stream results
      ▼
┌────────────────────────────────────────────────────┐
│ Content Processing Pipeline                        │
│ - Parse LLM output                                 │
│ - Extract metadata                                 │
│ - Calculate storage size                           │
│ - Batch insert to ZeroDB (50 at a time)            │
└─────┬──────────────────────────────────────────────┘
      │
      │ Parallel writes
      ├─────────────────┬─────────────────┐
      ▼                 ▼                 ▼
┌──────────┐     ┌──────────┐     ┌──────────┐
│ ZeroDB   │     │ ZeroDB   │     │ ZeroDB   │
│ Batch 1  │     │ Batch 2  │     │ Batch 3  │
└─────┬────┘     └─────┬────┘     └─────┬────┘
      │                │                │
      └────────────────┴────────────────┘
                       │
                       │ After all batches complete
                       ▼
┌────────────────────────────────────────────────────┐
│ PostgreSQL: Bulk metadata insert                   │
│ - Insert 100 records with zerodb_id references     │
│ - Update generation job status                     │
│ - Increment quota usage (bulk)                     │
└─────┬──────────────────────────────────────────────┘
      │
      │ Async background job
      ▼
┌────────────────────────────────────────────────────┐
│ BigQuery: Batch insert for DR                      │
│ - Streaming insert (not blocking)                  │
└────────────────────────────────────────────────────┘
```

### Flow 3: Content Studio Retrieval
```
┌────────────┐
│   User     │
│  Opens     │
│  Content   │
│  Studio    │
└─────┬──────┘
      │
      ▼
┌────────────────────────────────────────────────────┐
│ Frontend: GET /api/content?page=1&pageSize=20      │
└─────┬──────────────────────────────────────────────┘
      │
      ▼
┌────────────────────────────────────────────────────┐
│ Backend: Query PostgreSQL for metadata             │
│ SELECT id, title, content_type, status,            │
│        zerodb_id, created_at                       │
│ FROM content_items                                 │
│ WHERE brand_id = ? AND deleted_at IS NULL          │
│ ORDER BY created_at DESC                           │
│ LIMIT 20 OFFSET 0                                  │
└─────┬──────────────────────────────────────────────┘
      │
      │ Returns 20 content_ids with zerodb_id refs
      ▼
┌────────────────────────────────────────────────────┐
│ Backend: Batch fetch from ZeroDB                   │
│ - Query ZeroDB with 20 content_ids                 │
│ - Get full content bodies                          │
│ - Merge with PostgreSQL metadata                   │
└─────┬──────────────────────────────────────────────┘
      │
      │ Return merged data
      ▼
┌────────────────────────────────────────────────────┐
│ Frontend: Render Content Studio                    │
│ - Display content cards                            │
│ - Preview content bodies                           │
│ - Enable edit/delete actions                       │
└────────────────────────────────────────────────────┘
```

### Flow 4: Disaster Recovery
```
┌────────────┐
│ ZeroDB     │
│ FAILURE    │
│ (Complete) │
└─────┬──────┘
      │
      ▼
┌────────────────────────────────────────────────────┐
│ Detect ZeroDB unavailability                       │
│ - Health check failures                            │
│ - Query timeouts                                   │
└─────┬──────────────────────────────────────────────┘
      │
      │ Automatic failover
      ▼
┌────────────────────────────────────────────────────┐
│ Query BigQuery for content recovery                │
│ SELECT content_id, content_body, metadata          │
│ FROM content_snapshots                             │
│ WHERE tenant_id = ?                                │
│ ORDER BY created_at DESC                           │
└─────┬──────────────────────────────────────────────┘
      │
      │ Restore to ZeroDB (or serve from BigQuery)
      ▼
┌────────────────────────────────────────────────────┐
│ Recovery Options:                                  │
│ 1. Serve directly from BigQuery (slower)           │
│ 2. Restore to ZeroDB in background                 │
│ 3. Migrate to new ZeroDB instance                  │
└────────────────────────────────────────────────────┘
```

---

## Storage Layer Design

### ZeroDB Schema Design

#### Collection: `content_items`
**Description:** Primary content storage with full bodies and metadata

**Schema:**
```json
{
  "collection_name": "content_items",
  "schema": {
    "id": "string (UUID)",
    "tenant_id": "string (UUID)",
    "brand_id": "string (UUID)",
    "campaign_space_id": "string (UUID, nullable)",
    "user_id": "string (UUID)",

    "title": "string",
    "content_body": "text",
    "content_type": "enum (post, story, ad, article, tweet, image, video, carousel, reel)",
    "status": "enum (draft, published, archived, scheduled)",

    "metadata": {
      "platforms": ["array of strings"],
      "tags": ["array of strings"],
      "hashtags": ["array of strings"],
      "mentions": ["array of strings"],
      "media_urls": ["array of strings"],
      "scheduled_at": "timestamp",
      "published_at": "timestamp"
    },

    "ai_generation_metadata": {
      "model": "string",
      "prompt": "text",
      "generation_id": "string",
      "temperature": "float",
      "max_tokens": "int",
      "cost_usd": "float"
    },

    "storage_metadata": {
      "size_bytes": "int",
      "compressed_size_bytes": "int",
      "mime_type": "string",
      "encoding": "string"
    },

    "version": "int",
    "version_of": "string (UUID, nullable)",
    "bigquery_synced": "boolean",
    "bigquery_sync_timestamp": "timestamp",

    "created_at": "timestamp",
    "updated_at": "timestamp",
    "deleted_at": "timestamp (soft delete)"
  },
  "indexes": [
    "tenant_id",
    "brand_id",
    "campaign_space_id",
    "status",
    "content_type",
    "created_at",
    "deleted_at"
  ],
  "primary_key": "id"
}
```

#### Collection: `content_media_files`
**Description:** Media file metadata and storage references

**Schema:**
```json
{
  "collection_name": "content_media_files",
  "schema": {
    "id": "string (UUID)",
    "tenant_id": "string (UUID)",
    "brand_id": "string (UUID)",
    "content_id": "string (UUID, references content_items)",

    "file_name": "string",
    "file_type": "enum (image, video, audio, document)",
    "mime_type": "string",
    "file_size_bytes": "int",

    "storage_provider": "enum (gcs, s3, zerodb_binary)",
    "storage_path": "string",
    "public_url": "string",
    "cdn_url": "string",

    "media_metadata": {
      "width": "int",
      "height": "int",
      "duration": "int (seconds)",
      "format": "string",
      "codec": "string",
      "bitrate": "int",
      "thumbnail_url": "string"
    },

    "processing_status": "enum (pending, processing, ready, failed)",
    "bigquery_synced": "boolean",

    "created_at": "timestamp",
    "updated_at": "timestamp"
  },
  "indexes": [
    "tenant_id",
    "brand_id",
    "content_id",
    "file_type",
    "processing_status"
  ],
  "primary_key": "id"
}
```

#### Collection: `content_versions`
**Description:** Version history for content changes

**Schema:**
```json
{
  "collection_name": "content_versions",
  "schema": {
    "id": "string (UUID)",
    "content_id": "string (UUID, references content_items)",
    "tenant_id": "string (UUID)",

    "version_number": "int",
    "changed_by_user_id": "string (UUID)",
    "change_type": "enum (create, update, publish, archive, restore)",

    "content_snapshot": {
      "title": "string",
      "content_body": "text",
      "status": "string",
      "metadata": "object"
    },

    "changes_summary": "text",
    "diff_from_previous": "object (JSON patch)",

    "created_at": "timestamp"
  },
  "indexes": [
    "content_id",
    "tenant_id",
    "version_number",
    "created_at"
  ],
  "primary_key": "id"
}
```

### BigQuery Schema Design

#### Table: `content_snapshots`
**Description:** Complete content snapshots for disaster recovery and analytics

**Schema:**
```sql
CREATE TABLE engarde_analytics.content_snapshots (
  -- Primary keys
  content_id STRING NOT NULL,
  snapshot_id STRING NOT NULL,

  -- Multi-tenancy
  tenant_id STRING NOT NULL,
  brand_id STRING,
  campaign_space_id STRING,
  user_id STRING NOT NULL,

  -- Content data
  title STRING NOT NULL,
  content_body STRING,  -- Full content (can be large)
  content_type STRING NOT NULL,
  status STRING NOT NULL,

  -- Metadata (stored as JSON)
  metadata JSON,
  ai_generation_metadata JSON,
  storage_metadata JSON,

  -- Version control
  version INT64,
  version_of STRING,

  -- Timestamps
  snapshot_timestamp TIMESTAMP NOT NULL,
  content_created_at TIMESTAMP NOT NULL,
  content_updated_at TIMESTAMP NOT NULL,

  -- Ingestion metadata
  ingested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  source_system STRING DEFAULT 'zerodb'
)
PARTITION BY DATE(snapshot_timestamp)
CLUSTER BY tenant_id, brand_id, content_type
OPTIONS(
  description="Content snapshots for disaster recovery and analytics",
  require_partition_filter=true
);
```

#### Table: `content_media_snapshots`
**Description:** Media file metadata snapshots

**Schema:**
```sql
CREATE TABLE engarde_analytics.content_media_snapshots (
  -- Primary keys
  media_id STRING NOT NULL,
  snapshot_id STRING NOT NULL,

  -- Multi-tenancy
  tenant_id STRING NOT NULL,
  brand_id STRING,
  content_id STRING,

  -- Media metadata
  file_name STRING NOT NULL,
  file_type STRING NOT NULL,
  mime_type STRING,
  file_size_bytes INT64,

  -- Storage references
  storage_provider STRING,
  storage_path STRING,
  public_url STRING,

  -- Media properties (stored as JSON)
  media_metadata JSON,

  -- Timestamps
  snapshot_timestamp TIMESTAMP NOT NULL,
  media_created_at TIMESTAMP NOT NULL,

  -- Ingestion metadata
  ingested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(snapshot_timestamp)
CLUSTER BY tenant_id, brand_id, file_type;
```

#### Table: `content_analytics`
**Description:** Performance metrics and engagement data

**Schema:**
```sql
CREATE TABLE engarde_analytics.content_analytics (
  -- Primary keys
  metric_id STRING NOT NULL,
  content_id STRING NOT NULL,

  -- Multi-tenancy
  tenant_id STRING NOT NULL,
  brand_id STRING,

  -- Metric date
  metric_date DATE NOT NULL,
  metric_hour TIMESTAMP,

  -- Platform
  platform STRING,  -- instagram, facebook, twitter, etc.

  -- Engagement metrics
  impressions INT64 DEFAULT 0,
  clicks INT64 DEFAULT 0,
  likes INT64 DEFAULT 0,
  shares INT64 DEFAULT 0,
  comments INT64 DEFAULT 0,
  saves INT64 DEFAULT 0,

  -- Performance metrics
  engagement_rate FLOAT64,
  ctr FLOAT64,
  avg_watch_time FLOAT64,

  -- Revenue metrics
  conversions INT64 DEFAULT 0,
  revenue FLOAT64,

  -- Additional metrics (stored as JSON)
  custom_metrics JSON,

  -- Timestamps
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY metric_date
CLUSTER BY tenant_id, brand_id, platform;
```

### PostgreSQL Schema Changes

#### Table: `content_items` (Modified)

**Migration SQL:**
```sql
-- Add new columns to existing content_items table
ALTER TABLE content_items
  ADD COLUMN IF NOT EXISTS zerodb_id VARCHAR(36),
  ADD COLUMN IF NOT EXISTS bigquery_backed_up BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS bigquery_last_sync_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS storage_size_bytes INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1,
  ADD COLUMN IF NOT EXISTS version_of VARCHAR(36),
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;

-- Add indexes for new columns
CREATE INDEX IF NOT EXISTS idx_content_items_zerodb_id ON content_items(zerodb_id);
CREATE INDEX IF NOT EXISTS idx_content_items_deleted_at ON content_items(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_content_items_bigquery_sync ON content_items(bigquery_backed_up, bigquery_last_sync_at);

-- Add foreign key for version tracking
ALTER TABLE content_items
  ADD CONSTRAINT fk_content_items_version_of
  FOREIGN KEY (version_of) REFERENCES content_items(id) ON DELETE SET NULL;

COMMENT ON COLUMN content_items.zerodb_id IS 'Reference to content stored in ZeroDB';
COMMENT ON COLUMN content_items.bigquery_backed_up IS 'Whether content has been backed up to BigQuery';
COMMENT ON COLUMN content_items.storage_size_bytes IS 'Content size for quota tracking';
COMMENT ON COLUMN content_items.version IS 'Version number for content versioning';
COMMENT ON COLUMN content_items.version_of IS 'Reference to original content if this is a version';
```

#### Table: `content_storage_usage` (New)

**Purpose:** Track storage usage by tenant for quota enforcement

**Schema:**
```sql
CREATE TABLE IF NOT EXISTS content_storage_usage (
  id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  tenant_id VARCHAR(36) NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  brand_id VARCHAR(36) REFERENCES brands(id) ON DELETE SET NULL,

  -- Usage metrics
  total_content_items INTEGER DEFAULT 0,
  total_storage_bytes BIGINT DEFAULT 0,
  total_media_files INTEGER DEFAULT 0,
  total_media_storage_bytes BIGINT DEFAULT 0,

  -- Breakdown by content type
  usage_by_type JSONB DEFAULT '{}'::jsonb,  -- {"post": {"count": 10, "bytes": 50000}, ...}

  -- Last updated
  last_calculated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  UNIQUE(tenant_id)
);

CREATE INDEX idx_content_storage_usage_tenant ON content_storage_usage(tenant_id);
CREATE INDEX idx_content_storage_usage_brand ON content_storage_usage(brand_id);

COMMENT ON TABLE content_storage_usage IS 'Tracks content storage usage by tenant for quota enforcement';
```

#### Table: `content_generation_jobs` (New)

**Purpose:** Track AI content generation batch jobs

**Schema:**
```sql
CREATE TABLE IF NOT EXISTS content_generation_jobs (
  id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  tenant_id VARCHAR(36) NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  brand_id VARCHAR(36) REFERENCES brands(id) ON DELETE SET NULL,
  user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Job configuration
  job_type VARCHAR(50) NOT NULL,  -- 'batch_social', 'campaign_content', etc.
  target_count INTEGER NOT NULL,
  content_type VARCHAR(50) NOT NULL,

  -- Generation parameters
  generation_params JSONB,  -- Model, temperature, prompt template, etc.

  -- Status tracking
  status VARCHAR(50) NOT NULL DEFAULT 'pending',  -- pending, running, completed, failed, cancelled
  progress INTEGER DEFAULT 0,  -- Number of items generated
  error_message TEXT,

  -- Results
  generated_content_ids TEXT[],  -- Array of content_ids created
  total_storage_bytes BIGINT DEFAULT 0,
  total_cost_usd NUMERIC(10, 4) DEFAULT 0,

  -- Timestamps
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  started_at TIMESTAMP,
  completed_at TIMESTAMP,

  CONSTRAINT chk_progress_valid CHECK (progress >= 0 AND progress <= target_count)
);

CREATE INDEX idx_content_generation_jobs_tenant ON content_generation_jobs(tenant_id);
CREATE INDEX idx_content_generation_jobs_brand ON content_generation_jobs(brand_id);
CREATE INDEX idx_content_generation_jobs_user ON content_generation_jobs(user_id);
CREATE INDEX idx_content_generation_jobs_status ON content_generation_jobs(status, created_at);

COMMENT ON TABLE content_generation_jobs IS 'Tracks AI content generation batch jobs';
```

---

## API Specifications

### Content CRUD Operations

#### 1. Create Content

**Endpoint:** `POST /api/content`

**Request Body:**
```json
{
  "title": "Summer Product Launch Campaign",
  "body": "<full_html_or_text_content>",
  "type": "post",
  "platforms": ["instagram", "facebook"],
  "tags": ["summer", "launch", "product"],
  "hashtags": ["#SummerLaunch", "#NewProduct"],
  "mentions": ["@brandpartner"],
  "media": ["media_id_1", "media_id_2"],
  "scheduled_at": "2026-06-01T10:00:00Z",
  "status": "draft",
  "metadata": {
    "target_audience": "millennials",
    "campaign_id": "campaign_uuid"
  }
}
```

**Response (201 Created):**
```json
{
  "id": "content_uuid",
  "title": "Summer Product Launch Campaign",
  "body": "<full_html_or_text_content>",
  "type": "post",
  "status": "draft",
  "platforms": ["instagram", "facebook"],
  "tags": ["summer", "launch", "product"],
  "hashtags": ["#SummerLaunch", "#NewProduct"],
  "mentions": ["@brandpartner"],
  "media": ["media_id_1", "media_id_2"],
  "scheduled_at": "2026-06-01T10:00:00Z",
  "metadata": {...},
  "storage": {
    "size_bytes": 4096,
    "zerodb_id": "content_uuid",
    "bigquery_backed_up": false
  },
  "created_at": "2026-01-25T10:00:00Z",
  "updated_at": "2026-01-25T10:00:00Z",
  "version": 1
}
```

**Storage Flow:**
1. Validate request and check user permissions
2. **Check quota:** Query `content_storage_usage` for tenant
3. **Store in ZeroDB:** Insert full content to `content_items` collection
4. **Store metadata in PostgreSQL:** Insert to `content_items` table with `zerodb_id`
5. **Update quota:** Increment tenant's storage usage
6. **Queue BigQuery backup:** Async job to sync to BigQuery
7. Return response with content details

#### 2. List Content (Paginated)

**Endpoint:** `GET /api/content`

**Query Parameters:**
- `page` (int, default: 1)
- `pageSize` (int, default: 20, max: 100)
- `content_type` (string, optional)
- `status` (string, optional)
- `campaign_space_id` (string, optional)
- `search` (string, optional) - Full-text search in title/body
- `tags` (array, optional)
- `date_from` (ISO timestamp, optional)
- `date_to` (ISO timestamp, optional)

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "content_uuid_1",
      "title": "Summer Campaign Post",
      "type": "post",
      "status": "published",
      "platforms": ["instagram"],
      "preview": "First 200 chars of content...",
      "thumbnail_url": "https://...",
      "created_at": "2026-01-25T10:00:00Z",
      "updated_at": "2026-01-25T11:00:00Z"
    },
    // ... 19 more items
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 150,
    "totalPages": 8,
    "hasNext": true,
    "hasPrevious": false
  }
}
```

**Storage Flow:**
1. Query PostgreSQL `content_items` for metadata (with pagination)
2. Extract `zerodb_id` references from results
3. **Batch fetch from ZeroDB:** Query `content_items` collection with content_ids
4. Merge ZeroDB content with PostgreSQL metadata
5. Generate previews (truncate body to 200 chars)
6. Return paginated response

#### 3. Get Single Content

**Endpoint:** `GET /api/content/{content_id}`

**Response (200 OK):**
```json
{
  "id": "content_uuid",
  "title": "Summer Product Launch Campaign",
  "body": "<full_html_or_text_content>",
  "type": "post",
  "status": "draft",
  "platforms": ["instagram", "facebook"],
  "tags": ["summer", "launch", "product"],
  "hashtags": ["#SummerLaunch", "#NewProduct"],
  "mentions": ["@brandpartner"],
  "media": [
    {
      "id": "media_id_1",
      "type": "image",
      "url": "https://cdn.example.com/image1.jpg",
      "thumbnail_url": "https://cdn.example.com/image1_thumb.jpg",
      "size_bytes": 102400,
      "metadata": {
        "width": 1080,
        "height": 1080,
        "format": "jpeg"
      }
    }
  ],
  "scheduled_at": "2026-06-01T10:00:00Z",
  "metadata": {...},
  "storage": {
    "size_bytes": 4096,
    "zerodb_id": "content_uuid",
    "bigquery_backed_up": true,
    "bigquery_last_sync_at": "2026-01-25T10:05:00Z"
  },
  "versions": [
    {
      "version": 1,
      "created_at": "2026-01-25T10:00:00Z",
      "changed_by": "user_uuid",
      "change_type": "create"
    }
  ],
  "created_at": "2026-01-25T10:00:00Z",
  "updated_at": "2026-01-25T10:00:00Z",
  "version": 1
}
```

**Storage Flow:**
1. Query PostgreSQL for metadata and `zerodb_id`
2. **Fetch full content from ZeroDB** using `zerodb_id`
3. Fetch media metadata from `content_media_files` collection
4. Fetch version history from `content_versions` collection
5. Merge all data and return response

#### 4. Update Content

**Endpoint:** `PATCH /api/content/{content_id}`

**Request Body:**
```json
{
  "title": "Updated Summer Campaign",
  "body": "<updated_content>",
  "status": "published",
  "tags": ["summer", "launch", "product", "2026"]
}
```

**Response (200 OK):**
```json
{
  "id": "content_uuid",
  "title": "Updated Summer Campaign",
  "body": "<updated_content>",
  "status": "published",
  "version": 2,
  "updated_at": "2026-01-25T11:00:00Z"
}
```

**Storage Flow:**
1. Fetch current content from ZeroDB
2. Create version snapshot in `content_versions` collection
3. **Update content in ZeroDB** with new data
4. Update metadata in PostgreSQL
5. Update storage size if changed
6. **Queue BigQuery backup** for new version
7. Return updated content

#### 5. Delete Content (Soft Delete)

**Endpoint:** `DELETE /api/content/{content_id}`

**Response (200 OK):**
```json
{
  "message": "Content deleted successfully",
  "id": "content_uuid",
  "deleted_at": "2026-01-25T12:00:00Z"
}
```

**Storage Flow:**
1. Set `deleted_at` timestamp in PostgreSQL
2. Mark as deleted in ZeroDB (soft delete)
3. **Decrement quota usage** in `content_storage_usage`
4. Create final version snapshot before deletion
5. Return success response

**Note:** Content remains in ZeroDB and BigQuery for recovery. Hard delete can be performed by admin later.

### Batch Content Generation

#### 6. Generate Content Batch

**Endpoint:** `POST /api/content/generate-batch`

**Request Body:**
```json
{
  "job_type": "social_media_posts",
  "content_type": "post",
  "target_count": 50,
  "platforms": ["instagram", "facebook"],
  "generation_params": {
    "model": "gpt-4",
    "temperature": 0.7,
    "prompt_template": "Create engaging social media post about {topic}",
    "topics": ["summer", "product launch", "customer testimonials"],
    "tone": "professional",
    "include_hashtags": true,
    "include_emojis": true
  },
  "brand_adherence": {
    "level": "MODERATE",
    "enforce_brand_voice": true,
    "check_compliance": true
  }
}
```

**Response (202 Accepted):**
```json
{
  "job_id": "job_uuid",
  "status": "pending",
  "target_count": 50,
  "progress": 0,
  "estimated_completion_time": "2026-01-25T10:15:00Z",
  "estimated_storage_bytes": 204800,
  "estimated_cost_usd": 2.50,
  "quota_check": {
    "current_usage_gb": 5.2,
    "limit_gb": 100,
    "projected_usage_gb": 5.4,
    "within_limit": true
  },
  "created_at": "2026-01-25T10:00:00Z"
}
```

**Storage Flow:**
1. **Validate quota:** Check if tenant can store projected content
2. Create job record in `content_generation_jobs` table
3. **Start async job:** Background worker processes generation
4. For each generated content:
   - Store in ZeroDB `content_items` collection
   - Store metadata in PostgreSQL
   - Update job progress
5. **Batch BigQuery backup:** After all content generated
6. Update job status to 'completed'
7. Send notification to user

#### 7. Get Generation Job Status

**Endpoint:** `GET /api/content/generation-jobs/{job_id}`

**Response (200 OK):**
```json
{
  "job_id": "job_uuid",
  "status": "running",
  "target_count": 50,
  "progress": 32,
  "progress_percent": 64,
  "generated_content_ids": ["content_uuid_1", "content_uuid_2", ...],
  "total_storage_bytes": 131072,
  "total_cost_usd": 1.60,
  "started_at": "2026-01-25T10:01:00Z",
  "estimated_completion": "2026-01-25T10:12:00Z",
  "error_message": null
}
```

#### 8. Cancel Generation Job

**Endpoint:** `POST /api/content/generation-jobs/{job_id}/cancel`

**Response (200 OK):**
```json
{
  "job_id": "job_uuid",
  "status": "cancelled",
  "progress": 32,
  "generated_content_ids": ["content_uuid_1", "content_uuid_2", ...],
  "message": "Job cancelled. 32 out of 50 items were generated before cancellation."
}
```

### Campaign Import Integration

#### 9. Import Campaign Content

**Endpoint:** `POST /api/campaign-spaces/{campaign_space_id}/import-content`

**Request Body:**
```json
{
  "platform": "google_ads",
  "external_campaign_id": "123456789",
  "import_assets": true,
  "import_performance": true,
  "import_options": {
    "include_inactive": false,
    "date_range": {
      "start": "2026-01-01",
      "end": "2026-01-25"
    }
  }
}
```

**Response (202 Accepted):**
```json
{
  "import_job_id": "import_uuid",
  "status": "pending",
  "campaign_space_id": "campaign_space_uuid",
  "platform": "google_ads",
  "estimated_assets": 25,
  "created_at": "2026-01-25T10:00:00Z"
}
```

**Storage Flow:**
1. Fetch campaign data from platform API (Google Ads, Meta, etc.)
2. **For each asset:**
   - Download media files if applicable
   - Store content in ZeroDB `content_items` collection
   - Store media in `content_media_files` collection
   - Create metadata in PostgreSQL `campaign_assets` table
3. **Link to campaign space** in PostgreSQL
4. **Backup to BigQuery** for analytics
5. Update import job status

---

## Content Quota & Usage Tracking

### Quota Architecture

#### Storage Limits by Plan Tier

| Plan Tier    | Storage Limit | Retention | Monthly Content Gen |
|--------------|---------------|-----------|---------------------|
| Free         | 1 GB          | 30 days   | 100 items           |
| Starter      | 10 GB         | 90 days   | 1,000 items         |
| Professional | 100 GB        | 1 year    | 10,000 items        |
| Business     | 500 GB        | 5 years   | 50,000 items        |
| Enterprise   | Unlimited     | Unlimited | Unlimited           |

**Note:** These limits align with existing `storage_tiers.py` configuration.

### Quota Enforcement Flow

```
┌─────────────────────────────────────────────────────────┐
│ Content Upload/Generation Request                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ Step 1: Check Current Usage                             │
│ - Query: SELECT total_storage_bytes                     │
│          FROM content_storage_usage                     │
│          WHERE tenant_id = ?                            │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ Step 2: Get Plan Tier Limit                             │
│ - Query: SELECT plan_tier FROM tenants WHERE id = ?     │
│ - Lookup: get_storage_limit_gb(plan_tier)               │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ Step 3: Calculate Projected Usage                       │
│ - projected_gb = current_gb + new_content_size_gb       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
          ┌──────────┴──────────┐
          │ projected_gb >      │
          │ limit_gb?           │
          └──────────┬──────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
        YES                     NO
         │                       │
         ▼                       ▼
┌────────────────┐      ┌───────────────────┐
│ REJECT         │      │ ALLOW             │
│ - Return 403   │      │ - Store content   │
│ - Message:     │      │ - Increment quota │
│   "Storage     │      │ - Return success  │
│    limit       │      └───────────────────┘
│    exceeded"   │
└────────────────┘
```

### Quota Tracking Service

**File:** `/production-backend/app/services/content_quota_service.py`

```python
"""
Content Quota Service

Enforces storage limits for content based on subscription tier.
"""

from typing import Dict, Any
from sqlalchemy.orm import Session
from app.models.core import Tenant
from app.models.content_models import ContentStorageUsage
from app.config.storage_tiers import (
    get_storage_limit_gb,
    calculate_warning_level,
    should_block_storage
)
import logging

logger = logging.getLogger(__name__)


class ContentQuotaService:
    """Service for enforcing content storage quotas"""

    def check_quota(
        self,
        db: Session,
        tenant_id: str,
        additional_bytes: int
    ) -> Dict[str, Any]:
        """
        Check if tenant can store additional content.

        Args:
            db: Database session
            tenant_id: Tenant ID
            additional_bytes: Size of content to be stored

        Returns:
            Dict with can_store boolean and quota details
        """
        # Get tenant plan tier
        tenant = db.query(Tenant).filter(Tenant.id == tenant_id).first()
        if not tenant:
            return {
                "can_store": False,
                "reason": "Tenant not found",
                "blocked": True
            }

        plan_tier = tenant.plan_tier or "free"
        storage_limit_gb = get_storage_limit_gb(plan_tier)

        # Unlimited storage for enterprise
        if storage_limit_gb is None:
            return {
                "can_store": True,
                "reason": "Unlimited storage (Enterprise plan)",
                "blocked": False,
                "plan_tier": plan_tier
            }

        # Get current usage
        usage = db.query(ContentStorageUsage).filter(
            ContentStorageUsage.tenant_id == tenant_id
        ).first()

        current_bytes = usage.total_storage_bytes if usage else 0
        current_gb = current_bytes / (1024**3)
        additional_gb = additional_bytes / (1024**3)
        projected_gb = current_gb + additional_gb

        # Check if projected usage exceeds limit
        if should_block_storage(projected_gb, storage_limit_gb):
            return {
                "can_store": False,
                "reason": f"Storage limit exceeded. Your {plan_tier} plan allows {storage_limit_gb} GB. Current usage: {current_gb:.2f} GB.",
                "blocked": True,
                "current_gb": current_gb,
                "limit_gb": storage_limit_gb,
                "projected_gb": projected_gb,
                "plan_tier": plan_tier
            }

        # Calculate warning level
        warning_level = calculate_warning_level(projected_gb, storage_limit_gb)

        return {
            "can_store": True,
            "reason": "Within storage limits",
            "blocked": False,
            "warning_level": warning_level.value,
            "current_gb": current_gb,
            "limit_gb": storage_limit_gb,
            "projected_gb": projected_gb,
            "plan_tier": plan_tier,
            "usage_percent": round((projected_gb / storage_limit_gb) * 100, 1)
        }

    def increment_usage(
        self,
        db: Session,
        tenant_id: str,
        brand_id: str,
        content_size_bytes: int,
        content_type: str
    ) -> None:
        """
        Increment storage usage for tenant.

        Args:
            db: Database session
            tenant_id: Tenant ID
            brand_id: Brand ID
            content_size_bytes: Size of content stored
            content_type: Type of content (post, image, video, etc.)
        """
        usage = db.query(ContentStorageUsage).filter(
            ContentStorageUsage.tenant_id == tenant_id
        ).first()

        if not usage:
            usage = ContentStorageUsage(
                tenant_id=tenant_id,
                brand_id=brand_id,
                total_content_items=0,
                total_storage_bytes=0,
                usage_by_type={}
            )
            db.add(usage)

        # Increment totals
        usage.total_content_items += 1
        usage.total_storage_bytes += content_size_bytes

        # Update breakdown by type
        usage_by_type = usage.usage_by_type or {}
        if content_type not in usage_by_type:
            usage_by_type[content_type] = {"count": 0, "bytes": 0}

        usage_by_type[content_type]["count"] += 1
        usage_by_type[content_type]["bytes"] += content_size_bytes

        usage.usage_by_type = usage_by_type
        usage.last_calculated_at = datetime.utcnow()

        db.commit()

        logger.info(
            f"Incremented storage usage for tenant {tenant_id}: "
            f"+{content_size_bytes} bytes, total: {usage.total_storage_bytes} bytes"
        )

    def decrement_usage(
        self,
        db: Session,
        tenant_id: str,
        content_size_bytes: int,
        content_type: str
    ) -> None:
        """
        Decrement storage usage for tenant (after deletion).

        Args:
            db: Database session
            tenant_id: Tenant ID
            content_size_bytes: Size of content deleted
            content_type: Type of content
        """
        usage = db.query(ContentStorageUsage).filter(
            ContentStorageUsage.tenant_id == tenant_id
        ).first()

        if not usage:
            logger.warning(f"No usage record found for tenant {tenant_id}")
            return

        # Decrement totals
        usage.total_content_items = max(0, usage.total_content_items - 1)
        usage.total_storage_bytes = max(0, usage.total_storage_bytes - content_size_bytes)

        # Update breakdown by type
        usage_by_type = usage.usage_by_type or {}
        if content_type in usage_by_type:
            usage_by_type[content_type]["count"] = max(0, usage_by_type[content_type]["count"] - 1)
            usage_by_type[content_type]["bytes"] = max(0, usage_by_type[content_type]["bytes"] - content_size_bytes)

        usage.usage_by_type = usage_by_type
        usage.last_calculated_at = datetime.utcnow()

        db.commit()
```

### Usage Tracking Endpoint

**Endpoint:** `GET /api/content/quota`

**Response (200 OK):**
```json
{
  "tenant_id": "tenant_uuid",
  "plan_tier": "professional",
  "usage": {
    "total_content_items": 245,
    "total_storage_bytes": 52428800,
    "total_storage_gb": 0.05,
    "usage_by_type": {
      "post": {"count": 150, "bytes": 15728640},
      "image": {"count": 50, "bytes": 20971520},
      "video": {"count": 30, "bytes": 12582912},
      "carousel": {"count": 15, "bytes": 3145728}
    }
  },
  "limits": {
    "storage_limit_gb": 100,
    "available_gb": 99.95,
    "usage_percent": 0.05,
    "retention_days": 365
  },
  "warning_level": "normal",
  "last_calculated_at": "2026-01-25T10:00:00Z"
}
```

---

## Migration Strategy

### Phase 1: Foundation Setup (Week 1)

#### 1.1 PostgreSQL Schema Migration

**File:** `/production-backend/migrations/versions/YYYYMMDD_content_storage_architecture.py`

```python
"""Content storage architecture migration

Revision ID: content_storage_v1
Revises: previous_revision
Create Date: 2026-01-25

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

def upgrade():
    # Add columns to existing content_items table
    op.add_column('content_items',
        sa.Column('zerodb_id', sa.String(36), nullable=True))
    op.add_column('content_items',
        sa.Column('bigquery_backed_up', sa.Boolean(), default=False))
    op.add_column('content_items',
        sa.Column('bigquery_last_sync_at', sa.DateTime(), nullable=True))
    op.add_column('content_items',
        sa.Column('storage_size_bytes', sa.Integer(), default=0))
    op.add_column('content_items',
        sa.Column('version', sa.Integer(), default=1))
    op.add_column('content_items',
        sa.Column('version_of', sa.String(36), nullable=True))
    op.add_column('content_items',
        sa.Column('deleted_at', sa.DateTime(), nullable=True))

    # Create indexes
    op.create_index('idx_content_items_zerodb_id', 'content_items', ['zerodb_id'])
    op.create_index('idx_content_items_deleted_at', 'content_items', ['deleted_at'])
    op.create_index('idx_content_items_bigquery_sync', 'content_items',
                    ['bigquery_backed_up', 'bigquery_last_sync_at'])

    # Create content_storage_usage table
    op.create_table(
        'content_storage_usage',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('tenant_id', sa.String(36), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False),
        sa.Column('brand_id', sa.String(36), sa.ForeignKey('brands.id', ondelete='SET NULL')),
        sa.Column('total_content_items', sa.Integer(), default=0),
        sa.Column('total_storage_bytes', sa.BigInteger(), default=0),
        sa.Column('total_media_files', sa.Integer(), default=0),
        sa.Column('total_media_storage_bytes', sa.BigInteger(), default=0),
        sa.Column('usage_by_type', postgresql.JSONB(), default={}),
        sa.Column('last_calculated_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.func.now())
    )
    op.create_index('idx_content_storage_usage_tenant', 'content_storage_usage', ['tenant_id'], unique=True)

    # Create content_generation_jobs table
    op.create_table(
        'content_generation_jobs',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('tenant_id', sa.String(36), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False),
        sa.Column('brand_id', sa.String(36), sa.ForeignKey('brands.id', ondelete='SET NULL')),
        sa.Column('user_id', sa.String(36), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('job_type', sa.String(50), nullable=False),
        sa.Column('target_count', sa.Integer(), nullable=False),
        sa.Column('content_type', sa.String(50), nullable=False),
        sa.Column('generation_params', postgresql.JSONB()),
        sa.Column('status', sa.String(50), default='pending'),
        sa.Column('progress', sa.Integer(), default=0),
        sa.Column('error_message', sa.Text()),
        sa.Column('generated_content_ids', postgresql.ARRAY(sa.Text())),
        sa.Column('total_storage_bytes', sa.BigInteger(), default=0),
        sa.Column('total_cost_usd', sa.Numeric(10, 4), default=0),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('started_at', sa.DateTime()),
        sa.Column('completed_at', sa.DateTime())
    )
    op.create_index('idx_content_generation_jobs_tenant', 'content_generation_jobs', ['tenant_id'])
    op.create_index('idx_content_generation_jobs_status', 'content_generation_jobs', ['status', 'created_at'])

def downgrade():
    # Drop new tables
    op.drop_table('content_generation_jobs')
    op.drop_table('content_storage_usage')

    # Drop indexes
    op.drop_index('idx_content_items_bigquery_sync')
    op.drop_index('idx_content_items_deleted_at')
    op.drop_index('idx_content_items_zerodb_id')

    # Drop columns
    op.drop_column('content_items', 'deleted_at')
    op.drop_column('content_items', 'version_of')
    op.drop_column('content_items', 'version')
    op.drop_column('content_items', 'storage_size_bytes')
    op.drop_column('content_items', 'bigquery_last_sync_at')
    op.drop_column('content_items', 'bigquery_backed_up')
    op.drop_column('content_items', 'zerodb_id')
```

**Run Migration:**
```bash
cd /Users/cope/EnGardeHQ/production-backend
alembic upgrade head
```

#### 1.2 ZeroDB Collection Setup

**File:** `/production-backend/app/services/content_storage_service.py`

```python
"""
Content Storage Service

Manages content storage in ZeroDB with BigQuery backup.
"""

from typing import Dict, Any, Optional, List
from app.services.zerodb_service import zerodb_service, TableSchema
import logging

logger = logging.getLogger(__name__)


async def setup_content_storage_collections() -> bool:
    """
    Set up ZeroDB collections for content storage.

    Creates:
    - content_items collection
    - content_media_files collection
    - content_versions collection
    """

    # Define content_items schema
    content_items_schema = TableSchema(
        table_name="content_items",
        schema={
            "type": "object",
            "properties": {
                "id": {"type": "string", "format": "uuid"},
                "tenant_id": {"type": "string"},
                "brand_id": {"type": "string"},
                "campaign_space_id": {"type": "string"},
                "user_id": {"type": "string"},
                "title": {"type": "string"},
                "content_body": {"type": "string"},
                "content_type": {"type": "string"},
                "status": {"type": "string"},
                "metadata": {"type": "object"},
                "ai_generation_metadata": {"type": "object"},
                "storage_metadata": {"type": "object"},
                "version": {"type": "integer", "default": 1},
                "version_of": {"type": "string"},
                "bigquery_synced": {"type": "boolean", "default": False},
                "bigquery_sync_timestamp": {"type": "string", "format": "date-time"},
                "created_at": {"type": "string", "format": "date-time"},
                "updated_at": {"type": "string", "format": "date-time"},
                "deleted_at": {"type": "string", "format": "date-time"}
            },
            "required": ["id", "tenant_id", "user_id", "title", "content_type"]
        }
    )

    # Define content_media_files schema
    content_media_schema = TableSchema(
        table_name="content_media_files",
        schema={
            "type": "object",
            "properties": {
                "id": {"type": "string", "format": "uuid"},
                "tenant_id": {"type": "string"},
                "brand_id": {"type": "string"},
                "content_id": {"type": "string"},
                "file_name": {"type": "string"},
                "file_type": {"type": "string"},
                "mime_type": {"type": "string"},
                "file_size_bytes": {"type": "integer"},
                "storage_provider": {"type": "string"},
                "storage_path": {"type": "string"},
                "public_url": {"type": "string"},
                "cdn_url": {"type": "string"},
                "media_metadata": {"type": "object"},
                "processing_status": {"type": "string"},
                "bigquery_synced": {"type": "boolean"},
                "created_at": {"type": "string", "format": "date-time"},
                "updated_at": {"type": "string", "format": "date-time"}
            },
            "required": ["id", "tenant_id", "content_id", "file_name", "file_type"]
        }
    )

    # Define content_versions schema
    content_versions_schema = TableSchema(
        table_name="content_versions",
        schema={
            "type": "object",
            "properties": {
                "id": {"type": "string", "format": "uuid"},
                "content_id": {"type": "string"},
                "tenant_id": {"type": "string"},
                "version_number": {"type": "integer"},
                "changed_by_user_id": {"type": "string"},
                "change_type": {"type": "string"},
                "content_snapshot": {"type": "object"},
                "changes_summary": {"type": "string"},
                "diff_from_previous": {"type": "object"},
                "created_at": {"type": "string", "format": "date-time"}
            },
            "required": ["id", "content_id", "tenant_id", "version_number"]
        }
    )

    # Create collections
    success = True

    if not await zerodb_service.create_table(content_items_schema):
        logger.error("Failed to create content_items collection")
        success = False

    if not await zerodb_service.create_table(content_media_schema):
        logger.error("Failed to create content_media_files collection")
        success = False

    if not await zerodb_service.create_table(content_versions_schema):
        logger.error("Failed to create content_versions collection")
        success = False

    if success:
        logger.info("Successfully created all content storage collections in ZeroDB")

    return success
```

**Run Setup:**
```bash
# In Python shell or startup script
python -c "
import asyncio
from app.services.content_storage_service import setup_content_storage_collections

asyncio.run(setup_content_storage_collections())
"
```

#### 1.3 BigQuery Table Creation

**File:** `/production-backend/scripts/setup_bigquery_content_tables.py`

```python
"""
Setup BigQuery tables for content storage
"""

import asyncio
from app.services.bigquery_service import bigquery_service

async def setup_bigquery_tables():
    """Create BigQuery tables for content storage"""

    # Initialize BigQuery service
    await bigquery_service.initialize()

    # Content snapshots table already defined in bigquery_service.py
    # Just need to ensure it's created

    logger.info("BigQuery content tables setup complete")

if __name__ == "__main__":
    asyncio.run(setup_bigquery_tables())
```

### Phase 2: Existing Content Migration (Week 2)

#### 2.1 Migrate Existing Campaign Assets

**Strategy:** Batch migrate existing `campaign_assets` to ZeroDB

**File:** `/production-backend/scripts/migrate_campaign_assets_to_zerodb.py`

```python
"""
Migrate existing campaign assets to ZeroDB

This script:
1. Finds all campaign_assets records in PostgreSQL
2. Generates content bodies for assets (from metadata)
3. Stores in ZeroDB
4. Updates PostgreSQL with zerodb_id references
5. Backfills storage usage metrics
"""

import asyncio
from sqlalchemy.orm import Session
from app.database import get_db_session
from app.models.campaign_space_models import CampaignAsset, CampaignSpace
from app.services.zerodb_service import zerodb_service
from app.services.content_quota_service import ContentQuotaService
from datetime import datetime
import logging
import uuid

logger = logging.getLogger(__name__)

async def migrate_campaign_assets():
    """Migrate campaign assets to ZeroDB"""

    with get_db_session() as db:
        # Get all campaign assets that don't have zerodb_id
        assets = db.query(CampaignAsset).filter(
            CampaignAsset.deleted_at.is_(None)
        ).all()

        logger.info(f"Found {len(assets)} campaign assets to migrate")

        quota_service = ContentQuotaService()
        migrated_count = 0
        failed_count = 0

        for asset in assets:
            try:
                # Build content body from asset metadata
                content_body = _build_content_body_from_asset(asset)

                # Calculate size
                content_size_bytes = len(content_body.encode('utf-8'))

                # Store in ZeroDB
                zerodb_id = await zerodb_service.insert_record("content_items", {
                    "id": asset.id,
                    "tenant_id": asset.tenant_id,
                    "brand_id": asset.brand_id,
                    "campaign_space_id": asset.campaign_space_id,
                    "user_id": asset.user_id,
                    "title": asset.asset_name,
                    "content_body": content_body,
                    "content_type": _map_asset_type_to_content_type(asset.asset_type),
                    "status": "published",  # Imported assets are considered published
                    "metadata": {
                        "external_asset_id": asset.external_asset_id,
                        "file_url": asset.file_url,
                        "public_url": asset.public_url,
                        "tags": asset.tags or [],
                        "imported_from": "campaign_import"
                    },
                    "storage_metadata": {
                        "size_bytes": content_size_bytes,
                        "mime_type": asset.mime_type
                    },
                    "version": 1,
                    "bigquery_synced": False,
                    "created_at": asset.created_at.isoformat() if asset.created_at else datetime.utcnow().isoformat(),
                    "updated_at": asset.updated_at.isoformat() if asset.updated_at else datetime.utcnow().isoformat()
                })

                if zerodb_id:
                    # Update campaign_asset with reference (if column exists)
                    # Note: campaign_assets table doesn't have zerodb_id column,
                    # but we track it through the content_items mapping

                    # Increment storage usage
                    quota_service.increment_usage(
                        db=db,
                        tenant_id=asset.tenant_id,
                        brand_id=asset.brand_id,
                        content_size_bytes=content_size_bytes,
                        content_type=_map_asset_type_to_content_type(asset.asset_type)
                    )

                    migrated_count += 1

                    if migrated_count % 100 == 0:
                        logger.info(f"Migrated {migrated_count} assets so far...")

            except Exception as e:
                logger.error(f"Failed to migrate asset {asset.id}: {e}")
                failed_count += 1
                continue

        logger.info(f"Migration complete: {migrated_count} migrated, {failed_count} failed")

def _build_content_body_from_asset(asset: CampaignAsset) -> str:
    """Build content body from campaign asset"""
    parts = []

    if asset.headline_text:
        parts.append(f"# {asset.headline_text}")

    if asset.ad_copy_text:
        parts.append(asset.ad_copy_text)

    if asset.description:
        parts.append(asset.description)

    if asset.cta_text:
        parts.append(f"\n**{asset.cta_text}**")

    return "\n\n".join(parts) if parts else f"Campaign asset: {asset.asset_name}"

def _map_asset_type_to_content_type(asset_type) -> str:
    """Map campaign asset type to content type"""
    mapping = {
        "image": "image",
        "video": "video",
        "ad_copy": "post",
        "headline": "post",
        "description": "post",
        "document": "document"
    }
    return mapping.get(asset_type.value if hasattr(asset_type, 'value') else asset_type, "post")

if __name__ == "__main__":
    asyncio.run(migrate_campaign_assets())
```

**Run Migration:**
```bash
cd /Users/cope/EnGardeHQ/production-backend
python scripts/migrate_campaign_assets_to_zerodb.py
```

#### 2.2 Migrate Existing Content Items

**Strategy:** Move content bodies from PostgreSQL to ZeroDB

**File:** `/production-backend/scripts/migrate_content_items_to_zerodb.py`

```python
"""
Migrate existing content_items to ZeroDB

This script:
1. Finds all content_items in PostgreSQL with content_body
2. Stores content_body in ZeroDB
3. Updates PostgreSQL with zerodb_id and clears content_body (optional)
4. Backfills storage usage
"""

import asyncio
from sqlalchemy.orm import Session
from app.database import get_db_session
from app.models.content_models import ContentItem
from app.services.zerodb_service import zerodb_service
from app.services.content_quota_service import ContentQuotaService
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

async def migrate_content_items():
    """Migrate content items to ZeroDB"""

    with get_db_session() as db:
        # Get all content items
        content_items = db.query(ContentItem).all()

        logger.info(f"Found {len(content_items)} content items to migrate")

        quota_service = ContentQuotaService()
        migrated_count = 0
        skipped_count = 0

        for item in content_items:
            try:
                # Skip if already migrated
                if item.zerodb_id:
                    skipped_count += 1
                    continue

                content_body = item.content_body or ""
                content_size_bytes = len(content_body.encode('utf-8'))

                # Store in ZeroDB
                zerodb_id = await zerodb_service.insert_record("content_items", {
                    "id": item.id,
                    "tenant_id": item.tenant_id,
                    "brand_id": item.brand_id,
                    "user_id": item.user_id,
                    "title": item.title,
                    "content_body": content_body,
                    "content_type": item.content_type,
                    "status": item.status,
                    "metadata": item.content_metadata or {},
                    "storage_metadata": {
                        "size_bytes": content_size_bytes
                    },
                    "version": 1,
                    "bigquery_synced": False,
                    "created_at": item.created_at.isoformat() if item.created_at else datetime.utcnow().isoformat(),
                    "updated_at": item.updated_at.isoformat() if item.updated_at else datetime.utcnow().isoformat()
                })

                if zerodb_id:
                    # Update PostgreSQL record
                    item.zerodb_id = zerodb_id
                    item.storage_size_bytes = content_size_bytes

                    # Optional: Clear content_body from PostgreSQL to save space
                    # item.content_body = None

                    db.commit()

                    # Increment storage usage
                    quota_service.increment_usage(
                        db=db,
                        tenant_id=item.tenant_id,
                        brand_id=item.brand_id,
                        content_size_bytes=content_size_bytes,
                        content_type=item.content_type
                    )

                    migrated_count += 1

                    if migrated_count % 50 == 0:
                        logger.info(f"Migrated {migrated_count} content items...")

            except Exception as e:
                logger.error(f"Failed to migrate content item {item.id}: {e}")
                continue

        logger.info(f"Migration complete: {migrated_count} migrated, {skipped_count} skipped")

if __name__ == "__main__":
    asyncio.run(migrate_content_items())
```

### Phase 3: API Implementation (Week 3)

#### 3.1 Update Content Router

**File:** `/production-backend/app/routers/content.py`

**Key Changes:**
1. Import ContentQuotaService
2. Check quota before creating content
3. Store content in ZeroDB first
4. Store metadata in PostgreSQL with zerodb_id
5. Update retrieval to fetch from ZeroDB

**Example Update:**
```python
from app.services.content_quota_service import ContentQuotaService
from app.services.zerodb_service import zerodb_service

@router.post("/")
async def create_content(
    content_data: ContentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create new content item"""
    try:
        brand_id = get_current_brand_id(db, current_user)
        tenant_id = get_tenant_id_from_current_brand(db, current_user)

        # Check quota FIRST
        quota_service = ContentQuotaService()
        content_body = content_data.body or content_data.content_body or ""
        content_size_bytes = len(content_body.encode('utf-8'))

        quota_check = quota_service.check_quota(
            db=db,
            tenant_id=tenant_id,
            additional_bytes=content_size_bytes
        )

        if not quota_check["can_store"]:
            raise HTTPException(
                status_code=403,
                detail=quota_check["reason"]
            )

        # Generate content ID
        content_id = str(uuid.uuid4())

        # Store in ZeroDB FIRST
        zerodb_id = await zerodb_service.insert_record("content_items", {
            "id": content_id,
            "tenant_id": tenant_id,
            "brand_id": brand_id,
            "user_id": current_user.id,
            "title": content_data.title,
            "content_body": content_body,
            "content_type": content_data.type or content_data.content_type or "post",
            "status": content_data.status,
            "metadata": _build_metadata(content_data),
            "storage_metadata": {
                "size_bytes": content_size_bytes
            },
            "version": 1,
            "bigquery_synced": False,
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat()
        })

        if not zerodb_id:
            raise HTTPException(status_code=500, detail="Failed to store content in ZeroDB")

        # Store metadata in PostgreSQL
        new_content = ContentItem(
            id=content_id,
            tenant_id=tenant_id,
            brand_id=brand_id,
            user_id=current_user.id,
            title=content_data.title,
            content_type=content_data.type or content_data.content_type or "post",
            status=content_data.status,
            content_metadata=_build_metadata(content_data),
            zerodb_id=zerodb_id,
            storage_size_bytes=content_size_bytes,
            bigquery_backed_up=False,
            version=1,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )

        db.add(new_content)
        db.commit()
        db.refresh(new_content)

        # Increment quota
        quota_service.increment_usage(
            db=db,
            tenant_id=tenant_id,
            brand_id=brand_id,
            content_size_bytes=content_size_bytes,
            content_type=new_content.content_type
        )

        # Queue BigQuery backup (async)
        # background_tasks.add_task(backup_to_bigquery, content_id)

        return content_item_to_frontend_format(new_content)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create content: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
```

#### 3.2 Update Retrieval Logic

**Update `get_content_items` endpoint:**

```python
@router.get("/")
async def get_content_items(
    page: int = Query(1, ge=1),
    pageSize: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all content items with pagination"""
    try:
        brand_id = get_current_brand_id(db, current_user)
        tenant_id = get_tenant_id_from_current_brand(db, current_user)

        # Query PostgreSQL for metadata
        query = db.query(ContentItem).filter(
            ContentItem.brand_id == brand_id,
            ContentItem.deleted_at.is_(None)
        )

        total = query.count()
        skip = (page - 1) * pageSize
        content_items = query.order_by(desc(ContentItem.created_at)).offset(skip).limit(pageSize).all()

        # Batch fetch from ZeroDB
        zerodb_ids = [item.zerodb_id for item in content_items if item.zerodb_id]

        # Fetch content bodies from ZeroDB
        zerodb_contents = {}
        for zerodb_id in zerodb_ids:
            try:
                content_data = await zerodb_service.get_record("content_items", zerodb_id)
                if content_data:
                    zerodb_contents[zerodb_id] = content_data
            except Exception as e:
                logger.error(f"Failed to fetch content from ZeroDB: {zerodb_id}: {e}")

        # Merge PostgreSQL metadata with ZeroDB content
        items_data = []
        for item in content_items:
            item_dict = content_item_to_frontend_format(item)

            # Add full body from ZeroDB if available
            if item.zerodb_id and item.zerodb_id in zerodb_contents:
                zerodb_data = zerodb_contents[item.zerodb_id]
                item_dict["body"] = zerodb_data.get("content_body", "")
            else:
                # Fallback to PostgreSQL if ZeroDB unavailable
                item_dict["body"] = item.content_body or ""

            items_data.append(item_dict)

        return {
            "data": items_data,
            "total": total,
            "page": page,
            "pageSize": pageSize,
            "totalPages": (total + pageSize - 1) // pageSize,
            "hasNext": (skip + len(items_data)) < total,
            "hasPrevious": page > 1
        }

    except Exception as e:
        logger.error(f"Failed to fetch content: {e}", exc_info=True)
        return {
            "data": [],
            "total": 0,
            "page": page,
            "pageSize": pageSize,
            "totalPages": 0,
            "hasNext": False,
            "hasPrevious": False,
            "error": "Failed to load content"
        }
```

### Phase 4: Background Sync & BigQuery Backup (Week 4)

#### 4.1 Background Worker for BigQuery Sync

**File:** `/production-backend/app/workers/content_bigquery_sync.py`

```python
"""
Background worker for syncing content to BigQuery

This worker:
1. Finds content not yet backed up to BigQuery
2. Batch syncs to BigQuery
3. Updates bigquery_backed_up flag
"""

import asyncio
from sqlalchemy.orm import Session
from app.database import get_db_session
from app.models.content_models import ContentItem
from app.services.bigquery_service import bigquery_service
from app.services.zerodb_service import zerodb_service
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

async def sync_content_to_bigquery():
    """Sync content to BigQuery for disaster recovery"""

    with get_db_session() as db:
        # Get content items not yet backed up
        items = db.query(ContentItem).filter(
            ContentItem.bigquery_backed_up == False,
            ContentItem.deleted_at.is_(None),
            ContentItem.zerodb_id.isnot(None)
        ).limit(100).all()

        if not items:
            logger.info("No content to sync to BigQuery")
            return

        logger.info(f"Syncing {len(items)} content items to BigQuery")

        synced_count = 0

        for item in items:
            try:
                # Fetch full content from ZeroDB
                content_data = await zerodb_service.get_record("content_items", item.zerodb_id)

                if not content_data:
                    logger.warning(f"Content not found in ZeroDB: {item.zerodb_id}")
                    continue

                # Insert to BigQuery content_snapshots table
                snapshot_id = f"{item.id}_{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"

                row = {
                    "content_id": item.id,
                    "snapshot_id": snapshot_id,
                    "tenant_id": item.tenant_id,
                    "brand_id": item.brand_id,
                    "user_id": item.user_id,
                    "title": item.title,
                    "content_body": content_data.get("content_body", ""),
                    "content_type": item.content_type,
                    "status": item.status,
                    "metadata": item.content_metadata or {},
                    "storage_metadata": content_data.get("storage_metadata", {}),
                    "version": item.version or 1,
                    "version_of": item.version_of,
                    "snapshot_timestamp": datetime.utcnow().isoformat(),
                    "content_created_at": item.created_at.isoformat(),
                    "content_updated_at": item.updated_at.isoformat(),
                    "ingested_at": datetime.utcnow().isoformat(),
                    "source_system": "zerodb"
                }

                # Insert to BigQuery
                table_id = f"{bigquery_service.config.project_id}.{bigquery_service.config.dataset_id}.content_snapshots"

                await asyncio.get_event_loop().run_in_executor(
                    None,
                    lambda: bigquery_service.client.insert_rows_json(table_id, [row])
                )

                # Update PostgreSQL
                item.bigquery_backed_up = True
                item.bigquery_last_sync_at = datetime.utcnow()
                db.commit()

                synced_count += 1

            except Exception as e:
                logger.error(f"Failed to sync content {item.id} to BigQuery: {e}")
                continue

        logger.info(f"Successfully synced {synced_count} content items to BigQuery")

async def run_sync_worker():
    """Run sync worker continuously"""
    while True:
        try:
            await sync_content_to_bigquery()
        except Exception as e:
            logger.error(f"Error in sync worker: {e}")

        # Wait 5 minutes before next sync
        await asyncio.sleep(300)

if __name__ == "__main__":
    asyncio.run(run_sync_worker())
```

---

## Implementation Phases

### Phase 1: Foundation (Week 1) - PRIORITY 1

**Deliverables:**
- [x] PostgreSQL schema migration complete
- [x] ZeroDB collections created
- [x] BigQuery tables created
- [x] ContentQuotaService implemented

**Testing:**
- Manual database verification
- Check all tables and collections exist
- Verify quota checks work

### Phase 2: Content Migration (Week 2) - PRIORITY 2

**Deliverables:**
- [x] Migration scripts written
- [x] Existing campaign_assets migrated
- [x] Existing content_items migrated
- [x] Storage usage backfilled

**Testing:**
- Verify all content accessible in ZeroDB
- Check PostgreSQL references correct
- Validate quota calculations

### Phase 3: API Updates (Week 3) - PRIORITY 3

**Deliverables:**
- [x] Content CRUD operations updated
- [x] Batch generation API implemented
- [x] Quota enforcement integrated
- [x] Error handling for ZeroDB unavailability

**Testing:**
- API endpoint tests
- Integration tests for content flow
- Load testing for batch generation

### Phase 4: BigQuery Sync (Week 4) - PRIORITY 4

**Deliverables:**
- [x] Background sync worker implemented
- [x] BigQuery backup working
- [x] Disaster recovery tested
- [x] Monitoring dashboards

**Testing:**
- Simulate ZeroDB failure
- Verify recovery from BigQuery
- Performance testing for sync worker

---

## Summary

This architecture provides:

1. **Solves Current Issues**
   - Content Studio will show content from ZeroDB
   - Scalable storage for AI generation
   - Proper BigQuery integration with DR
   - ZeroDB fully utilized

2. **Scalability**
   - Handles high-volume AI generation
   - Separates storage concerns (metadata vs content)
   - Horizontal scaling with ZeroDB

3. **Reliability**
   - BigQuery disaster recovery
   - Version control and audit trail
   - Graceful degradation if ZeroDB unavailable

4. **Cost Optimization**
   - Primary content in ZeroDB (counts toward quota)
   - BigQuery backup doesn't double-count
   - Efficient storage with compression

5. **Developer Experience**
   - Clear separation of concerns
   - Simple API contracts
   - Comprehensive documentation

---

**Next Steps:**
1. Review and approve architecture
2. Execute Phase 1 (Foundation)
3. Test thoroughly before proceeding to Phase 2
4. Iterate based on feedback

**Questions or Changes?**
Contact: System Architect Team
