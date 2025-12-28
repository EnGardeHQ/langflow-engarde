# Walker Agents Communication Channels - Integration Setup Guide

**Version:** 1.0
**Last Updated:** December 25, 2025
**Estimated Setup Time:** 2-4 hours

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Twilio WhatsApp Integration](#twilio-whatsapp-integration)
3. [SendGrid Email Integration](#sendgrid-email-integration)
4. [Environment Configuration](#environment-configuration)
5. [Database Setup](#database-setup)
6. [Langflow Configuration](#langflow-configuration)
7. [Testing Procedures](#testing-procedures)
8. [Troubleshooting](#troubleshooting)
9. [Production Deployment Checklist](#production-deployment-checklist)

---

## Prerequisites

### Required Accounts

- [x] Twilio Account (for WhatsApp)
- [x] SendGrid Account (for Email)
- [x] PostgreSQL Database (v13+)
- [x] Redis Instance (v6+)
- [x] Langflow Instance or Cloud Access

### Required Tools

- Python 3.9+
- Node.js 18+
- PostgreSQL client
- Redis client
- Git
- Docker (optional, for local development)

### Required Skills

- Basic Python/FastAPI knowledge
- Understanding of webhooks
- Database management
- Environment variable configuration

---

## Twilio WhatsApp Integration

### Step 1: Create Twilio Account

1. Go to [https://www.twilio.com/](https://www.twilio.com/)
2. Sign up for a new account (free trial available)
3. Verify your phone number and email
4. Navigate to the Console Dashboard

### Step 2: Enable WhatsApp Sandbox

For development and testing:

1. In Twilio Console, go to **Messaging** → **Try it out** → **Send a WhatsApp message**
2. Follow instructions to join the sandbox:
   - Send a WhatsApp message to Twilio's sandbox number
   - Use the code provided (e.g., "join <your-code>")
3. Your sandbox number will be: `+1 415 523 8886` (or regional equivalent)

### Step 3: Get Twilio Credentials

1. Navigate to **Account** → **API keys & tokens**
2. Copy your credentials:
   - **Account SID**: `ACxxxxxxxxxxxxxxxxxxxxx`
   - **Auth Token**: Click "Show" to reveal

### Step 4: Configure Webhook

1. In Twilio Console, go to **Messaging** → **Settings** → **WhatsApp Sandbox Settings**
2. Set the webhook URL:
   ```
   https://your-domain.com/api/v1/channels/whatsapp/webhook
   ```
3. Set HTTP Method: **POST**
4. Save configuration

### Step 5: Update Environment Variables

Add to your `.env` file:

```bash
# Twilio Configuration
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_WHATSAPP_NUMBER=+14155238886
WHATSAPP_WEBHOOK_URL=https://your-domain.com/api/v1/channels/whatsapp/webhook
```

### Step 6: Test WhatsApp Integration

Run the test script:

```bash
cd /Users/cope/EnGardeHQ/production-backend
python scripts/test_whatsapp_integration.py
```

Expected output:
```
✅ Twilio credentials valid
✅ WhatsApp number configured
✅ Webhook endpoint reachable
✅ Test message sent successfully

Test your integration by sending a WhatsApp message to: +14155238886
Message: "join <your-code>"
Then send: "What's my ROAS?"
```

### Step 7: Production WhatsApp Number (Optional)

For production, request a dedicated WhatsApp Business number:

1. Go to **Messaging** → **Senders** → **WhatsApp senders**
2. Click **Request to enable WhatsApp**
3. Fill out the WhatsApp Business Profile form
4. Submit for approval (takes 1-2 business days)
5. Once approved, update `TWILIO_WHATSAPP_NUMBER` in `.env`

---

## SendGrid Email Integration

### Step 1: Create SendGrid Account

1. Go to [https://sendgrid.com/](https://sendgrid.com/)
2. Sign up for a free account (100 emails/day free tier)
3. Verify your email address
4. Complete account setup

### Step 2: Verify Sender Identity

1. Navigate to **Settings** → **Sender Authentication**
2. Click **Verify a Single Sender**
3. Fill in your details:
   - From Name: `En Garde`
   - From Email: `noreply@engarde.com` (or your domain)
   - Reply To: `support@engarde.com`
4. Verify email address via sent verification link

### Step 3: Create API Key

1. Go to **Settings** → **API Keys**
2. Click **Create API Key**
3. Name: `EnGarde Production API Key`
4. Permissions: **Full Access** (or restricted to Mail Send)
5. Copy the API key (shown only once):
   ```
   SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

### Step 4: Update Environment Variables

Add to your `.env` file:

```bash
# SendGrid Configuration
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SENDGRID_FROM_EMAIL=noreply@engarde.com
SENDGRID_FROM_NAME=En Garde
SENDGRID_REPLY_TO=support@engarde.com

# Email Templates
DAILY_BRIEF_TEMPLATE_ID=d-1234567890abcdef1234567890abcdef
```

### Step 5: Create Email Templates

#### Create Daily Brief Template

1. Go to **Email API** → **Dynamic Templates**
2. Click **Create a Dynamic Template**
3. Name: `Daily Brief Template`
4. Click **Add Version** → **Blank Template** → **Code Editor**
5. Paste the template code (see `/app/templates/emails/daily_brief.html`)
6. Click **Save**, then **Save** again
7. Copy Template ID (starts with `d-`)

Update `.env`:
```bash
DAILY_BRIEF_TEMPLATE_ID=d-your-template-id
```

### Step 6: Test Email Integration

Run the test script:

```bash
cd /Users/cope/EnGardeHQ/production-backend
python scripts/test_email_integration.py --to your_email@example.com
```

Expected output:
```
✅ SendGrid API key valid
✅ Sender email verified
✅ Test email sent successfully

Check your inbox at: your_email@example.com
Subject: "Test Email from En Garde"
```

### Step 7: Configure Domain Authentication (Production)

For better deliverability in production:

1. Go to **Settings** → **Sender Authentication** → **Authenticate Your Domain**
2. Add your domain (e.g., `engarde.com`)
3. Add DNS records to your domain registrar:
   - CNAME records for domain authentication
   - CNAME records for link branding
4. Verify DNS setup in SendGrid dashboard
5. Enable link branding

---

## Environment Configuration

### Complete `.env` File

Create `/Users/cope/EnGardeHQ/production-backend/.env`:

```bash
# ========================================
# Database Configuration
# ========================================
DATABASE_URL=postgresql://engarde_user:secure_password@localhost:5432/engarde
REDIS_URL=redis://localhost:6379/0

# ========================================
# Twilio Configuration (WhatsApp)
# ========================================
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_WHATSAPP_NUMBER=+14155238886
WHATSAPP_WEBHOOK_URL=https://api.engarde.com/api/v1/channels/whatsapp/webhook

# ========================================
# SendGrid Configuration (Email)
# ========================================
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SENDGRID_FROM_EMAIL=noreply@engarde.com
SENDGRID_FROM_NAME=En Garde
SENDGRID_REPLY_TO=support@engarde.com
DAILY_BRIEF_TEMPLATE_ID=d-1234567890abcdef1234567890abcdef

# ========================================
# Langflow Configuration
# ========================================
LANGFLOW_API_URL=https://langflow.engarde.com
LANGFLOW_API_KEY=lf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
LANGFLOW_TIMEOUT_SECONDS=30

# ========================================
# Security & Encryption
# ========================================
JWT_SECRET_KEY=your-super-secret-jwt-key-change-in-production
PII_ENCRYPTION_KEY=base64-encoded-32-byte-key-for-pii-encryption
ADMIN_ACCESS_LOG_ENABLED=true

# ========================================
# Feature Flags
# ========================================
ENABLE_WHATSAPP=true
ENABLE_EMAIL_BRIEFS=true
ENABLE_CHAT_UI=true
ENABLE_HITL=true

# ========================================
# Performance & Limits
# ========================================
MAX_WORKERS=4
WORKER_TIMEOUT=300
CELERY_BROKER_URL=redis://localhost:6379/1
CELERY_RESULT_BACKEND=redis://localhost:6379/2

# ========================================
# Monitoring & Logging
# ========================================
LOG_LEVEL=INFO
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
ENABLE_PERFORMANCE_MONITORING=true

# ========================================
# HITL Configuration
# ========================================
HITL_DEFAULT_SLA_HOURS=24
HITL_ESCALATION_HOURS=12
HITL_AUTO_APPROVE_LOW_RISK=false

# ========================================
# Rate Limiting
# ========================================
RATE_LIMIT_ENABLED=true
RATE_LIMIT_PER_MINUTE=100
RATE_LIMIT_PER_HOUR=2000
```

### Generate Encryption Keys

Generate secure keys for production:

```bash
# JWT Secret Key
python -c "import secrets; print(secrets.token_urlsafe(64))"

# PII Encryption Key (32 bytes, base64 encoded)
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Update `.env` with generated keys.

---

## Database Setup

### Step 1: Create Database

```bash
# Connect to PostgreSQL
psql postgres

# Create database and user
CREATE DATABASE engarde;
CREATE USER engarde_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE engarde TO engarde_user;

# Exit psql
\q
```

### Step 2: Run Migrations

```bash
cd /Users/cope/EnGardeHQ/production-backend

# Install dependencies
pip install -r requirements.txt

# Run Alembic migrations
alembic upgrade head
```

Expected output:
```
INFO  [alembic.runtime.migration] Running upgrade -> abc123, Add conversational analytics tables
INFO  [alembic.runtime.migration] Running upgrade abc123 -> def456, Add HITL approval system
INFO  [alembic.runtime.migration] Running upgrade def456 -> ghi789, Add user phone numbers
✅ Database migrations completed successfully
```

### Step 3: Seed Walker Agents

```bash
# Seed the 4 Walker Agents
python scripts/seed_walker_agents.py
```

Expected output:
```
============================================================
Walker Agent Seed Script
============================================================

Found 1 tenant(s)

Creating Walker Agents...

📦 Tenant: Demo Tenant (ID: 123e4567-e89b-12d3-a456-426614174000)
   ✅ Paid Ads Marketing: Created
   ✅ SEO: Created
   ✅ Content Generation: Created
   ✅ Audience Intelligence: Created

============================================================
✅ Walker Agent Creation Summary:
   Created: 4
   Skipped (already exist): 0
   Total: 4
============================================================
```

### Step 4: Create Demo Data (Optional)

```bash
# Create demo users and conversations
python scripts/seed_demo_data.py
```

---

## Langflow Configuration

### Step 1: Access Langflow Instance

If using Langflow Cloud:
1. Go to [https://langflow.ai/](https://langflow.ai/)
2. Sign up or log in
3. Create a new project: `EnGarde Walker Agents`

If self-hosting:
```bash
# Install Langflow
pip install langflow

# Run Langflow
langflow run --host 0.0.0.0 --port 7860
```

### Step 2: Create Walker Agent Workflows

Create workflows for each Walker Agent:

#### Paid Ads Marketing Agent Workflow

1. In Langflow, click **New Flow**
2. Name: `Paid Ads Marketing Agent`
3. Add nodes:
   - **Input Node**: User query
   - **Context Node**: Fetch campaign data from Meta/Google APIs
   - **LLM Node**: GPT-4 or Claude for analysis
   - **Decision Node**: Check if action requires HITL
   - **Output Node**: Formatted response
4. Connect nodes and configure
5. Test workflow with sample input
6. Deploy workflow

#### SEO Agent Workflow

Similar structure, but with SEO-specific nodes:
- **Keyword Research Node**
- **Technical Audit Node**
- **Competitor Analysis Node**

#### Content Generation Agent Workflow

- **Brand Voice Node**
- **Cultural Context Node**
- **Content Generation Node** (GPT-4)
- **Multi-format Output Node**

#### Audience Intelligence Agent Workflow

- **Data Ingestion Node** (CRM, Analytics)
- **Segmentation Node**
- **Predictive Analytics Node**
- **Recommendation Node**

### Step 3: Get Langflow API Credentials

1. In Langflow, go to **Settings** → **API Keys**
2. Create new API key
3. Copy API key: `lf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
4. Get API URL: `https://api.langflow.ai` or your self-hosted URL

Update `.env`:
```bash
LANGFLOW_API_URL=https://api.langflow.ai
LANGFLOW_API_KEY=lf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Step 4: Link Workflows to Walker Agents

Update Walker Agent configurations in database:

```sql
-- Update Paid Ads Agent with Langflow workflow ID
UPDATE ai_agents
SET configuration = jsonb_set(
  configuration,
  '{langflow_workflow_id}',
  '"flow-paid-ads-12345"'
)
WHERE agent_type = 'paid_ads_optimization'
AND agent_category = 'walker';

-- Repeat for other agents
```

---

## Testing Procedures

### Test 1: WhatsApp End-to-End

```bash
# Start the backend
cd /Users/cope/EnGardeHQ/production-backend
uvicorn app.main:app --reload --port 8000

# In a new terminal, expose webhook (for local testing)
ngrok http 8000

# Update Twilio webhook URL with ngrok URL:
# https://your-ngrok-url.ngrok.io/api/v1/channels/whatsapp/webhook

# Send test WhatsApp message
# From your phone, send to +14155238886:
# "What's my ROAS?"

# Check logs
tail -f logs/app.log
```

Expected response on WhatsApp:
```
Your overall ROAS across platforms:
• Meta: 3.2x (↑ 15%)
• Google Ads: 2.8x (↑ 8%)
• TikTok: 4.1x (↑ 23%)
• LinkedIn: 1.9x (↓ 5%)
```

### Test 2: Email Daily Brief

```bash
# Trigger daily brief for a user
python scripts/trigger_daily_brief.py --user_id <user_uuid>

# Or via API
curl -X POST "http://localhost:8000/api/v1/channels/email/send-daily-brief/<user_id>" \
  -H "Authorization: Bearer <jwt_token>"
```

Check your email inbox for the daily brief.

### Test 3: Chat UI WebSocket

```bash
# Start frontend (in new terminal)
cd /Users/cope/EnGardeHQ/production-frontend
npm install
npm run dev

# Open browser: http://localhost:3000
# Navigate to Chat UI
# Send test message: "What campaigns are running?"
```

### Test 4: HITL Approval Flow

```bash
# Via WhatsApp or Chat, request high-risk action:
# "Increase my Meta budget by $5,000"

# Check HITL queue in admin dashboard
# Approve or reject the request

# User should receive notification
```

### Test 5: Admin Monitoring

1. Log in to admin dashboard
2. Navigate to **Monitoring** → **Conversations**
3. View recent conversations
4. Click on a conversation to view details
5. Verify PII masking is working
6. Test "Show Full PII" toggle (if you have permissions)

---

## Troubleshooting

### WhatsApp Issues

#### Webhook not receiving messages

**Problem:** Twilio webhook returns 404 or 500 error

**Solution:**
1. Check webhook URL is correct and accessible
2. Verify FastAPI server is running
3. Check firewall/security group allows incoming requests
4. Review Twilio webhook logs in Twilio Console

```bash
# Test webhook endpoint directly
curl -X POST "http://localhost:8000/api/v1/channels/whatsapp/webhook" \
  -d "Body=test&From=+14155551234"
```

#### Responses not sent back to user

**Problem:** WhatsApp receives webhook but doesn't respond

**Solution:**
1. Check Twilio credentials in `.env`
2. Verify Twilio account has credits
3. Check `twilio_service.send_whatsapp_message()` logs

```bash
# Test Twilio send directly
python scripts/test_twilio_send.py --to +14155551234 --message "Test"
```

---

### Email Issues

#### Daily briefs not sending

**Problem:** Scheduled job runs but emails not sent

**Solution:**
1. Check SendGrid API key is valid
2. Verify sender email is verified
3. Check email preferences are enabled for user
4. Review SendGrid activity logs

```bash
# Check email preferences
psql $DATABASE_URL -c "SELECT * FROM user_email_preferences WHERE user_id = '<uuid>';"

# Test SendGrid directly
python scripts/test_sendgrid.py --to test@example.com
```

#### Emails going to spam

**Problem:** Emails delivered but in spam folder

**Solution:**
1. Complete domain authentication in SendGrid
2. Add SPF and DKIM records to your domain
3. Warm up your sending domain gradually
4. Avoid spam trigger words in subject/content

---

### Database Issues

#### Migration fails

**Problem:** Alembic migration returns error

**Solution:**
```bash
# Check current migration version
alembic current

# View migration history
alembic history

# Downgrade to previous version
alembic downgrade -1

# Fix migration file and re-run
alembic upgrade head
```

#### Connection errors

**Problem:** `psycopg2.OperationalError: could not connect to server`

**Solution:**
1. Verify PostgreSQL is running: `pg_isready`
2. Check DATABASE_URL in `.env`
3. Verify network connectivity
4. Check PostgreSQL logs: `tail -f /var/log/postgresql/postgresql-13-main.log`

---

### Langflow Issues

#### Workflow execution timeout

**Problem:** Langflow workflow takes too long and times out

**Solution:**
1. Increase timeout in `.env`: `LANGFLOW_TIMEOUT_SECONDS=60`
2. Optimize workflow (reduce API calls, cache data)
3. Check Langflow logs for bottlenecks

#### Authentication errors

**Problem:** `401 Unauthorized` when calling Langflow API

**Solution:**
1. Verify `LANGFLOW_API_KEY` in `.env`
2. Check API key hasn't expired
3. Ensure API key has correct permissions

```bash
# Test Langflow API directly
curl -X GET "$LANGFLOW_API_URL/api/v1/flows" \
  -H "Authorization: Bearer $LANGFLOW_API_KEY"
```

---

## Production Deployment Checklist

### Pre-Deployment

- [ ] All environment variables configured in production
- [ ] Database migrations run successfully
- [ ] Walker Agents seeded
- [ ] Twilio WhatsApp production number approved
- [ ] SendGrid domain authenticated
- [ ] SSL certificates installed
- [ ] Firewall rules configured
- [ ] Rate limiting enabled
- [ ] Monitoring tools configured (Sentry, Prometheus)

### Deployment Steps

1. **Deploy Backend**
   ```bash
   # Build Docker image
   docker build -t engarde-backend:latest .

   # Push to registry
   docker push your-registry.com/engarde-backend:latest

   # Deploy to Kubernetes
   kubectl apply -f k8s/backend-deployment.yaml
   ```

2. **Deploy Workers**
   ```bash
   kubectl apply -f k8s/celery-worker-deployment.yaml
   kubectl apply -f k8s/celery-beat-deployment.yaml
   ```

3. **Configure External Services**
   - Update Twilio webhook URL to production domain
   - Update SendGrid templates
   - Configure CDN/CloudFlare

4. **Run Health Checks**
   ```bash
   # Health check endpoint
   curl https://api.engarde.com/health

   # Expected response:
   # {"status": "healthy", "version": "1.0.0"}
   ```

### Post-Deployment

- [ ] Send test WhatsApp message
- [ ] Trigger test daily brief
- [ ] Test Chat UI
- [ ] Verify HITL approvals working
- [ ] Check admin dashboard
- [ ] Monitor error rates
- [ ] Review performance metrics
- [ ] Set up alerts

### Monitoring

Set up monitoring for:
- API response times
- WebSocket connections
- Twilio webhook success rate
- SendGrid delivery rate
- Database connection pool
- Redis memory usage
- Celery queue length
- HITL approval SLA compliance

---

## Support

### Documentation
- Full API documentation: `/docs/WALKER_AGENTS_API_DOCUMENTATION.md`
- Architecture diagrams: `/docs/WALKER_AGENTS_ARCHITECTURE_DIAGRAMS.md`
- PRD: `/docs/WALKER_AGENTS_COMMUNICATION_CHANNELS_PRD.md`

### Contact
- **Email:** support@engarde.com
- **Slack:** #en-garde-support
- **Documentation:** https://docs.engarde.com

### Emergency Contacts
- **On-call Engineer:** oncall@engarde.com
- **Twilio Support:** https://www.twilio.com/help
- **SendGrid Support:** https://support.sendgrid.com

---

**Document Version:** 1.0
**Last Updated:** December 25, 2025
**Next Review:** February 1, 2026
**Maintained By:** DevOps & Integration Team
