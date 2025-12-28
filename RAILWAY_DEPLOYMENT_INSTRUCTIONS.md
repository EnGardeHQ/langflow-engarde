# Railway Deployment Instructions

## Current Status

✅ **Code Committed & Pushed**: WhatsApp integration code is in GitHub
⏳ **Awaiting Railway Deployment**: Backend needs to redeploy to serve new routes

---

## Option 1: Manual Deployment via Railway Dashboard (Recommended)

1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Select your **production-backend** service
3. Click on the **Deployments** tab
4. You should see the latest deployment:
   - Commit: `5fe208b - Add Twilio WhatsApp integration...`
5. If deployment is:
   - **In Progress**: Wait for it to complete (2-5 minutes)
   - **Failed**: Click on it to see error logs
   - **Not Started**: Click **"Deploy"** button to trigger manual deployment

---

## Option 2: Verify Auto-Deployment Settings

1. In Railway Dashboard, go to your **production-backend** service
2. Click **Settings** tab
3. Under **Source**, verify:
   - ✅ **Auto Deploy** is enabled
   - ✅ **Deploy Branch** is set to `main`
   - ✅ **Deploy on Push** is enabled

If auto-deploy is disabled, enable it and it will deploy automatically on next push.

---

## Option 3: Force Redeploy via Railway CLI

```bash
# Login to Railway
railway login

# Link to your project
railway link

# Trigger deployment
railway up

# Or force redeploy
railway redeploy
```

---

## Option 4: Trigger Deployment via API (if Railway Token available)

```bash
# If you have a Railway API token
curl -X POST "https://backboard.railway.app/graphql/v2" \
  -H "Authorization: Bearer YOUR_RAILWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { deploymentRedeploy(id: \"YOUR_DEPLOYMENT_ID\") { id } }"
  }'
```

---

## How to Verify Deployment Completed

### Method 1: Check Webhook Endpoint

```bash
# Test if webhook is accessible
curl -I https://api.engarde.media/api/v1/channels/whatsapp/webhook

# Should return: 200, 405, or 422 (NOT 404)
# 404 means old code is still running
```

### Method 2: Check OpenAPI Spec

```bash
curl -s https://api.engarde.media/openapi.json | grep -o '/api/v1/channels/whatsapp/webhook'

# Should output: /api/v1/channels/whatsapp/webhook
```

### Method 3: Check Registered Routes

```bash
curl -s https://api.engarde.media/openapi.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
channel_routes = [p for p in data.get('paths', {}).keys() if '/api/v1/channels/' in p]
print('Channel routes found:')
for route in sorted(channel_routes):
    print(f'  {route}')
"

# Should show:
#   /api/v1/channels/email/...
#   /api/v1/channels/whatsapp/webhook
#   /api/v1/channels/whatsapp/send
```

---

## Expected Routes After Deployment

Once deployed, these routes will be available:

### WhatsApp Routes (4):
```
POST /api/v1/channels/whatsapp/webhook
POST /api/v1/channels/whatsapp/webhook/
POST /api/v1/channels/whatsapp/send
POST /api/v1/channels/whatsapp/send/
```

### Email Routes (8):
```
POST /api/v1/channels/email/send-daily-brief
POST /api/v1/channels/email/send
POST /api/v1/channels/email/schedule-daily-brief
GET  /api/v1/channels/email/templates
(+ trailing slash variants)
```

### Admin Monitoring Routes (4):
```
GET /api/v1/admin/conversations/whatsapp
GET /api/v1/admin/conversations/stats
GET /api/v1/admin/analytics/walker-agents
GET /api/v1/admin/hitl/review-queue
```

---

## Troubleshooting

### Issue: Deployment Not Starting

**Check GitHub Connection:**
1. Railway Dashboard → Settings → Source
2. Verify GitHub repository is connected
3. Verify branch is `main`
4. Check last commit shows `5fe208b`

**Force Trigger:**
- Make a minor change to `README.md`
- Commit and push
- Should trigger deployment

### Issue: Deployment Failing

**Check Build Logs:**
1. Railway Dashboard → Deployments
2. Click on failed deployment
3. View **Build Logs**
4. Look for Python import errors or missing dependencies

**Common Issues:**
- Missing dependencies in `requirements.txt`
- Python import errors
- Database connection issues (safe to ignore - app starts anyway)

### Issue: Routes Still 404 After Deployment

**Verify Route Registration:**
```bash
# SSH into Railway container (if possible)
railway run python3 -c "from app.main import app; print([r.path for r in app.routes if 'whatsapp' in r.path])"
```

**Check Logs:**
```bash
railway logs

# Look for:
# "✅ Core routers included (including ... communication channels)"
```

---

## Next Steps After Deployment

Once webhook endpoint is accessible (not 404):

1. **Configure Twilio Webhook URL**:
   ```
   https://api.engarde.media/api/v1/channels/whatsapp/webhook
   ```

2. **Test with Sample Message**:
   - Send WhatsApp message to Twilio number
   - Verify response received
   - Check logs in Railway

3. **Monitor Webhook Logs**:
   ```sql
   SELECT * FROM webhook_logs
   WHERE webhook_source = 'twilio_whatsapp'
   ORDER BY received_at DESC
   LIMIT 10;
   ```

4. **Register User Phone Numbers**:
   ```sql
   UPDATE users
   SET phone_number = '+12125551234'
   WHERE email = 'user@example.com';
   ```

---

## Quick Status Check

Run this to see current deployment status:

```bash
echo "=== Deployment Status Check ==="
echo ""
echo "1. Backend Health:"
curl -s https://api.engarde.media/health | python3 -m json.tool
echo ""
echo "2. WhatsApp Webhook Status:"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://api.engarde.media/api/v1/channels/whatsapp/webhook)
if [ "$STATUS" = "404" ]; then
  echo "   ❌ NOT DEPLOYED (404) - Old code still running"
elif [ "$STATUS" = "405" ] || [ "$STATUS" = "422" ] || [ "$STATUS" = "200" ]; then
  echo "   ✅ DEPLOYED ($STATUS) - Webhook endpoint accessible"
else
  echo "   ⚠️  UNKNOWN ($STATUS) - Check Railway logs"
fi
echo ""
echo "3. Total API Routes:"
curl -s https://api.engarde.media/openapi.json | python3 -c "import sys, json; print(f'   {len(json.load(sys.stdin).get(\"paths\", {}))} routes registered')"
```

---

## Support

- **Railway Dashboard**: https://railway.app/dashboard
- **Backend Logs**: `railway logs` or view in Railway Dashboard
- **GitHub Repo**: Check Actions tab for any CI/CD pipelines

---

**Last Updated**: December 25, 2025
**Commit**: 5fe208b
**Status**: Awaiting Railway deployment
