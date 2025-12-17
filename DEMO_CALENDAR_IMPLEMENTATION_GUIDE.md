# Demo Calendar Implementation Guide - Step by Step

## Overview
This guide walks you through implementing a self-hosted calendar scheduler using EasyAppointments integrated with Google Calendar (Gmail + Workspace) for the En Garde demo page.

## ✅ Phase 1: Frontend Button Updates (COMPLETED)

All landing page buttons have been updated to route to `/demo`:
- ✅ "Start Free Trial" → Scrolls to `#pricing` section
- ✅ "Schedule a Demo" (pricing section) → `/demo`
- ✅ "Watch Demo" → `/demo`
- ✅ "Schedule a Demo" (CTA section) → `/demo`
- ✅ "Get Started" (header) → `/demo`

**Status**: Committed and pushed to frontend repository.

## 📋 Phase 2: EasyAppointments Setup

### Step 1: Set Up EasyAppointments Docker Container

1. **Navigate to EasyAppointments directory:**
   ```bash
   cd /Users/cope/EnGardeHQ/easyappointments
   ```

2. **Copy environment file:**
   ```bash
   cp .env.example .env
   ```

3. **Edit `.env` file:**
   ```bash
   # Set secure passwords
   DB_PASSWORD=your_secure_password_here
   DB_ROOT_PASSWORD=your_secure_root_password_here
   
   # Set your production URL (or localhost for testing)
   EASYAPPOINTMENTS_URL=https://scheduler.engarde.media
   EASYAPPOINTMENTS_PORT=8080
   ```

4. **Start EasyAppointments:**
   ```bash
   docker-compose up -d
   ```

5. **Verify services are running:**
   ```bash
   docker ps
   # Should see easyappointments and easyappointments_db containers
   ```

6. **Access EasyAppointments:**
   - Local: `http://localhost:8080`
   - Follow installation wizard

### Step 2: Initial EasyAppointments Configuration

1. **Complete Installation Wizard:**
   - Database connection: Use `db` as hostname (Docker service name)
   - Database name: `easyappointments`
   - Username: `easyappointments`
   - Password: From your `.env` file
   - Create admin account

2. **Configure Basic Settings:**
   - Go to Settings > General
   - Set company name: "En Garde Media"
   - Upload En Garde logo
   - Set timezone

3. **Create Service Categories:**
   - Go to Settings > Services
   - Create category: "Demo Sessions"
   - Add service: "Product Demo" (30-60 minutes)

4. **Set Up Provider (Yourself):**
   - Go to Settings > Providers
   - Add provider with your name
   - Set working hours
   - Assign services

## 📅 Phase 3: Google Calendar Integration

### Step 1: Create Google Cloud Project

1. **Go to Google Cloud Console:**
   - Visit: https://console.cloud.google.com/
   - Sign in with your Google account

2. **Create New Project:**
   - Click "Select a project" → "New Project"
   - Project name: "En Garde Calendar Integration"
   - Click "Create"

3. **Enable Google Calendar API:**
   - Go to "APIs & Services" > "Library"
   - Search for "Google Calendar API"
   - Click "Enable"

### Step 2: Configure OAuth 2.0 Credentials

1. **Create OAuth Client:**
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client ID"
   - If prompted, configure OAuth consent screen first:
     - User Type: External
     - App name: "En Garde Calendar Scheduler"
     - Support email: your email
     - Developer contact: your email
     - Save and continue through scopes and test users

2. **Create OAuth Client ID:**
   - Application type: Web application
   - Name: "EasyAppointments Calendar Sync"
   - Authorized redirect URIs (add both):
     - `https://scheduler.engarde.media/index.php/google/sync`
     - `https://scheduler.engarde.media/index.php/google/oauth`
   - Click "Create"
   - **Copy Client ID and Client Secret** (you'll need these)

### Step 3: Configure Google Calendar in EasyAppointments

1. **Log in to EasyAppointments Admin Panel:**
   - Go to your EasyAppointments URL
   - Log in as admin

2. **Navigate to Google Calendar Settings:**
   - Go to Settings > Integrations > Google Calendar

3. **Enter OAuth Credentials:**
   - Paste Client ID
   - Paste Client Secret
   - Save settings

4. **Authorize Personal Gmail Calendar:**
   - Click "Authorize" button
   - Sign in with your personal Gmail account
   - Grant calendar permissions
   - Select your primary calendar
   - Confirm authorization

5. **Authorize Business Workspace Calendar:**
   - Click "Authorize" again (or add second calendar)
   - Sign in with your Workspace account
   - Grant calendar permissions
   - Select your business calendar
   - Confirm authorization

6. **Configure Sync Settings:**
   - Enable "Sync both ways"
   - Set sync frequency: Every 15 minutes
   - Enable "Block conflicting appointments"
   - Check both calendars for conflict detection
   - Save settings

### Step 4: Test Calendar Sync

1. **Create Test Appointment:**
   - Go to Calendar view in EasyAppointments
   - Create a test appointment
   - Wait for sync (or trigger manual sync)

2. **Verify in Google Calendar:**
   - Check your Gmail calendar
   - Check your Workspace calendar
   - Verify appointment appears in both

3. **Test Conflict Detection:**
   - Create manual event in Google Calendar
   - Try to book overlapping time in EasyAppointments
   - Verify system blocks the conflict

## 🎨 Phase 4: Branding Customization

### Step 1: Custom CSS Theme

1. **Create custom CSS directory:**
   ```bash
   mkdir -p easyappointments/custom/css
   ```

2. **Create En Garde theme file:**
   ```bash
   cat > easyappointments/custom/css/engarde-theme.css << 'EOF'
   /* En Garde Brand Colors */
   :root {
     --engarde-primary: #667eea;
     --engarde-secondary: #764ba2;
     --engarde-accent: #f7fafc;
   }

   /* Primary buttons */
   .btn-primary,
   button.btn-primary {
     background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
     border: none !important;
     color: white !important;
   }

   .btn-primary:hover {
     opacity: 0.9;
     transform: translateY(-1px);
   }

   /* Header */
   .header,
   .navbar {
     background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
   }

   /* Links */
   a {
     color: #667eea;
   }

   a:hover {
     color: #764ba2;
   }

   /* Calendar selected dates */
   .calendar-day.selected {
     background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
   }
   EOF
   ```

3. **Load custom CSS in EasyAppointments:**
   - Go to Settings > General > Custom CSS
   - Add: `/custom/css/engarde-theme.css`
   - Or edit EasyAppointments template files to include CSS

### Step 2: Logo Replacement

1. **Prepare En Garde logo:**
   - Use PNG format
   - Recommended size: 200x50px
   - Save as `logo.png`

2. **Upload logo:**
   ```bash
   cp logo.png easyappointments/uploads/
   ```

3. **Update logo in EasyAppointments:**
   - Go to Settings > General
   - Set logo path: `/uploads/logo.png`

## 🔌 Phase 5: Frontend Integration

### Step 1: Update Environment Variables

1. **Add to Frontend `.env.local`:**
   ```bash
   NEXT_PUBLIC_EASYAPPOINTMENTS_URL=https://scheduler.engarde.media
   ```

2. **Add to Vercel/Railway Environment Variables:**
   - Variable: `NEXT_PUBLIC_EASYAPPOINTMENTS_URL`
   - Value: `https://scheduler.engarde.media`

### Step 2: Verify Demo Page

The demo page (`/demo`) is already configured to use EasyAppointments when the environment variable is set. It will automatically show the iframe when `NEXT_PUBLIC_EASYAPPOINTMENTS_URL` is configured.

### Step 3: Test Integration

1. **Deploy frontend with environment variable**
2. **Visit `/demo` page**
3. **Verify calendar loads in iframe**
4. **Test booking flow**

## 🚀 Phase 6: Production Deployment

### Option A: Railway Deployment (Recommended)

#### Step 1: Prepare Repository for Railway

1. **Create GitHub Repository (if not already created):**
   ```bash
   cd /Users/cope/EnGardeHQ/easyappointments
   git init
   git add .
   git commit -m "Initial EasyAppointments setup for Railway"
   # Create a new repository on GitHub and push:
   git remote add origin https://github.com/YourUsername/easyappointments.git
   git branch -M main
   git push -u origin main
   ```

2. **Verify Dockerfile exists:**
   - The `Dockerfile` should be in the `easyappointments` directory
   - Railway will use this to build the container

#### Step 2: Create Railway Project

1. **Sign in to Railway:**
   - Go to https://railway.app/
   - Sign in with GitHub account

2. **Create New Project:**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your EasyAppointments repository
   - Railway will automatically detect the Dockerfile

#### Step 3: Add MySQL Database Service

1. **Add MySQL Service:**
   - In your Railway project, click "New"
   - Select "Database" → "MySQL"
   - Railway will automatically provision a MySQL 8.0 database
   - **Important:** Note the following values from the MySQL service:
     - `MYSQLHOST` (database hostname)
     - `MYSQLDATABASE` (database name)
     - `MYSQLUSER` (database username)
     - `MYSQLPASSWORD` (database password)
     - `MYSQLPORT` (usually 3306)

#### Step 4: Configure EasyAppointments Service

1. **Set Environment Variables:**
   - Click on your EasyAppointments service
   - Go to "Variables" tab
   - Add the following environment variables:

   ```bash
   # Database Configuration (from MySQL service)
   DB_HOST=${{MySQL.MYSQLHOST}}
   DB_NAME=${{MySQL.MYSQLDATABASE}}
   DB_USERNAME=${{MySQL.MYSQLUSER}}
   DB_PASSWORD=${{MySQL.MYSQLPASSWORD}}
   DB_PORT=${{MySQL.MYSQLPORT}}

   # EasyAppointments Configuration
   BASE_URL=https://scheduler.engarde.media
   
   # PHP Configuration (optional but recommended)
   PHP_MEMORY_LIMIT=256M
   PHP_UPLOAD_MAX_FILESIZE=10M
   PHP_POST_MAX_SIZE=10M
   ```

   **Note:** Railway uses `${{ServiceName.VariableName}}` syntax to reference variables from other services.

2. **Configure Port:**
   - Railway automatically exposes port 80
   - The EasyAppointments Docker image listens on port 80
   - No additional port configuration needed

3. **Set Build Command (if needed):**
   - Railway should auto-detect Dockerfile
   - If not, go to Settings → Build Command
   - Leave empty (Dockerfile handles build)

#### Step 5: Configure Custom Domain in Railway

1. **Add Custom Domain:**
   - In your EasyAppointments service, go to "Settings"
   - Scroll to "Domains" section
   - Click "Generate Domain" to get Railway's default domain first (for testing)
   - Then click "Custom Domain"
   - Enter: `scheduler.engarde.media`
   - Railway will show you the DNS records needed

2. **Note DNS Configuration:**
   - Railway will provide:
     - **CNAME Record:** `scheduler.engarde.media` → `your-app.up.railway.app`
     - Or **A Record:** IP address (if using root domain)
   - **Keep this information** - you'll need it for GoDaddy DNS setup

#### Step 6: Configure GoDaddy DNS Settings

1. **Log in to GoDaddy:**
   - Go to https://www.godaddy.com/
   - Sign in to your account
   - Navigate to "My Products" → "DNS"

2. **Access DNS Management:**
   - Find `engarde.media` domain
   - Click "DNS" or "Manage DNS"

3. **Add CNAME Record for Subdomain:**
   - Click "Add" or "+" to add a new record
   - Select record type: **CNAME**
   - **Name/Host:** `scheduler` (this creates scheduler.engarde.media)
   - **Value/Points to:** `your-app.up.railway.app` (from Railway domain settings)
   - **TTL:** 600 seconds (or default)
   - Click "Save"

   **Example CNAME Record:**
   ```
   Type: CNAME
   Name: scheduler
   Value: your-app-name.up.railway.app
   TTL: 600
   ```

4. **Verify DNS Propagation:**
   - DNS changes can take 5 minutes to 48 hours (usually 5-30 minutes)
   - Check propagation status:
     ```bash
     # In terminal, check DNS resolution:
     dig scheduler.engarde.media
     # Or use online tool: https://www.whatsmydns.net/
     ```
   - Wait until DNS shows Railway's IP address

5. **SSL Certificate Provisioning:**
   - Railway automatically provisions SSL certificates via Let's Encrypt
   - Once DNS propagates, Railway will detect the domain
   - SSL certificate will be issued automatically (usually within 5-10 minutes)
   - You can check SSL status in Railway → Settings → Domains

#### Step 7: Complete EasyAppointments Installation

1. **Access EasyAppointments:**
   - Once DNS and SSL are configured, visit: `https://scheduler.engarde.media`
   - You should see the EasyAppointments installation wizard

2. **Database Configuration:**
   - **Database Host:** Use the MySQL service hostname from Railway
   - **Database Name:** Use `MYSQLDATABASE` value
   - **Database Username:** Use `MYSQLUSER` value
   - **Database Password:** Use `MYSQLPASSWORD` value
   - **Database Port:** Usually `3306`
   - Click "Continue"

3. **Complete Installation:**
   - Follow the installation wizard
   - Create admin account
   - Set timezone and other settings
   - Complete installation

#### Step 8: Update Google OAuth Redirect URIs

1. **Go to Google Cloud Console:**
   - Visit https://console.cloud.google.com/
   - Navigate to your project → "APIs & Services" → "Credentials"

2. **Edit OAuth 2.0 Client:**
   - Click on your OAuth client ID
   - Under "Authorized redirect URIs", update/add:
     - `https://scheduler.engarde.media/index.php/google/sync`
     - `https://scheduler.engarde.media/index.php/google/oauth`
   - Click "Save"

3. **Test OAuth Connection:**
   - Go to EasyAppointments admin panel
   - Navigate to Settings → Integrations → Google Calendar
   - Click "Authorize" and verify it redirects correctly

#### Step 9: Configure Persistent Storage (Important!)

EasyAppointments needs persistent storage for uploads and configuration:

1. **Add Volume in Railway:**
   - Go to EasyAppointments service → Settings
   - Scroll to "Volumes" section
   - Click "Add Volume"
   - Mount path: `/var/www/html/uploads`
   - Mount path: `/var/www/html/config`
   - This ensures uploads and config persist across deployments

2. **Alternative: Use Railway's Persistent Storage:**
   - Railway provides persistent storage automatically
   - However, for production, consider using Railway's volume mounts
   - Or configure external storage (S3, etc.) in EasyAppointments settings

#### Step 10: Verify Deployment

1. **Test Basic Functionality:**
   - Visit `https://scheduler.engarde.media`
   - Verify EasyAppointments loads correctly
   - Log in as admin
   - Check that database connection works

2. **Test Google Calendar Integration:**
   - Go to Settings → Integrations → Google Calendar
   - Authorize calendars
   - Create a test appointment
   - Verify it syncs to Google Calendar

3. **Test Booking Flow:**
   - Visit booking page: `https://scheduler.engarde.media/index.php/book`
   - Create a test booking
   - Verify it appears in admin panel
   - Verify it syncs to Google Calendar

4. **Check Railway Logs:**
   - In Railway dashboard, go to your service
   - Click "Deployments" → View logs
   - Verify no errors in logs

#### Troubleshooting Railway Deployment

**Issue: Service won't start**
- Check environment variables are set correctly
- Verify database connection variables reference MySQL service correctly
- Check Railway logs for specific errors

**Issue: Domain not resolving**
- Verify DNS CNAME record is correct in GoDaddy
- Wait for DNS propagation (can take up to 48 hours)
- Check Railway domain settings show domain as "Active"

**Issue: SSL certificate not issued**
- Ensure DNS is fully propagated
- Railway needs to verify domain ownership via DNS
- Check Railway → Settings → Domains for SSL status

**Issue: Database connection errors**
- Verify MySQL service is running in Railway
- Check environment variables use correct syntax: `${{MySQL.MYSQLHOST}}`
- Verify database credentials are correct
- Check MySQL service logs in Railway

**Issue: Uploads/config not persisting**
- Add volume mounts in Railway settings
- Or configure external storage in EasyAppointments

### Option B: VPS Deployment (Alternative)

If you prefer VPS deployment instead of Railway:

1. **Set up VPS** (DigitalOcean, AWS EC2, etc.)
2. **Install Docker:**
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   ```

3. **Install Docker Compose:**
   ```bash
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

4. **Clone EasyAppointments setup:**
   ```bash
   git clone <your-repo> easyappointments
   cd easyappointments
   ```

5. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with production values
   ```

6. **Start services:**
   ```bash
   docker-compose up -d
   ```

7. **Set up Nginx reverse proxy:**
   ```nginx
   server {
       listen 80;
       server_name scheduler.engarde.media;
       
       location / {
           proxy_pass http://localhost:8080;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

8. **Set up SSL with Let's Encrypt:**
   ```bash
   sudo certbot --nginx -d scheduler.engarde.media
   ```

9. **Configure GoDaddy DNS (same as Railway):**
   - Add A record pointing to your VPS IP address
   - Or use CNAME if using a subdomain

## ✅ Phase 7: Testing & Verification

### Test Checklist

- [ ] EasyAppointments accessible at production URL
- [ ] Google Calendar OAuth working
- [ ] Both calendars (Gmail + Workspace) authorized
- [ ] Calendar sync working (both directions)
- [ ] Conflict detection working
- [ ] Demo page loads calendar iframe
- [ ] Booking flow works end-to-end
- [ ] Email notifications working (if configured)
- [ ] Branding (logo, colors) applied
- [ ] Mobile responsive

### Test Booking Flow

1. Visit `/demo` page
2. Click on calendar iframe
3. Select service
4. Choose date/time
5. Fill in booking form
6. Submit booking
7. Verify:
   - Confirmation email received
   - Appointment appears in EasyAppointments
   - Appointment syncs to Google Calendar
   - Conflict detection works

## 🔧 Troubleshooting

### Calendar Not Syncing

1. Check OAuth token expiration
2. Re-authorize calendars in EasyAppointments
3. Check sync logs in EasyAppointments admin panel
4. Verify Google Calendar API is enabled

### Iframe Not Loading

1. Check `NEXT_PUBLIC_EASYAPPOINTMENTS_URL` is set
2. Verify EasyAppointments is accessible
3. Check browser console for CORS errors
4. Ensure iframe src URL is correct

### Styling Not Applied

1. Clear browser cache
2. Verify custom CSS file path
3. Check file permissions
4. Ensure CSS is loaded in EasyAppointments

## 📚 Additional Resources

- **EasyAppointments Docs:** https://easyappointments.org/docs/
- **Google Calendar API:** https://developers.google.com/calendar
- **Docker Compose Docs:** https://docs.docker.com/compose/
- **Railway Documentation:** https://docs.railway.app/
- **GoDaddy DNS Help:** https://www.godaddy.com/help/manage-dns-records-680
- **Detailed Railway Deployment Guide:** See `RAILWAY_DEPLOYMENT_DETAILED.md` for step-by-step instructions

## Next Steps After Setup

1. Configure email notifications
2. Set up SMS reminders (optional)
3. Add custom booking form fields
4. Set up webhook notifications to En Garde backend
5. Monitor calendar sync logs
6. Set up backup for database

---

**Status**: Frontend and backend changes committed. Ready for EasyAppointments setup.
