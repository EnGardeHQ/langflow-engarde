# Langflow Integration - Quick Start Guide

Get Langflow up and running in 5 minutes.

## Prerequisites

- Docker and Docker Compose installed
- 4GB+ available RAM
- Ports 5432, 6379, 7860, 8000, 3001 available

## Step 1: Configure Environment (1 minute)

```bash
cd /Users/cope/EnGardeHQ

# Copy environment template
cp .env.example .env

# Optional: Edit passwords (recommended for production)
nano .env
```

**Important**: For production, change these in `.env`:
```bash
LANGFLOW_SUPERUSER_PASSWORD=your_secure_password
POSTGRES_PASSWORD=your_secure_password
```

## Step 2: Start Infrastructure (2 minutes)

```bash
# Start PostgreSQL and Redis
docker-compose up -d postgres redis

# Wait for services to be healthy (30-60 seconds)
docker-compose ps

# Expected output:
# engarde_postgres   Up (healthy)
# engarde_redis      Up (healthy)
```

## Step 3: Initialize Langflow Database (1 minute)

```bash
# Run initialization script
./scripts/init-langflow.sh

# Expected output:
# ✓ Database connection successful
# ✓ Schema initialization complete
# ✓ Langflow schema initialization complete
# ✓ User 'langflow_user' exists
# ✓ User has CREATE permission on langflow schema
```

## Step 4: Start Langflow (1 minute)

```bash
# Start Langflow service
docker-compose up -d langflow

# Follow startup logs
docker-compose logs -f langflow

# Wait for:
# "Application startup complete"
# or "Uvicorn running on http://0.0.0.0:7860"

# Press Ctrl+C to exit logs
```

## Step 5: Validate Setup (30 seconds)

```bash
# Run comprehensive validation
./scripts/validate-langflow.sh

# Expected output:
# ========================================
# ✓ ALL CRITICAL TESTS PASSED
# ========================================
```

## Step 6: Access Langflow

Open your browser to: **http://localhost:7860**

**Default Login:**
- Username: `admin`
- Password: `admin` (or your configured password)

## Verification Checklist

- [ ] All services showing "Up (healthy)" in `docker-compose ps`
- [ ] Langflow UI accessible at http://localhost:7860
- [ ] Login successful with credentials
- [ ] No errors in `docker-compose logs langflow`
- [ ] Validation script passes all tests

## Common Quick Fixes

### Service Won't Start

```bash
# Check logs
docker-compose logs langflow

# Restart
./scripts/restart-langflow.sh
```

### Health Check Failing

```bash
# Wait 60 seconds, then check
curl http://localhost:7860/health

# If still failing, rebuild
./scripts/restart-langflow.sh --rebuild
```

### Database Connection Error

```bash
# Verify PostgreSQL is healthy
docker-compose ps postgres

# Reinitialize if needed
./scripts/init-langflow.sh
```

## What's Next?

1. **Create Your First Flow**
   - Click "New Flow" in Langflow UI
   - Drag and drop components
   - Connect nodes and save

2. **Integrate with EnGarde Backend**
   - API endpoint: http://localhost:7860/api
   - Documentation: http://localhost:7860/docs

3. **Explore Documentation**
   - Full setup guide: `/Users/cope/EnGardeHQ/LANGFLOW_SETUP.md`
   - Management scripts: `/Users/cope/EnGardeHQ/scripts/README.md`
   - Deployment checklist: `/Users/cope/EnGardeHQ/LANGFLOW_DEPLOYMENT_CHECKLIST.md`

## Useful Commands

```bash
# View logs
docker-compose logs -f langflow

# Restart service
./scripts/restart-langflow.sh

# Validate setup
./scripts/validate-langflow.sh

# Stop all services
docker-compose down

# Start all services
docker-compose up -d

# Clean reinstall
./scripts/cleanup-langflow.sh --full
./scripts/init-langflow.sh
docker-compose up -d langflow
```

## Get Help

If something goes wrong:

1. Check validation: `./scripts/validate-langflow.sh`
2. Review logs: `docker-compose logs --tail=100 langflow`
3. Consult troubleshooting: `/Users/cope/EnGardeHQ/LANGFLOW_SETUP.md#troubleshooting`

## Success!

Your Langflow integration is ready when:
- ✅ Web UI loads at http://localhost:7860
- ✅ You can log in successfully
- ✅ Validation script passes all tests

**Happy workflow building!** 🎉

---

**Quick Reference:**
- Web UI: http://localhost:7860
- API: http://localhost:7860/api
- Docs: http://localhost:7860/docs
- Health: http://localhost:7860/health
