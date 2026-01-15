# Platform Adapters - Quick Reference

## 🚀 Quick Start

### List All Available Platforms

```python
from app.services.platform_adapters.adapter_registry import get_adapter_registry

registry = get_adapter_registry()
platforms = registry.list_available_platforms()
print(f"Total platforms: {len(platforms)}")  # 195
```

### Get an Adapter

```python
# Get adapter for a specific platform
adapter = registry.get_adapter(
    platform='shopify',       # Platform ID
    tenant_id=tenant_id,      # Your tenant ID
    db=db_session            # SQLAlchemy session
)
```

### Test Connection

```python
is_connected = await adapter.test_connection()
if is_connected:
    print("✅ Connection successful")
else:
    print("❌ Connection failed")
```

### Fetch Data

```python
# Fetch customers
customers = await adapter.fetch_customers(limit=100)

# Fetch products
products = await adapter.fetch_products()

# Fetch orders with date range
from datetime import date, timedelta
end_date = date.today()
start_date = end_date - timedelta(days=30)

orders = await adapter.fetch_orders(
    limit=1000,
    date_from=start_date,
    date_to=end_date
)

# Fetch campaigns (for advertising platforms)
campaigns = await adapter.fetch_campaigns()
```

---

## 📋 Complete Platform List (195 Total)

### Payment Processors (13)
`stripe`, `stripe_connect`, `paypal`, `square`, `adyen`, `authorize_net`, `braintree`, `checkout`, `mercadopago`, `razorpay`, `mollie`, `klarna`, `affirm`

### POS Systems (11)
`square_pos`, `clover`, `toast`, `lightspeed`, `shopify_pos`, `revel`, `vend`, `touchbistro`, `ncr_silver`, `lavu_pos`, `easypost`

### Advertising (25)
`google_ads`, `meta_ads`, `facebook_ads`, `instagram_ads`, `linkedin_ads`, `tiktok_ads`, `twitter_ads`, `x_ads`, `pinterest_ads`, `snapchat_ads`, `reddit_ads`, `bing_ads`, `microsoft_ads`, `amazon_ads`, `yahoo_ads`, `quora_ads`, `outbrain`, `taboola`, `facebook`, `instagram`, `linkedin`, `pinterest`, `snapchat`, `tiktok`, `twitter`

### Analytics (11)
`google_analytics`, `mixpanel`, `amplitude`, `segment`, `heap`, `hotjar`, `fullstory`, `pendo`, `looker`, `tableau`, `datadog`

### CRM (9)
`salesforce`, `hubspot`, `pipedrive`, `zoho_crm`, `freshsales`, `microsoft_dynamics`, `insightly`, `copper`, `nimble`

### Communication (14)
`slack`, `twilio`, `sendgrid`, `mailgun`, `postmark`, `intercom`, `zendesk`, `freshdesk`, `drift`, `livechat`, `discord`, `telegram`, `whatsapp`, `teams`, `zoom`

### E-commerce (12)
`shopify`, `woocommerce`, `magento`, `bigcommerce`, `prestashop`, `opencart`, `volusion`, `ecwid`, `wix_ecommerce`, `squarespace_commerce`, `etsy`, `ebay`, `amazon_seller`

### Marketing (13)
`mailchimp`, `klaviyo`, `activecampaign`, `constant_contact`, `constantcontact`, `marketo`, `pardot`, `eloqua`, `drip`, `convertkit`, `omnisend`, `sendinblue`, `brevo`

### Workflow (8)
`zapier`, `make`, `integromat`, `n8n`, `ifttt`, `workato`, `tray`, `automate`

### Social Media (10)
`facebook`, `instagram`, `twitter`, `x`, `linkedin`, `youtube`, `tiktok`, `pinterest`, `snapchat`, `reddit`

### Accounting (10)
`quickbooks`, `xero`, `freshbooks`, `wave`, `sage`, `netsuite`, `expensify`, `bill`, `divvy`, `ramp`

### Project Management (10)
`asana`, `trello`, `monday`, `jira`, `basecamp`, `clickup`, `notion`, `airtable`, `smartsheet`, `wrike`

### Data Storage (24)
`snowflake`, `redshift`, `bigquery`, `databricks`, `azure_synapse`, `dropbox`, `google_drive`, `onedrive`, `box`, `aws_s3`, `mparticle`, `rudderstack`, `tealium`, `wordpress`, `webflow`, `contentful`, `sanity`, `algolia`, `auth0`, `okta`, `cloudflare`, `vercel`, `netlify`, `heroku`

### Developer Tools (6)
`github`, `gitlab`, `bitbucket`, `circleci`, `jenkins`, `travis_ci`

### HR & Recruiting (7)
`greenhouse`, `lever`, `workday`, `bamboohr`, `gusto`, `rippling`, `adp`

### Shipping & Logistics (7)
`shipstation`, `shippo`, `easypost`, `ups`, `fedex`, `usps`, `dhl`

---

## 🗃️ Supported Entities by Category

### Payment
- `customers`, `orders`, `transactions`, `refunds`, `payouts`

### POS
- `customers`, `products`, `orders`, `inventory`, `transactions`

### Advertising
- `campaigns`, `ad_groups`, `ads`, `keywords`, `audiences`

### Analytics
- `events`, `sessions`, `users`, `conversions`, `funnels`

### CRM
- `contacts`, `companies`, `deals`, `activities`, `tasks`

### E-commerce
- `customers`, `products`, `orders`, `inventory`, `collections`

### Marketing
- `contacts`, `lists`, `campaigns`, `automations`, `forms`

### Communication
- `messages`, `conversations`, `contacts`, `campaigns`

### Workflow
- `workflows`, `tasks`, `triggers`, `actions`

### Social
- `posts`, `comments`, `followers`, `engagement`, `stories`

### Accounting
- `invoices`, `expenses`, `customers`, `vendors`, `transactions`

### Project
- `projects`, `tasks`, `users`, `comments`, `files`

### Data
- `datasets`, `tables`, `files`, `schemas`, `queries`

### Developer
- `repositories`, `commits`, `pull_requests`, `issues`, `branches`

### HR
- `employees`, `candidates`, `jobs`, `applications`, `interviews`

### Shipping
- `shipments`, `tracking`, `rates`, `labels`, `addresses`

---

## 🔧 Common Patterns

### Pattern 1: Check Platform Support

```python
# Check if platform is supported
if registry.is_platform_supported('shopify'):
    print("✅ Shopify is supported")

# Get platform capabilities
capabilities = registry.get_platform_capabilities('shopify')
print(f"Entities: {capabilities['supported_entities']}")
```

### Pattern 2: Batch Fetch with Error Handling

```python
async def fetch_all_data(platform: str, tenant_id: str, db):
    """Fetch all supported entities from a platform"""
    try:
        adapter = registry.get_adapter(platform, tenant_id, db)

        # Get supported entities
        entities = adapter.get_supported_entities()

        results = {}
        for entity in entities:
            try:
                data = await adapter.fetch_entity(entity, limit=100)
                results[entity] = data
                print(f"✅ Fetched {len(data)} {entity}")
            except NotImplementedError:
                print(f"⏭️  {entity} not implemented yet")
            except Exception as e:
                print(f"❌ Error fetching {entity}: {e}")

        return results
    except Exception as e:
        print(f"❌ Failed to get adapter: {e}")
        return None
```

### Pattern 3: Sync with Rate Limiting

```python
async def sync_with_rate_limit(adapter, entity_type: str):
    """Fetch data with rate limit handling"""
    import asyncio

    max_retries = 3
    retry_delay = 60  # seconds

    for attempt in range(max_retries):
        try:
            data = await adapter.fetch_entity(entity_type)
            return data
        except RateLimitError as e:
            if attempt < max_retries - 1:
                print(f"⏳ Rate limited, waiting {retry_delay}s...")
                await asyncio.sleep(retry_delay)
                retry_delay *= 2  # Exponential backoff
            else:
                raise
        except Exception as e:
            print(f"❌ Error: {e}")
            raise
```

### Pattern 4: Multi-Platform Sync

```python
async def sync_multiple_platforms(tenant_id: str, db):
    """Sync data from multiple platforms"""
    platforms = ['shopify', 'stripe', 'google_ads', 'mailchimp']

    results = {}
    for platform in platforms:
        try:
            adapter = registry.get_adapter(platform, tenant_id, db)

            if await adapter.test_connection():
                # Fetch all supported entities
                for entity in adapter.get_supported_entities():
                    key = f"{platform}_{entity}"
                    results[key] = await adapter.fetch_entity(entity)
                    print(f"✅ {platform}.{entity}: {len(results[key])} records")
            else:
                print(f"⚠️  {platform} connection failed")

        except Exception as e:
            print(f"❌ Error with {platform}: {e}")

    return results
```

---

## 🛠️ Testing Commands

```bash
# Test adapter registry
python3 scripts/test_adapter_registry.py

# Generate new adapters
python3 scripts/generate_platform_adapters.py

# Check database tables
psql $DATABASE_URL -c "\dt platform_*"

# View adapter files
ls -la app/services/platform_adapters/*_adapter.py | wc -l  # Should be 195
```

---

## 📝 Adding a New Platform

1. **Add to generator script** (`scripts/generate_platform_adapters.py`):
```python
PLATFORMS = {
    'your_category': ['new_platform_name']
}
```

2. **Run generator**:
```bash
python3 scripts/generate_platform_adapters.py
```

3. **Implement adapter** (`app/services/platform_adapters/new_platform_name_adapter.py`):
```python
async def fetch_customers(self, limit=None, date_from=None, date_to=None):
    # Replace TODO with actual implementation
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{self.base_url}/customers",
            headers=self._get_headers(),
            params={"limit": limit}
        )
        return response.json()
```

4. **Test**:
```bash
python3 scripts/test_adapter_registry.py
```

5. **Deploy** - Registry auto-discovers new adapters!

---

## 🔍 Debugging

### Check if Adapter is Registered

```python
registry = get_adapter_registry()
platforms = registry.list_available_platforms()

if 'shopify' in platforms:
    print("✅ Shopify adapter is registered")
else:
    print("❌ Shopify adapter not found")
```

### Check Adapter Implementation

```python
try:
    adapter = registry.get_adapter('shopify', tenant_id, db)
    print(f"✅ Adapter created: {type(adapter)}")
    print(f"   Platform: {adapter.get_platform_name()}")
    print(f"   Entities: {adapter.get_supported_entities()}")
except Exception as e:
    print(f"❌ Error: {e}")
```

### Test Connection

```python
adapter = registry.get_adapter('shopify', tenant_id, db)
is_connected = await adapter.test_connection()

if is_connected:
    print("✅ Connection test passed")
else:
    print("❌ Connection test failed - check credentials")
```

---

## 🚨 Common Issues

### Issue: "Platform not found"
**Solution**: Check spelling - use underscore not dash (e.g., `google_ads` not `google-ads`)

### Issue: "Integration not found for tenant"
**Solution**: Ensure platform connection exists in `platform_connections` table

### Issue: "NotImplementedError"
**Solution**: Adapter method not implemented yet - add implementation or use placeholder

### Issue: "Connection test failed"
**Solution**: Verify API credentials in `platform_connections` table

---

## 📊 Database Queries

### Check Platform Connections

```sql
SELECT
    id,
    tenant_id,
    platform_name,
    connection_type,
    is_active,
    last_sync_at
FROM platform_connections
WHERE tenant_id = 'your-tenant-id'
ORDER BY platform_name;
```

### Check Sync Status

```sql
SELECT
    platform,
    entity_type,
    sync_status,
    last_successful_sync,
    performance_metrics->>'records_synced' as records_synced
FROM platform_sync_status
WHERE tenant_id = 'your-tenant-id'
ORDER BY last_successful_sync DESC;
```

### Check Rate Limits

```sql
SELECT
    platform,
    endpoint_pattern,
    current_usage,
    limit_value,
    remaining_quota,
    reset_time
FROM platform_rate_limits
WHERE tenant_id = 'your-tenant-id'
AND current_usage > (limit_value * 0.8)  -- Near limit
ORDER BY remaining_quota ASC;
```

---

## 📞 Support

- **Documentation**: `/PLATFORM_ADAPTERS_COMPLETE.md`
- **Base Adapter**: `/app/services/platform_adapters/base_adapter.py`
- **Registry**: `/app/services/platform_adapters/adapter_registry.py`
- **Test Script**: `/scripts/test_adapter_registry.py`

---

*Quick Reference v1.0 | Last Updated: January 15, 2026*
