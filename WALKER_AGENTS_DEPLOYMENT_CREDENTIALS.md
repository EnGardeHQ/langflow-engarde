# Walker Agents - Deployment Credentials

**CONFIDENTIAL - Store Securely**

**Date Generated**: December 28, 2025

---

## Database Migration Status

✅ **COMPLETE** - All Walker Agent tables created successfully:
- `walker_agent_api_keys`
- `walker_agent_suggestions`
- `walker_agent_notification_preferences`

---

## Generated API Keys

⚠️ **CRITICAL**: These API keys cannot be retrieved again. Save them immediately in a secure location (1Password, environment variables, etc.)

### Environment Variables for Langflow

```bash
# Backend API URL
ENGARDE_API_URL="https://api.engarde.media"

# OnSide SEO Walker Agent
WALKER_AGENT_API_KEY_ONSIDE_SEO="wa_onside_production_tvKoJ-yGxSzPkmJ9vAxgnvsdGd_zUPBLDCYVYQg_GDc"

# OnSide Content Walker Agent
WALKER_AGENT_API_KEY_ONSIDE_CONTENT="wa_onside_production_1-oq6OFlu0Pb3kvVHlNeiTcbe8S6u1CMbzmc8ppfxP4"

# Sankore Paid Ads Walker Agent
WALKER_AGENT_API_KEY_SANKORE_PAID_ADS="wa_sankore_production_sBhmczd9F_nN_PY94H8TJuS9e7-jZqp5l7rwrQSOscc"

# MadanSara Audience Intelligence Walker Agent
WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE="wa_madansara_production_k6XDe6dbAU-JD5zVxOWr8zsPjI-h6OyQAfh1jtRAn5g"
```

### Railway Configuration

If deploying Langflow on Railway, set these variables:

```bash
railway variables set ENGARDE_API_URL="https://api.engarde.media"
railway variables set WALKER_AGENT_API_KEY_ONSIDE_SEO="wa_onside_production_tvKoJ-yGxSzPkmJ9vAxgnvsdGd_zUPBLDCYVYQg_GDc"
railway variables set WALKER_AGENT_API_KEY_ONSIDE_CONTENT="wa_onside_production_1-oq6OFlu0Pb3kvVHlNeiTcbe8S6u1CMbzmc8ppfxP4"
railway variables set WALKER_AGENT_API_KEY_SANKORE_PAID_ADS="wa_sankore_production_sBhmczd9F_nN_PY94H8TJuS9e7-jZqp5l7rwrQSOscc"
railway variables set WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE="wa_madansara_production_k6XDe6dbAU-JD5zVxOWr8zsPjI-h6OyQAfh1jtRAn5g"
```

### Docker Compose Configuration

If using Docker Compose, add to `docker-compose.yml`:

```yaml
services:
  langflow:
    environment:
      - ENGARDE_API_URL=https://api.engarde.media
      - WALKER_AGENT_API_KEY_ONSIDE_SEO=wa_onside_production_tvKoJ-yGxSzPkmJ9vAxgnvsdGd_zUPBLDCYVYQg_GDc
      - WALKER_AGENT_API_KEY_ONSIDE_CONTENT=wa_onside_production_1-oq6OFlu0Pb3kvVHlNeiTcbe8S6u1CMbzmc8ppfxP4
      - WALKER_AGENT_API_KEY_SANKORE_PAID_ADS=wa_sankore_production_sBhmczd9F_nN_PY94H8TJuS9e7-jZqp5l7rwrQSOscc
      - WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE=wa_madansara_production_k6XDe6dbAU-JD5zVxOWr8zsPjI-h6OyQAfh1jtRAn5g
```

---

## API Key Details

| Service | Microservice | Agent Type | Key ID |
|---------|--------------|------------|---------|
| OnSide SEO Walker Agent | onside | seo | `2e4c05a9-d0d0-44de-a2a3-ea72bd79420c` |
| OnSide Content Walker Agent | onside | content | `2fcad482-8d8a-47c3-8854-729c36f3be73` |
| Sankore Paid Ads Walker Agent | sankore | paid_ads | `03d28313-184c-43de-b4d0-c4195ec9ac4d` |
| MadanSara Audience Intelligence Walker Agent | madansara | audience_intelligence | `c0ff3839-88f9-4cba-9483-101d7e09572f` |

---

## Next Steps

1. **✅ Database Migration**: COMPLETE
2. **✅ API Key Generation**: COMPLETE
3. **⏭️ Configure Langflow**:
   - Add environment variables above
   - Import flows from `langflow/flows/`
   - Test each flow manually
4. **⏭️ Schedule Automated Runs**:
   - SEO Agent: Daily at 5:00 AM
   - Paid Ads Agent: Daily at 6:00 AM
   - Content Agent: Daily at 6:00 AM
   - Audience Intelligence: Daily at 8:00 AM

---

## Security Notes

- API keys are hashed in the database using SHA-256
- Keys cannot be retrieved from the database (only compared)
- If a key is compromised, mark as revoked in database and generate new one
- Store this file in a secure location (1Password, encrypted vault, etc.)
- Delete this file after copying credentials to secure location

---

## Verification

To verify API keys are active:

```sql
SELECT id, microservice, agent_type, is_active, revoked, created_at, usage_count
FROM walker_agent_api_keys
WHERE is_active = true AND revoked = false
ORDER BY created_at DESC;
```

Expected result: 4 active keys

---

**Document Status**: CONFIDENTIAL
**Generated**: December 28, 2025
**Expires**: Never (but should be stored securely and this file deleted)
