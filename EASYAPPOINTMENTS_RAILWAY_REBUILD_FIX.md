# EasyAppointments Railway Rebuild - Quick Fix Guide

## Problem
You've completed steps 1-5 of the Railway setup guide, but Railway deployment is failing because the Docker image was built for the local environment instead of Railway production.

## Root Cause
The Docker image contains local environment configurations (database URLs, localhost URLs, etc.) that don't work in Railway's production environment.

## Solution: Rebuild Image for Railway Production

### Step 1: Clean Previous Builds
```bash
cd /Users/cope/EnGardeHQ/easyappointments-source

# Remove any existing local images
docker rmi cope84/easyappointments:latest 2>/dev/null || true

# Clean Docker build cache
docker system prune -a -f
```

### Step 2: Rebuild with --no-cache Flag
**CRITICAL:** The `--no-cache` flag ensures a completely fresh build without any cached layers that might contain local configurations.

```bash
docker build --no-cache -t cope84/easyappointments:latest .
```

**Why --no-cache is important:**
- Forces Docker to rebuild every layer from scratch
- Ensures no local environment variables are accidentally cached
- Guarantees Railway environment variables are used at runtime

### Step 3: Push Fresh Image to Docker Hub
```bash
docker push cope84/easyappointments:latest
```

Wait for upload to complete (5-15 minutes depending on internet speed).

### Step 4: Redeploy in Railway

**Option A: Redeploy Existing Service**
1. Go to Railway dashboard
2. Click on your EasyAppointments service
3. Go to "Deployments" tab
4. Click "Redeploy" button
5. Railway will pull the fresh image from Docker Hub

**Option B: Recreate Service (if redeploy doesn't work)**
1. Delete the existing EasyAppointments service in Railway
2. Create new service → "Deploy from Docker Hub"
3. Enter: `cope84/easyappointments:latest`
4. Configure environment variables (see Step 7 in main guide)

### Step 5: Verify Environment Variables in Railway

Ensure these are set correctly in Railway → Service → Variables:

**Database Variables (use Railway's reference syntax):**
- `DB_HOST` = `${{MySQL.MYSQLHOST}}`
- `DB_NAME` = `${{MySQL.MYSQLDATABASE}}`
- `DB_USERNAME` = `${{MySQL.MYSQLUSER}}`
- `DB_PASSWORD` = `${{MySQL.MYSQLPASSWORD}}`
- `DB_PORT` = `${{MySQL.MYSQLPORT}}`

**Application Variables:**
- `BASE_URL` = `https://scheduler.engarde.media`
- `PHP_MEMORY_LIMIT` = `256M`
- `PHP_UPLOAD_MAX_FILESIZE` = `10M`
- `PHP_POST_MAX_SIZE` = `10M`

**Railway-Specific:**
- `PORT` = (automatically provided by Railway - don't set manually)

### Step 6: Verify Deployment

1. Check Railway logs:
   - Go to Service → Deployments → Click latest deployment → View logs
   - Should see: "Starting EasyAppointments on port [PORT]"
   - Should see: "Starting Apache..."

2. Test the service:
   - Visit Railway-generated domain: `your-app-name.up.railway.app`
   - Should see EasyAppointments installation page
   - If custom domain configured: `https://scheduler.engarde.media`

## Common Errors After Rebuild

### "Database connection failed"
- **Fix:** Verify environment variables use Railway reference syntax: `${{MySQL.MYSQLHOST}}`
- Check MySQL service is running in Railway

### "Port binding failed"
- **Fix:** Verify `docker-entrypoint-fixed.sh` exists and handles PORT variable
- Check Railway logs for PORT value

### "BASE_URL is localhost"
- **Fix:** Set `BASE_URL=https://scheduler.engarde.media` in Railway environment variables
- Redeploy service

## Verification Checklist

- [ ] Image rebuilt with `--no-cache` flag
- [ ] Fresh image pushed to Docker Hub
- [ ] Railway service redeployed/recreated
- [ ] All environment variables set correctly in Railway
- [ ] Database variables use Railway reference syntax
- [ ] BASE_URL set to production domain
- [ ] Service starts successfully (check logs)
- [ ] Can access installation page

## Key Takeaways

1. **Always use `--no-cache`** when building for Railway production
2. **Never bake environment variables into the image** - Railway provides them at runtime
3. **The Dockerfile is already Railway-ready** - it handles PORT dynamically
4. **Environment variables are configured in Railway, not in Dockerfile**

## Next Steps

After successful rebuild and deployment:
- Continue with Step 6: Add MySQL Database in Railway
- Step 7: Configure Environment Variables
- Step 8: Configure Custom Domain
- Step 9: Configure DNS in GoDaddy

See `EASYAPPOINTMENTS_RAILWAY_SETUP_STEP_BY_STEP.md` for complete guide.
