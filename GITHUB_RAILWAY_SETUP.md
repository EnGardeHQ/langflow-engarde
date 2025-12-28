# GitHub Repository Setup for Railway Deployment

## Step 1: Create GitHub Repository

1. **Go to GitHub:**
   - Visit: https://github.com/organizations/EnGardeHQ/repositories/new
   - Or: GitHub → EnGardeHQ organization → Repositories → New

2. **Repository Settings:**
   - **Repository name:** `easyappointments-railway`
   - **Description:** `EasyAppointments configured for Railway deployment`
   - **Visibility:** Private (or Public, your choice)
   - **DO NOT** initialize with README, .gitignore, or license (we already have files)
   - Click "Create repository"

## Step 2: Update Git Remote and Push

Run these commands in your terminal:

```bash
cd /Users/cope/EnGardeHQ/easyappointments-source

# Remove old remote (points to original EasyAppointments repo)
git remote remove origin

# Add new remote pointing to EnGardeHQ organization
git remote add origin https://github.com/EnGardeHQ/easyappointments-railway.git

# Push to GitHub
git push -u origin main
```

**Note:** If you get authentication errors, you may need to:
- Use SSH: `git@github.com:EnGardeHQ/easyappointments-railway.git`
- Or authenticate with GitHub CLI: `gh auth login`

## Step 3: Deploy in Railway from GitHub

1. **Go to Railway Dashboard:**
   - Visit: https://railway.app/
   - Sign in

2. **Create New Project:**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Authorize Railway to access your GitHub account (if first time)
   - Select: **EnGardeHQ** organization
   - Choose repository: **easyappointments-railway**

3. **Railway will automatically:**
   - Detect `railway.json` configuration
   - Build using `Dockerfile`
   - Start deploying

4. **Add MySQL Database:**
   - In Railway project dashboard
   - Click "New" button (top right)
   - Select "Database" → "MySQL"
   - Wait for provisioning (1-2 minutes)

5. **Configure Environment Variables:**
   - Click on the EasyAppointments service
   - Go to "Variables" tab
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

6. **Wait for Deployment:**
   - Railway will automatically redeploy when you add variables
   - Check "Deployments" tab for progress
   - View logs to verify startup

7. **Verify Deployment:**
   - Railway generates a domain: `your-app-name.up.railway.app`
   - Visit it - should see EasyAppointments installation page
   - Check logs for: "Starting EasyAppointments on port..."

## Step 4: Configure Custom Domain

1. **In Railway Service:**
   - Go to Service → Settings tab
   - Scroll to "Domains" section
   - Click "Custom Domain"
   - Enter: `scheduler.engarde.media`
   - Click "Add"

2. **Get DNS Configuration:**
   - Railway will show DNS instructions
   - **Note the CNAME value** (e.g., `your-app-name.up.railway.app`)
   - Keep this page open for GoDaddy DNS setup

3. **Configure GoDaddy DNS:**
   - Log in to GoDaddy
   - Go to DNS Management for `engarde.media`
   - Add CNAME record:
     - **Name/Host:** `scheduler`
     - **Value/Points to:** Railway domain from above
     - **TTL:** `600`
   - Save

4. **Wait for DNS Propagation:**
   - Usually 5-30 minutes
   - Railway will automatically issue SSL certificate

## Step 5: Complete EasyAppointments Installation

1. **Access Installation Wizard:**
   - Visit: `https://scheduler.engarde.media`
   - Should see EasyAppointments installation page

2. **Database Configuration:**
   - Use MySQL credentials from Railway (Step 5 above)
   - Test connection
   - Complete installation wizard

## Troubleshooting

### Railway Build Fails
- Check Railway logs for specific errors
- Verify Dockerfile syntax is correct
- Ensure all files are committed to GitHub

### Deployment Fails
- Check environment variables are set correctly
- Verify MySQL service is running
- Check logs for Apache startup errors

### Domain Not Working
- Verify DNS CNAME record is correct
- Wait for DNS propagation (can take up to 48 hours)
- Check Railway domain shows as "Active"

## Quick Commands Reference

```bash
# Update remote to EnGardeHQ
cd /Users/cope/EnGardeHQ/easyappointments-source
git remote remove origin
git remote add origin https://github.com/EnGardeHQ/easyappointments-railway.git
git push -u origin main

# Make changes and push updates
git add .
git commit -m "Your commit message"
git push
```

## Benefits of GitHub Deployment

✅ **Automatic builds** - Railway builds on every push  
✅ **Better error messages** - See build logs directly  
✅ **Version control** - Track all changes  
✅ **Easy updates** - Just push to GitHub  
✅ **Railway integration** - railway.json is respected  
