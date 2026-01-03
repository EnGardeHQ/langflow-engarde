# Production Environment Variables - FINAL

**Complete list of environment variables for Railway langflow-server**

---

## 🔧 Environment Variables (Copy to Railway)

### Main EnGarde Backend (2 variables)

```bash
ENGARDE_API_URL=https://api.engarde.media
ENGARDE_API_KEY=<your_main_backend_api_key>
```

---

### PostgreSQL Main Database (1 variable)

```bash
DATABASE_URL=postgresql://postgres:<password>@switchback.proxy.rlwy.net:54319/railway
```

---

### BigQuery Data Lake (3 variables)

```bash
BIGQUERY_PROJECT_ID=engarde-production
BIGQUERY_DATASET_ID=engarde_analytics
GOOGLE_APPLICATION_CREDENTIALS_JSON={"type":"service_account","project_id":"engarde-production",...}
```

**Note:** `GOOGLE_APPLICATION_CREDENTIALS_JSON` must be the complete service account JSON as a single-line string.

---

### ZeroDB Real-Time Database (3 variables)

```bash
ZERODB_API_KEY=<your_zerodb_api_key>
ZERODB_PROJECT_ID=<your_zerodb_project_uuid>
ZERODB_API_BASE_URL=https://api.ainative.studio/api/v1
```

---

### Walker Microservices (3 variables)

**Production URLs:**

```bash
# Onside Microservice (SEO + Content)
ONSIDE_API_URL=https://onside-production.up.railway.app

# Sankore Microservice (Paid Ads)
SANKORE_API_URL=https://sankore-production.up.railway.app

# MadanSara Microservice (Audience Intelligence)
MADANSARA_API_URL=https://madansara-production.up.railway.app
```

**Local Development URLs (if running microservices locally):**

```bash
ONSIDE_API_URL=http://localhost:8000
SANKORE_API_URL=http://localhost:8001
MADANSARA_API_URL=http://localhost:8002
```

---

### Walker Agent API Keys (4 variables)

```bash
WALKER_AGENT_API_KEY_ONSIDE_SEO=wa_onside_production_<random_string>
WALKER_AGENT_API_KEY_SANKORE_PAID_ADS=wa_sankore_production_<random_string>
WALKER_AGENT_API_KEY_ONSIDE_CONTENT=wa_onside_production_<random_string>
WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE=wa_madansara_production_<random_string>
```

**To generate API keys:**

```bash
# Generate random API key
python3 -c "import secrets; print(f'wa_onside_production_{secrets.token_urlsafe(32)}')"
python3 -c "import secrets; print(f'wa_sankore_production_{secrets.token_urlsafe(32)}')"
python3 -c "import secrets; print(f'wa_onside_production_{secrets.token_urlsafe(32)}')"
python3 -c "import secrets; print(f'wa_madansara_production_{secrets.token_urlsafe(32)}')"
```

---

## 📊 Summary

**Total Environment Variables: 16**

| Category | Count | Variables |
|----------|-------|-----------|
| Main Backend | 2 | ENGARDE_API_URL, ENGARDE_API_KEY |
| Database | 1 | DATABASE_URL |
| BigQuery | 3 | BIGQUERY_PROJECT_ID, BIGQUERY_DATASET_ID, GOOGLE_APPLICATION_CREDENTIALS_JSON |
| ZeroDB | 3 | ZERODB_API_KEY, ZERODB_PROJECT_ID, ZERODB_API_BASE_URL |
| Microservices | 3 | ONSIDE_API_URL, SANKORE_API_URL, MADANSARA_API_URL |
| Walker Keys | 4 | WALKER_AGENT_API_KEY_* (4 keys) |

---

## ✅ Verification Commands

### Check all variables are set:

```bash
railway variables --service langflow-server
```

### Test specific variables:

```bash
# Check EnGarde API
railway run --service langflow-server -- python3 -c "import os; print('ENGARDE_API_URL:', os.getenv('ENGARDE_API_URL'))"

# Check BigQuery credentials
railway run --service langflow-server -- python3 -c "import os, json; creds = os.getenv('GOOGLE_APPLICATION_CREDENTIALS_JSON'); print('BigQuery project:', json.loads(creds)['project_id'] if creds else 'NOT SET')"

# Check ZeroDB
railway run --service langflow-server -- python3 -c "import os; print('ZeroDB project:', os.getenv('ZERODB_PROJECT_ID'))"

# Check Microservices
railway run --service langflow-server -- python3 -c "import os; print('Onside:', os.getenv('ONSIDE_API_URL')); print('Sankore:', os.getenv('SANKORE_API_URL')); print('MadanSara:', os.getenv('MADANSARA_API_URL'))"
```

---

## 🔐 Security Notes

1. **Never commit API keys to git** - Use Railway environment variables only
2. **Rotate keys regularly** - Especially WALKER_AGENT_API_KEY_* keys
3. **Use HTTPS for all microservices** - Production URLs use https://
4. **Validate API keys in backend** - EnGarde API should validate walker agent keys
5. **Limit key permissions** - Each walker key should only access its endpoint

---

## 🚀 Setting Variables in Railway

### Via Railway Dashboard:

1. Go to https://railway.app
2. Select your project
3. Click on `langflow-server` service
4. Go to "Variables" tab
5. Click "New Variable"
6. Add each variable from the list above

### Via Railway CLI:

```bash
# Set individual variable
railway variables --service langflow-server --set ENGARDE_API_URL=https://api.engarde.media

# Set multiple variables from file
railway variables --service langflow-server --set-from-file .env.production
```

### Via .env.production file:

Create `.env.production` with all variables, then:

```bash
railway variables --service langflow-server --set-from-file .env.production
```

---

## 📝 Template .env.production File

Create this file and update with your actual values:

```bash
# Main Backend
ENGARDE_API_URL=https://api.engarde.media
ENGARDE_API_KEY=your_main_backend_api_key_here

# Database
DATABASE_URL=postgresql://postgres:your_password@switchback.proxy.rlwy.net:54319/railway

# BigQuery
BIGQUERY_PROJECT_ID=engarde-production
BIGQUERY_DATASET_ID=engarde_analytics
GOOGLE_APPLICATION_CREDENTIALS_JSON={"type":"service_account","project_id":"engarde-production","private_key_id":"...","private_key":"...","client_email":"...","client_id":"...","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"..."}

# ZeroDB
ZERODB_API_KEY=your_zerodb_api_key_here
ZERODB_PROJECT_ID=your_zerodb_project_uuid_here
ZERODB_API_BASE_URL=https://api.ainative.studio/api/v1

# Microservices (Production)
ONSIDE_API_URL=https://onside-production.up.railway.app
SANKORE_API_URL=https://sankore-production.up.railway.app
MADANSARA_API_URL=https://madansara-production.up.railway.app

# Walker Agent API Keys
WALKER_AGENT_API_KEY_ONSIDE_SEO=wa_onside_production_generated_key_here
WALKER_AGENT_API_KEY_SANKORE_PAID_ADS=wa_sankore_production_generated_key_here
WALKER_AGENT_API_KEY_ONSIDE_CONTENT=wa_onside_production_generated_key_here
WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE=wa_madansara_production_generated_key_here
```

---

## ⚠️ Important Notes

### BigQuery Credentials JSON

The `GOOGLE_APPLICATION_CREDENTIALS_JSON` must be:
- Valid JSON (test with `echo $GOOGLE_APPLICATION_CREDENTIALS_JSON | jq .`)
- Single line (no newlines)
- Properly escaped quotes
- Contains all required fields: `type`, `project_id`, `private_key_id`, `private_key`, `client_email`, etc.

### Microservice URLs

- **Production:** Use `https://` URLs from Railway deployments
- **Local Development:** Use `http://localhost` URLs
- **Port mapping (local):** Onside=8000, Sankore=8001, MadanSara=8002
- **Never hardcode** - Always use environment variables

### Database URL

- Use `DATABASE_PUBLIC_URL` for external connections
- Railway provides this automatically
- Format: `postgresql://user:pass@host:port/database`

---

## 🔍 Troubleshooting

### Issue: "Environment variable not found"

**Check variable is set:**
```bash
railway variables --service langflow-server | grep ONSIDE_API_URL
```

**If missing, add it:**
```bash
railway variables --service langflow-server --set ONSIDE_API_URL=https://onside-production.up.railway.app
```

### Issue: "BigQuery authentication failed"

**Test credentials are valid:**
```bash
railway run --service langflow-server -- python3 -c "
import os, json
from google.cloud import bigquery
from google.oauth2 import service_account

creds_json = os.getenv('GOOGLE_APPLICATION_CREDENTIALS_JSON')
creds_dict = json.loads(creds_json)
credentials = service_account.Credentials.from_service_account_info(creds_dict)
client = bigquery.Client(credentials=credentials, project='engarde-production')
print('✓ BigQuery authentication successful')
"
```

### Issue: "Microservice connection refused"

**Test microservice is accessible:**
```bash
# Test Onside
curl -I https://onside-production.up.railway.app/health

# Test Sankore
curl -I https://sankore-production.up.railway.app/health

# Test MadanSara
curl -I https://madansara-production.up.railway.app/health
```

---

## ✅ Final Checklist

Before deploying agents, verify:

- [ ] All 16 environment variables are set in Railway
- [ ] BigQuery credentials JSON is valid
- [ ] ZeroDB API key is correct
- [ ] All microservice URLs are accessible (https://)
- [ ] Walker agent API keys are generated and stored
- [ ] Database URL is correct and accessible
- [ ] EnGarde API URL and key are valid

**Verify all at once:**
```bash
railway variables --service langflow-server | wc -l
# Should show at least 16 lines (plus headers)
```

---

**Ready to deploy agents with correct production URLs! 🚀**
