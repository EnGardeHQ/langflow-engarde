# EnGarde Langflow Customization Summary

**Quick Reference Guide**

---

## What Was Customized?

### 1. SSO Authentication
- **Custom Endpoint:** `/api/v1/custom/sso_login`
- **Location:** `src/backend/base/langflow/api/v1/login.py`
- **Purpose:** Accept JWT tokens from EnGarde backend for seamless authentication
- **Flow:** EnGarde → JWT Token → Langflow → Auto-login

### 2. Frontend Branding
- **Logo:** EnGarde logo replaces Langflow logo
- **Files:**
  - `src/frontend/src/components/core/appHeaderComponent/index.tsx`
  - `src/frontend/src/assets/EnGardeIcon.svg`
- **Footer:** "Made by EnGarde with ❤️"
- **File:** `src/frontend/src/components/core/engardeFooter/index.tsx`
- **Page Title:** "EnGarde - AI Campaign Builder"
- **Manifest:** EnGarde branding in PWA manifest

### 3. Custom Components (14 Total)
- **Location:** `/En Garde Components/` (root directory)
- **Walker Agents:**
  - SEO Walker Agent
  - Paid Ads Walker Agent
  - Content Walker Agent
  - Audience Intelligence Walker Agent
  - Campaign Creation Agent
  - Campaign Launcher Agent
  - Content Approval Agent
  - Notification Agent
  - Performance Monitoring Agent
  - Analytics Report Agent
- **Building Blocks:**
  - Tenant ID Input
  - Walker Suggestion Builder
  - Walker Agent API

### 4. Docker Configuration
- **Production:** `Dockerfile.engarde` (5.33GB, full build)
- **Testing:** `Dockerfile.railway-final` (lightweight)
- **Features:**
  - Multi-stage build
  - Frontend built with branding
  - Custom components included
  - Railway PORT support

---

## Key Files Modified

### Backend
```
src/backend/base/langflow/api/v1/
├── login.py                    # SSO endpoint added
└── custom.py                   # Alternative SSO location
```

### Frontend
```
src/frontend/src/
├── components/core/
│   ├── appHeaderComponent/index.tsx    # EnGarde logo
│   └── engardeFooter/index.tsx         # EnGarde footer
├── assets/
│   ├── EnGardeIcon.svg                 # Logo file
│   └── EGMBlackIcon.svg                # Footer icon
├── index.html                          # Page title changed
└── public/
    ├── manifest.json                   # EnGarde manifest
    └── favicon.ico                     # EnGarde favicon
```

### Custom Components
```
En Garde Components/
├── README.md
├── seo_walker_agent.py
├── paid_ads_walker_agent.py
├── content_walker_agent.py
├── audience_intelligence_walker_agent.py
├── campaign_creation_agent.py
├── campaign_launcher_agent.py
├── content_approval_agent.py
├── notification_agent.py
├── performance_monitoring_agent.py
├── analytics_report_agent.py
├── tenant_id_input.py
├── walker_suggestion_builder.py
└── walker_agent_api.py
```

---

## Environment Variables Required

### Essential
```bash
LANGFLOW_SECRET_KEY=shared-secret-with-engarde-backend
LANGFLOW_DATABASE_URL=postgresql://user:pass@host:port/db
LANGFLOW_AUTO_LOGIN=false
LANGFLOW_COMPONENTS_PATH=/app/components
LANGFLOW_HOST=0.0.0.0
```

### EnGarde Integration
```bash
ENGARDE_API_URL=https://api.engarde.media
WALKER_AGENT_API_KEY_ONSIDE_SEO=wa_xxx
WALKER_AGENT_API_KEY_ONSIDE_CONTENT=wa_xxx
WALKER_AGENT_API_KEY_SANKORE_PAID_ADS=wa_xxx
WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE=wa_xxx
```

---

## Deployment Commands

### Build Docker Image
```bash
docker build -f Dockerfile.engarde -t cope84/engarde-langflow:latest .
```

### Deploy to Railway
```bash
railway service create langflow-server
railway service set-source --repo EnGardeHQ/langflow-engarde
railway variables set LANGFLOW_SECRET_KEY="..."
railway variables set LANGFLOW_DATABASE_URL="${{Postgres.DATABASE_URL}}"
railway up
```

### Test SSO
```bash
curl -X POST https://api.engarde.media/api/v1/sso/langflow \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Integration Points

### EnGarde Backend → Langflow
1. **SSO Token Generation**
   - File: `production-backend/app/routers/langflow_sso.py`
   - Endpoint: `POST /api/v1/sso/langflow`
   - Returns: `{ sso_url: "..." }`

2. **JWT Token Structure**
   ```json
   {
     "email": "user@example.com",
     "tenant_id": "uuid",
     "tenant_name": "Company",
     "role": "admin",
     "subscription_tier": "business",
     "exp": 1704996000
   }
   ```

### Langflow → EnGarde Backend
1. **Walker Agent API Calls**
   - Components call EnGarde backend
   - Endpoint: `POST /api/v1/walker-agents/suggestions`
   - Auth: Bearer token from env variable

### EnGarde Frontend → Langflow
1. **Iframe Embedding**
   - File: `production-frontend/components/workflow/AuthenticatedLangflowIframe.tsx`
   - Page: `production-frontend/app/agent-suite/page.tsx`
   - Calls SSO endpoint, then embeds Langflow in iframe

---

## Testing Checklist

- [ ] Health check: `curl https://langflow.engarde.media/health_check`
- [ ] SSO login from EnGarde dashboard works
- [ ] EnGarde logo appears in header (not Langflow)
- [ ] EnGarde footer appears at bottom
- [ ] Page title is "EnGarde - AI Campaign Builder"
- [ ] Custom components appear in component palette
- [ ] Tenant ID Input component works
- [ ] Walker Agent API component can send suggestions
- [ ] Database user created after SSO login
- [ ] 30-day session token set in cookies

---

## Quick Rebuild Guide

If you need to rebuild from scratch:

1. Clone repo: `git clone https://github.com/EnGardeHQ/langflow-engarde.git`
2. Build: `docker build -f Dockerfile.engarde -t engarde-langflow .`
3. Push: `docker push cope84/engarde-langflow:latest`
4. Deploy: `railway service set-image cope84/engarde-langflow:latest`
5. Set env vars (see Environment Variables section)
6. Test SSO integration
7. Verify custom components loaded

---

## Common Issues

### SSO not working
- Check `LANGFLOW_SECRET_KEY` matches in both services
- Verify `LANGFLOW_AUTO_LOGIN=false`
- Test JWT token is valid and not expired

### Components not loading
- Check `LANGFLOW_COMPONENTS_PATH=/app/components`
- Verify components directory exists in container
- Restart service to reload components

### Branding not showing
- Hard refresh browser (Ctrl+Shift+R)
- Verify correct Docker image deployed
- Check frontend files in container

---

## Documentation Files

- **Complete Guide:** `ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md`
- **This Summary:** `CUSTOMIZATION_SUMMARY.md`
- **Component Docs:** `En Garde Components/README.md`
- **Deployment:** `DEPLOYMENT_SUMMARY.md`
- **EnGarde Readme:** `README_ENGARDE.md`

---

**Repository:** https://github.com/EnGardeHQ/langflow-engarde
**Based On:** Langflow v1.7.1
**Last Updated:** January 10, 2026
