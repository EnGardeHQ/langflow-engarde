# EnGarde Langflow - Deployment Guide (Official Base Image)

**Date:** January 11, 2026
**Dockerfile:** `Dockerfile.official-base`
**Base Image:** `langflowai/langflow:latest`

---

## Overview

This guide covers deploying EnGarde Langflow to Railway using the official Langflow Docker image as a base. This approach:

✅ **Uses official Langflow image** - Inherits all official features and updates
✅ **Adds custom components** - Includes 14 Walker Agent components
✅ **Configures SSO** - Enables integration with EnGarde backend
✅ **Railway compatible** - Handles dynamic PORT variable
✅ **Faster builds** - No frontend rebuild required

⚠️ **Note:** This build does NOT include full branding customizations (logo, footer). For complete branding, use `Dockerfile.engarde`.

---

## Prerequisites

Before deploying, ensure you have:

- [ ] Railway account with CLI installed (`npm i -g @railway/cli`)
- [ ] PostgreSQL database provisioned in Railway
- [ ] EnGarde backend deployed and running
- [ ] Shared SSO secret key generated

---

## Step 1: Configure Environment Variables

Create a `.env` file or set these variables in Railway:

### Critical Variables (REQUIRED)

```bash
# SSO Configuration (MUST match EnGarde backend)
LANGFLOW_SECRET_KEY="your-shared-secret-key-here"

# Database Configuration
LANGFLOW_DATABASE_URL="postgresql://user:password@host:port/database"

# Disable auto-login for SSO
LANGFLOW_AUTO_LOGIN=false

# EnGarde API URL
ENGARDE_API_URL="https://api.engarde.media"
```

### Walker Agent API Keys

```bash
# SEO Walker Agent
WALKER_AGENT_API_KEY_ONSIDE_SEO="your-api-key-here"

# Content Walker Agent
WALKER_AGENT_API_KEY_ONSIDE_CONTENT="your-api-key-here"

# Paid Ads Walker Agent
WALKER_AGENT_API_KEY_SANKORE_PAID_ADS="your-api-key-here"

# Audience Intelligence Walker Agent
WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE="your-api-key-here"
```

### Optional Variables

```bash
# Logging level
LANGFLOW_LOG_LEVEL="info"

# Component path (already set in Dockerfile)
LANGFLOW_COMPONENTS_PATH="/app/components"

# Host and port (handled by startup script)
LANGFLOW_HOST="0.0.0.0"
```

---

## Step 2: Deploy to Railway

### Method 1: GitHub Integration (Recommended)

1. **Push code to GitHub:**

```bash
cd /Users/cope/EnGardeHQ/langflow-engarde

# Ensure you're on the correct branch
git checkout rollback-pre-subscription

# Add the new Dockerfile
git add Dockerfile.official-base railway.toml

# Commit changes
git commit -m "feat: add official base image Dockerfile for Railway deployment

- Uses langflowai/langflow:latest as base
- Adds 14 custom Walker Agent components
- Configures SSO with EnGarde backend
- Railway-compatible startup script
- Health check endpoint
- Dynamic PORT handling

Deployment:
- Railway will use Dockerfile.official-base
- All customizations from ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md applied
- SSO endpoint configuration required
- Environment variables must be set in Railway

🤖 Generated with Claude Code"

# Push to remote
git push origin rollback-pre-subscription
```

2. **Configure Railway project:**

```bash
# Login to Railway
railway login

# Link to existing project or create new one
railway link

# Set environment variables
railway variables set LANGFLOW_SECRET_KEY="your-secret-here"
railway variables set LANGFLOW_DATABASE_URL="$DATABASE_URL"
railway variables set LANGFLOW_AUTO_LOGIN="false"
railway variables set ENGARDE_API_URL="https://api.engarde.media"
railway variables set WALKER_AGENT_API_KEY_ONSIDE_SEO="your-key"
railway variables set WALKER_AGENT_API_KEY_ONSIDE_CONTENT="your-key"
railway variables set WALKER_AGENT_API_KEY_SANKORE_PAID_ADS="your-key"
railway variables set WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE="your-key"

# Deploy
railway up
```

3. **Monitor deployment:**

```bash
# View build logs
railway logs --build

# View runtime logs
railway logs

# Check service status
railway status
```

### Method 2: Railway CLI Direct Deploy

```bash
cd /Users/cope/EnGardeHQ/langflow-engarde

# Deploy directly from local files
railway up

# Follow logs
railway logs -f
```

### Method 3: Docker Hub (Advanced)

1. **Build and push to Docker Hub:**

```bash
# Build image
docker build -f Dockerfile.official-base -t yourusername/engarde-langflow:official .

# Push to Docker Hub
docker push yourusername/engarde-langflow:official
```

2. **Deploy from Docker Hub in Railway:**

- Go to Railway dashboard
- Create new service
- Select "Docker Image"
- Enter: `yourusername/engarde-langflow:official`
- Set environment variables
- Deploy

---

## Step 3: Verify Deployment

### 1. Check Service Health

```bash
# Get the Railway URL
railway domain

# Test health endpoint
curl https://your-app.railway.app/health
```

Expected response:
```json
{
  "status": "ok"
}
```

### 2. Verify Custom Components Loaded

Check the logs for component loading confirmation:

```bash
railway logs | grep "Custom components found"
```

Expected output:
```
✓ Custom components found: 14 files
```

### 3. Test SSO Integration

1. Navigate to EnGarde frontend `/agent-suite` page
2. Frontend should call `POST /api/v1/sso/langflow`
3. EnGarde backend generates JWT token
4. Iframe loads Langflow with SSO URL
5. User should see authenticated Langflow UI

### 4. Verify Walker Agents

1. Open Langflow UI
2. Check component palette (left sidebar)
3. Look for "En Garde Components" folder
4. Should see:
   - SEO Walker Agent
   - Content Walker Agent
   - Paid Ads Walker Agent
   - Audience Intelligence Walker Agent
   - Walker Agent API (utility component)
   - Other utility components

---

## Step 4: Configure SSO Endpoint (CRITICAL)

⚠️ **Important:** The official Langflow image does not include the custom SSO endpoint by default. You need to add it manually or deploy with the full custom build (`Dockerfile.engarde`).

### Option A: Use Official Image + External SSO Proxy

Since the official image doesn't have the custom `/api/v1/custom/sso_login` endpoint, you can:

1. Deploy this Dockerfile (components only)
2. Handle SSO in EnGarde backend/middleware
3. Use Langflow's standard authentication endpoints

### Option B: Deploy Full Custom Build

For complete SSO integration, use `Dockerfile.engarde` instead:

```bash
# Update railway.toml
sed -i 's/Dockerfile.official-base/Dockerfile.engarde/g' railway.toml

# Rebuild and deploy
railway up
```

**Note:** `Dockerfile.engarde` rebuilds Langflow from source with:
- Custom SSO endpoint
- EnGarde branding (logo, footer, favicon)
- All customizations from documentation

---

## Troubleshooting

### Issue 1: Components Not Loading

**Symptom:** Walker Agent components missing from palette

**Solution:**
```bash
# Check logs
railway logs | grep -i component

# Verify environment variable
railway variables get LANGFLOW_COMPONENTS_PATH

# Should be: /app/components

# Restart service
railway restart
```

### Issue 2: Database Connection Failed

**Symptom:** "Could not connect to database" error

**Solution:**
```bash
# Check database URL
railway variables get LANGFLOW_DATABASE_URL

# Verify database service is running
railway status

# Check database logs
railway logs --service database

# Run migrations manually
railway run langflow migration --fix
```

### Issue 3: SSO Token Invalid

**Symptom:** "Invalid or expired token" error

**Solution:**
1. Verify `LANGFLOW_SECRET_KEY` matches EnGarde backend
2. Check token expiration (5 minutes max)
3. Ensure `LANGFLOW_AUTO_LOGIN=false`
4. Verify JWT signature algorithm (HS256)

```bash
# Check secret key
railway variables get LANGFLOW_SECRET_KEY

# Compare with EnGarde backend
# They MUST match exactly
```

### Issue 4: Port Binding Error

**Symptom:** "Address already in use" or "Port not available"

**Solution:**
The startup script handles Railway's dynamic PORT variable automatically.

```bash
# Check logs for port confirmation
railway logs | grep "Starting Langflow server on port"

# Verify PORT variable is not set manually
railway variables get PORT
# Should be empty (Railway sets this automatically)
```

### Issue 5: Build Fails on Railway

**Symptom:** "failed to solve with frontend dockerfile.v0"

**Solution:**
```bash
# Ensure railway.toml is correct
cat railway.toml

# Should show:
# builder = "DOCKERFILE"
# dockerfilePath = "Dockerfile.official-base"

# Verify Dockerfile exists
ls -la Dockerfile.official-base

# Check for syntax errors
docker build --check -f Dockerfile.official-base .
```

---

## Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `LANGFLOW_SECRET_KEY` | ✅ Yes | `""` | Shared secret with EnGarde backend for SSO |
| `LANGFLOW_DATABASE_URL` | ✅ Yes | `""` | PostgreSQL connection string |
| `LANGFLOW_AUTO_LOGIN` | ✅ Yes | `false` | Must be false for SSO |
| `ENGARDE_API_URL` | ✅ Yes | `""` | EnGarde backend API URL |
| `WALKER_AGENT_API_KEY_ONSIDE_SEO` | ⚠️ Recommended | `""` | API key for SEO walker |
| `WALKER_AGENT_API_KEY_ONSIDE_CONTENT` | ⚠️ Recommended | `""` | API key for content walker |
| `WALKER_AGENT_API_KEY_SANKORE_PAID_ADS` | ⚠️ Recommended | `""` | API key for paid ads walker |
| `WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE` | ⚠️ Recommended | `""` | API key for audience walker |
| `LANGFLOW_HOST` | ❌ No | `0.0.0.0` | Bind address |
| `LANGFLOW_LOG_LEVEL` | ❌ No | `info` | Logging verbosity |
| `LANGFLOW_COMPONENTS_PATH` | ❌ No | `/app/components` | Custom components directory |
| `PORT` | ❌ No | Auto | Railway sets this automatically |

---

## Performance Optimization

### 1. Database Connection Pooling

```bash
# Add to environment variables
railway variables set LANGFLOW_DATABASE_POOL_SIZE="20"
railway variables set LANGFLOW_DATABASE_MAX_OVERFLOW="10"
```

### 2. Worker Configuration

```bash
# Set number of Gunicorn workers
railway variables set LANGFLOW_WORKERS="2"
```

### 3. Caching

```bash
# Enable Redis caching (if Redis available)
railway variables set LANGFLOW_CACHE_TYPE="redis"
railway variables set LANGFLOW_REDIS_URL="redis://..."
```

---

## Monitoring

### Health Checks

Railway will automatically monitor the `/health` endpoint every 30 seconds.

```bash
# Manual health check
curl https://your-app.railway.app/health
```

### Logs

```bash
# Follow live logs
railway logs -f

# Search logs
railway logs | grep ERROR

# Export logs
railway logs > langflow-logs.txt
```

### Metrics

Railway dashboard shows:
- CPU usage
- Memory usage
- Network traffic
- Request latency
- Error rates

---

## Rollback Procedure

If deployment fails or issues arise:

```bash
# View deployment history
railway deployments

# Rollback to previous deployment
railway rollback <deployment-id>

# Or redeploy from specific commit
git checkout <previous-commit>
railway up
```

---

## Next Steps

After successful deployment:

1. **Test SSO integration** with EnGarde frontend
2. **Create Walker Agent flows** in Langflow UI
3. **Test API endpoints** for campaign analysis
4. **Monitor performance** and optimize as needed
5. **Set up alerts** in Railway for downtime/errors
6. **Configure domain** (optional) for production URL

---

## Support

**Documentation:**
- See `ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md` for full details
- See `QUICK_REFERENCE.md` for common commands
- See `ARCHITECTURE_DIAGRAM.md` for system design

**Troubleshooting:**
- Check Railway logs first: `railway logs`
- Review environment variables: `railway variables`
- Verify database connection: `railway run langflow migration --fix`
- Test health endpoint: `curl https://your-app.railway.app/health`

**External Resources:**
- [Railway Documentation](https://docs.railway.app)
- [Langflow Documentation](https://docs.langflow.org)
- [Docker Documentation](https://docs.docker.com)

---

**Created:** January 11, 2026
**Maintained By:** EnGarde Development Team
**Version:** 2.0.0 (Official Base)
**Repository:** https://github.com/EnGardeHQ/langflow-engarde

---

**End of Deployment Guide**
