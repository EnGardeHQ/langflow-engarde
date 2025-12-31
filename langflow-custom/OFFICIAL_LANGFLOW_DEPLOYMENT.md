# Official Langflow Deployment on Railway

## Overview

After extensive testing with custom builds, this guide provides instructions for deploying the **official Langflow image** to Railway without custom branding.

**Decision Date:** December 30, 2025
**Reason:** Custom Docker builds consistently failed/hung for 24+ hours. Official image is stable and production-ready.

---

## Railway Deployment Instructions

### Option 1: Deploy via Railway CLI (Recommended)

1. **Install Railway CLI** (if not already installed):
   ```bash
   npm install -g @railway/cli
   railway login
   ```

2. **Link to your Railway project**:
   ```bash
   cd /Users/cope/EnGardeHQ/langflow-custom
   railway link
   ```

3. **Deploy official Langflow image**:
   ```bash
   railway service create langflow
   railway up --service langflow --image langflowai/langflow:latest
   ```

4. **Set required environment variables**:
   ```bash
   railway variables set LANGFLOW_AUTO_LOGIN=true --service langflow
   railway variables set LANGFLOW_DATABASE_URL=$DATABASE_PUBLIC_URL --service langflow
   ```

5. **Generate domain**:
   ```bash
   railway domain --service langflow
   ```

### Option 2: Deploy via Railway Dashboard

1. **Go to your Railway project**:
   - Visit https://railway.app/dashboard
   - Select your project

2. **Create new service**:
   - Click "New Service"
   - Select "Docker Image"

3. **Configure the service**:
   - **Image:** `langflowai/langflow:latest`
   - **Service Name:** `langflow`

4. **Add environment variables**:
   ```
   LANGFLOW_AUTO_LOGIN=true
   LANGFLOW_DATABASE_URL=${{Postgres.DATABASE_PUBLIC_URL}}
   LANGFLOW_HOST=0.0.0.0
   LANGFLOW_PORT=${{PORT}}
   ```

5. **Deploy**:
   - Click "Deploy"
   - Wait for deployment to complete
   - Railway will automatically assign a domain

---

## Important Environment Variables

### Required Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `LANGFLOW_AUTO_LOGIN` | `true` | Enables automatic login (no auth required) |
| `LANGFLOW_DATABASE_URL` | `${{Postgres.DATABASE_PUBLIC_URL}}` | PostgreSQL connection string |
| `LANGFLOW_HOST` | `0.0.0.0` | Listen on all interfaces |
| `LANGFLOW_PORT` | `${{PORT}}` | Use Railway's dynamic port |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LANGFLOW_COMPONENTS_PATH` | `/app/custom_components` | Custom components directory |
| `LANGFLOW_CACHE_TYPE` | `memory` | Cache backend (memory/redis) |
| `LANGFLOW_LOG_LEVEL` | `INFO` | Logging level |

---

## Database Setup

### Using Railway PostgreSQL

1. **Add PostgreSQL to your project**:
   ```bash
   railway add --service postgres
   ```

2. **Link database to Langflow service**:
   - Railway automatically creates `DATABASE_PUBLIC_URL` variable
   - Reference it in Langflow as: `${{Postgres.DATABASE_PUBLIC_URL}}`

3. **Verify connection**:
   ```bash
   railway logs --service langflow
   # Look for: "Connected to database"
   ```

---

## Deployment Verification

### 1. Check Deployment Status
```bash
railway status --service langflow
```

### 2. View Logs
```bash
railway logs --service langflow
```

Expected output:
```
Starting Langflow v1.x.x
Connected to database
Langflow running on http://0.0.0.0:XXXX
```

### 3. Test the Deployment

Visit your Railway domain (e.g., `https://langflow-production.up.railway.app`)

**Verify:**
- [ ] Web interface loads
- [ ] Can create new flows
- [ ] Can save flows (database working)
- [ ] API endpoints respond at `/api/v1/version`

### 4. Health Check
```bash
curl https://your-railway-domain.up.railway.app/health
```

---

## Comparison: Official vs Custom Image

### Official Langflow Image (`langflowai/langflow:latest`)

**Pros:**
- Stable, tested by Langflow team
- Regular updates and security patches
- No build time (instant deployment)
- Community support
- Official documentation applies

**Cons:**
- Langflow branding (logo, favicon, welcome message)
- No custom modifications

### Custom Image (`cope84/engarde-langflow:v1.0.4`)

**Pros:**
- Partial EnGarde branding (title, manifest)
- Railway PORT support

**Cons:**
- Build process unreliable (hung for 24+ hours)
- Maintenance burden
- No full branding achieved
- Requires manual rebuilds for updates

**Decision:** Use official image for stability and maintainability.

---

## Post-Deployment Customization

While the official image has Langflow branding, you can still customize the experience:

### 1. Custom Domain
```bash
railway domain --service langflow
# Then add custom domain: agents.engarde.media
```

### 2. Reverse Proxy with Custom Branding

Deploy a reverse proxy (e.g., Nginx) that:
- Proxies requests to Langflow
- Injects custom CSS/JavaScript for branding
- Modifies response headers

This approach keeps Langflow official while adding branding at the proxy layer.

### 3. Browser Extension

Create a browser extension that:
- Detects your Langflow domain
- Replaces logo/favicon via DOM manipulation
- Changes welcome message

---

## Rollback Plan

If issues occur with the official image:

### Rollback to Custom v1.0.4
```bash
railway up --service langflow --image cope84/engarde-langflow:v1.0.4
```

This version has:
- Railway PORT support
- Partial branding (title, manifest)
- Verified stability

### Rollback to Previous Official Version
```bash
# Use specific version tag
railway up --service langflow --image langflowai/langflow:1.0.0
```

---

## Monitoring and Maintenance

### View Live Logs
```bash
railway logs --service langflow --follow
```

### Check Resource Usage
```bash
railway service --service langflow
```

### Update to Latest Version
```bash
# Pull latest official image
railway up --service langflow --image langflowai/langflow:latest
```

---

## Troubleshooting

### Issue: Container Won't Start

**Check:**
1. PORT variable is set to `${{PORT}}`
2. Database URL is correct
3. View logs: `railway logs --service langflow`

### Issue: Database Connection Failed

**Fix:**
```bash
# Verify Postgres is running
railway status --service postgres

# Check DATABASE_PUBLIC_URL
railway variables --service langflow
```

### Issue: Out of Memory

**Solution:**
- Increase Railway plan tier
- Or optimize LANGFLOW_CACHE_TYPE setting

---

## Support and Resources

### Official Langflow Documentation
- Website: https://langflow.org
- Docs: https://docs.langflow.org
- GitHub: https://github.com/langflow-ai/langflow

### Railway Documentation
- Docs: https://docs.railway.app
- Discord: https://discord.gg/railway

### Custom Build Archive
- Location: `/Users/cope/EnGardeHQ/langflow-custom/`
- Custom image: `cope84/engarde-langflow:v1.0.4`
- Status: Archived (not recommended for production)

---

## Next Steps

1. Deploy official Langflow image to Railway
2. Verify functionality
3. Configure custom domain (optional)
4. Set up monitoring/alerts
5. Archive custom build files

---

**Last Updated:** December 30, 2025
**Deployment Method:** Official Langflow Docker Image
**Railway Compatible:** Yes (uses dynamic PORT variable)
