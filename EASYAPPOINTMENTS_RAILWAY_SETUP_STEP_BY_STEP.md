# EasyAppointments Railway Setup - Complete Step-by-Step Guide

## Overview
This guide walks you through setting up EasyAppointments on Railway using Docker Hub. We'll:
1. Get EasyAppointments source code
2. Build a Docker image locally
3. Push to Docker Hub
4. Deploy to Railway from Docker Hub
5. Configure DNS in GoDaddy

---

## Prerequisites
- Docker Desktop installed and running
- Docker Hub account (free at https://hub.docker.com/)
- Railway account (free at https://railway.app/)
- GoDaddy account with `engarde.media` domain
- Terminal/Command line access

---

## Step 1: Get EasyAppointments Source Code

### Option A: Clone from Official Repository (Recommended)

1. **Open Terminal:**
   ```bash
   cd /Users/cope/EnGardeHQ
   ```

2. **Clone EasyAppointments Repository:**
   ```bash
   git clone https://github.com/alextselegidis/easyappointments.git easyappointments-source
   cd easyappointments-source
   ```

3. **Verify Files:**
   ```bash
   ls -la
   # You should see files like: index.php, config/, application/, etc.
   ```

### Option B: Download ZIP File

1. **Download from GitHub:**
   - Visit: https://github.com/alextselegidis/easyappointments
   - Click "Code" → "Download ZIP"
   - Extract ZIP file to: `/Users/cope/EnGardeHQ/easyappointments-source`

2. **Navigate to Directory:**
   ```bash
   cd /Users/cope/EnGardeHQ/easyappointments-source
   ```

---

## Step 2: Create Dockerfile

1. **Create Dockerfile in the EasyAppointments Directory:**
   ```bash
   cd /Users/cope/EnGardeHQ/easyappointments-source
   ```

2. **Create Dockerfile:**
   ```bash
   cat > Dockerfile << 'EOF'
   FROM php:8.1-apache

   # Install system dependencies
   RUN apt-get update && apt-get install -y \
       libpng-dev \
       libjpeg-dev \
       libfreetype6-dev \
       libzip-dev \
       unzip \
       && rm -rf /var/lib/apt/lists/*

   # Install PHP extensions
   RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
       && docker-php-ext-install -j$(nproc) gd pdo pdo_mysql zip

   # Enable Apache mod_rewrite
   RUN a2enmod rewrite

   # Set working directory
   WORKDIR /var/www/html

   # Copy EasyAppointments files
   COPY . /var/www/html/

   # Set permissions
   RUN chown -R www-data:www-data /var/www/html \
       && chmod -R 755 /var/www/html

   # Expose port 80
   EXPOSE 80

   # Start Apache
   CMD ["apache2-foreground"]
   EOF
   ```

3. **Verify Dockerfile Created:**
   ```bash
   cat Dockerfile
   # Should show the Dockerfile contents
   ```

---

## Step 3: Build Docker Image Locally

1. **Log in to Docker Hub (if not already):**
   ```bash
   docker login
   # Enter your Docker Hub username and password
   ```

2. **Build Docker Image:**
   ```bash
   cd /Users/cope/EnGardeHQ/easyappointments-source
   
   # Build image (replace 'your-dockerhub-username' with your actual Docker Hub username)
   docker build -t your-dockerhub-username/easyappointments:latest .
   
   # Example:
   # docker build -t johndoe/easyappointments:latest .
   ```

3. **Wait for Build to Complete:**
   - This may take 5-10 minutes
   - You'll see progress output
   - Wait for "Successfully built" message

4. **Verify Image Created:**
   ```bash
   docker images | grep easyappointments
   # Should show your image
   ```

5. **Test Image Locally (Optional but Recommended):**
   ```bash
   # Run container locally to test
   docker run -d -p 8080:80 --name easyappointments-test your-dockerhub-username/easyappointments:latest
   
   # Visit http://localhost:8080 in browser
   # Should see EasyAppointments installation page
   
   # Stop and remove test container when done:
   docker stop easyappointments-test
   docker rm easyappointments-test
   ```

---

## Step 4: Push Docker Image to Docker Hub

1. **Push Image to Docker Hub:**
   ```bash
   # Push the image (replace with your Docker Hub username)
   docker push your-dockerhub-username/easyappointments:latest
   
   # Example:
   # docker push johndoe/easyappointments:latest
   ```

2. **Wait for Upload to Complete:**
   - This may take 5-15 minutes depending on your internet speed
   - You'll see progress output

3. **Verify Image on Docker Hub:**
   - Visit https://hub.docker.com/
   - Log in
   - Go to "Repositories"
   - You should see `easyappointments` repository
   - Click on it to verify the image is there

---

## Step 5: Create Railway Project

1. **Sign in to Railway:**
   - Visit https://railway.app/
   - Click "Start a New Project"
   - Sign in with GitHub (recommended) or email

2. **Create New Project:**
   - Click "New Project"
   - Select "Deploy from Docker Hub"

3. **Enter Docker Image Details:**
   - **Docker Image:** `your-dockerhub-username/easyappointments:latest`
     - Example: `johndoe/easyappointments:latest`
   - **Image Registry:** Docker Hub
   - Click "Deploy"

4. **Wait for Initial Deployment:**
   - Railway will pull your image from Docker Hub
   - This may take 2-5 minutes
   - You'll see deployment progress

---

## Step 6: Add MySQL Database in Railway

1. **Add MySQL Service:**
   - In your Railway project dashboard
   - Click "New" button (top right)
   - Select "Database" → "MySQL"

2. **Wait for MySQL to Provision:**
   - Railway will automatically create MySQL 8.0 database
   - Takes 1-2 minutes

3. **Get Database Credentials:**
   - Click on the MySQL service
   - Go to "Variables" tab
   - **Write down these values** (you'll need them):
     - `MYSQLHOST` (e.g., `containers-us-west-123.railway.app`)
     - `MYSQLDATABASE` (e.g., `railway`)
     - `MYSQLUSER` (e.g., `root`)
     - `MYSQLPASSWORD` (random password - copy this!)
     - `MYSQLPORT` (usually `3306`)

---

## Step 7: Configure EasyAppointments Service in Railway

1. **Go to EasyAppointments Service:**
   - Click on your EasyAppointments service in Railway dashboard

2. **Add Environment Variables:**
   - Click "Variables" tab
   - Click "New Variable" for each:

   **Database Variables (use Railway's reference syntax):**
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
   ```

3. **Save Variables:**
   - Click "Save" after adding each variable
   - Railway will automatically redeploy with new variables

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
   - **Database Host:** Use `MYSQLHOST` value from Step 6
     - Example: `containers-us-west-123.railway.app`
   - **Database Name:** Use `MYSQLDATABASE` value
     - Example: `railway`
   - **Database Username:** Use `MYSQLUSER` value
     - Example: `root`
   - **Database Password:** Use `MYSQLPASSWORD` value (copy from Railway)
   - **Database Port:** `3306`
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

1. **Go to EasyAppointments Admin:**
   - Visit: `https://scheduler.engarde.media/index.php/backend`
   - Log in

2. **Navigate to Google Calendar Settings:**
   - Go to: Settings → Integrations → Google Calendar

3. **Enter OAuth Credentials:**
   - Paste Client ID
   - Paste Client Secret
   - Click "Save"

4. **Authorize Calendars:**
   - Click "Authorize" button
   - Sign in with your **personal Gmail account**
   - Grant calendar permissions
   - Select your primary calendar
   - Confirm authorization

5. **Authorize Second Calendar:**
   - Click "Authorize" again (or add second calendar)
   - Sign in with your **Workspace account**
   - Grant calendar permissions
   - Select your business calendar
   - Confirm authorization

6. **Configure Sync Settings:**
   - Enable "Sync both ways"
   - Set sync frequency: Every 15 minutes
   - Enable "Block conflicting appointments"
   - Check both calendars for conflict detection
   - Click "Save"

---

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

- **Error:** "Database connection failed"
  - **Solution:** Check environment variables use correct syntax: `${{MySQL.MYSQLHOST}}`

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
# Clone EasyAppointments
git clone https://github.com/alextselegidis/easyappointments.git easyappointments-source
cd easyappointments-source

# Build Docker image
docker build -t your-dockerhub-username/easyappointments:latest .

# Push to Docker Hub
docker push your-dockerhub-username/easyappointments:latest

# Test locally
docker run -d -p 8080:80 --name easyappointments-test your-dockerhub-username/easyappointments:latest

# Check DNS propagation
dig scheduler.engarde.media
```

---

## Summary Checklist

- [ ] Cloned/downloaded EasyAppointments source code
- [ ] Created Dockerfile
- [ ] Built Docker image locally
- [ ] Pushed image to Docker Hub
- [ ] Created Railway project
- [ ] Deployed from Docker Hub to Railway
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
