# Railway Deployment Guide for EasyAppointments

## Quick Reference: Railway + GoDaddy DNS Setup

### Prerequisites
- GitHub account
- Railway account (sign up at https://railway.app/)
- GoDaddy account with `engarde.media` domain
- Google Cloud Console access (for OAuth setup)

---

## Part 1: Railway Deployment

### Step 1: Prepare Repository

1. **Ensure Dockerfile exists:**
   ```bash
   cd /Users/cope/EnGardeHQ/easyappointments
   ls -la Dockerfile  # Should exist
   ```

2. **Create/Update GitHub Repository:**
   ```bash
   # If repository doesn't exist:
   git init
   git add .
   git commit -m "EasyAppointments setup for Railway"
   
   # Create repository on GitHub, then:
   git remote add origin https://github.com/YourUsername/easyappointments.git
   git branch -M main
   git push -u origin main
   ```

### Step 2: Create Railway Project

1. **Sign in to Railway:**
   - Visit https://railway.app/
   - Click "Start a New Project"
   - Sign in with GitHub

2. **Deploy from GitHub:**
   - Select "Deploy from GitHub repo"
   - Choose your `easyappointments` repository
   - Railway will detect the Dockerfile automatically

### Step 3: Add MySQL Database

1. **Add MySQL Service:**
   - In your Railway project dashboard
   - Click "New" → "Database" → "MySQL"
   - Railway will provision MySQL 8.0 automatically

2. **Note Database Credentials:**
   - Click on the MySQL service
   - Go to "Variables" tab
   - You'll see these variables (save them):
     - `MYSQLHOST` (e.g., `containers-us-west-xxx.railway.app`)
     - `MYSQLDATABASE` (e.g., `railway`)
     - `MYSQLUSER` (e.g., `root`)
     - `MYSQLPASSWORD` (random password)
     - `MYSQLPORT` (usually `3306`)

### Step 4: Configure EasyAppointments Service

1. **Set Environment Variables:**
   - Click on your EasyAppointments service
   - Go to "Variables" tab
   - Click "New Variable" and add each:

   **Database Variables (use Railway's reference syntax):**
   ```
   DB_HOST = ${{MySQL.MYSQLHOST}}
   DB_NAME = ${{MySQL.MYSQLDATABASE}}
   DB_USERNAME = ${{MySQL.MYSQLUSER}}
   DB_PASSWORD = ${{MySQL.MYSQLPASSWORD}}
   DB_PORT = ${{MySQL.MYSQLPORT}}
   ```

   **Application Variables:**
   ```
   BASE_URL = https://scheduler.engarde.media
   PHP_MEMORY_LIMIT = 256M
   PHP_UPLOAD_MAX_FILESIZE = 10M
   PHP_POST_MAX_SIZE = 10M
   ```

   **Important:** Use `${{ServiceName.VariableName}}` syntax to reference MySQL variables.

2. **Verify Port Configuration:**
   - Railway automatically exposes port 80
   - EasyAppointments Docker image listens on port 80
   - No manual port configuration needed

### Step 5: Configure Custom Domain

1. **Generate Railway Domain (for testing):**
   - Go to EasyAppointments service → Settings
   - Scroll to "Domains" section
   - Click "Generate Domain"
   - Railway will create: `your-app-name.up.railway.app`
   - Test that this works first

2. **Add Custom Domain:**
   - Still in "Domains" section
   - Click "Custom Domain"
   - Enter: `scheduler.engarde.media`
   - Railway will show DNS configuration needed
   - **Copy the CNAME value** (e.g., `your-app-name.up.railway.app`)

---

## Part 2: GoDaddy DNS Configuration

### Step 1: Access GoDaddy DNS Management

1. **Log in to GoDaddy:**
   - Visit https://www.godaddy.com/
   - Sign in to your account

2. **Navigate to DNS:**
   - Go to "My Products"
   - Find `engarde.media` domain
   - Click "DNS" or "Manage DNS"

### Step 2: Add CNAME Record

1. **Create CNAME Record:**
   - In DNS Management page
   - Click "Add" or "+" button
   - Select record type: **CNAME**

2. **Fill in CNAME Details:**
   - **Name/Host:** `scheduler`
     - This creates the subdomain `scheduler.engarde.media`
   - **Value/Points to:** `your-app-name.up.railway.app`
     - Use the Railway domain from Step 5 above
   - **TTL:** `600` seconds (or leave default)
   - Click "Save"

   **Example:**
   ```
   Type: CNAME
   Name: scheduler
   Value: your-app-name.up.railway.app
   TTL: 600
   ```

### Step 3: Verify DNS Propagation

1. **Check DNS Propagation:**
   ```bash
   # In terminal:
   dig scheduler.engarde.media
   # Or use online tool: https://www.whatsmydns.net/
   ```

2. **Wait for Propagation:**
   - DNS changes typically take 5-30 minutes
   - Can take up to 48 hours in rare cases
   - Check until `scheduler.engarde.media` resolves to Railway's IP

3. **Verify in Railway:**
   - Go back to Railway → Service → Settings → Domains
   - You should see `scheduler.engarde.media` status change to "Active"
   - SSL certificate will be issued automatically (5-10 minutes)

---

## Part 3: Complete EasyAppointments Setup

### Step 1: Access Installation Wizard

1. **Visit Your Domain:**
   - Go to `https://scheduler.engarde.media`
   - You should see EasyAppointments installation wizard

2. **If SSL Not Ready:**
   - Wait a few more minutes
   - Check Railway → Domains for SSL status
   - Railway uses Let's Encrypt for automatic SSL

### Step 2: Configure Database

1. **Enter Database Details:**
   - Use the values from Railway MySQL service:
     - **Host:** `containers-us-west-xxx.railway.app` (from `MYSQLHOST`)
     - **Database:** `railway` (from `MYSQLDATABASE`)
     - **Username:** `root` (from `MYSQLUSER`)
     - **Password:** (from `MYSQLPASSWORD` - copy from Railway)
     - **Port:** `3306` (from `MYSQLPORT`)

2. **Test Connection:**
   - Click "Test Connection"
   - Should succeed if credentials are correct

### Step 3: Complete Installation

1. **Create Admin Account:**
   - Enter admin email, password, etc.
   - Complete installation wizard

2. **Log in and Configure:**
   - Log in to admin panel
   - Go to Settings → General
   - Set company name, logo, timezone

---

## Part 4: Google Calendar Integration

### Step 1: Update OAuth Redirect URIs

1. **Go to Google Cloud Console:**
   - Visit https://console.cloud.google.com/
   - Select your project

2. **Update OAuth Client:**
   - Go to "APIs & Services" → "Credentials"
   - Click on your OAuth 2.0 Client ID
   - Under "Authorized redirect URIs", add:
     - `https://scheduler.engarde.media/index.php/google/sync`
     - `https://scheduler.engarde.media/index.php/google/oauth`
   - Click "Save"

### Step 2: Configure in EasyAppointments

1. **Add Google Calendar Integration:**
   - Log in to EasyAppointments admin
   - Go to Settings → Integrations → Google Calendar
   - Enter Client ID and Client Secret
   - Click "Authorize" for each calendar (Gmail + Workspace)

---

## Troubleshooting

### DNS Issues

**Problem:** Domain not resolving
- **Solution:** 
  - Verify CNAME record in GoDaddy is correct
  - Check TTL hasn't expired
  - Wait longer for propagation (up to 48 hours)
  - Verify Railway domain shows as "Active"

**Problem:** SSL certificate not issued
- **Solution:**
  - Ensure DNS is fully propagated
  - Railway needs DNS to resolve before issuing SSL
  - Check Railway → Settings → Domains for errors
  - Try removing and re-adding domain in Railway

### Database Connection Issues

**Problem:** Can't connect to database
- **Solution:**
  - Verify environment variables use correct syntax: `${{MySQL.MYSQLHOST}}`
  - Check MySQL service is running in Railway
  - Verify database credentials match Railway MySQL service
  - Check Railway logs for specific error messages

### Service Won't Start

**Problem:** EasyAppointments service fails to start
- **Solution:**
  - Check Railway logs: Service → Deployments → View logs
  - Verify all environment variables are set
  - Ensure Dockerfile is correct
  - Check that port 80 is exposed

### Persistent Storage

**Problem:** Uploads/config lost after redeployment
- **Solution:**
  - Add volume mounts in Railway:
    - Go to Service → Settings → Volumes
    - Add volume: `/var/www/html/uploads`
    - Add volume: `/var/www/html/config`
  - Or configure external storage (S3) in EasyAppointments

---

## Verification Checklist

- [ ] Railway project created
- [ ] MySQL database service added
- [ ] EasyAppointments service deployed
- [ ] Environment variables configured
- [ ] Custom domain added in Railway
- [ ] CNAME record added in GoDaddy DNS
- [ ] DNS propagated (verified with dig/whatsmydns)
- [ ] SSL certificate issued (check Railway domains)
- [ ] EasyAppointments installation completed
- [ ] Google Calendar OAuth configured
- [ ] Test booking created successfully
- [ ] Calendar sync working

---

## Next Steps

After successful deployment:

1. Configure email notifications in EasyAppointments
2. Set up backup for MySQL database
3. Monitor Railway logs for any issues
4. Test booking flow end-to-end
5. Update frontend `NEXT_PUBLIC_EASYAPPOINTMENTS_URL` environment variable
