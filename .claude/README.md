# Claude Agent Swarm Configuration

This directory contains the definitive rules and guidelines for all Claude agents working on the EnGarde application.

## Purpose

These documents ensure that:
- All agents follow consistent deployment procedures
- Code changes are properly verified before completion
- Docker operations follow modern best practices
- Local development environment stays healthy
- Changes are automatically reflected without manual intervention

## Core Documents

### 0. ENGARDE_DEVELOPMENT_RULES.md (MANDATORY - FOUNDATION)
**Status:** 🔴 MANDATORY - MUST READ BEFORE ANY ENGARDE WORK

**Location:** `/Users/cope/EnGardeHQ/ENGARDE_DEVELOPMENT_RULES.md`

**Purpose:** Complete development standards for the entire EnGarde platform (frontend + backend)

**When to Use:** ALWAYS - Before starting ANY work on EnGarde application code

**Key Sections:**
- Part 1: Frontend Development (UI abstractions, colors, spacing, data retrieval)
- Part 2: Backend Development (RESTful API, database models, service layer, auth)
- Part 3: Third-Party Integrations (AI, social media, e-commerce)
- Part 4: Security & Compliance (SOC II, PII protection)
- Part 5: TDD/BDD & Testing (Red-Green-Refactor, Given/When/Then)
- Part 6: Git & PR Workflow
- Part 7: Enforcement & Verification
- Part 8: Quick Reference (anti-patterns)

**File Size:** 1,054 lines | 24KB

**Last Updated:** January 26, 2026

**CRITICAL:** This document supersedes conflicting rules in other files and is the single source of truth for EnGarde application development.

---

### 1. AGENT_DEPLOYMENT_RULES.md (MANDATORY - DEPLOYMENT)
**Status:** 🔴 MANDATORY - ALL AGENTS MUST FOLLOW

**Purpose:** Comprehensive rulebook for all Docker deployments and code changes

**When to Use:** Before starting ANY deployment or code change task

**Key Sections:**
- Critical Rules (Never violate these)
- 5-Phase Deployment Protocol
- Docker Update Rules by Change Type
- Verification & Testing Requirements
- Error Handling & Recovery Procedures
- Communication Standards

**File Size:** 1,995 lines | 53KB

**Last Updated:** October 29, 2025

### 2. AGENT_CHECKLIST.md (QUICK REFERENCE)
**Status:** ⚡ RECOMMENDED - Use as quick reference

**Purpose:** Scannable checklist for quick verification during tasks

**When to Use:** During active deployment work as a quick reference

**Key Sections:**
- Pre-Task Checklist
- Execution Checklists (code, Docker, dependencies, schema)
- Verification Checklist (MANDATORY before marking complete)
- Common Scenarios Quick Reference
- Emergency Procedures

**File Size:** 308 lines | 8.1KB

**Last Updated:** October 29, 2025

---

## How to Use These Documents

### Rules Hierarchy

```
┌─────────────────────────────────────────────────────┐
│ ENGARDE_DEVELOPMENT_RULES.md (FOUNDATION)           │
│ - Frontend: UI abstractions, colors, data retrieval │
│ - Backend: API design, models, auth, security       │
│ - Testing: TDD/BDD standards                        │
│ - ALL application code must follow these rules      │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│ AGENT_DEPLOYMENT_RULES.md (DEPLOYMENT)              │
│ - Docker operations and hot-reload                  │
│ - Service orchestration                             │
│ - Deployment verification                           │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│ AGENT_CHECKLIST.md (QUICK REFERENCE)                │
│ - Task execution checklist                          │
│ - Quick command reference                           │
└─────────────────────────────────────────────────────┘
```

**Priority Order:**
1. **ENGARDE_DEVELOPMENT_RULES.md** - Code quality, architecture, security
2. **AGENT_DEPLOYMENT_RULES.md** - Deployment and Docker operations
3. **AGENT_CHECKLIST.md** - Quick verification during execution

**When Rules Conflict:** ENGARDE_DEVELOPMENT_RULES.md always wins for application code.

---

### For General-Purpose Agents

**Before Starting Any EnGarde Task:**
1. **ALWAYS read ENGARDE_DEVELOPMENT_RULES.md relevant section first**
   - Frontend work? → Read Part 1 (Frontend Rules)
   - Backend work? → Read Part 2 (Backend Rules)
   - Third-party integration? → Read Part 3
   - Database/security? → Read Part 4
2. Read the user's request completely
3. Classify the change type using AGENT_DEPLOYMENT_RULES.md Section 2.1
4. Follow the appropriate workflow from AGENT_DEPLOYMENT_RULES.md Section 3

**During Task Execution:**
1. Follow coding standards from ENGARDE_DEVELOPMENT_RULES.md
2. Keep AGENT_CHECKLIST.md open for quick reference
3. Check off items as you complete them
4. Monitor logs continuously
5. Document what you're doing

**Before Marking Complete:**
1. Verify compliance with ENGARDE_DEVELOPMENT_RULES.md
2. Go through the MANDATORY verification checklist (AGENT_CHECKLIST.md Section 3)
3. Ensure ALL items pass
4. Document results to user

### For DevOps-Orchestrator Agent

**Primary Reference:** AGENT_DEPLOYMENT_RULES.md

**Focus Areas:**
- Section 2: Agent Swarm Deployment Protocol
- Section 3: Docker Update Rules by Change Type
- Section 7: Error Handling & Recovery

**Special Responsibilities:**
- Ensure hot-reload is working
- Verify watch mode is active
- Monitor Docker container health
- Handle rebuilds and recreations

### For Backend-API-Architect Agent

**PRIMARY REFERENCE:** ENGARDE_DEVELOPMENT_RULES.md Part 2 (Backend Development)

**MANDATORY READING BEFORE ANY BACKEND WORK:**
- RESTful API Standards (naming, methods, responses)
- Database Models (SQLAlchemy patterns)
- Service Layer Pattern (business logic separation)
- Authentication & Authorization (JWT, role checks)
- Error Handling Standards
- Database Migrations (Alembic/direct SQL)
- TDD/BDD Testing Patterns

**Secondary Reference:** AGENT_DEPLOYMENT_RULES.md Section 4 (Backend Changes)

**Focus Areas:**
- Python code change workflow (hot-reload)
- Dependency management (requirements.txt)
- Database migrations (Alembic)
- API endpoint testing

**Special Responsibilities:**
- Follow RESTful API conventions from ENGARDE_DEVELOPMENT_RULES.md
- Use service layer pattern (never put business logic in routes)
- Verify Uvicorn reload after Python changes
- Test API endpoints with curl
- Apply database migrations safely
- Write TDD tests (Red → Green → Refactor)
- Ensure no errors in backend logs

### For Frontend-UI-Builder Agent

**PRIMARY REFERENCE:** ENGARDE_DEVELOPMENT_RULES.md Part 1 (Frontend Development)

**MANDATORY READING BEFORE ANY FRONTEND WORK:**
- UI Component Abstractions (NO direct Chakra imports!)
- Color System (semantic tokens ONLY, NO hex colors)
- Spacing System (tokens ONLY, NO pixel values)
- Typography System (Heading, Text components)
- Responsive Design (mobile-first breakpoints)
- Data Retrieval Patterns (useAuth, useCurrentBrand)
- Dark Mode Support (useColorModeValue)

**CRITICAL RULES:**
- ❌ NEVER import from `@chakra-ui/react` directly
- ✅ ALWAYS use abstractions from `@/components/ui/*`
- ❌ NEVER use hardcoded colors like `#3182CE`
- ✅ ALWAYS use semantic tokens like `color="blue.500"`
- ❌ NEVER use pixel values like `padding="16px"`
- ✅ ALWAYS use spacing tokens like `p={4}`

**Secondary Reference:** AGENT_DEPLOYMENT_RULES.md Section 4 (Frontend Changes)

**Focus Areas:**
- React/TypeScript code changes (Fast Refresh)
- Next.js build verification
- npm dependency management
- Browser cache handling

**Special Responsibilities:**
- Follow UI abstraction patterns from ENGARDE_DEVELOPMENT_RULES.md
- Use semantic color tokens and spacing scale
- Verify Fast Refresh working
- Check browser console for errors
- Test UI changes visually
- Ensure responsive design works on mobile/tablet/desktop
- Handle Next.js compilation errors

---

## Decision Trees

### "What Action Should I Take?"

```
┌─────────────────────────────────────┐
│ What type of file am I changing?   │
└─────────────────────────────────────┘
              │
    ┌─────────┼─────────┬─────────┐
    │         │         │         │
    ▼         ▼         ▼         ▼
┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐
│.py  │  │.tsx │  │.txt │  │.yml │
│.ts  │  │.jsx │  │.json│  │.env │
└─────┘  └─────┘  └─────┘  └─────┘
    │         │         │         │
    ▼         ▼         ▼         ▼
┌─────────┐┌─────────┐┌─────────┐┌─────────┐
│NO ACTION││NO ACTION││ REBUILD ││ RESTART │
│REQUIRED ││REQUIRED ││ NEEDED  ││ NEEDED  │
└─────────┘└─────────┘└─────────┘└─────────┘
Hot-reload  Hot-reload  5-10 min   < 30 sec
```

**Quick Lookup:**
- `.py`, `.tsx`, `.ts`, `.jsx`, `.css` → NO ACTION (hot-reload)
- `requirements.txt`, `package.json` → REBUILD
- `Dockerfile`, `docker-compose.yml` → REBUILD + RECREATE
- `.env` files → RESTART
- Alembic migrations → RUN MIGRATION

### "Is My Task Complete?"

```
┌────────────────────────────────┐
│ Can I mark this task complete? │
└────────────────────────────────┘
              │
              ▼
    ┌─────────────────────┐
    │ Are services healthy? │
    └─────────────────────┘
         ▼           ▼
        YES          NO → FIX FIRST
         │
         ▼
    ┌──────────────────────┐
    │ Hot-reload confirmed? │
    └──────────────────────┘
         ▼           ▼
        YES          N/A
         │            │
         └────┬───────┘
              ▼
    ┌────────────────────┐
    │ No errors in logs? │
    └────────────────────┘
         ▼           ▼
        YES          NO → FIX FIRST
         │
         ▼
    ┌────────────────────────┐
    │ Endpoint tested & works? │
    └────────────────────────┘
         ▼           ▼
        YES          NO → FIX FIRST
         │
         ▼
    ┌───────────────────┐
    │ User informed?    │
    └───────────────────┘
         ▼           ▼
        YES          NO → DOCUMENT NOW
         │
         ▼
    ┌────────────────────┐
    │ ✅ MARK COMPLETE   │
    └────────────────────┘
```

---

## Golden Rules (Never Violate)

1. **ALWAYS verify changes appear locally** before marking complete
2. **NEVER assume hot-reload worked** - always check logs
3. **NEVER use relative paths** - use `/Users/cope/EnGardeHQ/...`
4. **ALWAYS check service health** after deployment
5. **NEVER mark complete if errors exist** in logs
6. **ALWAYS ask confirmation** before destructive operations
7. **NEVER skip verification steps** - they prevent failures
8. **ALWAYS document what you changed** to the user

---

## Common Scenarios

### Scenario 1: "Add a new Python function"
1. **Change Type:** Code change (Python)
2. **Action Required:** None - hot-reload handles it
3. **Workflow:**
   - Edit the `.py` file
   - Wait 2-3 seconds
   - Check logs: `./scripts/dev-logs.sh -n 20 backend`
   - Look for: "Reloading..." message
   - Test endpoint: `curl http://localhost:8000/api/...`
4. **Verification:** Health check + endpoint test
5. **Time:** < 5 seconds

### Scenario 2: "Add requests library to backend"
1. **Change Type:** Dependency change
2. **Action Required:** Rebuild backend container
3. **Workflow:**
   - Update `requirements.txt`
   - Run: `./scripts/dev-rebuild.sh`
   - Wait 5-10 minutes
   - Verify: `docker compose exec backend pip list | grep requests`
4. **Verification:** Health check + import test
5. **Time:** 5-10 minutes

### Scenario 3: "Update environment variable"
1. **Change Type:** Configuration change
2. **Action Required:** Restart services
3. **Workflow:**
   - Update `.env` file
   - Run: `docker compose -f docker-compose.dev.yml restart backend`
   - Wait 30 seconds
   - Verify: `docker compose exec backend env | grep VAR_NAME`
4. **Verification:** Health check + functionality test
5. **Time:** < 1 minute

### Scenario 4: "Change database schema"
1. **Change Type:** Schema change
2. **Action Required:** Run migration or reset
3. **Workflow:**
   - **Option A:** Create and apply migration (preserves data)
   - **Option B:** Reset database (deletes data - ASK USER)
   - Follow AGENT_DEPLOYMENT_RULES.md Section 3.4
4. **Verification:** Health check + database query
5. **Time:** 1-3 minutes

---

## Emergency Procedures

### Services Won't Start
```bash
# 1. Check logs
./scripts/dev-logs.sh

# 2. Check health
./scripts/dev-health.sh

# 3. Try restart
docker compose -f docker-compose.dev.yml restart

# 4. Try rebuild
./scripts/dev-rebuild.sh

# 5. Nuclear option (ASK USER FIRST)
./scripts/dev-reset.sh
```

### Changes Not Appearing
```bash
# 1. Verify file saved
cat /Users/cope/EnGardeHQ/production-backend/app/file.py

# 2. Check volume mounts
docker inspect engarde_backend_dev | grep Mounts

# 3. Check watch mode active
docker compose -f docker-compose.dev.yml logs -f backend

# 4. Restart if needed
docker compose -f docker-compose.dev.yml restart backend
```

### Environment Completely Broken
```bash
# ASK USER FOR CONFIRMATION FIRST!
./scripts/dev-reset.sh --yes
./scripts/dev-start.sh
```

---

## Quick Command Reference

### Essential Commands
```bash
# Start development
./scripts/dev-start.sh

# Check health
./scripts/dev-health.sh

# View logs
./scripts/dev-logs.sh backend

# Rebuild
./scripts/dev-rebuild.sh

# Stop (preserves data)
./scripts/dev-stop.sh

# Reset (deletes data - ask user!)
./scripts/dev-reset.sh
```

### Service URLs
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- PostgreSQL: localhost:5432
- Redis: localhost:6379

---

## Integration with Existing Documentation

These agent rules complement the existing documentation:

### Architecture & Design
- **DOCKER_DEVELOPMENT_ARCHITECTURE.md** - Why these rules exist
- **DOCKER_ARCHITECTURE_DIAGRAMS.md** - Visual reference
- **DOCKER_BEST_PRACTICES.md** - Long-term guidelines

### Quick Start & Reference
- **DEV_QUICK_START.md** - Human-readable quick start
- **QUICK_START_DOCKER.md** - Developer onboarding
- **DEV_QUICK_REFERENCE.md** - Command cheat sheet

### Scripts & Tools
- **scripts/DEV_SCRIPTS_README.md** - Script documentation
- **scripts/dev-*.sh** - Automated tools

**Relationship:**
```
Human Documentation → Agent Rules → Automated Scripts
     (Why)          →   (How)    →    (Execute)
```

---

## Maintenance

### Updating These Rules

**When to Update:**
- New Docker Compose features added
- New services added to the stack
- Development workflow changes
- Common errors discovered
- User feedback on agent behavior

**How to Update:**
1. Edit the relevant document
2. Update version number and date
3. Test with agent to verify rules work
4. Document changes in this README

**Version Control:**
- All documents are version controlled with git
- Major changes should be communicated to all agents
- Keep version numbers in sync across documents

---

## Support & Feedback

### If Agent Rules Fail
1. Check if agent followed the rules correctly
2. Check if rules are clear enough
3. Update rules if needed
4. Report to user what happened

### If Deployment Fails
1. Follow rollback procedures (AGENT_DEPLOYMENT_RULES.md Section 7)
2. Report detailed error to user
3. Document what went wrong
4. Suggest rule updates if needed

---

## File Structure

```
/Users/cope/EnGardeHQ/.claude/
├── README.md                    # This file - Overview and guide
├── AGENT_DEPLOYMENT_RULES.md    # MANDATORY - Complete rulebook
├── AGENT_CHECKLIST.md           # Quick reference checklist
└── settings.local.json          # Claude Code settings
```

---

## Success Metrics

An agent deployment is successful when:
- ✅ All verification steps pass
- ✅ Changes are visible and working
- ✅ No errors in service logs
- ✅ Hot-reload functioning (if applicable)
- ✅ User can test the changes
- ✅ Documentation provided to user
- ✅ System remains stable

---

## Final Note

**These rules exist to ensure quality and consistency.**

Following these rules means:
- Fewer deployment failures
- Faster iteration cycles
- More confident code changes
- Better user experience
- Less time debugging

**When in doubt:**
1. Check the rules
2. Check the logs
3. Run health checks
4. Ask the user

**Remember:** It's better to ask for clarification than to deploy broken code.

---

**Last Updated:** October 29, 2025
**Maintained By:** Claude Agent Swarm
**Status:** Active and Mandatory
