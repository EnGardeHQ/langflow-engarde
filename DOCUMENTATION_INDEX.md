# EnGarde Langflow - Documentation Index

**Complete documentation suite for EnGarde's customized Langflow integration**

---

## Overview

This directory contains comprehensive documentation for rebuilding and deploying the EnGarde-customized Langflow platform from scratch. The documentation is organized into multiple files for easy navigation.

**Repository:** `https://github.com/EnGardeHQ/langflow-engarde`
**Based On:** Langflow v1.7.1 (Official)
**Last Updated:** January 10, 2026

---

## Documentation Files

### 1. Complete Implementation Guide
**File:** `ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md`

**Who Should Read:** Developers setting up Langflow from scratch, DevOps engineers

**Contents:**
- Overview of Langflow and EnGarde integration
- Complete list of all customizations
- SSO integration (step-by-step)
- Subscription tier synchronization
- Custom components documentation
- User synchronization between platforms
- Database configuration and schema
- Complete environment variables reference
- Dockerfile configuration (both versions)
- Railway deployment steps
- Local development setup
- Testing procedures

**Use This For:**
- Initial setup and installation
- Understanding the complete architecture
- Troubleshooting integration issues
- Reference for all configuration options

**Estimated Reading Time:** 45-60 minutes

---

### 2. Customization Summary
**File:** `CUSTOMIZATION_SUMMARY.md`

**Who Should Read:** Product managers, developers needing quick overview

**Contents:**
- High-level summary of what was customized
- Key files modified (backend and frontend)
- Environment variables quick reference
- Deployment commands
- Integration points overview
- Testing checklist
- Common issues

**Use This For:**
- Quick understanding of customizations
- Reference during code reviews
- Onboarding new team members
- Executive summaries

**Estimated Reading Time:** 10-15 minutes

---

### 3. Architecture Diagrams
**File:** `ARCHITECTURE_DIAGRAM.md`

**Who Should Read:** Technical architects, senior developers, DevOps

**Contents:**
- System overview diagram
- SSO authentication flow (sequence diagram)
- Walker Agent execution flow
- Component loading architecture
- Database schema (entity-relationship)
- Deployment architecture (Railway)
- Docker build process
- Frontend integration flow
- Security layers

**Use This For:**
- Understanding data flows
- System design discussions
- Security audits
- Performance optimization planning

**Estimated Reading Time:** 20-30 minutes

---

### 4. Quick Reference Card
**File:** `QUICK_REFERENCE.md`

**Who Should Read:** All developers (daily reference)

**Contents:**
- Key file locations
- Essential environment variables
- Common commands (Docker, Railway, Database)
- Quick troubleshooting guide
- SSO testing steps
- Component customization examples
- Deployment checklist

**Use This For:**
- Daily development tasks
- Quick command lookup
- Debugging common issues
- Deployment verification

**Estimated Reading Time:** 5 minutes

---

### 5. Custom Components Guide
**File:** `En Garde Components/README.md`

**Who Should Read:** Developers building agent flows, component authors

**Contents:**
- Component overview and purpose
- Deployment requirements
- Quick start guide
- Component reference (all 14 components)
- Example flows
- Customization instructions
- Troubleshooting

**Use This For:**
- Building Walker Agent flows
- Creating new custom components
- Understanding component API
- Flow assembly

**Estimated Reading Time:** 20-30 minutes

---

## Documentation by Use Case

### I'm Setting Up Langflow for the First Time

**Read in this order:**
1. `CUSTOMIZATION_SUMMARY.md` - Get the overview
2. `ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md` - Follow deployment steps
3. `QUICK_REFERENCE.md` - Use for commands during setup
4. `ARCHITECTURE_DIAGRAM.md` - Understand what you built

**Key Sections:**
- Deployment Steps
- Environment Variables
- Testing the Installation

---

### I Need to Understand How SSO Works

**Read in this order:**
1. `ARCHITECTURE_DIAGRAM.md` - See the SSO flow diagram
2. `ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md` → SSO Integration section
3. `QUICK_REFERENCE.md` → Test SSO section

**Key Files to Review:**
- `production-backend/app/routers/langflow_sso.py` (EnGarde backend)
- `src/backend/base/langflow/api/v1/login.py` (Langflow backend)
- `production-frontend/components/workflow/AuthenticatedLangflowIframe.tsx` (Frontend)

---

### I'm Building Custom Walker Agent Flows

**Read in this order:**
1. `En Garde Components/README.md` - Component reference
2. `QUICK_REFERENCE.md` → Test Component section
3. `ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md` → Custom Components section

**Key Sections:**
- Component Examples
- Flow Building
- API Integration

---

### I'm Debugging an Issue

**Start here:**
1. `QUICK_REFERENCE.md` → Common Issues section
2. `ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md` → Troubleshooting Guide

**Common Issue Guides:**
- SSO not working → Check shared secret, auto-login setting
- Components not loading → Verify COMPONENTS_PATH, restart service
- Database errors → Check DATABASE_URL, run migrations
- Branding not showing → Hard refresh, verify Docker image

---

### I'm Customizing the Branding

**Read in this order:**
1. `CUSTOMIZATION_SUMMARY.md` → Frontend Branding section
2. `ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md` → Frontend Customizations
3. `QUICK_REFERENCE.md` → Customization Points

**Key Files to Modify:**
- `src/frontend/src/components/core/appHeaderComponent/index.tsx`
- `src/frontend/src/components/core/engardeFooter/index.tsx`
- `src/frontend/src/assets/EnGardeIcon.svg`
- `src/frontend/public/favicon.ico`
- `src/frontend/index.html`

---

### I'm Adding a New Custom Component

**Read in this order:**
1. `En Garde Components/README.md` → Component Reference
2. `QUICK_REFERENCE.md` → Add Custom Component example
3. `ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md` → Custom Components section

**Steps:**
1. Create Python file in `En Garde Components/`
2. Implement Component class
3. Test locally
4. Rebuild Docker image
5. Deploy to Railway
6. Verify in UI

---

### I'm Updating to a New Langflow Version

**Read in this order:**
1. `ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md` → Support & Maintenance → Updating
2. `CUSTOMIZATION_SUMMARY.md` → Review all customizations
3. `ARCHITECTURE_DIAGRAM.md` → Understand what might break

**Critical Files to Preserve:**
- `src/backend/base/langflow/api/v1/login.py` (SSO endpoint)
- `src/frontend/src/components/core/appHeaderComponent/index.tsx` (Logo)
- `src/frontend/src/components/core/engardeFooter/index.tsx` (Footer)
- `En Garde Components/*.py` (All custom components)

---

## File Structure

```
langflow-engarde/
├── DOCUMENTATION_INDEX.md                           # This file
├── ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md       # Complete guide
├── CUSTOMIZATION_SUMMARY.md                         # Quick summary
├── ARCHITECTURE_DIAGRAM.md                          # Visual diagrams
├── QUICK_REFERENCE.md                               # One-page reference
├── En Garde Components/
│   ├── README.md                                    # Component guide
│   └── *.py                                         # Custom components
├── src/
│   ├── backend/
│   │   └── base/langflow/
│   │       ├── api/v1/login.py                      # SSO endpoint
│   │       └── ...
│   └── frontend/
│       └── src/
│           ├── components/core/
│           │   ├── appHeaderComponent/index.tsx     # Logo
│           │   └── engardeFooter/index.tsx          # Footer
│           └── ...
├── Dockerfile.engarde                               # Production build
├── Dockerfile.railway-final                         # Quick testing
├── .env.example                                     # Environment template
└── README_ENGARDE.md                                # Legacy readme
```

---

## Appendices

### A. External Integration Points

These files are in the **main EnGarde repositories** (not in langflow-engarde):

**EnGarde Backend:**
- `production-backend/app/routers/langflow_sso.py` - SSO token generation
- `production-backend/.env.langflow` - Environment variables reference

**EnGarde Frontend:**
- `production-frontend/components/workflow/AuthenticatedLangflowIframe.tsx` - Iframe component
- `production-frontend/app/agent-suite/page.tsx` - Agent Suite page
- `production-frontend/services/langflow.service.ts` - API client

---

### B. Key Concepts

**SSO (Single Sign-On):**
- Allows EnGarde users to access Langflow without separate login
- Uses JWT tokens signed with shared secret
- Token expires in 5 minutes for security
- Session token lasts 30 days after successful authentication

**Custom Components:**
- Python classes that extend Langflow's Component base class
- Discovered automatically on startup
- Appear in UI component palette
- Can call external APIs (e.g., EnGarde backend)

**Walker Agents:**
- AI agents that analyze campaigns and provide suggestions
- Types: SEO, Content, Paid Ads, Audience Intelligence
- Built as Langflow flows using custom components
- Send suggestions back to EnGarde backend

**Multi-tenant:**
- Each EnGarde tenant can have multiple users
- Tenant ID passed via SSO JWT token
- Currently not enforced at Langflow database level
- Future: Add row-level security for true isolation

---

### C. Versioning

| Component | Version | Notes |
|-----------|---------|-------|
| Langflow Base | 1.7.1 | Official upstream |
| EnGarde Fork | 1.0.0 | Current custom version |
| Python | 3.12 | Required |
| Node.js | 18+ | For frontend build |
| PostgreSQL | 14+ | Database |
| Docker | 20+ | Container runtime |

---

### D. Environment Checklist

When deploying to a new environment, ensure these are set:

**Critical (Will Fail Without These):**
- [ ] `LANGFLOW_SECRET_KEY` (must match EnGarde backend)
- [ ] `LANGFLOW_DATABASE_URL` (PostgreSQL connection)
- [ ] `LANGFLOW_AUTO_LOGIN=false` (required for SSO)

**Important (Affects Functionality):**
- [ ] `LANGFLOW_COMPONENTS_PATH=/app/components`
- [ ] `LANGFLOW_HOST=0.0.0.0`
- [ ] `ENGARDE_API_URL` (for Walker Agents)

**Walker Agent API Keys:**
- [ ] `WALKER_AGENT_API_KEY_ONSIDE_SEO`
- [ ] `WALKER_AGENT_API_KEY_ONSIDE_CONTENT`
- [ ] `WALKER_AGENT_API_KEY_SANKORE_PAID_ADS`
- [ ] `WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE`

**Optional (Can Configure Later):**
- [ ] `LANGFLOW_LOG_LEVEL` (default: info)
- [ ] `LANGFLOW_CACHE_TYPE` (default: memory)
- [ ] `LANGFLOW_WORKERS` (default: 1)

---

### E. Quick Links

**External Resources:**
- [Official Langflow Docs](https://docs.langflow.org)
- [Langflow GitHub](https://github.com/langflow-ai/langflow)
- [Railway Docs](https://docs.railway.app)
- [FastAPI Docs](https://fastapi.tiangolo.com)
- [React Documentation](https://react.dev)

**EnGarde Resources:**
- EnGarde Platform: https://app.engarde.media
- Langflow Instance: https://langflow.engarde.media
- EnGarde API: https://api.engarde.media

---

### F. Support

**For Questions About:**

- **Langflow customization:** Review this documentation first, then contact EnGarde dev team
- **Official Langflow features:** See [Langflow Documentation](https://docs.langflow.org)
- **Railway deployment:** See [Railway Documentation](https://docs.railway.app)
- **EnGarde integration:** Contact EnGarde development team

**Common Resources:**
- Langflow Discord: https://discord.gg/langflow
- Railway Community: https://railway.app/discord

---

## Document Updates

This documentation suite should be updated when:

- [ ] New custom components are added
- [ ] SSO implementation changes
- [ ] New environment variables are required
- [ ] Langflow base version is updated
- [ ] Deployment process changes
- [ ] New branding elements are added

**Update Process:**
1. Modify relevant documentation files
2. Update version number in each file
3. Update "Last Updated" date
4. Commit with descriptive message
5. Notify team of documentation changes

---

## Getting Started

**New to EnGarde Langflow?**
1. Start with `CUSTOMIZATION_SUMMARY.md` for a high-level overview
2. Review `ARCHITECTURE_DIAGRAM.md` to understand the system
3. Follow `ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md` for deployment
4. Bookmark `QUICK_REFERENCE.md` for daily use

**Ready to deploy?**
1. Open `ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md`
2. Go to "Deployment Steps" section
3. Follow instructions for Railway deployment
4. Use "Testing the Installation" section to verify

**Need help?**
1. Check `QUICK_REFERENCE.md` → Common Issues
2. Review `ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md` → Troubleshooting Guide
3. Contact EnGarde development team

---

**Created:** January 10, 2026
**Maintained By:** EnGarde Development Team
**Repository:** https://github.com/EnGardeHQ/langflow-engarde

---

**End of Documentation Index**
