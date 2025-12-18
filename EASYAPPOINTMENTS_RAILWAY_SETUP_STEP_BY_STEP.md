# EasyAppointments Railway Setup - Complete Step-by-Step Guide

## Overview
This guide walks you through setting up EasyAppointments on Railway using GitHub deployment (EnGardeHQ organization). We'll:
1. Get EasyAppointments source code (already configured for MySQL)
2. Deploy from GitHub to Railway
3. Add MySQL database in Railway
4. Configure environment variables
5. Configure DNS in GoDaddy

---

## Prerequisites
- Railway account (free at https://railway.app/)
- GitHub account with access to EnGardeHQ organization
- GoDaddy account with `engarde.media` domain
- Terminal/Command line access (optional, for local testing)

---

## ⚠️ CRITICAL: Railway Deployment Notes

**This setup uses GitHub deployment - Railway builds directly from the repository!**

### Key Points:
- ✅ **Railway builds from GitHub** - No Docker Hub needed
- ✅ **MySQL configured** - Uses MySQL as the primary database
- ✅ **Environment variables** - Set in Railway, not baked into image
- ✅ **PORT handling** - Dockerfile handles Railway's PORT variable (e.g., 8080)
- ✅ **Repository:** `EnGardeHQ/easyappointments-railway` on GitHub

### If Deployment Fails:
1. Check Railway build logs for specific errors
2. Verify MySQL service is running
3. Ensure environment variables use MySQL references: `${{MySQL.MYSQLHOST}}`
4. Check that `railway.json` and `Dockerfile` are in the repository

See **Step 5** for deployment instructions and troubleshooting sections for common issues.

---

## Step 1: Repository Already Configured

✅ **The EasyAppointments repository is already set up in the EnGardeHQ GitHub organization:**
- Repository: `https://github.com/EnGardeHQ/easyappointments-railway`
- Configured for MySQL
- Railway-ready Dockerfile included
- `railway.json` configuration file included

**Note:** The repository is already configured with:
- MySQL PHP extensions (`mysqli`, `pdo_mysql`)
- MySQL database driver configuration
- Railway PORT handling
- Apache MPM configuration fixes

If you need to make changes locally:
```bash
cd /Users/cope/EnGardeHQ/easyappointments-source
git pull origin main
```

---

## Step 2: Dockerfile Already Configured

✅ **The Dockerfile is already configured in the repository with:**
- MySQL support (`mysqli`, `pdo_mysql` extensions)
- Railway PORT handling (listens on Railway's PORT environment variable)
- Apache MPM configuration fixes
- Proper directory permissions

**Key Features:**
- Uses MySQL natively
- Handles Railway's PORT variable (e.g., 8080)
- Fixes Apache MPM conflicts
- Ready for Railway deployment

No action needed - the Dockerfile is production-ready!

---

## Step 3: Deploy from GitHub (Skip Docker Hub)

**✅ Railway builds directly from GitHub - no Docker Hub needed!**

Railway will automatically:
- Build the Dockerfile from the GitHub repository
- Use the `railway.json` configuration
- Deploy the service

**No local Docker build required** - Railway handles everything!

---

## Step 4: (Skipped - Using GitHub Deployment)

**✅ No Docker Hub needed!** Railway builds directly from GitHub.

---

## Step 5: Create Railway Project from GitHub

1. **Sign in to Railway:**
   - Visit https://railway.app/
   - Click "Start a New Project"
   - Sign in with GitHub (required for GitHub deployment)

2. **Authorize Railway (if first time):**
   - Railway will ask to access your GitHub account
   - Grant access to EnGardeHQ organization
   - Allow Railway to access repositories

3. **Create New Project:**
   - Click "New Project"
   - Select "Deploy from GitHub repo"

4. **Select Repository:**
   - Select: **EnGardeHQ** organization
   - Choose repository: **easyappointments-railway**
   - Click "Deploy"

5. **Wait for Initial Build:**
   - Railway will automatically:
     - Detect `railway.json` configuration
     - Build using `Dockerfile`
     - Start deploying
   - This may take 5-10 minutes for first build
   - You'll see build progress and logs

6. **Verify Build Success:**
   - Check Railway logs for successful build
   - Should see: "Starting EasyAppointments on port 8080"
   - No errors about MPM or port conflicts

---

## Step 6: Add MySQL Database in Railway

1. **Add MySQL Service:**
   - In your Railway project dashboard
   - Click "New" button (top right)
   - Select "Database" → "MySQL"

2. **Wait for MySQL to Provision:**
   - Railway will automatically create MySQL database
   - Takes 1-2 minutes
   - Railway will show provisioning progress

3. **Get Database Credentials:**
   - Click on the MySQL service
   - Go to "Variables" tab
   - Railway automatically provides these variables:
     - `MYSQLHOST` (e.g., `containers-us-west-123.railway.app`)
     - `MYSQLDATABASE` (e.g., `railway`)
     - `MYSQLUSER` (e.g., `postgres`)
     - `MYSQLPASSWORD` (random password - Railway manages this)
     - `MYSQLPORT` (usually `3306`)
   
   **Note:** You don't need to write these down - Railway will provide them via environment variable references in the next step.

---

## Step 7: Configure EasyAppointments Service in Railway

1. **Go to EasyAppointments Service:**
   - Click on your EasyAppointments service in Railway dashboard

2. **Add Environment Variables:**
   - Click "Variables" tab
   - Click "New Variable" for each:

   **MySQL Database Variables (use Railway's reference syntax):**
   ```
   Variable Name: DB_HOST
   Value: ${{MySQL.MYSQLHOST}}
   (Click "Reference" button and select MySQL → MYSQLHOST)
   
   Variable Name: DB_NAME
   Value: ${{MySQL.MYSQLDATABASE}}
   (Click "Reference" button and select MySQL → MYSQLDATABASE)
   
   Variable Name: DB_USERNAME
   Value: ${{MySQL.MYSQLUSER}}
   (Click "Reference" button and select MySQL → MYSQLUSER)
   
   Variable Name: DB_PASSWORD
   Value: ${{MySQL.MYSQLPASSWORD}}
   (Click "Reference" button and select MySQL → MYSQLPASSWORD)
   
   Variable Name: DB_PORT
   Value: ${{MySQL.MYSQLPORT}}
   (Click "Reference" button and select MySQL → MYSQLPORT)
   ```

   **Application Variables:**
   ```
   Variable Name: BASE_URL
   Value: https://scheduler.engarde.media
   
   Variable Name: PHP_MEMORY_LIMIT
   Value: 256M
   
   Variable Name: PHP_UPLOAD_MAX_FILESIZE
   Value: 10M
      Variable Name: PHP_POST_MAX_SIZE
    Value: 10M
    
    # Optional: Google Calendar Integration
    Variable Name: GOOGLE_CLIENT_ID
    Value: your-google-client-id
    
    Variable Name: GOOGLE_CLIENT_SECRET
    Value: your-google-client-secret
    
    Variable Name: GOOGLE_SYNC_FEATURE
    Value: true
    ```

   **Important Notes:**
   - ✅ Use Railway's "Reference" button to link MySQL variables
   - ✅ This ensures automatic updates if database credentials change
   - ✅ Railway handles password rotation automatically

3. **Save Variables:**
   - Click "Save" after adding each variable
   - Railway will automatically redeploy with new variables
   - Check deployment logs to verify database connection succeeds

---

## Step 8: Configure Custom Domain in Railway

1. **Generate Railway Domain (for testing):**
   - Go to EasyAppointments service → "Settings" tab
   - Scroll to "Domains" section
   - Click "Generate Domain"
   - Railway creates: `your-app-name.up.railway.app`
   - **Copy this domain** - you'll need it for DNS

2. **Add Custom Domain:**
   - Still in "Domains" section
   - Click "Custom Domain"
   - Enter: `scheduler.engarde.media`
   - Click "Add"

3. **Get DNS Configuration:**
   - Railway will show DNS instructions
   - **Note the CNAME value** (e.g., `your-app-name.up.railway.app`)
   - Keep this page open - you'll need it for GoDaddy

---

## Step 9: Configure GoDaddy DNS

1. **Log in to GoDaddy:**
   - Visit https://www.godaddy.com/
   - Sign in to your account

2. **Navigate to DNS Management:**
   - Click "My Products"
   - Find `engarde.media` domain
   - Click "DNS" or "Manage DNS"

3. **Add CNAME Record:**
   - Click "Add" button (or "+" icon)
   - Select record type: **CNAME**

4. **Fill in CNAME Details:**
   - **Name/Host:** `scheduler`
     - This creates `scheduler.engarde.media`
   - **Value/Points to:** `your-app-name.up.railway.app`
     - Use the Railway domain from Step 8
     - Example: `easyappointments-production.up.railway.app`
   - **TTL:** `600` (or leave default)
   - Click "Save"

5. **Verify Record Added:**
   - You should see a new CNAME record:
     ```
     Type: CNAME
     Name: scheduler
     Value: your-app-name.up.railway.app
     TTL: 600
     ```

---

## Step 10: Wait for DNS Propagation

1. **Check DNS Propagation:**
   ```bash
   # In terminal:
   dig scheduler.engarde.media
   
   # Or use online tool:
   # Visit: https://www.whatsmydns.net/
   # Enter: scheduler.engarde.media
   # Select: CNAME
   ```

2. **Wait for Propagation:**
   - Usually takes 5-30 minutes
   - Can take up to 48 hours in rare cases
   - Check every 10 minutes until it resolves

3. **Verify in Railway:**
   - Go back to Railway → Service → Settings → Domains
   - `scheduler.engarde.media` should show as "Active"
   - SSL certificate will be issued automatically (5-10 minutes after DNS resolves)

---

## Step 11: Complete EasyAppointments Installation

1. **Access Installation Wizard:**
   - Visit: `https://scheduler.engarde.media`
   - You should see EasyAppointments installation page
   - If SSL not ready yet, wait 5-10 more minutes

2. **Database Configuration:**
   - **Database Host:** Use `MYSQLHOST` value from Railway MySQL service
     - Example: `containers-us-west-123.railway.app`
     - Get from: Railway → MySQL service → Variables → MYSQLHOST
   - **Database Name:** Use `MYSQLDATABASE` value
     - Example: `railway`
     - Get from: Railway → MySQL service → Variables → MYSQLDATABASE
   - **Database Username:** Use `MYSQLUSER` value
     - Example: `postgres`
     - Get from: Railway → MySQL service → Variables → MYSQLUSER
   - **Database Password:** Use `MYSQLPASSWORD` value
     - Get from: Railway → MySQL service → Variables → MYSQLPASSWORD
     - Click "Show" to reveal the password
   - **Database Port:** `3306` (MySQL default)
   - **Database Type:** Select "MySQL" (if prompted)
   - Click "Test Connection" - should succeed
   - Click "Continue"

3. **Complete Installation:**
   - Follow installation wizard
   - Create admin account:
     - Email: your email
     - Password: create secure password
   - Set timezone and other settings
   - Complete installation

4. **Log in to Admin Panel:**
   - Visit: `https://scheduler.engarde.media/index.php/backend`
   - Log in with admin credentials

---

## Step 12: Configure Google Calendar Integration

### Part A: Google Cloud Console Setup

1. **Go to Google Cloud Console:**
   - Visit https://console.cloud.google.com/
   - Sign in with your Google account

2. **Create Project (if not exists):**
   - Click "Select a project" → "New Project"
   - Project name: "En Garde Calendar Integration"
   - Click "Create"

3. **Enable Google Calendar API:**
   - Go to "APIs & Services" → "Library"
   - Search: "Google Calendar API"
   - Click "Enable"

4. **Configure OAuth Consent Screen:**
   - Go to "APIs & Services" → "OAuth consent screen"
   - User Type: External
   - App name: "En Garde Calendar Scheduler"
   - Support email: your email
   - Developer contact: your email
   - Click "Save and Continue"
   - Skip Scopes (click "Save and Continue")
   - Add test users (your email)
   - Click "Save and Continue"

5. **Create OAuth Credentials:**
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "OAuth 2.0 Client ID"
   - Application type: Web application
   - Name: "EasyAppointments Calendar Sync"
   - Authorized redirect URIs (add both):
     - `https://scheduler.engarde.media/index.php/google/sync`
     - `https://scheduler.engarde.media/index.php/google/oauth`
   - Click "Create"
   - **Copy Client ID and Client Secret** - you'll need these

### Part B: Configure in EasyAppointments

1. **Wait for Deployment**: Ensure you have set the `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, and `GOOGLE_SYNC_FEATURE=true` variables in Railway.

2. **Go to EasyAppointments Admin**:
   - Visit: `https://scheduler.engarde.media/index.php/backend`
   - Log in

3. **Enable Sync on Calendar Page**:
   - Navigate to the **Calendar** tab in the sidebar.
   - You should see a **"Enable Sync"** or **"Synchronize"** button near the top reload icon.
   - Click it to start the OAuth process with Google.

4. **Authorize**:
   - Follow the Google login prompts to grant access to your calendar.
   - Once redirected back, your appointments will begin syncing.

---

## Step 13: Alternative - Sync via API (Experimental)

If you prefer to build a custom sync or the native integration doesn't meet your needs, you can use the built-in REST API.

1. **Enable API**:
   - Go to Settings → Integrations → API.
   - Generate a New API Token.

2. **Key Endpoints**:
   - **Get Appointments**: `GET /api/v1/appointments`
   - **Create Unavailability (Block time)**: `POST /api/v1/unavailabilities`
   - **Check Availability**: `GET /api/v1/availabilities`

3. **Workflow for Google Sync**:
   - Monitor Google Calendar events.
   - For every new "Busy" block in Google, call the EasyAppointments API to create an `unavailability` record for that provider/time.

## Step 13: Test Everything

1. **Test Booking Flow:**
   - Visit: `https://scheduler.engarde.media/index.php/book`
   - Select service
   - Choose date/time
   - Fill in booking form
   - Submit booking

2. **Verify in Admin Panel:**
   - Go to Calendar view
   - Verify booking appears

3. **Verify Google Calendar Sync:**
   - Check your Gmail calendar
   - Check your Workspace calendar
   - Verify appointment appears in both

4. **Test Conflict Detection:**
   - Create manual event in Google Calendar
   - Try to book overlapping time in EasyAppointments
   - Verify system blocks the conflict

---

## Step 14: Update Frontend Environment Variable

1. **Add Environment Variable to Frontend:**
   - In Vercel/Railway frontend deployment
   - Go to Environment Variables
   - Add:
     - Variable: `NEXT_PUBLIC_EASYAPPOINTMENTS_URL`
     - Value: `https://scheduler.engarde.media`
   - Save and redeploy

2. **Verify Demo Page:**
   - Visit: `https://app.engarde.media/demo`
   - Calendar iframe should load

---

## Troubleshooting

### Docker Build Fails
- **Error:** "Cannot connect to Docker daemon"
  - **Solution:** Make sure Docker Desktop is running

- **Error:** "Permission denied"
  - **Solution:** Use `sudo` (Mac/Linux) or run Docker Desktop as administrator (Windows)

### Docker Push Fails
- **Error:** "unauthorized: authentication required"
  - **Solution:** Run `docker login` again

- **Error:** "denied: requested access to the resource is denied"
  - **Solution:** Make sure Docker Hub username matches image tag

### Railway Deployment Fails

- **Error:** "Image not found"
  - **Solution:** Verify image name in Railway matches Docker Hub exactly

- **Error:** "Database connection failed" or "Connection refused"
  - **Solution:** 
    1. Check environment variables use correct MySQL syntax: `${{MySQL.MYSQLHOST}}`
    2. Verify MySQL service is running in Railway
    3. Check that all MySQL variables are set correctly:
       - `DB_HOST` = `${{MySQL.MYSQLHOST}}`
       - `DB_NAME` = `${{MySQL.MYSQLDATABASE}}`
       - `DB_USERNAME` = `${{MySQL.MYSQLUSER}}`
       - `DB_PASSWORD` = `${{MySQL.MYSQLPASSWORD}}`
       - `DB_PORT` = `${{MySQL.MYSQLPORT}}`
    4. Verify MySQL service shows as "Active" in Railway
    5. Check Railway logs for specific database connection errors

- **Error:** "Port binding failed" or "Cannot bind to port"
  - **Solution:**
    1. Verify Dockerfile uses Railway's PORT environment variable
    2. Check that `docker-entrypoint-fixed.sh` handles PORT correctly
    3. Rebuild image: `docker build --no-cache -t cope84/easyappointments:latest .`

- **Error:** "Environment variable not found" or "BASE_URL is localhost"
  - **Solution:**
    1. **Root cause:** Image has local environment baked in
    2. **Fix:** Rebuild image without local environment variables:
       ```bash
       cd /Users/cope/EnGardeHQ/easyappointments-source
       docker build --no-cache -t cope84/easyappointments:latest .
       docker push cope84/easyappointments:latest
       ```
    3. In Railway, ensure BASE_URL is set to: `https://scheduler.engarde.media`
    4. Redeploy service in Railway

- **Error:** Service starts but shows "localhost" URLs instead of production domain
  - **Solution:** 
    1. This means BASE_URL environment variable is not set correctly in Railway
    2. Go to Railway → Service → Variables
    3. Add/update: `BASE_URL=https://scheduler.engarde.media`
    4. Redeploy service

- **Error:** "Image built for local environment, needs Railway rebuild"
  - **Solution:** This is the exact issue you're experiencing!
    1. Follow the rebuild instructions in Step 5 (section 5)
    2. Use `--no-cache` flag to force complete rebuild
    3. Ensure no local environment variables are baked into the image
    4. Push fresh image to Docker Hub
    5. Redeploy in Railway

### DNS Not Resolving
- **Problem:** Domain not working after 30 minutes
  - **Solution:** 
    - Verify CNAME record in GoDaddy is correct
    - Check Railway domain shows as "Active"
    - Wait longer (can take up to 48 hours)

### SSL Certificate Not Issued
- **Problem:** HTTPS not working
  - **Solution:**
    - Ensure DNS is fully propagated
    - Check Railway → Settings → Domains for SSL status
    - Wait 10-15 minutes after DNS resolves

---

## Quick Reference Commands

```bash
# Pull latest changes from GitHub (if working locally)
cd /Users/cope/EnGardeHQ/easyappointments-source
git pull origin main

# Test locally with MySQL (optional)
docker run -d -p 8080:8080 \
  -e PORT=8080 \
  -e DB_HOST=your-postgres-host \
  -e DB_NAME=your-db-name \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD=your-password \
  -e DB_PORT=3306 \
  --name easyappointments-test \
  cope84/easyappointments:latest

# Check DNS propagation
dig scheduler.engarde.media
```

---

## Summary Checklist

- [ ] Repository configured in EnGardeHQ GitHub organization
- [ ] Dockerfile configured for MySQL
- [ ] Created Railway project
- [ ] Deployed from GitHub to Railway
- [ ] Added MySQL database in Railway
- [ ] Configured environment variables
- [ ] Added custom domain in Railway
- [ ] Configured CNAME record in GoDaddy DNS
- [ ] DNS propagated successfully
- [ ] SSL certificate issued
- [ ] Completed EasyAppointments installation
- [ ] Configured Google Calendar OAuth
- [ ] Tested booking flow
- [ ] Updated frontend environment variable

---

**You're all set!** EasyAppointments should now be running at `https://scheduler.engarde.media`
