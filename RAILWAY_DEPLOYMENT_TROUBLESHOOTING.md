# Railway Deployment Troubleshooting

## Common Issues Preventing Container Deployment

### Issue 1: Port Configuration (Most Common)
**Problem:** Railway assigns a dynamic PORT environment variable, but Apache is hardcoded to listen on port 80.

**Solution:** The entrypoint script should handle this. Verify:
- Entrypoint script reads `$PORT` environment variable
- Apache is configured to listen on `$PORT` instead of 80

### Issue 2: Container Exits Immediately
**Problem:** Container starts but exits right away, causing Railway to mark it as failed.

**Solution:** Ensure:
- Apache runs in foreground mode (`apache2-foreground`)
- Entrypoint script uses `exec` to keep process running
- No errors in startup that cause immediate exit

### Issue 3: Health Check Failures
**Problem:** Railway's health checks fail because container isn't responding.

**Solution:** 
- Container must respond to HTTP requests on the assigned PORT
- Health check endpoint should be accessible

### Issue 4: Missing Required Files
**Problem:** EasyAppointments requires certain files/directories that don't exist.

**Solution:** Ensure:
- `uploads/` directory exists and is writable
- `config/` directory exists and is writable
- Proper file permissions set

### Issue 5: Apache Configuration Errors
**Problem:** Apache fails to start due to configuration issues.

**Solution:**
- Check Apache error logs
- Ensure mod_rewrite is enabled
- Verify virtual host configuration

## Diagnostic Steps

1. **Check Railway Logs:**
   - Go to Railway dashboard → Your service → Deployments → Click on failed deployment → View logs
   - Look for Apache error messages
   - Check for PHP errors
   - Look for permission errors

2. **Test Container Locally:**
   ```bash
   docker run -d -p 8080:80 -e PORT=80 cope84/easyappointments:latest
   docker logs <container-id>
   ```

3. **Check Environment Variables:**
   - Railway automatically sets `PORT` variable
   - Verify it's being read correctly

4. **Verify Entrypoint Script:**
   - Script should be executable
   - Should handle PORT variable
   - Should start Apache in foreground

## Quick Fixes to Try

### Fix 1: Simplified Dockerfile (No Entrypoint Script)
Sometimes entrypoint scripts cause issues. Try a simpler approach:

```dockerfile
FROM php:8.1-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev unzip \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_mysql zip

# Enable mod_rewrite
RUN a2enmod rewrite

# Configure Apache for Railway PORT
RUN echo 'Listen ${PORT:-80}' > /etc/apache2/ports.conf.new && \
    cat /etc/apache2/ports.conf >> /etc/apache2/ports.conf.new && \
    mv /etc/apache2/ports.conf.new /etc/apache2/ports.conf

WORKDIR /var/www/html
COPY . /var/www/html/

RUN mkdir -p uploads config && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod -R 777 uploads config

EXPOSE 80
CMD ["apache2-foreground"]
```

### Fix 2: Use Railway's Port Detection
Railway automatically maps the PORT variable. The container should:
- Listen on port 80 internally
- Railway will map it to the assigned PORT

### Fix 3: Check Railway Service Settings
1. Go to Railway → Your Service → Settings
2. Check "Deploy" settings:
   - Start Command: Should be empty (uses CMD from Dockerfile)
   - Health Check Path: `/` or `/index.php`
   - Health Check Timeout: 100 seconds
   - Health Check Interval: 30 seconds

## Most Likely Issue

Based on the error, the most likely issue is:
1. **Apache not starting** - Check logs for Apache errors
2. **Port mismatch** - Apache listening on wrong port
3. **Missing directories** - uploads/config directories not created

## Next Steps

1. Check Railway logs for specific error messages
2. Try deploying with simplified Dockerfile
3. Verify environment variables are set correctly
4. Test container locally first
