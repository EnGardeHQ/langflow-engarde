# Sankore Intelligence Layer Integration Guide

**Created**: 2025-12-24
**Status**: Complete
**Integration Type**: API Gateway Proxy + Client Service Layer

---

## Overview

The integration layer connects En Garde backend with the Sankore Intelligence Layer, enabling advanced AI-powered advertising intelligence capabilities including ad trend analysis, copy auditing, creative pattern recognition, and performance predictions.

### Architecture

```
┌─────────────────────┐
│  En Garde Frontend  │
└──────────┬──────────┘
           │
           │ HTTP Requests
           ▼
┌─────────────────────┐
│  En Garde Backend   │
│   (FastAPI)         │
│                     │
│  ┌───────────────┐  │
│  │ API Gateway   │  │ ← /api/sankore/* routes
│  │ Proxy Layer   │  │
│  └───────┬───────┘  │
│          │          │
│  ┌───────▼───────┐  │
│  │ SankoreClient │  │ ← Service client for direct calls
│  │    Service    │  │
│  └───────────────┘  │
└──────────┬──────────┘
           │
           │ HTTP/JSON
           ▼
┌─────────────────────┐
│ Sankore Intelligence│
│      Layer          │
│   (Railway/Local)   │
└─────────────────────┘
```

---

## Implementation Summary

### 1. Files Created/Modified

#### Created Files:
- `/Users/cope/EnGardeHQ/production-backend/app/services/sankore_client.py` (570 lines)
  - Comprehensive Python client for Sankore API
  - Circuit breaker pattern for reliability
  - Graceful error handling
  - Singleton pattern for connection pooling

#### Modified Files:
- `/Users/cope/EnGardeHQ/production-backend/app/main.py`
  - Added `import httpx` and `import json`
  - Added `SANKORE_API_URL` environment variable
  - Added `/api/sankore/{path:path}` proxy route (100+ lines)

- `/Users/cope/EnGardeHQ/production-backend/.env.example`
  - Added Sankore configuration section
  - Documented production and local URLs

#### Verified Files:
- `/Users/cope/EnGardeHQ/production-backend/requirements.txt`
  - Confirmed `httpx==0.27.0` is already present (no changes needed)

---

## API Gateway Proxy Details

### Endpoint
```
Route: /api/sankore/{path:path}
Methods: GET, POST, PUT, DELETE, PATCH
Location: /Users/cope/EnGardeHQ/production-backend/app/main.py (lines 432-530)
```

### Features

1. **Full HTTP Method Support**: Handles GET, POST, PUT, DELETE, PATCH
2. **Header Forwarding**: Forwards all headers except hop-by-hop headers
3. **Query Parameter Forwarding**: Preserves all query parameters
4. **Body Forwarding**: Streams request body to Sankore
5. **Response Passthrough**: Returns Sankore response with original status codes and headers

### Error Handling

| Error Type | Status Code | Response |
|------------|-------------|----------|
| Timeout (>30s) | 504 | `{"error": "Sankore Intelligence Layer timeout", ...}` |
| Service Unavailable | 503 | `{"error": "Sankore Intelligence Layer unavailable", ...}` |
| General Error | 500 | `{"error": "Proxy error", "detail": "...", ...}` |

### Example Usage

```bash
# Fetch trends via proxy
curl -X POST "https://app.engarde.media/api/sankore/api/v1/trends/fetch?industry=fashion&limit=10"

# Analyze copy via proxy
curl -X POST "https://app.engarde.media/api/sankore/api/v1/analysis/audit-copy" \
  -H "Content-Type: application/json" \
  -d '{"text": "Get 50% off today!", "objective": "conversion"}'

# Health check via proxy
curl "https://app.engarde.media/api/sankore/health"
```

---

## SankoreClient Service Details

### Location
`/Users/cope/EnGardeHQ/production-backend/app/services/sankore_client.py`

### Class: `SankoreClient`

#### Initialization
```python
from app.services.sankore_client import SankoreClient, get_sankore_client

# Create new instance
client = SankoreClient(base_url="https://sankore-production.up.railway.app", timeout=30.0)

# Use singleton (recommended)
client = get_sankore_client()
```

#### Methods

##### 1. `fetch_trends(industry, platform=None, limit=10)`
Fetch latest ad trends for a specific industry.

**Parameters:**
- `industry` (str): Industry/vertical (e.g., "fashion", "tech", "beauty")
- `platform` (str, optional): Platform filter (e.g., "meta", "tiktok", "google")
- `limit` (int): Maximum number of trends to fetch (default: 10)

**Returns:** `List[Dict[str, Any]]` - List of trend objects

**Example:**
```python
client = get_sankore_client()
trends = await client.fetch_trends("fashion", platform="meta", limit=10)
for trend in trends:
    print(f"Ad ID: {trend['ad_id']}, Hook: {trend['hook']}")
```

##### 2. `get_trends(platform=None, industry=None, limit=10)`
Get stored trends from Sankore database (cached, fast).

**Parameters:**
- `platform` (str, optional): Platform filter
- `industry` (str, optional): Industry filter
- `limit` (int): Maximum number of trends (default: 10)

**Returns:** `List[Dict[str, Any]]` - List of stored trends

**Example:**
```python
trends = await client.get_trends(platform="meta", industry="fashion", limit=20)
```

##### 3. `analyze_copy(text, objective="conversion", platform=None)`
Analyze ad copy and get AI-powered recommendations.

**Parameters:**
- `text` (str): Ad copy text to analyze
- `objective` (str): Campaign objective (default: "conversion")
- `platform` (str, optional): Platform context

**Returns:** `Dict[str, Any]` with keys:
- `score`: Quality score (0-100)
- `hooks`: List of detected hooks with effectiveness ratings
- `ctas`: List of call-to-action elements
- `improvements`: List of improvement suggestions
- `winning_patterns`: Patterns from successful similar ads

**Example:**
```python
result = await client.analyze_copy(
    text="Get 50% off today! Limited time offer.",
    objective="conversion",
    platform="meta"
)
print(f"Score: {result['score']}")
print(f"Improvements: {result['improvements']}")
```

##### 4. `health_check()`
Check if Sankore service is available.

**Returns:** `bool` - True if healthy, False otherwise

**Example:**
```python
if await client.health_check():
    print("Sankore is available")
else:
    print("Sankore is down")
```

##### 5. `get_creative_suggestions(industry, objective="conversion", limit=5)`
Get creative suggestions based on winning patterns.

**Parameters:**
- `industry` (str): Industry/vertical
- `objective` (str): Campaign objective
- `limit` (int): Number of suggestions (default: 5)

**Returns:** `List[Dict[str, Any]]` - List of creative suggestions

**Example:**
```python
suggestions = await client.get_creative_suggestions("fashion", "conversion", 5)
```

### Circuit Breaker Pattern

The client implements a circuit breaker to prevent cascading failures:

- **Threshold**: 3 consecutive failures
- **Auto-Reset**: After 60 seconds
- **Behavior**: When open, methods return empty/default responses immediately

**States:**
1. **Closed** (Normal): All requests proceed
2. **Open** (Failed): Requests return defaults immediately
3. **Half-Open** (Testing): After 60s, allows one test request

---

## Error Handling Approach

### Design Philosophy
- **Graceful Degradation**: Never raise exceptions to caller
- **Default Responses**: Return empty lists/default dicts on error
- **Comprehensive Logging**: All errors logged with context
- **Circuit Breaker**: Prevents repeated failures from blocking

### Error Scenarios

| Scenario | Client Behavior | Proxy Behavior |
|----------|----------------|----------------|
| Timeout (>30s) | Return empty list/default dict | Return 504 JSON error |
| Connection refused | Return empty list/default dict | Return 503 JSON error |
| HTTP 4xx/5xx | Return empty list/default dict | Forward status code |
| Network error | Return empty list/default dict | Return 503 JSON error |
| Circuit breaker open | Return immediately (no request) | N/A |

### Logging

All errors are logged with context:
```
[SANKORE-CLIENT] Timeout fetching trends: ReadTimeout()
[SANKORE-PROXY] Error connecting to Sankore: ConnectError()
```

---

## Environment Configuration

### Environment Variable

Add to `.env`:
```bash
# Production (Railway)
SANKORE_API_URL=https://sankore-production.up.railway.app

# Local development
SANKORE_API_URL=http://localhost:8001
```

### Configuration File

Already documented in `/Users/cope/EnGardeHQ/production-backend/.env.example`:

```bash
# =============================================================================
# SANKORE INTELLIGENCE LAYER
# =============================================================================
# Sankore provides advanced AI-powered advertising intelligence including:
# - Ad trend analysis and creative pattern recognition
# - Ad copy auditing and recommendations
# - Performance predictions based on winning patterns
# Production URL: https://sankore-production.up.railway.app
# Local development: http://localhost:8001
SANKORE_API_URL=https://sankore-production.up.railway.app
```

---

## Testing Instructions

### 1. Local Testing (Prerequisites)

Ensure Sankore is running locally:
```bash
cd /path/to/sankore
python -m uvicorn main:app --reload --port 8001
```

Set environment variable:
```bash
export SANKORE_API_URL=http://localhost:8001
```

### 2. Unit Tests (Client)

Create test file: `tests/test_sankore_client.py`

```python
import pytest
from app.services.sankore_client import SankoreClient, get_sankore_client

@pytest.mark.asyncio
async def test_fetch_trends():
    client = SankoreClient(base_url="http://localhost:8001")
    trends = await client.fetch_trends("fashion", limit=5)
    assert isinstance(trends, list)

@pytest.mark.asyncio
async def test_analyze_copy():
    client = SankoreClient(base_url="http://localhost:8001")
    result = await client.analyze_copy(
        text="Get 50% off today!",
        objective="conversion"
    )
    assert "score" in result
    assert "hooks" in result
    assert "improvements" in result

@pytest.mark.asyncio
async def test_health_check():
    client = SankoreClient(base_url="http://localhost:8001")
    healthy = await client.health_check()
    assert healthy is True

@pytest.mark.asyncio
async def test_circuit_breaker():
    # Use invalid URL to trigger failures
    client = SankoreClient(base_url="http://invalid:9999", timeout=1.0)

    # Trigger 3 failures
    for i in range(3):
        result = await client.analyze_copy("test")
        assert result["score"] == 0

    # Circuit should be open now
    assert client._circuit_open is True

@pytest.mark.asyncio
async def test_singleton():
    client1 = get_sankore_client()
    client2 = get_sankore_client()
    assert client1 is client2  # Same instance
```

Run tests:
```bash
cd /Users/cope/EnGardeHQ/production-backend
pytest tests/test_sankore_client.py -v
```

### 3. Integration Tests (Proxy)

Test proxy endpoints:

```bash
# Start En Garde backend
cd /Users/cope/EnGardeHQ/production-backend
export SANKORE_API_URL=http://localhost:8001
uvicorn app.main:app --reload --port 8000
```

Test requests:

```bash
# Health check
curl http://localhost:8000/api/sankore/health

# Fetch trends (POST with params)
curl -X POST "http://localhost:8000/api/sankore/api/v1/trends/fetch?industry=fashion&limit=5"

# Get trends (GET with params)
curl "http://localhost:8000/api/sankore/api/v1/trends/?platform=meta&limit=10"

# Analyze copy (POST with JSON body)
curl -X POST http://localhost:8000/api/sankore/api/v1/analysis/audit-copy \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Get 50% off your first purchase! Shop now while supplies last.",
    "objective": "conversion",
    "platform": "meta"
  }'

# Test error handling (invalid endpoint)
curl http://localhost:8000/api/sankore/invalid/endpoint
```

### 4. Production Testing

Test against Railway deployment:

```bash
# Set production URL
export SANKORE_API_URL=https://sankore-production.up.railway.app

# Restart backend
# ... then run same curl tests as above
```

### 5. Load Testing

Test concurrent requests:

```python
import asyncio
from app.services.sankore_client import get_sankore_client

async def test_concurrent():
    client = get_sankore_client()

    # Create 10 concurrent requests
    tasks = [
        client.analyze_copy(f"Test copy {i}", "conversion")
        for i in range(10)
    ]

    results = await asyncio.gather(*tasks)

    # All should complete without errors
    assert all(isinstance(r, dict) for r in results)
    print(f"Completed {len(results)} concurrent requests")

asyncio.run(test_concurrent())
```

### 6. Error Scenario Testing

Test error handling:

```bash
# Test timeout (set SANKORE_API_URL to slow endpoint)
export SANKORE_API_URL=http://httpbin.org/delay/60
curl http://localhost:8000/api/sankore/health
# Should return 504 Gateway Timeout after 30s

# Test unavailable service
export SANKORE_API_URL=http://localhost:9999
curl http://localhost:8000/api/sankore/health
# Should return 503 Service Unavailable
```

### 7. Frontend Integration Test

Test from En Garde frontend:

```javascript
// Fetch trends
const response = await fetch('/api/sankore/api/v1/trends/fetch?industry=fashion&limit=10', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
  }
});
const trends = await response.json();
console.log('Trends:', trends);

// Analyze copy
const analyzeResponse = await fetch('/api/sankore/api/v1/analysis/audit-copy', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
  },
  body: JSON.stringify({
    text: 'Get 50% off today!',
    objective: 'conversion',
    platform: 'meta'
  })
});
const analysis = await analyzeResponse.json();
console.log('Analysis:', analysis);
```

---

## Usage Examples

### Example 1: Campaign Creative Analysis

```python
from app.services.sankore_client import get_sankore_client

async def analyze_campaign_creative(campaign_id: str, copy_text: str):
    """Analyze campaign creative and store recommendations."""
    client = get_sankore_client()

    # Analyze copy
    analysis = await client.analyze_copy(
        text=copy_text,
        objective="conversion",
        platform="meta"
    )

    # Store results in database
    # ... (your database logic)

    return {
        "campaign_id": campaign_id,
        "score": analysis["score"],
        "recommendations": analysis["improvements"],
        "hooks": analysis["hooks"],
        "ctas": analysis["ctas"]
    }
```

### Example 2: Trend-Based Content Generation

```python
async def generate_content_from_trends(industry: str):
    """Generate content ideas based on latest trends."""
    client = get_sankore_client()

    # Fetch latest trends
    trends = await client.fetch_trends(industry, limit=5)

    if not trends:
        return []

    # Extract patterns
    content_ideas = []
    for trend in trends:
        content_ideas.append({
            "hook": trend.get("hook"),
            "format": trend.get("format"),
            "platform": trend.get("platform"),
            "engagement_score": trend.get("engagement_score")
        })

    return content_ideas
```

### Example 3: Real-time Copy Validation

```python
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()

class CopyValidationRequest(BaseModel):
    text: str
    objective: str = "conversion"
    platform: str = "meta"

@router.post("/api/campaigns/validate-copy")
async def validate_copy(request: CopyValidationRequest):
    """Validate ad copy before campaign launch."""
    client = get_sankore_client()

    # Check Sankore availability
    if not await client.health_check():
        raise HTTPException(
            status_code=503,
            detail="AI validation service temporarily unavailable"
        )

    # Analyze copy
    analysis = await client.analyze_copy(
        text=request.text,
        objective=request.objective,
        platform=request.platform
    )

    # Return validation results
    return {
        "valid": analysis["score"] >= 70,  # 70+ is considered good
        "score": analysis["score"],
        "improvements": analysis["improvements"],
        "hooks": analysis["hooks"],
        "ctas": analysis["ctas"]
    }
```

---

## Monitoring & Observability

### Logging

All Sankore operations are logged with `[SANKORE-CLIENT]` or `[SANKORE-PROXY]` prefixes:

```
[SANKORE-CLIENT] Initialized with base_url: https://sankore-production.up.railway.app
[SANKORE-CLIENT] Fetching trends: {'industry': 'fashion', 'limit': 10}
[SANKORE-CLIENT] Successfully fetched 10 trends
[SANKORE-PROXY] POST https://sankore-production.up.railway.app/api/v1/trends/fetch
[SANKORE-PROXY] Response: 200
```

### Error Monitoring

Errors include full context:

```
[SANKORE-CLIENT] HTTP error fetching trends: 500 Server Error
[SANKORE-CLIENT] Circuit breaker opened after 3 consecutive failures
[SANKORE-PROXY] Error connecting to Sankore: ConnectError(...)
```

### Metrics to Track

Consider adding these metrics:

1. **Request Volume**: Requests per minute to Sankore
2. **Error Rate**: Failed requests / Total requests
3. **Latency**: Average response time (p50, p95, p99)
4. **Circuit Breaker State**: Open/Closed/Half-Open
5. **Timeout Rate**: Requests exceeding 30s timeout

---

## Deployment Checklist

- [x] Proxy route added to `main.py`
- [x] SankoreClient service created
- [x] Environment variable documented
- [x] Error handling implemented
- [x] Circuit breaker pattern added
- [x] Logging configured
- [ ] Set `SANKORE_API_URL` in production `.env`
- [ ] Test proxy endpoints
- [ ] Test client methods
- [ ] Verify error handling
- [ ] Monitor logs for issues
- [ ] Add metrics collection (optional)

---

## Troubleshooting

### Issue: 503 Service Unavailable

**Cause**: Sankore service is down or unreachable
**Solution**:
1. Check Sankore health: `curl https://sankore-production.up.railway.app/health`
2. Verify `SANKORE_API_URL` environment variable
3. Check Railway deployment status

### Issue: 504 Gateway Timeout

**Cause**: Sankore taking longer than 30s to respond
**Solution**:
1. Reduce `limit` parameter in requests
2. Check Sankore service performance
3. Consider increasing timeout (in `sankore_client.py`)

### Issue: Circuit Breaker Stuck Open

**Cause**: 3+ consecutive failures, circuit breaker opened
**Solution**:
1. Wait 60 seconds for auto-reset
2. Fix underlying Sankore connectivity issue
3. Restart backend to reset circuit breaker

### Issue: Empty Responses

**Cause**: Sankore returns empty data or client fails silently
**Solution**:
1. Check Sankore logs for errors
2. Review En Garde backend logs for `[SANKORE-CLIENT]` errors
3. Verify request parameters are correct

---

## Next Steps

1. **Deploy to Production**: Set `SANKORE_API_URL` in Railway environment
2. **Frontend Integration**: Update frontend to use `/api/sankore/*` endpoints
3. **Add Metrics**: Implement Prometheus metrics for monitoring
4. **Create Admin UI**: Build dashboard for Sankore integration status
5. **Add Caching**: Consider caching trend data in Redis
6. **Rate Limiting**: Add rate limiting to prevent Sankore abuse

---

## Support

For issues or questions:
- Backend Team: Check `/Users/cope/EnGardeHQ/production-backend/app/services/sankore_client.py`
- Sankore Service: Check Sankore documentation/logs
- Integration Issues: Review this guide and logs with `[SANKORE-*]` prefix
