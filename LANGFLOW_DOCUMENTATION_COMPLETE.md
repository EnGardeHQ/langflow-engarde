# Langflow Documentation - Complete ✅

**Date:** January 10, 2026
**Status:** Documentation Complete and Ready for Use

---

## Summary

Comprehensive documentation has been created for the EnGarde-customized Langflow installation. This documentation enables any coding assistant or developer to recreate the entire Langflow setup from an official Langflow repository.

---

## Documentation Files Created

All files are located in `/Users/cope/EnGardeHQ/langflow-engarde/`:

### 1. ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md (55.8 KB)
**Purpose:** Main comprehensive guide for complete setup and deployment

**Contents:**
- Overview of Langflow and EnGarde integration
- Complete customization inventory
- SSO integration implementation (step-by-step)
- Subscription tier synchronization via JWT
- All 14 custom Walker Agent components documented
- User/admin synchronization between platforms
- Database configuration and schema
- Complete environment variables reference (30+ variables)
- Dockerfile configuration explanations (Dockerfile.engarde vs Dockerfile.railway-final)
- Railway deployment methods (GitHub, Docker Hub, Template)
- Local development setup instructions
- Comprehensive testing procedures
- Troubleshooting guide
- Security considerations
- Maintenance and update procedures

**Target Audience:** Developers, DevOps engineers, technical architects

---

### 2. CUSTOMIZATION_SUMMARY.md (6.7 KB)
**Purpose:** Quick overview for understanding what was customized

**Contents:**
- High-level summary of customizations
- Key files modified (backend and frontend)
- Environment variables quick reference
- Deployment commands
- Integration points with EnGarde backend/frontend
- Testing checklist
- Common issues and resolutions

**Target Audience:** Product managers, new developers, code reviewers

---

### 3. ARCHITECTURE_DIAGRAM.md (40.6 KB)
**Purpose:** Visual documentation of system architecture and data flows

**Contents:**
- System overview diagram (EnGarde → Langflow integration)
- SSO authentication flow (sequence diagram)
- Walker Agent execution flow
- Component loading architecture
- Database schema (entity-relationship)
- Deployment architecture (Railway infrastructure)
- Docker build process (multi-stage builds)
- Frontend integration flow (iframe embedding)
- Security layers (headers, CORS, authentication)

**Target Audience:** Technical architects, senior developers, security engineers

---

### 4. QUICK_REFERENCE.md (8.2 KB)
**Purpose:** One-page reference card for daily development tasks

**Contents:**
- Key file locations (quick lookup)
- Essential environment variables
- Common commands (Docker, Railway, Database, Langflow CLI)
- Quick troubleshooting guide
- SSO testing steps
- Component customization examples
- Deployment checklist

**Target Audience:** All developers (daily reference)

---

### 5. DOCUMENTATION_INDEX.md (13.1 KB)
**Purpose:** Navigation guide for all documentation with use-case-based paths

**Contents:**
- Documentation file descriptions
- Use-case-based reading paths:
  - Setting up for the first time
  - Understanding SSO
  - Building Walker Agent flows
  - Debugging issues
  - Customizing branding
  - Adding new components
  - Updating Langflow version
- File structure reference
- External integration points
- Key concepts glossary
- Environment checklist
- Quick links to resources

**Target Audience:** All users (starting point for documentation)

---

## Key Customizations Documented

### Backend Customizations

1. **SSO Endpoint** (`src/backend/base/langflow/api/v1/login.py`)
   - Custom `/api/v1/custom/sso_login` endpoint
   - JWT validation with shared secret
   - User creation/update logic
   - Cookie-based session management
   - Subscription tier synchronization

2. **Custom Components** (`En Garde Components/`)
   - 14 Walker Agent components:
     - `SEOWalkerAgent.py` - SEO analysis and recommendations
     - `ContentWalkerAgent.py` - Content strategy suggestions
     - `PaidAdsWalkerAgent.py` - Ad campaign optimization
     - `AudienceIntelligenceWalkerAgent.py` - Audience analysis
     - `EngardeAPIFetcher.py` - Campaign data retrieval
     - `ExtractCampaignID.py` - Campaign ID parsing
     - `ExtractRecommendations.py` - AI output parsing
     - `DataAggregator.py` - Multi-source data combination
     - `SelectBestWalkerAgent.py` - Agent selection logic
     - `APIEndpointSelector.py` - Dynamic endpoint selection
     - `ConditionalRouter.py` - Flow routing based on conditions
     - `DataTransformer.py` - Data format transformation
     - `WalkerAgentOrchestrator.py` - Multi-agent coordination
     - `EnGardeOpenAIModel.py` - Custom AI model wrapper

3. **Configuration** (`.env.example`)
   - 30+ environment variables documented
   - API keys for Walker Agents
   - Database configuration
   - SSO secret key
   - Component paths

### Frontend Customizations

1. **Branding** (Logo, Footer, Page Title)
   - `src/frontend/src/components/core/appHeaderComponent/index.tsx` - EnGarde logo
   - `src/frontend/src/components/core/engardeFooter/index.tsx` - Custom footer
   - `src/frontend/src/assets/EnGardeIcon.svg` - Icon asset
   - `src/frontend/public/favicon.ico` - Browser favicon
   - `src/frontend/index.html` - Page title

2. **Auto-Login Disabled**
   - `LANGFLOW_AUTO_LOGIN=false` required for SSO
   - Forces JWT-based authentication

### Deployment Customizations

1. **Dockerfile.engarde** (Production)
   - Multi-stage build (builder → frontend → runtime)
   - Custom component installation
   - Branding assets included
   - Gunicorn configuration

2. **Dockerfile.railway-final** (Quick Testing)
   - Single-stage build
   - Faster iteration for testing
   - Same functionality as production build

---

## Integration Points with EnGarde Platform

### EnGarde Backend Files

**`production-backend/app/routers/langflow_sso.py`**
- Generates SSO JWT tokens
- Includes user email, tenant_id, subscription_tier
- 5-minute token expiration

**Key Endpoint:** `POST /api/v1/sso/langflow`

### EnGarde Frontend Files

**`production-frontend/components/workflow/AuthenticatedLangflowIframe.tsx`**
- Fetches SSO token from backend
- Creates iframe with SSO URL
- Handles authentication errors

**`production-frontend/app/agent-suite/page.tsx`**
- Hosts the Langflow iframe
- SSO authentication flow triggered on page load

**Key Endpoint Called:** `/api/v1/sso/langflow`

---

## SSO Authentication Flow

```
1. User visits /agent-suite in EnGarde frontend
2. Frontend calls POST /api/v1/sso/langflow
3. EnGarde backend generates JWT token with:
   - email: user@example.com
   - tenant_id: tenant_uuid
   - subscription_tier: professional
   - exp: 5 minutes
4. Frontend receives token and creates iframe:
   http://localhost:7860/api/v1/custom/sso_login?token=<JWT>
5. Langflow validates JWT signature
6. Langflow creates/updates user in database
7. Langflow sets auth cookies (access + refresh)
8. User sees authenticated Langflow UI
```

---

## Walker Agent Flow Architecture

```
EnGarde Campaign Page
    ↓
User clicks "Analyze Campaign"
    ↓
Frontend calls EnGarde Backend API
    ↓
Backend triggers Langflow flow via webhook
    ↓
Langflow Flow Execution:
    1. EngardeAPIFetcher → Fetch campaign data
    2. SelectBestWalkerAgent → Choose agent (SEO/Content/Ads/Audience)
    3. Walker Agent Component → Analyze campaign with AI
    4. ExtractRecommendations → Parse AI output
    5. Walker Agent Component → POST suggestions to EnGarde API
    ↓
Suggestions appear in EnGarde campaign page
```

---

## Environment Variables Reference

### Critical Variables (Required)

```bash
LANGFLOW_SECRET_KEY=<shared-secret-with-engarde-backend>
LANGFLOW_DATABASE_URL=postgresql://user:pass@host:port/db
LANGFLOW_AUTO_LOGIN=false
LANGFLOW_COMPONENTS_PATH=/app/components
LANGFLOW_HOST=0.0.0.0
ENGARDE_API_URL=https://api.engarde.media
```

### Walker Agent API Keys

```bash
WALKER_AGENT_API_KEY_ONSIDE_SEO=<api-key>
WALKER_AGENT_API_KEY_ONSIDE_CONTENT=<api-key>
WALKER_AGENT_API_KEY_SANKORE_PAID_ADS=<api-key>
WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE=<api-key>
```

### Optional Variables

```bash
LANGFLOW_LOG_LEVEL=info
LANGFLOW_CACHE_TYPE=memory
LANGFLOW_WORKERS=1
```

---

## Deployment Methods

### Method 1: GitHub Integration (Recommended)
1. Push code to GitHub repository
2. Connect Railway to GitHub repo
3. Railway automatically builds and deploys
4. Uses `Dockerfile.engarde` for production build

### Method 2: Docker Hub
1. Build image locally: `docker buildx build -t engarde/langflow:latest -f Dockerfile.engarde .`
2. Push to Docker Hub: `docker push engarde/langflow:latest`
3. Deploy to Railway using Docker Hub image

### Method 3: Railway Template
1. Create Railway template from project
2. Share template link
3. One-click deployment for new environments

---

## Testing Checklist

### SSO Authentication
- [ ] Navigate to `http://localhost:3003/agent-suite`
- [ ] Langflow iframe loads without errors
- [ ] User is automatically authenticated
- [ ] User email matches EnGarde user
- [ ] Workflows are accessible

### Custom Components
- [ ] All 14 components appear in component palette
- [ ] Components can be dragged to canvas
- [ ] Components have correct input/output ports
- [ ] Test Walker Agent flow execution

### Walker Agent Flows
- [ ] Create test campaign in EnGarde
- [ ] Trigger Walker Agent analysis
- [ ] Verify flow executes successfully
- [ ] Confirm suggestions appear in EnGarde

### Branding
- [ ] EnGarde logo displays in header
- [ ] EnGarde footer displays at bottom
- [ ] Favicon shows EnGarde icon
- [ ] Page title reads "EnGarde Agent Suite"

---

## Local Development Setup

```bash
# 1. Clone repository
git clone https://github.com/EnGardeHQ/langflow-engarde.git
cd langflow-engarde

# 2. Copy environment variables
cp .env.example .env

# 3. Install dependencies (using uv)
uv sync

# 4. Run database migrations
uv run langflow migration --fix

# 5. Start Langflow
uv run langflow run \
  --host 0.0.0.0 \
  --port 7860 \
  --env-file .env \
  --components-path "En Garde Components"

# 6. Access Langflow
# Visit http://localhost:7860
```

---

## Railway Deployment

```bash
# 1. Install Railway CLI
npm i -g @railway/cli

# 2. Login to Railway
railway login

# 3. Link to project
railway link

# 4. Set environment variables
railway variables set LANGFLOW_SECRET_KEY="<secret>"
railway variables set LANGFLOW_DATABASE_URL="<postgres-url>"
railway variables set LANGFLOW_AUTO_LOGIN="false"
# ... set all required variables

# 5. Deploy
railway up

# 6. View logs
railway logs
```

---

## Common Issues and Solutions

### Issue 1: SSO Not Working
**Symptom:** "Invalid or expired token" error

**Solutions:**
1. Verify `LANGFLOW_SECRET_KEY` matches EnGarde backend
2. Check token expiration (5 minutes max)
3. Ensure `LANGFLOW_AUTO_LOGIN=false`
4. Verify JWT signature algorithm (HS256)

### Issue 2: Components Not Loading
**Symptom:** Walker Agent components missing from palette

**Solutions:**
1. Verify `LANGFLOW_COMPONENTS_PATH=/app/components`
2. Check component files exist in `En Garde Components/`
3. Restart Langflow service
4. Check logs for import errors

### Issue 3: Database Connection Failed
**Symptom:** "Could not connect to database" error

**Solutions:**
1. Verify `LANGFLOW_DATABASE_URL` is correct
2. Check database is accessible from Langflow container
3. Run migrations: `langflow migration --fix`
4. Verify PostgreSQL version (14+ required)

### Issue 4: Branding Not Showing
**Symptom:** Default Langflow logo instead of EnGarde logo

**Solutions:**
1. Hard refresh browser (Ctrl+Shift+R)
2. Verify Docker image includes branding files
3. Check frontend build logs for asset errors
4. Rebuild Docker image with `--no-cache`

---

## File Structure

```
langflow-engarde/
├── ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md    # Main guide (55.8 KB)
├── CUSTOMIZATION_SUMMARY.md                       # Quick summary (6.7 KB)
├── ARCHITECTURE_DIAGRAM.md                        # Visual docs (40.6 KB)
├── QUICK_REFERENCE.md                             # One-page reference (8.2 KB)
├── DOCUMENTATION_INDEX.md                         # Navigation guide (13.1 KB)
├── En Garde Components/                           # Custom components
│   ├── SEOWalkerAgent.py
│   ├── ContentWalkerAgent.py
│   ├── PaidAdsWalkerAgent.py
│   ├── AudienceIntelligenceWalkerAgent.py
│   ├── EngardeAPIFetcher.py
│   ├── ExtractCampaignID.py
│   ├── ExtractRecommendations.py
│   ├── DataAggregator.py
│   ├── SelectBestWalkerAgent.py
│   ├── APIEndpointSelector.py
│   ├── ConditionalRouter.py
│   ├── DataTransformer.py
│   ├── WalkerAgentOrchestrator.py
│   └── EnGardeOpenAIModel.py
├── src/
│   ├── backend/base/langflow/api/v1/login.py      # SSO endpoint
│   └── frontend/src/components/core/
│       ├── appHeaderComponent/index.tsx           # Logo
│       └── engardeFooter/index.tsx                # Footer
├── Dockerfile.engarde                             # Production build
├── Dockerfile.railway-final                       # Quick testing
└── .env.example                                   # Environment template
```

---

## Next Steps

### For Developers
1. **Read the documentation:**
   - Start with `DOCUMENTATION_INDEX.md`
   - Follow use-case-based reading paths
   - Bookmark `QUICK_REFERENCE.md` for daily use

2. **Set up local environment:**
   - Follow "Local Development Setup" in main docs
   - Test SSO authentication
   - Verify custom components load

3. **Build and deploy:**
   - Test with `Dockerfile.railway-final` first
   - Deploy to Railway using GitHub integration
   - Verify all functionality in production

### For Product/Project Managers
1. **Understand the architecture:**
   - Review `CUSTOMIZATION_SUMMARY.md`
   - See `ARCHITECTURE_DIAGRAM.md` for visual overview

2. **Plan updates:**
   - Review "Updating Langflow" section
   - Understand customization preservation requirements

### For DevOps Engineers
1. **Deploy to production:**
   - Follow Railway deployment steps
   - Set all environment variables
   - Configure database and secrets

2. **Monitor and maintain:**
   - Set up logging and monitoring
   - Review troubleshooting guide
   - Implement backup procedures

---

## Documentation Maintenance

### When to Update
- New custom components added
- SSO implementation changes
- Environment variables added/changed
- Langflow base version updated
- Deployment process modified
- Branding elements changed

### How to Update
1. Modify relevant documentation files
2. Update version number in each file
3. Update "Last Updated" date
4. Commit with descriptive message
5. Notify team of changes

---

## Success Criteria ✅

All documentation requirements have been met:

- ✅ **Comprehensive Guide:** 55.8 KB main documentation covering all aspects
- ✅ **SSO Integration:** Complete JWT-based authentication flow documented
- ✅ **Subscription Tier Sync:** JWT payload structure and synchronization explained
- ✅ **Custom Components:** All 14 Walker Agent components documented with examples
- ✅ **Admin/User Sync:** User creation/update logic documented
- ✅ **Step-by-Step Instructions:** Deployment procedures for local and Railway
- ✅ **File References:** All key files identified with line numbers where applicable
- ✅ **Environment Variables:** Complete reference of 30+ variables
- ✅ **Dockerfiles:** Both Dockerfile.engarde and Dockerfile.railway-final explained
- ✅ **GitHub to Railway:** Deployment workflow documented
- ✅ **Navigation:** Use-case-based documentation index created
- ✅ **Quick Reference:** One-page reference card for daily tasks
- ✅ **Visual Documentation:** Architecture diagrams and flow charts

---

## Repository Information

**GitHub Repository:** https://github.com/EnGardeHQ/langflow-engarde
**Based On:** Langflow v1.7.1 (Official)
**Python Version:** 3.12
**Node.js Version:** 18+
**Database:** PostgreSQL 14+

---

## Contact and Support

**For questions about:**
- **Langflow customization:** Review documentation, then contact EnGarde dev team
- **Official Langflow features:** See https://docs.langflow.org
- **Railway deployment:** See https://docs.railway.app
- **EnGarde integration:** Contact EnGarde development team

**External Resources:**
- Langflow Documentation: https://docs.langflow.org
- Langflow GitHub: https://github.com/langflow-ai/langflow
- Railway Documentation: https://docs.railway.app
- Langflow Discord: https://discord.gg/langflow

---

**Documentation Status:** Complete ✅
**Last Updated:** January 10, 2026
**Total Documentation Size:** 124.4 KB (5 files)
**Maintained By:** EnGarde Development Team

---

**End of Summary**
