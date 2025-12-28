# Railway Deployment Fix - EasyAppointments

## Problem
Railway deployment from Docker Hub fails because:
1. ENTRYPOINT script conflicts with Railway's startCommand
2. Railway handles port mapping automatically - containers should listen on port 80
3. Complex entrypoint script causes runtime failures

## Solution
Use CMD instead of ENTRYPOINT and let Railway handle port mapping automatically.

## Steps to Fix

### Step 1: Rebuild Docker Image with Fixed Dockerfile

```bash
cd /Users/cope/EnGardeHQ/easyappointments-source

# Clean old builds
docker rmi cope84/easyappointments:latest 2>/dev/null || true
docker system prune -f

# Rebuild with Railway-optimized Dockerfile
docker build --no-cache -t cope84/easyappointments:latest .

# Push to Docker Hub
docker push cope84/easyappointments:latest
```

### Step 2: Update Railway Service Configuration

1. **Go to Railway Dashboard**
   - Navigate to your EasyAppointments service

2. **Remove startCommand Override (if exists)**
   - Go to Service → Settings → Deploy
   - Remove any custom startCommand
   - Railway will use CMD from Dockerfile

3. **Verify Environment Variables**
   - Go to Service → Variables
   - Ensure these are set:
     ```
     DB_HOST = ${{MySQL.MYSQLHOST}}
     DB_NAME = ${{MySQL.MYSQLDATABASE}}
     DB_USERNAME = ${{MySQL.MYSQLUSER}}
     DB_PASSWORD = ${{MySQL.MYSQLPASSWORD}}
     DB_PORT = ${{MySQL.MYSQLPORT}}
     BASE_URL = https://scheduler.engarde.media
     ```

4. **Redeploy Service**
   - Go to Deployments tab
   - Click "Redeploy"
   - OR delete and recreate service with image: `cope84/easyappointments:latest`

### Step 3: Verify Deployment

1. **Check Railway Logs**
   - Go to Service → Deployments → Latest deployment → Logs
   - Should see: "Apache/2.4.x (Debian) configured"
   - Should see: "Server listening on port 80"

2. **Test Health Check**
   - Railway healthcheck should pass at `/`
   - Visit Railway-generated domain to verify

## Key Changes Made

### Dockerfile Changes:
- ✅ Removed ENTRYPOINT script
- ✅ Changed to CMD ["apache2-foreground"]
- ✅ Container listens on port 80 (Railway maps automatically)
- ✅ Simplified configuration

### railway.json Changes:
- ✅ Removed startCommand (conflicted with ENTRYPOINT)
- ✅ Railway uses CMD from Dockerfile

## Why This Works

1. **Railway Port Mapping**: Railway automatically maps the PORT environment variable to port 80 in the container. The container doesn't need to know about PORT.

2. **CMD vs ENTRYPOINT**: Using CMD allows Railway to override if needed, and doesn't conflict with Railway's deployment system.

3. **Simplified Startup**: Removing the entrypoint script eliminates potential runtime failures and configuration issues.

## Troubleshooting

### If deployment still fails:

1. **Check Railway Logs**
   ```bash
   # In Railway dashboard → Service → Deployments → Logs
   # Look for error messages
   ```

2. **Verify Image is Correct**
   ```bash
   docker run -d -p 8080:80 --name test cope84/easyappointments:latest
   # Visit http://localhost:8080
   # Should see EasyAppointments installation page
   docker stop test && docker rm test
   ```

3. **Check Environment Variables**
   - Ensure all database variables use Railway reference syntax
   - Verify BASE_URL is set correctly

4. **Try Fresh Service**
   - Delete existing service
   - Create new service → Deploy from Docker Hub
   - Image: `cope84/easyappointments:latest`
   - Configure environment variables
   - Deploy

## Expected Behavior

After fix:
- ✅ Container starts successfully
- ✅ Apache listens on port 80
- ✅ Railway maps to PORT automatically
- ✅ Healthcheck passes
- ✅ Service accessible via Railway domain
