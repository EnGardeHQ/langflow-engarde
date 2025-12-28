# EasyAppointments Setup for En Garde

## Quick Start

1. **Copy environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` file with your credentials:**
   - Set secure database passwords
   - Set EasyAppointments URL (e.g., `https://scheduler.engarde.media`)
   - Add Google OAuth credentials (after creating Google Cloud project)

3. **Start services:**
   ```bash
   docker-compose up -d
   ```

4. **Access EasyAppointments:**
   - Open `http://localhost:8080` (or your configured URL)
   - Complete installation wizard
   - Log in as admin

5. **Configure Google Calendar:**
   - Go to Settings > Integrations > Google Calendar
   - Enter OAuth credentials
   - Authorize both calendars (Gmail + Workspace)
   - Enable sync

## Google Calendar Setup

### Step 1: Create Google Cloud Project
1. Visit https://console.cloud.google.com/
2. Create new project: "En Garde Calendar Integration"
3. Enable Google Calendar API

### Step 2: Create OAuth Credentials
1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth 2.0 Client ID"
3. Application type: Web application
4. Name: "EasyAppointments Calendar Sync"
5. Authorized redirect URIs:
   - `https://scheduler.engarde.media/index.php/google/sync`
   - `https://scheduler.engarde.media/index.php/google/oauth`
6. Copy Client ID and Client Secret

### Step 3: Configure in EasyAppointments
1. Log in to EasyAppointments admin panel
2. Navigate to Settings > Integrations > Google Calendar
3. Paste Client ID and Client Secret
4. Click "Authorize" for each calendar:
   - Personal Gmail calendar
   - Business Workspace calendar
5. Enable "Sync both ways"
6. Set sync frequency (recommended: 15 minutes)

## Custom Branding

### Theme Customization
Create custom CSS file at `custom/css/engarde-theme.css`:

```css
/* En Garde Brand Colors */
:root {
  --engarde-primary: #667eea;
  --engarde-secondary: #764ba2;
  --engarde-accent: #f7fafc;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
  border: none !important;
}

.header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
}
```

### Logo Replacement
1. Replace logo files in `uploads/` directory
2. Update logo path in Settings > General

## Integration with En Garde Frontend

The frontend demo page (`/demo`) will embed EasyAppointments using an iframe:

```tsx
<iframe
  src="https://scheduler.engarde.media/index.php/book"
  width="100%"
  height="100%"
  frameBorder="0"
  style={{ minHeight: '600px', border: 'none' }}
  title="Schedule a Demo - En Garde"
/>
```

## Production Deployment

### Railway Deployment
1. Create new Railway project
2. Add MySQL service
3. Deploy EasyAppointments:
   - Use `docker-compose.yml`
   - Set environment variables
   - Configure domain: `scheduler.engarde.media`
4. Set up SSL certificate (automatic with Railway)

### Environment Variables for Railway
- `DB_PASSWORD`: Secure database password
- `DB_ROOT_PASSWORD`: Secure root password
- `EASYAPPOINTMENTS_URL`: Your production URL
- `GOOGLE_CLIENT_ID`: From Google Cloud Console
- `GOOGLE_CLIENT_SECRET`: From Google Cloud Console

## Troubleshooting

### Calendar Sync Not Working
- Check OAuth token expiration
- Verify redirect URIs match exactly
- Check EasyAppointments sync logs
- Ensure Google Calendar API is enabled

### Database Connection Issues
- Verify database credentials in `.env`
- Check database container is running: `docker ps`
- Check logs: `docker-compose logs db`

### Styling Issues
- Clear browser cache
- Verify custom CSS file is loaded
- Check file permissions on custom directory

## Support

For EasyAppointments documentation:
- Official docs: https://easyappointments.org/docs/
- GitHub: https://github.com/alextselegidis/easyappointments
