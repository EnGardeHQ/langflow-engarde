# Langflow EnGarde - Quick Reference Card

**One-page reference for common tasks**

---

## Repository

```bash
git clone https://github.com/EnGardeHQ/langflow-engarde.git
```

**Based on:** Langflow v1.7.1

---

## Key Files

| What | Where |
|------|-------|
| SSO Endpoint | `src/backend/base/langflow/api/v1/login.py` |
| Header (logo) | `src/frontend/src/components/core/appHeaderComponent/index.tsx` |
| Footer | `src/frontend/src/components/core/engardeFooter/index.tsx` |
| Custom Components | `En Garde Components/*.py` |
| Production Dockerfile | `Dockerfile.engarde` |
| Environment Vars | `.env.example` |

---

## Environment Variables

### Required
```bash
LANGFLOW_SECRET_KEY=min-32-chars-shared-with-engarde
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

## Build & Deploy

### Build Docker Image
```bash
docker build -f Dockerfile.engarde -t cope84/engarde-langflow:latest .
docker push cope84/engarde-langflow:latest
```

### Deploy to Railway
```bash
# Create service
railway service create langflow-server

# Set source
railway service set-source --repo EnGardeHQ/langflow-engarde --branch main

# Configure build
railway service set-dockerfile Dockerfile.engarde

# Set environment variables
railway variables set LANGFLOW_SECRET_KEY="your-secret-key"
railway variables set LANGFLOW_DATABASE_URL="${{Postgres.DATABASE_URL}}"
railway variables set LANGFLOW_AUTO_LOGIN="false"
railway variables set LANGFLOW_COMPONENTS_PATH="/app/components"

# Deploy
railway up
```

---

## Test SSO

```bash
# 1. Generate SSO token
curl -X POST https://api.engarde.media/api/v1/sso/langflow \
  -H "Authorization: Bearer YOUR_ENGARDE_TOKEN"

# 2. Copy sso_url from response and open in browser

# 3. Should redirect to authenticated Langflow session
```

---

## Verify Installation

### Health Check
```bash
curl https://langflow.engarde.media/health_check
```

### Check Components Loaded
```bash
railway shell
ls -la /app/components/En\ Garde\ Components/
```

### Check Logs
```bash
railway logs --service langflow-server | grep -i component
```

### Test Component in UI
1. Open https://langflow.engarde.media
2. Create new flow
3. Search for "Tenant" or "Walker"
4. Should see custom components

---

## Common Issues

### SSO Not Working
```bash
# Check secret key matches
railway variables --service langflow-server | grep SECRET_KEY
railway variables --service Main | grep LANGFLOW_SECRET

# Verify auto-login is disabled
railway variables --service langflow-server | grep AUTO_LOGIN
# Should be: false

# Check logs
railway logs --service langflow-server | grep -i sso
```

### Components Not Loading
```bash
# Verify path
railway variables --service langflow-server | grep COMPONENTS_PATH

# Check components exist
railway shell
ls -la /app/components/En\ Garde\ Components/

# Restart service
railway restart --service langflow-server
```

### Database Connection Fails
```bash
# Check DATABASE_URL
railway variables --service langflow-server | grep DATABASE_URL

# Test connection
railway shell
psql $LANGFLOW_DATABASE_URL -c "SELECT 1;"

# Run migrations
railway shell
alembic upgrade head
```

---

## Customization Points

### Change Branding

**Logo:**
```bash
# Replace file
src/frontend/src/assets/EnGardeIcon.svg
```

**Footer:**
```bash
# Edit file
src/frontend/src/components/core/engardeFooter/index.tsx
```

**Page Title:**
```bash
# Edit file
src/frontend/index.html
# Change: <title>EnGarde - AI Campaign Builder</title>
```

### Add Custom Component

1. Create Python file in `En Garde Components/`
2. Implement Component class
3. Rebuild Docker image
4. Deploy

Example:
```python
from langflow.custom import Component
from langflow.io import MessageTextInput, Output
from langflow.schema.message import Message

class MyComponent(Component):
    display_name = "My Component"
    description = "Does something"

    inputs = [
        MessageTextInput(name="input_text", display_name="Input"),
    ]

    outputs = [
        Output(name="output", method="process"),
    ]

    def process(self) -> Message:
        return Message(text=f"Processed: {self.input_text}")
```

---

## SSO Integration Points

### EnGarde Backend
```python
# File: production-backend/app/routers/langflow_sso.py

@router.post("/langflow")
async def generate_langflow_sso_token():
    # Generate JWT
    # Return sso_url
```

### Langflow Backend
```python
# File: src/backend/base/langflow/api/v1/login.py

@router.get("/custom/sso_login")
async def sso_login(token: str):
    # Validate JWT
    # Create/update user
    # Set cookies
    # Redirect
```

### EnGarde Frontend
```typescript
// File: production-frontend/components/workflow/AuthenticatedLangflowIframe.tsx

const setupAuthenticatedIframe = async () => {
  const response = await fetch('/api/v1/sso/langflow');
  const { sso_url } = await response.json();
  setIframeUrl(sso_url);
};
```

---

## Database Schema

### User Table
```sql
SELECT id, username, is_active, is_superuser, created_at
FROM "user"
WHERE username = 'user@example.com';
```

### Flows Table
```sql
SELECT id, name, user_id, created_at
FROM flow
ORDER BY created_at DESC
LIMIT 10;
```

### Check SSO User Created
```sql
SELECT * FROM "user" WHERE username = 'your-email@example.com';
```

---

## Local Development

```bash
# Clone repo
git clone https://github.com/EnGardeHQ/langflow-engarde.git
cd langflow-engarde

# Install dependencies
uv sync --extra postgresql
source .venv/bin/activate

# Create .env file
cat > .env << EOF
LANGFLOW_DATABASE_URL=postgresql://langflow_user:pass@localhost:5432/langflow_dev
LANGFLOW_SECRET_KEY=dev-secret-key-min-32-chars
LANGFLOW_AUTO_LOGIN=false
LANGFLOW_COMPONENTS_PATH=/absolute/path/to/En Garde Components
EOF

# Run migrations
cd src/backend/base
alembic upgrade head

# Start Langflow
langflow run --host 0.0.0.0 --port 7860

# Open browser
open http://localhost:7860
```

---

## Useful Commands

### Railway
```bash
railway login                    # Authenticate
railway link                     # Link to project
railway status                   # Check service status
railway logs                     # View logs
railway shell                    # SSH into container
railway variables                # List env vars
railway restart                  # Restart service
railway rollback                 # Rollback deployment
```

### Docker
```bash
docker build -f Dockerfile.engarde -t engarde-langflow .
docker run -p 7860:7860 engarde-langflow
docker logs -f container-id
docker exec -it container-id /bin/bash
docker system prune -af          # Clean up
```

### Database
```bash
psql $DATABASE_URL               # Connect
alembic upgrade head             # Run migrations
alembic downgrade -1             # Rollback
alembic revision -m "msg"        # Create migration
```

---

## Documentation Files

| File | Purpose |
|------|---------|
| `ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md` | Complete guide |
| `CUSTOMIZATION_SUMMARY.md` | Quick summary |
| `ARCHITECTURE_DIAGRAM.md` | Visual diagrams |
| `QUICK_REFERENCE.md` | This file |
| `En Garde Components/README.md` | Component docs |

---

## Support

- **Repository:** https://github.com/EnGardeHQ/langflow-engarde
- **Langflow Docs:** https://docs.langflow.org
- **Railway Docs:** https://docs.railway.app

---

## Checklist: New Deployment

- [ ] Clone repository
- [ ] Build Docker image
- [ ] Push to Docker Hub
- [ ] Create Railway service
- [ ] Set environment variables
- [ ] Deploy to Railway
- [ ] Test health check endpoint
- [ ] Test SSO login
- [ ] Verify custom components load
- [ ] Check branding appears correctly
- [ ] Create test flow
- [ ] Execute test flow
- [ ] Verify database user created
- [ ] Test Walker Agent API component

---

**Quick tip:** If something doesn't work, check the logs first:
```bash
railway logs --service langflow-server
```
