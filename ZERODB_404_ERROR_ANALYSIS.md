# ZeroDB 404 Authentication Error - Root Cause Analysis

**Date:** 2025-11-17
**Issue:** Failed to query records from users: 404 - {"detail":"Not Found"}
**Project ID:** d9c00084-0185-4506-b9b5-3baa2369b813
**Environment:** Railway Production Deployment

---

## Executive Summary

The ZeroDB 404 error occurs when querying the "users" table due to a **fundamental mismatch between the implementation approach and the ZeroDB API architecture**. The service is attempting to use an event-sourcing pattern with the `/database/events` endpoint to simulate relational database operations, but this endpoint returns 404 because:

1. **Wrong API Endpoint Architecture**: The code uses `/database/events` for table operations, but this endpoint doesn't exist or isn't accessible
2. **API Key Mismatch**: Railway environment uses `ZERODB_API_KEY` but the code looks for `API_Key` first
3. **Incorrect Project ID**: Railway uses project ID `d9c00084-0185-4506-b9b5-3baa2369b813`, but local config has `5ad82287-06cd-469e-9a51-7ac1e151a2b9`
4. **Missing Table Infrastructure**: No actual "users" table exists in ZeroDB - the service tries to reconstruct it from events

---

## 1. Code Causing the 404 Error

### Location: `/Users/cope/EnGardeHQ/production-backend/app/services/zerodb_service.py`

**Lines 629-709: `query_records()` method**

```python
async def query_records(
    self,
    table_name: str,
    filters: Optional[Dict[str, Any]] = None,
    limit: int = 100,
    offset: int = 0
) -> List[Dict[str, Any]]:
    """Query records from a table with filters"""
    if self.mock_mode:
        logger.info(f"Mock: Querying {table_name} with filters {filters}")
        return [{
            "id": f"mock_record_{i}",
            "table_name": table_name,
            "mock_data": True,
            "created_at": "2025-08-19T00:00:00Z"
        } for i in range(min(limit, 5))]

    project_id = await self._ensure_project()

    try:
        session = await self._get_session()
        headers = {"X-API-Key": self.config.api_key}

        params = {
            "topic": f"table_{table_name}",
            "limit": min(limit * 2, 1000)  # Get more events to find latest versions
        }

        # THIS IS THE LINE CAUSING THE 404 ERROR
        async with session.get(
            f"{self.config.base_url}/public/projects/{project_id}/database/events",
            headers=headers,
            params=params
        ) as response:
            if response.status == 200:
                events = await response.json()

                # Process events to reconstruct current table state
                records = {}
                for event in events:
                    payload = event.get("event_payload", {})
                    if payload.get("table_name") == table_name:
                        record_id = payload.get("record_id")
                        operation = payload.get("operation")

                        if operation == "insert":
                            records[record_id] = payload.get("data", {})
                        elif operation == "update" and record_id in records:
                            records[record_id].update(payload.get("data", {}))
                        elif operation == "delete":
                            records.pop(record_id, None)

                # Apply filters and pagination...
                logger.info(f"Found {len(result)} records in {table_name}")
                return result
            else:
                error_text = await response.text()
                logger.error(f"Failed to query records from {table_name}: {response.status} - {error_text}")
                return []
```

**Called by:** `/Users/cope/EnGardeHQ/production-backend/app/services/zerodb_auth.py`

**Lines 40-59: `get_user_by_email()` method**

```python
async def get_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
    """Get user by email from ZeroDB"""
    try:
        logger.info(f"Searching for user with email: {email}")

        # ZeroDB filtering seems to have issues, so we'll use manual search
        # This is a temporary workaround until ZeroDB filtering is fixed
        all_users = await query_users(limit=100)  # THIS CALLS query_records() -> 404
        logger.info(f"Searching through {len(all_users)} users for email: {email}")

        for user in all_users:
            if user.get('email') == email:
                logger.info(f"Found user: {email} (ID: {user.get('id')})")
                return user

        logger.warning(f"User not found: {email}")
        return None
    except Exception as e:
        logger.error(f"Error getting user by email {email}: {e}")
        return None
```

---

## 2. Root Cause Analysis

### 2.1 Architectural Mismatch

**Problem:** The code implements a custom event-sourcing pattern to simulate relational database operations:

1. Insert operations publish events to `/database/events/publish` with topic `table_users`
2. Query operations try to read events from `/database/events` and reconstruct the current state
3. This pattern assumes ZeroDB has a functional events system for table operations

**Reality:** According to the ZeroDB DevGuide:
- Event operations exist for pub/sub messaging, NOT for relational table storage
- The `/database/events` endpoint is for event streaming, not table persistence
- There's no guarantee events persist long enough to reconstruct table state

### 2.2 Missing Table Infrastructure

**The Problem:**
```python
# Line 828-850: Table schema defined but never actually created
ENGARDE_TABLE_SCHEMAS = {
    "users": TableSchema(
        table_name="users",
        schema={
            "type": "object",
            "properties": {
                "id": {"type": "string", "format": "uuid"},
                "email": {"type": "string", "format": "email"},
                "hashed_password": {"type": "string", "minLength": 1},
                # ... more fields
            },
            "required": ["id", "email", "hashed_password"]
        }
    )
}
```

**The Issue:**
- Schema is defined but tables are never created in production
- `setup_engarde_tables()` function exists (line 1113) but isn't called during service initialization
- Railway deployment doesn't run table setup scripts

### 2.3 Configuration Issues

#### Issue A: API Key Variable Name Mismatch

**Code checks (line 48):**
```python
api_key = os.getenv("API_Key") or os.getenv("ZERODB_API_KEY")
```

**Railway environment has:**
```
ZERODB_API_KEY=8XjG6qVuCo1pUDBFtisVGUcIYf4uXByNCAY2LgtmTAE
```

**Local .env.zerodb has:**
```
API_Key=9khD3l6lpI9O7AwVOkxdl5ZOQP0upsu0vIsiQbLCUGk
```

**Impact:** Railway will use `ZERODB_API_KEY` as fallback, which works, but inconsistent configuration.

#### Issue B: Project ID Mismatch

**Railway environment:**
```
ZERODB_PROJECT_ID=d9c00084-0185-4506-b9b5-3baa2369b813
```

**Local .env.zerodb:**
```
ZERODB_PROJECT_ID=5ad82287-06cd-469e-9a51-7ac1e151a2b9
```

**Impact:** Different project IDs mean different data isolation between environments.

#### Issue C: Missing Railway Environment Variables

**Railway DOES NOT have:**
- `API_Key` (uses `ZERODB_API_KEY` instead)
- `API_Base_URL` (code defaults to `https://api.ainative.studio/api/v1`)

**Code fallback logic (lines 48-50):**
```python
api_key = os.getenv("API_Key") or os.getenv("ZERODB_API_KEY")
base_url = os.getenv("API_Base_URL") or os.getenv("ZERODB_API_URL") or "https://api.ainative.studio/api/v1"
project_id = os.getenv("ZERODB_PROJECT_ID")
```

This works due to fallback chain, but creates configuration inconsistency.

---

## 3. Why the 404 Error Occurs

### HTTP Request Being Made:
```
GET https://api.ainative.studio/api/v1/public/projects/d9c00084-0185-4506-b9b5-3baa2369b813/database/events?topic=table_users&limit=200
Headers:
  X-API-Key: 8XjG6qVuCo1pUDBFtisVGUcIYf4uXByNCAY2LlgtmTAE
```

### Why It Returns 404:

1. **Endpoint Doesn't Exist for This Use Case**
   - The `/database/events` endpoint is documented for pub/sub event streaming
   - It's NOT designed for relational table storage/retrieval
   - The ZeroDB API guide shows events are for messaging, not data persistence

2. **No Events Published Yet**
   - Even if the endpoint works, no user insert events were ever published
   - The users table was never populated using the event-sourcing pattern
   - Query returns 404 because there's no data matching the query

3. **Project May Not Have Events Enabled**
   - The project `d9c00084-0185-4506-b9b5-3baa2369b813` may not have event streaming enabled
   - Database initialization might not include events setup

4. **Wrong Authentication Credentials**
   - The truncated API key in Railway (`8XjG6qVuCo1pUDBFtisVGUcIYf4uXByNCAY2Lgtm`) may be incomplete
   - Full key should be verified against ZeroDB dashboard

---

## 4. ZeroDB API Documentation Analysis

According to `/docs/Zerodb_DevGuide.md`:

### Table Operations (Lines 313-316):
```
POST /api/v1/public/projects/{id}/database/tables - Create table
GET /api/v1/public/projects/{id}/database/tables - List tables
```

**Note:** Only CREATE and LIST endpoints exist. There's NO endpoint for:
- Querying table data (SELECT)
- Inserting records (INSERT)
- Updating records (UPDATE)
- Deleting records (DELETE)

### Event Operations (Lines 318-320):
```
POST /api/v1/public/projects/{id}/database/events/publish - Publish event
GET /api/v1/public/projects/{id}/database/events - List events
GET /api/v1/public/projects/{id}/database/events/stream - Stream events
```

**Purpose:** Event streaming and pub/sub messaging, NOT table data persistence.

### The Fundamental Problem:

**ZeroDB doesn't provide traditional relational database CRUD operations on tables.**

The service is trying to implement a **custom event-sourcing pattern** to simulate relational operations:
- Inserts → Publish event with topic `table_users`
- Queries → List events, filter by topic, reconstruct state
- Updates → Publish update event, merge with existing state
- Deletes → Publish delete event, remove from reconstructed state

**This pattern has critical flaws:**
1. Events may have retention limits (not designed for long-term storage)
2. No indexing or query optimization
3. Performance degrades linearly with event count
4. No transactional consistency guarantees
5. The `/database/events` endpoint may not support this use case at all

---

## 5. Configuration Issues Summary

### Railway Production Environment:
```bash
ZERODB_API_KEY=8XjG6qVuCo1pUDBFtisVGUcIYf4uXByNCAY2LgtmTAE  # Incomplete/truncated?
ZERODB_PROJECT_ID=d9c00084-0185-4506-b9b5-3baa2369b813
ZERODB_USERNAME=cope@engarde.media
ZERODB_PASSWORD=Yewande@535455
# MISSING: API_Key, API_Base_URL
```

### Local Development (.env.zerodb):
```bash
ZERODB_PROJECT_ID=5ad82287-06cd-469e-9a51-7ac1e151a2b9
ZERODB_API_KEY=9khD3l6lpI9O7AwVOkxdl5ZOQP0upsu0vIsiQbLCUGk
ZERODB_API_URL=https://api.ainative.studio/api/v1
API_Key=9khD3l6lpI9O7AwVOkxdl5ZOQP0upsu0vIsiQbLCUGk  # Duplicate
API_Base_URL=https://api.ainative.studio/api/v1        # Duplicate
```

### Issues:
1. **Different Project IDs** → Data isolation between environments
2. **Different API Keys** → Potential access/permissions mismatch
3. **Variable Name Inconsistency** → `API_Key` vs `ZERODB_API_KEY`
4. **Potential Truncated API Key** → Railway key appears cut off

---

## 6. Specific Code Changes Needed

### Fix #1: Stop Using Event-Sourcing for Tables

**Current broken approach:**
```python
# DON'T DO THIS - Events are not for table storage
async with session.get(
    f"{self.config.base_url}/public/projects/{project_id}/database/events",
    headers=headers,
    params={"topic": f"table_{table_name}"}
) as response:
    # Try to reconstruct table from events...
```

**Recommended approach:**

**Option A: Use ZeroDB Memory API for user data**
```python
async def get_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
    """Get user by email using ZeroDB Memory API"""
    try:
        # Search memories with email as metadata
        search_results = await zerodb_service.search_memory(
            query=email,
            limit=1
        )

        if search_results:
            memory = search_results[0]
            # User data stored in memory_metadata
            user_data = memory.get("memory_metadata", {})
            return user_data if user_data.get("email") == email else None

        return None
    except Exception as e:
        logger.error(f"Error searching user memory: {e}")
        return None
```

**Option B: Use PostgreSQL/SQLite for relational data**
```python
# Add to .env
DATABASE_URL=postgresql://user:pass@host:5432/engarde
USE_POSTGRES=true
USE_ZERODB=false  # Only for vectors/memory, not tables

# Update service to use SQLAlchemy for users table
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User

async def get_user_by_email(self, email: str, db: AsyncSession) -> Optional[User]:
    """Get user from PostgreSQL"""
    result = await db.execute(
        select(User).where(User.email == email)
    )
    return result.scalar_one_or_none()
```

**Option C: Use proper ZeroDB table API (if it exists)**
```python
# First verify this endpoint exists in ZeroDB
async def query_records(self, table_name: str, filters: Dict[str, Any]) -> List[Dict]:
    """Query using actual ZeroDB table query endpoint"""
    try:
        session = await self._get_session()
        headers = {"X-API-Key": self.config.api_key}

        # Use proper table query endpoint (verify this exists!)
        async with session.post(
            f"{self.config.base_url}/public/projects/{project_id}/database/tables/{table_name}/query",
            headers=headers,
            json={"filters": filters}
        ) as response:
            if response.status == 200:
                return await response.json()
            else:
                logger.error(f"Table query failed: {response.status}")
                return []
    except Exception as e:
        logger.error(f"Error querying table: {e}")
        return []
```

### Fix #2: Standardize Environment Variable Names

**Update zerodb_service.py:**
```python
# Lines 47-50: Simplify to single variable check
api_key = os.getenv("ZERODB_API_KEY")  # Use consistent name
base_url = os.getenv("ZERODB_API_URL", "https://api.ainative.studio/api/v1")
project_id = os.getenv("ZERODB_PROJECT_ID")
```

**Update Railway environment variables:**
```bash
# Add missing variables for consistency
railway variables set API_Key=8XjG6qVuCo1pUDBFtisVGUcIYf4uXByNCAY2LgtmTAE
railway variables set API_Base_URL=https://api.ainative.studio/api/v1

# Verify complete API key
railway variables set ZERODB_API_KEY=<FULL_API_KEY_FROM_ZERODB_DASHBOARD>
```

### Fix #3: Initialize Tables on Startup

**Add to app/main.py:**
```python
from app.services.zerodb_service import setup_engarde_tables

@app.on_event("startup")
async def startup_event():
    """Initialize ZeroDB tables on startup"""
    try:
        logger.info("Setting up ZeroDB tables...")
        success = await setup_engarde_tables()
        if success:
            logger.info("✅ All ZeroDB tables ready")
        else:
            logger.warning("⚠️ Some ZeroDB tables failed to initialize")
    except Exception as e:
        logger.error(f"❌ Failed to setup ZeroDB tables: {e}")
```

### Fix #4: Add Proper Error Handling

**Update query_records() method:**
```python
async def query_records(
    self,
    table_name: str,
    filters: Optional[Dict[str, Any]] = None,
    limit: int = 100,
    offset: int = 0
) -> List[Dict[str, Any]]:
    """Query records from a table with filters"""

    # Log configuration for debugging
    logger.info(f"Querying {table_name} with config: base_url={self.config.base_url}, project_id={self.config.project_id}")

    if self.mock_mode:
        logger.warning(f"Mock mode active - returning mock data for {table_name}")
        return self._generate_mock_data(table_name, limit)

    project_id = await self._ensure_project()

    try:
        session = await self._get_session()
        headers = {"X-API-Key": self.config.api_key}

        # Build the API URL
        api_url = f"{self.config.base_url}/public/projects/{project_id}/database/events"
        params = {"topic": f"table_{table_name}", "limit": min(limit * 2, 1000)}

        logger.info(f"Making request to: {api_url}")
        logger.debug(f"Query params: {params}")

        async with session.get(api_url, headers=headers, params=params) as response:
            response_text = await response.text()

            if response.status == 200:
                events = json.loads(response_text) if response_text else []
                records = self._reconstruct_records_from_events(events, table_name, filters)
                logger.info(f"Found {len(records)} records in {table_name}")
                return records[offset:offset+limit]
            elif response.status == 404:
                logger.error(f"404 Not Found - Endpoint or project doesn't exist")
                logger.error(f"URL: {api_url}")
                logger.error(f"Project ID: {project_id}")
                logger.error(f"Response: {response_text}")
                return []
            elif response.status == 401:
                logger.error(f"401 Unauthorized - API key may be invalid")
                logger.error(f"API Key (first 10 chars): {self.config.api_key[:10]}...")
                return []
            else:
                logger.error(f"Unexpected status {response.status}: {response_text}")
                return []

    except aiohttp.ClientError as e:
        logger.error(f"Network error querying {table_name}: {e}")
        return []
    except Exception as e:
        logger.error(f"Unexpected error querying {table_name}: {e}", exc_info=True)
        return []
```

---

## 7. Recommended Solution: Hybrid Approach

### Use the Right Tool for Each Job:

1. **PostgreSQL/SQLite for Relational Data (Users, Tenants, Campaigns)**
   ```python
   # Traditional CRUD operations
   DATABASE_URL=postgresql://...
   ```

2. **ZeroDB for Vector Embeddings**
   ```python
   # Semantic search, AI embeddings
   await zerodb_service.store_vector(embedding, metadata, namespace="documents")
   ```

3. **ZeroDB for Agent Memory**
   ```python
   # Conversation history, agent state
   await zerodb_service.store_memory(content, agent_id, session_id)
   ```

4. **ZeroDB Events for Pub/Sub**
   ```python
   # Real-time notifications, webhooks
   await zerodb_service.publish_event("user_login", payload)
   ```

### Migration Steps:

1. **Immediate: Add PostgreSQL support**
   ```bash
   railway add postgres
   railway variables set DATABASE_URL=$POSTGRES_URL
   ```

2. **Update models to use SQLAlchemy**
   ```python
   # app/models/user.py
   from sqlalchemy import Column, String, Boolean
   from app.core.database import Base

   class User(Base):
       __tablename__ = "users"
       id = Column(String, primary_key=True)
       email = Column(String, unique=True, nullable=False)
       hashed_password = Column(String, nullable=False)
       # ...
   ```

3. **Keep ZeroDB for its strengths**
   ```python
   # Use ZeroDB for AI features only
   - Vector search for semantic queries
   - Memory storage for AI agents
   - Event streaming for real-time updates
   ```

---

## 8. Is This a ZeroDB API Issue or Configuration Problem?

### It's BOTH:

1. **API Issue (ZeroDB Limitation):**
   - ZeroDB doesn't provide traditional table CRUD operations
   - The `/database/events` endpoint is NOT designed for table storage
   - Using events for relational data is an architectural anti-pattern
   - **Verdict:** ZeroDB is not a relational database replacement

2. **Configuration Problem:**
   - Inconsistent environment variable naming
   - Missing Railway environment variables
   - Different project IDs between environments
   - Potentially incomplete API key in Railway
   - **Verdict:** Configuration needs standardization

3. **Implementation Issue:**
   - Service tries to use ZeroDB as a relational database
   - Event-sourcing pattern is inappropriate for this use case
   - No fallback to traditional database when ZeroDB can't handle relational data
   - **Verdict:** Needs architectural redesign

---

## 9. Immediate Action Items

### Critical (Do First):
1. ✅ Add PostgreSQL to Railway deployment
2. ✅ Migrate user authentication to PostgreSQL
3. ✅ Update environment variables for consistency
4. ✅ Verify complete API key in Railway

### Important (Do Soon):
5. ✅ Document ZeroDB's intended use cases (vectors, memory, events only)
6. ✅ Remove event-sourcing pattern for relational data
7. ✅ Add table initialization to startup process
8. ✅ Implement proper error handling with detailed logging

### Nice to Have (Do Later):
9. ✅ Create migration script for existing data
10. ✅ Add health checks for both PostgreSQL and ZeroDB
11. ✅ Write tests for hybrid database approach
12. ✅ Update documentation with correct architecture

---

## 10. Testing Plan

### Test 1: Verify ZeroDB API Key
```bash
# Test if the API key works
curl -X GET "https://api.ainative.studio/api/v1/public/projects/" \
  -H "X-API-Key: 8XjG6qVuCo1pUDBFtisVGUcIYf4uXByNCAY2LgtmTAE"

# Expected: 200 OK with project list
# If 401: API key is invalid/incomplete
```

### Test 2: Check Project Exists
```bash
# Verify the project ID
curl -X GET "https://api.ainative.studio/api/v1/public/projects/d9c00084-0185-4506-b9b5-3baa2369b813" \
  -H "X-API-Key: 8XjG6qVuCo1pUDBFtisVGUcIYf4uXByNCAY2LgtmTAE"

# Expected: 200 OK with project details
# If 404: Project doesn't exist or no access
```

### Test 3: Try Events Endpoint
```bash
# Test if events endpoint exists
curl -X GET "https://api.ainative.studio/api/v1/public/projects/d9c00084-0185-4506-b9b5-3baa2369b813/database/events" \
  -H "X-API-Key: 8XjG6qVuCo1pUDBFtisVGUcIYf4uXByNCAY2LgtmTAE"

# Expected: 200 OK with events array (may be empty)
# If 404: Events not enabled or endpoint doesn't exist
```

### Test 4: Publish Test Event
```bash
# Try to publish an event
curl -X POST "https://api.ainative.studio/api/v1/public/projects/d9c00084-0185-4506-b9b5-3baa2369b813/database/events/publish" \
  -H "X-API-Key: 8XjG6qVuCo1pUDBFtisVGUcIYf4uXByNCAY2LgtmTAE" \
  -H "Content-Type: application/json" \
  -d '{
    "topic": "test_event",
    "event_payload": {"test": "data"}
  }'

# Expected: 200 OK with event ID
# Then list events to verify it was stored
```

---

## Conclusion

The 404 error is caused by a **fundamental architectural mismatch**: the service attempts to use ZeroDB's event system as a relational database, but ZeroDB is designed for vectors, memory, and pub/sub events, NOT traditional table operations.

**The solution is to use a hybrid approach:**
- PostgreSQL/SQLite for relational data (users, tenants, campaigns)
- ZeroDB for AI-specific features (vectors, memory, events)

This requires refactoring the authentication and data access layers to use the appropriate database for each use case.
