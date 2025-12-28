# Walker Agents Lakehouse Architecture
## Complete Microservices Infrastructure Guide

**Date**: December 27, 2025
**Status**: Implementation Guide
**Purpose**: Unified lakehouse architecture across all Walker Agent microservices

---

## Executive Summary

Each Walker Agent has its own dedicated microservice with an identical lakehouse architecture:
- **Apache Airflow**: ETL processing engine with DAG-based orchestration
- **MinIO**: S3-compatible object storage for bucket management
- **PostgreSQL**: Data lakehouse for structured analytics
- **Redis**: Caching and task queue
- **Celery**: Asynchronous task processing
- **FastAPI**: REST API layer

---

## Walker Agent → Microservice Mapping

| Walker Agent Type | Microservice | Port | Purpose |
|-------------------|--------------|------|---------|
| **SEO Agent** | OnSide | 8000 | Search rankings, PageSpeed, domain authority |
| **Content Generation Agent** | OnSide | 8000 | AI-powered content creation (shares OnSide) |
| **Paid Ads Agent** | Sankore | 8001 | Ad campaign intelligence, trend analysis |
| **Audience Intelligence Agent** | MadanSara | 8002 | Conversion optimization, outreach automation |

---

## Current State Assessment

### ✅ OnSide (SEO + Content) - **FULLY CONFIGURED**

**Status**: Production-ready with complete lakehouse architecture

**Infrastructure**:
- ✅ Apache Airflow (DAGs in `dags/` directory)
- ✅ MinIO (configured in docker-compose.yml, ports 9000/9001)
- ✅ PostgreSQL (configured as lakehouse)
- ✅ Redis (caching + Celery broker)
- ✅ Celery Worker + Beat
- ✅ Flower (Celery monitoring, port 5555)

**Existing DAGs**:
- `data_ingestion_dag.py` - External API ingestion
- `analytics_pipeline_dag.py` - Analytics processing
- `seo_pipeline_dag.py` - SEO Walker Agent (NEW)

**Next Step**: Create `content_generation_dag.py` for Content Walker Agent

---

### ⚠️ Sankore (Paid Ads) - **NEEDS LAKEHOUSE UPGRADE**

**Current State**:
- ✅ FastAPI application (production-ready)
- ✅ PostgreSQL database
- ✅ Redis caching
- ❌ **MISSING: Apache Airflow**
- ❌ **MISSING: MinIO object storage**
- ❌ **MISSING: Celery workers**
- ❌ **MISSING: DAGs for ad data processing**

**What Needs to be Added**:
1. MinIO service for ad creative storage, performance data buckets
2. Airflow setup with DAGs for:
   - Google Ads data ingestion
   - Meta Ads data ingestion
   - LinkedIn Ads data ingestion
   - Ad performance aggregation
   - Budget optimization recommendations
   - Walker Agent notifications
3. Celery workers for async task processing
4. Directory structure: `dags/`, `alembic/`

**Priority**: HIGH - Paid Ads Agent is critical functionality

---

### ⚠️ MadanSara (Audience Intelligence) - **NEEDS LAKEHOUSE UPGRADE**

**Current State**:
- ✅ Basic FastAPI structure (in planning phase)
- ✅ PostgreSQL (via Alembic migrations setup)
- ❌ **MISSING: Apache Airflow**
- ❌ **MISSING: MinIO object storage**
- ❌ **MISSING: Redis + Celery**
- ❌ **MISSING: Complete service implementation**

**What Needs to be Added**:
1. MinIO service for audience segment data, outreach templates
2. Airflow setup with DAGs for:
   - Audience segmentation processing
   - Engagement data collection
   - Conversion funnel analysis
   - Multi-channel outreach scheduling
   - A/B test result aggregation
   - Walker Agent notifications
3. Redis + Celery for async outreach automation
4. Complete docker-compose.yml with all services

**Priority**: MEDIUM - Foundation exists but needs build-out

---

## Standardized Lakehouse Architecture

Each microservice MUST implement this architecture:

```
{microservice}/
├── src/                          # Source code
│   ├── api/                      # FastAPI endpoints
│   ├── models/                   # SQLAlchemy models
│   ├── services/                 # Business logic
│   ├── repositories/             # Data access layer
│   └── core/                     # Core utilities
├── dags/                         # Airflow DAG definitions
│   ├── data_ingestion_dag.py
│   ├── analytics_pipeline_dag.py
│   └── {agent}_walker_dag.py
├── alembic/                      # Database migrations
├── tests/                        # Test suites
├── scripts/                      # Utility scripts
├── docs/                         # Documentation
├── docker-compose.yml            # Multi-service orchestration
├── .env.example                  # Environment template
└── README.md                     # Service documentation
```

---

## Docker Compose Standard Template

Each microservice docker-compose.yml MUST include:

```yaml
version: "3.8"

services:
  # FastAPI Application
  {service}-api:
    build: .
    ports:
      - "{port}:{port}"
    environment:
      - DATABASE_URL=postgresql://user:pass@{service}-db:5432/{service}
      - REDIS_URL=redis://{service}-redis:6379/0
      - MINIO_ENDPOINT={service}-minio:9000
      - MINIO_ACCESS_KEY=${MINIO_ACCESS_KEY}
      - MINIO_SECRET_KEY=${MINIO_SECRET_KEY}
    depends_on:
      - {service}-db
      - {service}-redis
      - {service}-minio
    networks:
      - {service}-network

  # PostgreSQL Lakehouse
  {service}-db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB={service}
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "{db_port}:5432"
    networks:
      - {service}-network

  # Redis Cache & Queue
  {service}-redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data
    ports:
      - "{redis_port}:6379"
    networks:
      - {service}-network

  # MinIO Object Storage
  {service}-minio:
    image: minio/minio:latest
    environment:
      - MINIO_ROOT_USER=${MINIO_ACCESS_KEY}
      - MINIO_ROOT_PASSWORD=${MINIO_SECRET_KEY}
    volumes:
      - minio-data:/data
    ports:
      - "{minio_port}:9000"
      - "{minio_console_port}:9001"
    command: server /data --console-address ":9001"
    networks:
      - {service}-network

  # Celery Worker
  {service}-celery-worker:
    build: .
    command: celery -A src.celery_app worker --loglevel=info
    environment:
      - DATABASE_URL=postgresql://user:pass@{service}-db:5432/{service}
      - REDIS_URL=redis://{service}-redis:6379/0
      - CELERY_BROKER_URL=redis://{service}-redis:6379/0
    depends_on:
      - {service}-db
      - {service}-redis
    networks:
      - {service}-network

  # Celery Beat (Scheduler)
  {service}-celery-beat:
    build: .
    command: celery -A src.celery_app beat --loglevel=info
    environment:
      - DATABASE_URL=postgresql://user:pass@{service}-db:5432/{service}
      - REDIS_URL=redis://{service}-redis:6379/0
      - CELERY_BROKER_URL=redis://{service}-redis:6379/0
    depends_on:
      - {service}-db
      - {service}-redis
    networks:
      - {service}-network

  # Flower (Celery Monitoring)
  {service}-flower:
    build: .
    command: celery -A src.celery_app flower --port=5555
    ports:
      - "{flower_port}:5555"
    environment:
      - CELERY_BROKER_URL=redis://{service}-redis:6379/0
    depends_on:
      - {service}-redis
    networks:
      - {service}-network

networks:
  {service}-network:
    driver: bridge

volumes:
  postgres-data:
  redis-data:
  minio-data:
```

---

## Port Allocation Strategy

To avoid conflicts, each microservice uses a dedicated port range:

| Microservice | API Port | DB Port | Redis Port | MinIO | MinIO Console | Flower |
|--------------|----------|---------|------------|-------|---------------|--------|
| **OnSide** | 8000 | 5432 | 6379 | 9000 | 9001 | 5555 |
| **Sankore** | 8001 | 5433 | 6380 | 9002 | 9003 | 5556 |
| **MadanSara** | 8002 | 5434 | 6381 | 9004 | 9005 | 5557 |

---

## Sankore Lakehouse Implementation Plan

### Phase 1: Add MinIO Service

**Update**: `/Users/cope/EnGardeHQ/Sankore/docker-compose.yml`

```yaml
  # MinIO Object Storage (ADD THIS)
  sankore-minio:
    image: minio/minio:latest
    container_name: sankore-minio
    ports:
      - "9002:9000"
      - "9003:9001"
    environment:
      - MINIO_ROOT_USER=sankore-minio-key
      - MINIO_ROOT_PASSWORD=sankore-minio-secret
    volumes:
      - minio_data:/data
    networks:
      - sankore-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 10s
      retries: 3
    command: server /data --console-address ":9001"

volumes:
  postgres_data:
  redis_data:
  minio_data:  # ADD THIS
```

### Phase 2: Add Celery Services

```yaml
  # Celery Worker (ADD THIS)
  sankore-celery-worker:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    container_name: sankore-celery-worker
    command: celery -A src.celery_app worker --loglevel=info --concurrency=4 -Q default,ads,trends,analysis
    environment:
      - DATABASE_URL=postgresql+asyncpg://sankore:sankore_password@postgres:5432/sankore_db
      - REDIS_URL=redis://redis:6379/0
      - CELERY_BROKER_URL=redis://redis:6379/0
      - CELERY_RESULT_BACKEND=redis://redis:6379/0
      - MINIO_ENDPOINT=sankore-minio:9000
      - MINIO_ACCESS_KEY=sankore-minio-key
      - MINIO_SECRET_KEY=sankore-minio-secret
    depends_on:
      - postgres
      - redis
      - sankore-minio
    networks:
      - sankore-network

  # Celery Beat Scheduler (ADD THIS)
  sankore-celery-beat:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    container_name: sankore-celery-beat
    command: celery -A src.celery_app beat --loglevel=info
    environment:
      - DATABASE_URL=postgresql+asyncpg://sankore:sankore_password@postgres:5432/sankore_db
      - REDIS_URL=redis://redis:6379/0
      - CELERY_BROKER_URL=redis://redis:6379/0
      - CELERY_RESULT_BACKEND=redis://redis:6379/0
    depends_on:
      - postgres
      - redis
    networks:
      - sankore-network

  # Flower Monitoring (ADD THIS)
  sankore-flower:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    container_name: sankore-flower
    command: celery -A src.celery_app flower --port=5555
    ports:
      - "5556:5555"
    environment:
      - CELERY_BROKER_URL=redis://redis:6379/0
      - CELERY_RESULT_BACKEND=redis://redis:6379/0
    depends_on:
      - redis
    networks:
      - sankore-network
```

### Phase 3: Create Airflow DAG Directory

```bash
cd /Users/cope/EnGardeHQ/Sankore
mkdir -p dags
```

### Phase 4: Create Paid Ads Walker Agent DAG

**File**: `/Users/cope/EnGardeHQ/Sankore/dags/paid_ads_walker_dag.py`

```python
"""
Paid Ads Walker Agent Pipeline DAG

This DAG processes paid advertising data for the Walker Agent:
- Google Ads performance data ingestion
- Meta Ads performance data ingestion
- LinkedIn Ads performance data ingestion
- Ad creative storage to MinIO
- Performance metrics aggregation
- Budget optimization recommendations
- Walker Agent notifications
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.utils.task_group import TaskGroup

def ingest_google_ads_data(**context):
    """Ingest Google Ads campaign performance data"""
    # Implementation here
    pass

def ingest_meta_ads_data(**context):
    """Ingest Meta Ads campaign performance data"""
    # Implementation here
    pass

def ingest_linkedin_ads_data(**context):
    """Ingest LinkedIn Ads campaign performance data"""
    # Implementation here
    pass

def calculate_roas_metrics(**context):
    """Calculate ROAS and efficiency metrics"""
    # Implementation here
    pass

def identify_budget_optimizations(**context):
    """Identify budget reallocation opportunities"""
    # Implementation here
    pass

def generate_creative_recommendations(**context):
    """Generate ad creative recommendations using AI"""
    # Implementation here
    pass

def aggregate_results(**context):
    """Aggregate all ad performance results"""
    # Implementation here
    pass

def notify_walker_agent(**context):
    """Send insights to Paid Ads Walker Agent"""
    # Implementation here
    pass

default_args = {
    'owner': 'walker-agent',
    'depends_on_past': True,
    'start_date': datetime(2025, 1, 1),
    'email': ['paid-ads-walker@engarde.media'],
    'email_on_failure': True,
    'retries': 2,
    'retry_delay': timedelta(minutes=10),
}

dag = DAG(
    'paid_ads_walker_agent_pipeline',
    default_args=default_args,
    description='Paid Ads Walker Agent daily pipeline',
    schedule_interval='0 6 * * *',  # 6 AM daily
    catchup=False,
    tags=['walker-agent', 'paid-ads', 'sankore'],
    max_active_runs=1,
)

# Task definitions
start = DummyOperator(task_id='start', dag=dag)

with TaskGroup('ad_platform_ingestion', dag=dag) as ingestion_group:
    google_ads = PythonOperator(
        task_id='ingest_google_ads',
        python_callable=ingest_google_ads_data,
        provide_context=True,
    )
    meta_ads = PythonOperator(
        task_id='ingest_meta_ads',
        python_callable=ingest_meta_ads_data,
        provide_context=True,
    )
    linkedin_ads = PythonOperator(
        task_id='ingest_linkedin_ads',
        python_callable=ingest_linkedin_ads_data,
        provide_context=True,
    )

calc_roas = PythonOperator(
    task_id='calculate_roas',
    python_callable=calculate_roas_metrics,
    provide_context=True,
    dag=dag,
)

with TaskGroup('optimization_analysis', dag=dag) as analysis_group:
    budget_opt = PythonOperator(
        task_id='identify_budget_optimizations',
        python_callable=identify_budget_optimizations,
        provide_context=True,
    )
    creative_rec = PythonOperator(
        task_id='generate_creative_recommendations',
        python_callable=generate_creative_recommendations,
        provide_context=True,
    )

aggregate = PythonOperator(
    task_id='aggregate_results',
    python_callable=aggregate_results,
    provide_context=True,
    dag=dag,
)

notify = PythonOperator(
    task_id='notify_walker_agent',
    python_callable=notify_walker_agent,
    provide_context=True,
    dag=dag,
)

end = DummyOperator(task_id='end', dag=dag)

# Dependencies
start >> ingestion_group >> calc_roas >> analysis_group >> aggregate >> notify >> end
```

### Phase 5: Update Environment Variables

**Add to**: `/Users/cope/EnGardeHQ/Sankore/.env.example`

```bash
# MinIO Object Storage
MINIO_ENDPOINT=sankore-minio:9000
MINIO_ACCESS_KEY=sankore-minio-key
MINIO_SECRET_KEY=sankore-minio-secret

# Celery Configuration
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0
CELERY_TASK_TRACK_STARTED=true

# EnGarde Integration
ENGARDE_API_URL=https://api.engarde.com
ENGARDE_API_KEY=your-api-key
ENGARDE_TENANT_UUID=your-tenant-uuid
```

---

## MadanSara Lakehouse Implementation Plan

### Phase 1: Create Complete docker-compose.yml

**Create**: `/Users/cope/EnGardeHQ/MadanSara/docker-compose.yml`

```yaml
version: "3.8"

services:
  # MadanSara API
  madansara-api:
    build: .
    container_name: madansara-api
    ports:
      - "8002:8002"
    environment:
      - DATABASE_URL=postgresql://postgres:madansara_password@madansara-db:5432/madansara
      - REDIS_URL=redis://madansara-redis:6379/0
      - MINIO_ENDPOINT=madansara-minio:9000
      - MINIO_ACCESS_KEY=madansara-minio-key
      - MINIO_SECRET_KEY=madansara-minio-secret
    depends_on:
      - madansara-db
      - madansara-redis
      - madansara-minio
    networks:
      - madansara-network

  # PostgreSQL Lakehouse
  madansara-db:
    image: postgres:15-alpine
    container_name: madansara-db
    environment:
      - POSTGRES_DB=madansara
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=madansara_password
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "5434:5432"
    networks:
      - madansara-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d madansara"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache & Queue
  madansara-redis:
    image: redis:7-alpine
    container_name: madansara-redis
    volumes:
      - redis-data:/data
    ports:
      - "6381:6379"
    networks:
      - madansara-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # MinIO Object Storage
  madansara-minio:
    image: minio/minio:latest
    container_name: madansara-minio
    ports:
      - "9004:9000"
      - "9005:9001"
    environment:
      - MINIO_ROOT_USER=madansara-minio-key
      - MINIO_ROOT_PASSWORD=madansara-minio-secret
    volumes:
      - minio-data:/data
    networks:
      - madansara-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 10s
      retries: 3
    command: server /data --console-address ":9001"

  # Celery Worker
  madansara-celery-worker:
    build: .
    container_name: madansara-celery-worker
    command: celery -A app.celery_app worker --loglevel=info --concurrency=4 -Q default,outreach,segmentation,analysis
    environment:
      - DATABASE_URL=postgresql://postgres:madansara_password@madansara-db:5432/madansara
      - REDIS_URL=redis://madansara-redis:6379/0
      - CELERY_BROKER_URL=redis://madansara-redis:6379/0
      - MINIO_ENDPOINT=madansara-minio:9000
    depends_on:
      - madansara-db
      - madansara-redis
      - madansara-minio
    networks:
      - madansara-network

  # Celery Beat
  madansara-celery-beat:
    build: .
    container_name: madansara-celery-beat
    command: celery -A app.celery_app beat --loglevel=info
    environment:
      - DATABASE_URL=postgresql://postgres:madansara_password@madansara-db:5432/madansara
      - REDIS_URL=redis://madansara-redis:6379/0
      - CELERY_BROKER_URL=redis://madansara-redis:6379/0
    depends_on:
      - madansara-db
      - madansara-redis
    networks:
      - madansara-network

  # Flower Monitoring
  madansara-flower:
    build: .
    container_name: madansara-flower
    command: celery -A app.celery_app flower --port=5555
    ports:
      - "5557:5555"
    environment:
      - CELERY_BROKER_URL=redis://madansara-redis:6379/0
    depends_on:
      - madansara-redis
    networks:
      - madansara-network

networks:
  madansara-network:
    driver: bridge

volumes:
  postgres-data:
  redis-data:
  minio-data:
```

### Phase 2: Create DAG Directory and Audience Intelligence DAG

```bash
cd /Users/cope/EnGardeHQ/MadanSara
mkdir -p dags
```

**File**: `/Users/cope/EnGardeHQ/MadanSara/dags/audience_intelligence_walker_dag.py`

```python
"""
Audience Intelligence Walker Agent Pipeline DAG

This DAG processes audience conversion intelligence:
- Audience segmentation analysis
- Multi-channel outreach scheduling
- Conversion funnel tracking
- A/B test result aggregation
- Social engagement automation
- Walker Agent notifications
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.utils.task_group import TaskGroup

# DAG implementation similar to SEO and Paid Ads patterns
# ... (full implementation details)
```

---

## OnSide Content Generation DAG

### Create Content Generation Walker Agent DAG

**File**: `/Users/cope/EnGardeHQ/Onside/dags/content_generation_dag.py`

```python
"""
Content Generation Walker Agent Pipeline DAG

This DAG processes content generation and performance analysis:
- Content generation via OpenAI/Anthropic APIs
- Content performance tracking
- Engagement metrics analysis
- Content optimization recommendations
- Walker Agent notifications
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.utils.task_group import TaskGroup

# DAG implementation
# ... (full implementation details)
```

---

## Deployment Sequence

### Step 1: OnSide (Already Complete ✅)
```bash
cd /Users/cope/EnGardeHQ/Onside
docker-compose up -d
# Verify all services running
# Add content_generation_dag.py
```

### Step 2: Sankore (Upgrade Required)
```bash
cd /Users/cope/EnGardeHQ/Sankore

# 1. Update docker-compose.yml (add MinIO, Celery, Flower)
# 2. Create dags/ directory
# 3. Add paid_ads_walker_dag.py
# 4. Update .env with MinIO and Celery config

docker-compose down
docker-compose up -d

# Verify:
# - MinIO Console: http://localhost:9003
# - Flower: http://localhost:5556
# - API: http://localhost:8001/health
```

### Step 3: MadanSara (Build Required)
```bash
cd /Users/cope/EnGardeHQ/MadanSara

# 1. Create docker-compose.yml (full lakehouse stack)
# 2. Create dags/ directory
# 3. Add audience_intelligence_walker_dag.py
# 4. Complete FastAPI application structure

docker-compose up -d

# Verify:
# - MinIO Console: http://localhost:9005
# - Flower: http://localhost:5557
# - API: http://localhost:8002/health
```

---

## Summary

### Current Status
- ✅ **OnSide**: Fully configured lakehouse (SEO + Content)
- ⚠️ **Sankore**: Needs MinIO + Celery + Airflow additions
- ⚠️ **MadanSara**: Needs complete lakehouse implementation

### Next Actions
1. **Sankore**: Add lakehouse components to existing service
2. **MadanSara**: Build complete microservice with lakehouse
3. **OnSide**: Add Content Generation DAG

### Unified Architecture Benefits
- Consistent data processing patterns
- Reusable DAG templates
- Standardized deployment
- Unified monitoring via Flower
- Scalable object storage via MinIO
- Structured analytics via PostgreSQL
