# Hot-Reload Testing Guide

This guide provides step-by-step instructions to verify that hot-reload is working correctly.

## Prerequisites

Ensure Docker is running:
```bash
docker info
```

## Test 1: Start the Environment

```bash
# Start with watch mode
./dev-start.sh --watch
```

**Expected Output:**
- Services building and starting
- Health checks passing
- Watch mode active and monitoring files
- Access points displayed

**Verify:**
- Frontend accessible at http://localhost:3000
- Backend accessible at http://localhost:8000
- API docs at http://localhost:8000/docs

## Test 2: Backend Hot-Reload

### Step 1: Find the main.py file
```bash
ls -la /Users/cope/EnGardeHQ/production-backend/app/main.py
```

### Step 2: Make a test change
Open `/Users/cope/EnGardeHQ/production-backend/app/main.py` and add a comment:

```python
# Test hot-reload - added at [current time]
```

### Step 3: Watch the logs
In a separate terminal:
```bash
docker compose -f docker-compose.dev.yml logs -f backend
```

**Expected Output:**
```
backend_dev | INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
backend_dev | INFO:     Started reloader process [X] using WatchFiles
backend_dev | WARNING:  WatchFiles detected changes in 'main.py'. Reloading...
backend_dev | INFO:     Started server process [Y]
backend_dev | INFO:     Waiting for application startup.
backend_dev | INFO:     Application startup complete.
```

**Success Criteria:**
- Uvicorn detects the change
- Server reloads automatically
- No manual restart needed
- Reload completes in ~1 second

## Test 3: Frontend Hot-Reload

### Step 1: Find a React component
```bash
ls -la /Users/cope/EnGardeHQ/production-frontend/app/page.tsx
```

### Step 2: Make a test change
Open `/Users/cope/EnGardeHQ/production-frontend/app/page.tsx` and modify some text:

For example, change:
```tsx
<h1>Welcome to EnGarde</h1>
```

To:
```tsx
<h1>Welcome to EnGarde - Hot Reload Working!</h1>
```

### Step 3: Watch the browser
Open http://localhost:3000 in your browser

**Expected Behavior:**
- Browser updates automatically (no refresh needed)
- Change appears instantly (~100-500ms)
- No full page reload
- Next.js Fast Refresh indicator appears briefly

### Step 4: Watch the logs
```bash
docker compose -f docker-compose.dev.yml logs -f frontend
```

**Expected Output:**
```
frontend_dev | event - compiled client and server successfully in X ms
frontend_dev | wait  - compiling...
frontend_dev | event - compiled successfully in Y ms
```

**Success Criteria:**
- Fast Refresh compiles the change
- Browser updates without refresh
- Console shows no errors
- Change visible immediately

## Test 4: Watch Mode File Sync

### Check watch mode is active
The watch mode should show sync events:

```
[+] Watching 12 targets
backend: Sync /Users/cope/EnGardeHQ/production-backend/app -> /app/app
frontend: Sync /Users/cope/EnGardeHQ/production-frontend/app -> /app/app
```

### Make multiple changes rapidly
Edit both backend and frontend files in quick succession.

**Expected Behavior:**
- All changes are synced automatically
- No sync conflicts
- No manual intervention needed

## Test 5: Configuration Changes

### Test backend configuration
Edit `/Users/cope/EnGardeHQ/production-backend/requirements.txt` and add:
```
# httpx>=0.25.0  # Already exists, just add a comment
```

**Expected Behavior:**
- Watch mode triggers rebuild
- Container rebuilds with new dependencies
- Service restarts automatically

### Test frontend configuration
Edit `/Users/cope/EnGardeHQ/production-frontend/next.config.js` and add a comment:
```javascript
// Test configuration change
```

**Expected Behavior:**
- Watch mode triggers sync+restart
- Container restarts
- Changes take effect after restart

## Test 6: Error Recovery

### Introduce a Python syntax error
In `main.py`, add:
```python
this is invalid syntax
```

**Expected Behavior:**
- Uvicorn detects error
- Shows error message in logs
- Server keeps running (doesn't crash)
- Fix the error
- Server recovers automatically

### Introduce a TypeScript error
In a component, add:
```typescript
const x: string = 123; // Type error
```

**Expected Behavior:**
- Next.js shows error overlay in browser
- Error details displayed
- Fix the error
- Fast Refresh recovers automatically

## Test 7: Volume Persistence

### Create a test file
```bash
# In backend
docker compose -f docker-compose.dev.yml exec backend bash -c "echo 'test' > /app/test.txt"

# Verify it exists on host (should NOT, as it's not mounted)
ls /Users/cope/EnGardeHQ/production-backend/test.txt
```

### Check mounted directories
```bash
# Create in mounted directory
echo "test" > /Users/cope/EnGardeHQ/production-backend/app/test_file.py

# Verify in container
docker compose -f docker-compose.dev.yml exec backend ls -la /app/app/test_file.py

# Clean up
rm /Users/cope/EnGardeHQ/production-backend/app/test_file.py
```

## Test 8: Service Dependencies

### Restart PostgreSQL
```bash
docker compose -f docker-compose.dev.yml restart postgres
```

**Expected Behavior:**
- Backend waits for PostgreSQL to be healthy
- Backend reconnects automatically
- No data loss
- Services resume normal operation

## Test 9: Health Checks

### Check service health
```bash
docker compose -f docker-compose.dev.yml ps
```

**Expected Output:**
```
NAME                    STATUS              PORTS
engarde_backend_dev     Up (healthy)        0.0.0.0:8000->8000/tcp
engarde_frontend_dev    Up (healthy)        0.0.0.0:3000->3000/tcp
engarde_postgres_dev    Up (healthy)        0.0.0.0:5432->5432/tcp
engarde_redis_dev       Up (healthy)        0.0.0.0:6379->6379/tcp
```

### Test health endpoint
```bash
curl http://localhost:8000/health
curl http://localhost:3000/
```

## Test 10: Resource Usage

### Monitor container resources
```bash
docker stats engarde_backend_dev engarde_frontend_dev
```

**Expected:**
- Reasonable CPU usage (< 50% during idle)
- Memory usage stable (< 1GB per service)
- No memory leaks over time

## Troubleshooting Tests

### If hot-reload stops working:

1. **Check watch mode is running:**
```bash
docker compose -f docker-compose.dev.yml watch
```

2. **Check file permissions:**
```bash
ls -la /Users/cope/EnGardeHQ/production-backend/app/
```

3. **Restart services:**
```bash
docker compose -f docker-compose.dev.yml restart backend frontend
```

4. **Check logs for errors:**
```bash
docker compose -f docker-compose.dev.yml logs backend frontend
```

## Success Criteria Summary

All tests should pass with:
- ✓ Backend hot-reload working (~1 second)
- ✓ Frontend Fast Refresh working (instant)
- ✓ Watch mode syncing files automatically
- ✓ Configuration changes trigger appropriate actions
- ✓ Error recovery works correctly
- ✓ Health checks passing
- ✓ No manual rebuilds needed
- ✓ Services stable and performant

## Cleanup After Testing

```bash
# Stop all services
docker compose -f docker-compose.dev.yml down

# Remove test files
rm /Users/cope/EnGardeHQ/production-backend/app/test_file.py 2>/dev/null || true

# Optional: Remove volumes (will require rebuild)
docker compose -f docker-compose.dev.yml down -v
```

## Report Issues

If any test fails, collect the following information:

1. Docker version: `docker --version`
2. Compose version: `docker compose version`
3. Container logs: `docker compose -f docker-compose.dev.yml logs`
4. Container status: `docker compose -f docker-compose.dev.yml ps`
5. System resources: `docker stats`

Include this information when reporting issues.
