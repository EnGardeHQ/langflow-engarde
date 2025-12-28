# Railway Deployment - Complete Fix Guide

## Problem Analysis
Railway deployment is failing because:
1. **Deployment method mismatch**: railway.json says "build from Dockerfile" but you're deploying from Docker Hub
2. **PORT handling**: Railway provides PORT env var but container might not be handling it correctly
3. **Healthcheck**: Railway needs a working healthcheck endpoint

## Solution Options

### Option 1: Deploy from GitHub Source (RECOMMENDED)
This is more reliable and allows Railway to build directly from your source code.

### Option 2: Fix Docker Hub Deployment
Update Docker image and Railway configuration to work together.

---

## Option 1: Deploy from GitHub Source (RECOMMENDED)

### Step 1: Push Source Code to GitHub
```bash
cd /Users/cope/EnGardeHQ/easyappointments-source

# If not already a git repo, initialize it
git init
git add .
git commit -m "Initial commit - Railway ready"

# Create GitHub repo and push
# Go to GitHub → New Repository → easyappointments-railway
git remote add origin https://github.com/YOUR_USERNAME/easyappointments-railway.git
git branch -M main
git push -u origin main
```

### Step 2: Deploy in Railway from GitHub

1. **Go to Railway Dashboard**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your `easyappointments-railway` repository

2. **Railway will automatically:**
   - Detect `railway.json`
   - Build using `Dockerfile`
   - Deploy the service

3. **Add MySQL Database:**
   - Click "New" → "Database" → "MySQL"
   - Wait for provisioning

4. **Configure Environment Variables:**
   - Go to Service → Variables
   - Add:
     ```
     DB_HOST = ${{MySQL.MYSQLHOST}}
     DB_NAME = ${{MySQL.MYSQLDATABASE}}
     DB_USERNAME = ${{MySQL.MYSQLUSER}}
     DB_PASSWORD = ${{MySQL.MYSQLPASSWORD}}
     DB_PORT = ${{MySQL.MYSQLPORT}}
     BASE_URL = https://scheduler.engarde.media
     ```

5. **Deploy:**
   - Railway will automatically build and deploy
   - Check logs for any errors

---

## Option 2: Fix Docker Hub Deployment

### Step 1: Update Dockerfile with PORT Handling

The Dockerfile needs to handle Railway's PORT variable properly.

### Step 2: Rebuild and Push Image

```bash
cd /Users/cope/EnGardeHQ/easyappointments-source

# Copy the Railway-optimized Dockerfile
cp Dockerfile.railway-final Dockerfile

# Rebuild
docker build --no-cache -t cope84/easyappointments:latest .

# Push
docker push cope84/easyappointments:latest
```

### Step 3: Update Railway Service Configuration

1. **Go to Railway Dashboard**
   - Navigate to your EasyAppointments service

2. **Service Settings:**
   - Go to Settings → Deploy
   - **Remove** any custom startCommand
   - Ensure "Build from Docker Hub" is selected
   - Image: `cope84/easyappointments:latest`

3. **Environment Variables:**
   - Ensure PORT is NOT manually set (Railway provides it automatically)
   - Verify database variables use reference syntax

4. **Redeploy:**
   - Go to Deployments → Redeploy
   - Or delete service and recreate

---

## Option 3: Use Railway's Nixpacks Builder (EASIEST)

Railway can auto-detect PHP applications and build them automatically.

### Step 1: Create railway.toml

```toml
[build]
builder = "nixpacks"

[deploy]
startCommand = "apache2-foreground"
healthcheckPath = "/"
healthcheckTimeout = 100
```

### Step 2: Deploy from GitHub

Railway will automatically:
- Detect PHP application
- Install dependencies
- Configure Apache
- Deploy

---

## Troubleshooting Railway Deployment Failures

### Check Railway Logs

1. Go to Railway → Service → Deployments
2. Click on latest deployment
3. View logs for errors

### Common Errors and Fixes

#### Error: "Container failed to start"
- **Cause**: PORT not handled correctly
- **Fix**: Use Dockerfile.railway-final which handles PORT

#### Error: "Healthcheck failed"
- **Cause**: Application not responding on `/`
- **Fix**: Ensure index.php exists and Apache is configured correctly

#### Error: "Build failed"
- **Cause**: Dockerfile issues or missing files
- **Fix**: Test Dockerfile locally first:
  ```bash
  docker build -t test .
  docker run -p 8080:80 test
  ```

#### Error: "Database connection failed"
- **Cause**: Environment variables not set correctly
- **Fix**: Verify variables use Railway reference syntax: `${{MySQL.MYSQLHOST}}`

### Verify Deployment

1. **Check Service Status:**
   - Railway Dashboard → Service → Should show "Active"

2. **Test Healthcheck:**
   - Railway generates a domain: `your-app.up.railway.app`
   - Visit it - should see EasyAppointments installation page

3. **Check Logs:**
   - Should see: "Apache/2.4.x configured"
   - Should see: "Server listening on port..."

---

## Recommended Approach

**Use Option 1 (Deploy from GitHub)** because:
- ✅ Railway builds directly from source
- ✅ railway.json is properly respected
- ✅ Easier to update and redeploy
- ✅ Better error messages
- ✅ Automatic builds on git push

**Steps:**
1. Push source code to GitHub
2. Connect Railway to GitHub repo
3. Railway builds automatically
4. Configure environment variables
5. Deploy!

---

## Quick Test Commands

```bash
# Test Docker image locally
docker run -d -p 8080:80 \
  -e PORT=80 \
  --name test \
  cope84/easyappointments:latest

# Check logs
docker logs test

# Test HTTP response
curl http://localhost:8080

# Cleanup
docker stop test && docker rm test
```

---

## Next Steps After Successful Deployment

1. ✅ Service is running
2. ✅ Add custom domain: `scheduler.engarde.media`
3. ✅ Configure DNS in GoDaddy
4. ✅ Complete EasyAppointments installation wizard
5. ✅ Configure Google Calendar integration
