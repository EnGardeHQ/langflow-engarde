# SignUp_Sync Microservice & En Garde Platform User - Implementation Guide

**Created:** January 19, 2026
**Status:** Phase 1 & 2 Complete - Backend & Database
**Remaining:** Background Scheduler + Frontend Components

---

## 📋 Overview

This implementation adds two major features to En Garde:

### 1. **SignUp_Sync Microservice**
A dedicated microservice that syncs funnel data from multiple sources (EasyAppointments, Zoom, Eventbrite, Posh.VIP, etc.) into En Garde's database for comprehensive marketing funnel tracking.

### 2. **En Garde as Platform User**
Allows En Garde to use its own platform as a special user with unlimited usage, managed by superusers and designated admins who can track AI token usage and BigQuery storage across all users.

---

## ✅ What's Been Implemented

### Phase 1: Database Models & Schema

#### Funnel Tracking Models
**Location:** `/production-backend/app/models/funnel_models.py`

- ✅ `FunnelSource` - Configuration for each funnel source (EasyAppointments, Zoom, etc.)
- ✅ `FunnelEvent` - Individual funnel events (lead captured, appointment booked, etc.)
- ✅ `FunnelConversion` - Tracks successful conversions from lead to platform user
- ✅ `FunnelSyncLog` - Logs for sync operations

**Key Features:**
- Support for 7 funnel source types (EasyAppointments, Zoom, Eventbrite, Posh.VIP, Manual, Referral, Direct Signup)
- 11 event types tracking full user journey
- First-touch and last-touch attribution
- UTM parameter tracking
- External system ID linking

#### Platform User Models
**Location:** `/production-backend/app/models/platform_models.py`

- ✅ `PlatformBrand` - En Garde's internal brands
- ✅ `AdminUsageReport` - Pre-aggregated usage reports for fast admin queries
- ✅ `PlatformAdminAction` - Audit log for platform admin actions
- ✅ `TenantHealthMetrics` - Daily health metrics per tenant

**Key Features:**
- Unlimited usage tracking (track but don't limit)
- Demo and template brand flags
- Multiple aggregation levels (tenant, user, organization)
- Provider and model-level breakdowns

### Phase 2: Platform User Seed Data
**Location:** `/production-backend/migrations/20260119_seed_platform_user.sql`

- ✅ Creates "En Garde Platform" organization
- ✅ Creates "En Garde Admin" tenant with unlimited quotas
- ✅ Creates platform superuser: `admin@engarde.platform`
- ✅ Creates EasyAppointments funnel source
- ✅ Sets up proper roles and permissions

**IMPORTANT SECURITY NOTES:**
- Default password: `EnGardePlatform2026!SecurePassword`
- **MUST BE CHANGED** immediately after deployment
- Enable 2FA for platform user
- This user has full superuser privileges

### Phase 3: SignUp_Sync Microservice
**Location:** `/signup-sync-service/`

#### Files Created:
```
signup-sync-service/
├── app/
│   ├── main.py                          ✅ FastAPI app with all endpoints
│   ├── models/
│   │   ├── sync_request.py              ✅ Request/response models
│   │   └── health.py                    ✅ Health check models
│   ├── services/
│   │   └── funnel_sync_service.py       ✅ Core sync logic
│   ├── database/
│   │   └── connection.py                ✅ DB connection to En Garde
│   └── auth/
│       └── verify.py                    ✅ Service token verification
```

#### Endpoints Implemented:
- `POST /sync/easyappointments` - Sync EasyAppointments
- `POST /sync/zoom` - Sync Zoom
- `POST /sync/eventbrite` - Sync Eventbrite
- `POST /sync/poshvip` - Sync Posh.VIP
- `POST /sync/all` - Sync all sources
- `GET /sync/status/{source_type}` - Get sync status
- `POST /funnel/event` - Track funnel event
- `POST /funnel/conversion` - Mark lead as converted
- `GET /analytics/funnel-metrics` - Get funnel analytics

### Phase 4: Admin API Endpoints
**Location:** `/production-backend/app/routers/`

#### Platform Brands API (`admin_platform_brands.py`)
- ✅ `GET /api/admin/platform/brands` - List all En Garde brands with usage stats
- ✅ `POST /api/admin/platform/brands` - Create new En Garde brand
- ✅ `GET /api/admin/platform/brands/{brand_id}/usage` - Detailed usage for specific brand

#### Platform Usage API (`admin_platform_usage.py`)
- ✅ `GET /api/admin/platform/usage/users` - Platform-wide user usage
- ✅ `GET /api/admin/platform/usage/tenants` - Platform-wide tenant usage
- ✅ `GET /api/admin/platform/usage/export` - Export usage data (placeholder)

**Key Features:**
- Flexible view modes: realtime, daily, monthly
- Filters by plan tier, date range
- Pagination support
- Platform vs customer usage split
- Model-level breakdown

---

## 🚧 What Needs to Be Completed

### Phase 5: Background Scheduler (Backend)
**Priority:** HIGH
**Estimated Effort:** 2-3 hours

#### Tasks:
1. **Create Scheduler Service**
   - File: `/production-backend/app/services/funnel_sync_scheduler.py`
   - Use APScheduler (already used for logo cache)
   - Schedule daily sync at configurable time

2. **Integrate with Main App**
   - Update `/production-backend/app/main.py`
   - Initialize scheduler on app startup
   - Add shutdown handler

3. **Environment Configuration**
   - Add `FUNNEL_SYNC_ENABLED=true`
   - Add `FUNNEL_SYNC_TIME=18:30` (6:30 PM UTC)
   - Add `SIGNUP_SYNC_SERVICE_URL=https://signup-sync.railway.app`
   - Add `SIGNUP_SYNC_SERVICE_TOKEN=<secure_random_token>`

#### Example Scheduler Code:
```python
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
import httpx

class FunnelSyncScheduler:
    def __init__(self):
        self.scheduler = AsyncIOScheduler()
        self.service_url = os.getenv("SIGNUP_SYNC_SERVICE_URL")
        self.service_token = os.getenv("SIGNUP_SYNC_SERVICE_TOKEN")

    async def sync_all_funnels(self):
        """Trigger sync for all funnel sources"""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.service_url}/sync/all",
                headers={"Authorization": f"Bearer {self.service_token}"}
            )
            logger.info(f"Funnel sync completed: {response.status_code}")

    def start(self):
        # Schedule daily at 6:30 PM UTC
        self.scheduler.add_job(
            self.sync_all_funnels,
            CronTrigger(hour=18, minute=30),
            id="funnel_sync_daily"
        )
        self.scheduler.start()
```

### Phase 6: Admin Dashboard Frontend (Frontend)
**Priority:** HIGH
**Estimated Effort:** 4-6 hours

#### Task 1: Add "En Garde Brands" Section to Main Dashboard
**File:** `/production-frontend/app/admin/page.tsx`

Add after line 382 (after EasyAppointments card):

```tsx
{/* En Garde Platform Brands */}
<Card bg={cardBg} shadow="sm">
    <CardBody>
        <HStack spacing={4} mb={4}>
            <Box p={3} bg="indigo.100" borderRadius="lg" color="indigo.600">
                <Icon as={Building2} boxSize="6" />
            </Box>
            <VStack align="start" spacing={0}>
                <Text color="gray.500" fontSize="sm">En Garde Brands</Text>
                <Heading size="md">{platformBrandsCount || 0}</Heading>
            </VStack>
        </HStack>
        <Text fontSize="sm" color="gray.600" mb={4}>
            Platform brands with unlimited usage tracking
        </Text>
        <Button
            size="sm"
            colorScheme="indigo"
            variant="outline"
            onClick={() => router.push('/admin/engarde-brands')}
            width="full"
        >
            Manage Platform Brands
        </Button>
    </CardBody>
</Card>
```

**Required State:**
```tsx
const [platformBrandsCount, setPlatformBrandsCount] = useState<number>(0);

// In useEffect, add:
const platformBrandsRes = await apiClient.get('/admin/platform/brands');
if (platformBrandsRes.success) {
    setPlatformBrandsCount(platformBrandsRes.data.total_count);
}
```

#### Task 2: Create En Garde Brands Management Page
**File:** `/production-frontend/app/admin/engarde-brands/page.tsx`

```tsx
'use client';

import { useState, useEffect } from 'react';
import {
    Box, Container, Heading, Button, Table, Thead, Tbody,
    Tr, Th, Td, Badge, useToast, Modal, ModalOverlay,
    ModalContent, ModalHeader, ModalBody, ModalFooter,
    FormControl, FormLabel, Input, Textarea, Checkbox,
    Select, useDisclosure
} from '@chakra-ui/react';
import { Header } from '@/components/layout/header';
import { SidebarNav } from '@/components/layout/sidebar-nav';
import { apiClient } from '@/lib/api/client';

export default function EnGardeBrandsPage() {
    const [brands, setBrands] = useState([]);
    const [loading, setLoading] = useState(true);
    const { isOpen, onOpen, onClose } = useDisclosure();
    const toast = useToast();

    const fetchBrands = async () => {
        try {
            const response = await apiClient.get('/admin/platform/brands');
            if (response.success) {
                setBrands(response.data.brands);
            }
        } catch (error) {
            toast({
                title: 'Error',
                description: 'Failed to load platform brands',
                status: 'error',
            });
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchBrands();
    }, []);

    return (
        <Box minH="100vh">
            <Header />
            <Container maxW="container.xl" py={10}>
                <Heading mb={6}>En Garde Platform Brands</Heading>

                <Button colorScheme="blue" onClick={onOpen} mb={4}>
                    Create New Brand
                </Button>

                <Table variant="simple">
                    <Thead>
                        <Tr>
                            <Th>Brand Name</Th>
                            <Th>Purpose</Th>
                            <Th>Type</Th>
                            <Th>LLM Tokens</Th>
                            <Th>Storage (GB)</Th>
                            <Th>Total Cost</Th>
                            <Th>Actions</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {brands.map((brand) => (
                            <Tr key={brand.id}>
                                <Td>{brand.brand_name}</Td>
                                <Td>{brand.purpose || '-'}</Td>
                                <Td>
                                    {brand.is_demo && <Badge colorScheme="purple">Demo</Badge>}
                                    {brand.is_template && <Badge colorScheme="green">Template</Badge>}
                                </Td>
                                <Td>{brand.total_llm_tokens.toLocaleString()}</Td>
                                <Td>{brand.total_bigquery_storage_gb}</Td>
                                <Td>${brand.total_cost_usd.toFixed(2)}</Td>
                                <Td>
                                    <Button size="sm" variant="link">View Details</Button>
                                </Td>
                            </Tr>
                        ))}
                    </Tbody>
                </Table>
            </Container>

            {/* Create Brand Modal */}
            {/* TODO: Implement create brand modal */}
        </Box>
    );
}
```

#### Task 3: Create Platform Usage Tracking Page
**File:** `/production-frontend/app/admin/platform-usage/page.tsx`

```tsx
'use client';

import { useState, useEffect } from 'react';
import {
    Box, Container, Heading, Select, Button, Table,
    Thead, Tbody, Tr, Th, Td, HStack, Text, Badge,
    Card, CardBody, SimpleGrid, Stat, StatLabel,
    StatNumber, StatHelpText
} from '@chakra-ui/react';
import { Header } from '@/components/layout/header';
import { apiClient } from '@/lib/api/client';

export default function PlatformUsagePage() {
    const [viewMode, setViewMode] = useState('daily');
    const [usage, setUsage] = useState(null);
    const [loading, setLoading] = useState(true);

    const fetchUsage = async () => {
        try {
            const response = await apiClient.get('/admin/platform/usage/users', {
                params: { view_mode: viewMode }
            });
            if (response.success) {
                setUsage(response.data);
            }
        } catch (error) {
            console.error('Failed to load usage:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchUsage();
    }, [viewMode]);

    return (
        <Box minH="100vh">
            <Header />
            <Container maxW="container.xl" py={10}>
                <HStack justify="space-between" mb={6}>
                    <Heading>Platform-Wide Usage</Heading>
                    <Select w="200px" value={viewMode} onChange={(e) => setViewMode(e.target.value)}>
                        <option value="realtime">Real-time</option>
                        <option value="daily">Daily</option>
                        <option value="monthly">Monthly</option>
                    </Select>
                </HStack>

                {/* Summary Stats */}
                <SimpleGrid columns={4} spacing={6} mb={8}>
                    <Card>
                        <CardBody>
                            <Stat>
                                <StatLabel>Total LLM Tokens</StatLabel>
                                <StatNumber>{usage?.total_llm_tokens.toLocaleString()}</StatNumber>
                                <StatHelpText>${usage?.total_llm_cost_usd.toFixed(2)}</StatHelpText>
                            </Stat>
                        </CardBody>
                    </Card>
                    <Card>
                        <CardBody>
                            <Stat>
                                <StatLabel>BigQuery Storage</StatLabel>
                                <StatNumber>{usage?.total_bigquery_storage_gb.toFixed(2)} GB</StatNumber>
                            </Stat>
                        </CardBody>
                    </Card>
                    <Card>
                        <CardBody>
                            <Stat>
                                <StatLabel>Platform Usage</StatLabel>
                                <StatNumber>${usage?.platform_usage_usd.toFixed(2)}</StatNumber>
                                <StatHelpText>En Garde Brands</StatHelpText>
                            </Stat>
                        </CardBody>
                    </Card>
                    <Card>
                        <CardBody>
                            <Stat>
                                <StatLabel>Customer Usage</StatLabel>
                                <StatNumber>${usage?.customer_usage_usd.toFixed(2)}</StatNumber>
                                <StatHelpText>All Customer Brands</StatHelpText>
                            </Stat>
                        </CardBody>
                    </Card>
                </SimpleGrid>

                {/* Usage Table */}
                <Table variant="simple">
                    <Thead>
                        <Tr>
                            <Th>User</Th>
                            <Th>Tenant</Th>
                            <Th>Plan</Th>
                            <Th>LLM Tokens</Th>
                            <Th>Storage (GB)</Th>
                            <Th>Total Cost</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {usage?.users.map((user) => (
                            <Tr key={user.user_id}>
                                <Td>{user.email}</Td>
                                <Td>{user.tenant_name}</Td>
                                <Td><Badge>{user.plan_tier}</Badge></Td>
                                <Td>{user.llm_tokens.toLocaleString()}</Td>
                                <Td>{user.bigquery_storage_gb}</Td>
                                <Td>${user.total_cost_usd.toFixed(2)}</Td>
                            </Tr>
                        ))}
                    </Tbody>
                </Table>
            </Container>
        </Box>
    );
}
```

#### Task 4: Add API Client Functions
**File:** `/production-frontend/lib/api/admin.ts`

Add these functions:

```typescript
// Platform Brands
export async function getPlatformBrands() {
    return apiClient.get('/admin/platform/brands');
}

export async function createPlatformBrand(brandData: any) {
    return apiClient.post('/admin/platform/brands', brandData);
}

export async function getPlatformBrandUsage(brandId: string) {
    return apiClient.get(`/admin/platform/brands/${brandId}/usage`);
}

// Platform Usage
export async function getPlatformUsage(viewMode: string, filters?: any) {
    return apiClient.get('/admin/platform/usage/users', {
        params: { view_mode: viewMode, ...filters }
    });
}

export async function exportPlatformUsage(format: string = 'csv') {
    return apiClient.get('/admin/platform/usage/export', {
        params: { format }
    });
}
```

---

## 📦 Deployment Checklist

### Database Migrations
```bash
# 1. Run funnel models migration
cd /Users/cope/EnGardeHQ/production-backend
psql $DATABASE_URL -f migrations/20260119_seed_platform_user.sql

# 2. Verify tables created
psql $DATABASE_URL -c "\dt funnel*"
psql $DATABASE_URL -c "\dt platform*"

# 3. Verify platform user created
psql $DATABASE_URL -c "SELECT * FROM users WHERE email = 'admin@engarde.platform';"
```

### SignUp_Sync Microservice Deployment

#### Option 1: Railway (Recommended)
```bash
cd /Users/cope/EnGardeHQ/signup-sync-service

# Create requirements.txt
cat > requirements.txt <<EOF
fastapi==0.109.0
uvicorn[standard]==0.27.0
sqlalchemy==2.0.25
psycopg2-binary==2.9.9
pydantic==2.5.3
httpx==0.26.0
python-dotenv==1.0.0
EOF

# Create railway.json
cat > railway.json <<EOF
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port $PORT",
    "healthcheckPath": "/health",
    "healthcheckTimeout": 100
  }
}
EOF

# Deploy to Railway
railway link
railway up
railway variables set ENGARDE_DATABASE_URL=$DATABASE_PUBLIC_URL
railway variables set SIGNUP_SYNC_SERVICE_TOKEN=$(openssl rand -hex 32)
```

#### Option 2: Docker
```bash
# Create Dockerfile
cat > Dockerfile <<EOF
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app /app/app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
EOF

# Build and run
docker build -t signup-sync-service .
docker run -p 8001:8001 -e ENGARDE_DATABASE_URL=$DATABASE_URL signup-sync-service
```

### Backend API Routes Registration
**File:** `/production-backend/app/main.py`

Add these lines to register new routers:

```python
from app.routers import admin_platform_brands, admin_platform_usage

# ... existing code ...

# Register new routers
app.include_router(admin_platform_brands.router)
app.include_router(admin_platform_usage.router)
```

### Environment Variables
Add to production environment:

```bash
# Platform User
PLATFORM_USER_EMAIL=admin@engarde.platform
PLATFORM_TENANT_ID=00000000-0000-0000-0000-000000000002

# SignUp_Sync Service
SIGNUP_SYNC_SERVICE_URL=https://signup-sync.railway.app
SIGNUP_SYNC_SERVICE_TOKEN=<secure_random_token>
FUNNEL_SYNC_ENABLED=true
FUNNEL_SYNC_TIME=18:30

# EasyAppointments Integration
EASYAPPOINTMENTS_URL=https://scheduler.engarde.media
EASYAPPOINTMENTS_API_KEY=<api_key_if_needed>
```

---

## 🧪 Testing

### Test Platform User
```bash
# 1. Login as platform user
curl -X POST https://api.engarde.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@engarde.platform", "password": "EnGardePlatform2026!SecurePassword"}'

# 2. Create a platform brand
curl -X POST https://api.engarde.app/api/admin/platform/brands \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "brand_name": "En Garde Demo Brand",
    "purpose": "For product demos and screenshots",
    "is_demo": true
  }'
```

### Test Funnel Sync
```bash
# 1. Manually trigger EasyAppointments sync
curl -X POST https://signup-sync.railway.app/sync/easyappointments \
  -H "Authorization: Bearer $SIGNUP_SYNC_SERVICE_TOKEN"

# 2. Check sync status
curl https://signup-sync.railway.app/sync/status/easyappointments \
  -H "Authorization: Bearer $SIGNUP_SYNC_SERVICE_TOKEN"

# 3. Track a test funnel event
curl -X POST https://signup-sync.railway.app/funnel/event \
  -H "Authorization: Bearer $SIGNUP_SYNC_SERVICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "source_type": "easyappointments",
    "event_type": "appointment_booked",
    "email": "test@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "event_data": {"service": "Demo Consultation"}
  }'
```

### Test Usage Tracking
```bash
# Get platform-wide usage
curl "https://api.engarde.app/api/admin/platform/usage/users?view_mode=daily" \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Get specific brand usage
curl "https://api.engarde.app/api/admin/platform/brands/$BRAND_ID/usage" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

---

## 📊 Monitoring & Metrics

### Key Metrics to Track

1. **Funnel Performance**
   - Leads captured per source
   - Conversion rate by source
   - Time to conversion
   - Funnel drop-off points

2. **Platform Usage**
   - Total LLM tokens used
   - BigQuery storage growth
   - Cost per brand
   - Platform vs customer usage split

3. **System Health**
   - SignUp_Sync service uptime
   - Sync success rate
   - Database connection pool
   - API response times

---

## 🔒 Security Considerations

1. **Service Token Security**
   - Generate strong random tokens (32+ bytes)
   - Rotate tokens quarterly
   - Never commit tokens to git
   - Use environment variables only

2. **Platform User Access**
   - Change default password immediately
   - Enable 2FA
   - Limit access to designated admins only
   - Audit all platform admin actions

3. **Data Privacy**
   - PII in funnel events (encrypt if needed)
   - GDPR compliance for funnel tracking
   - Data retention policies
   - Right to deletion

---

## 📚 Next Steps

### Immediate (This Week)
1. ✅ Database migrations
2. ✅ Deploy SignUp_Sync microservice to Railway
3. ⏳ Complete background scheduler
4. ⏳ Build frontend pages

### Short Term (Next 2 Weeks)
1. Implement EasyAppointments API integration (replace placeholder)
2. Add Zoom, Eventbrite, Posh.VIP integrations
3. Build conversion tracking webhooks
4. Add funnel analytics dashboard

### Long Term (Next Month)
1. AI-powered funnel insights (like EasyAppointments insights)
2. Predictive lead scoring
3. Automated nurture campaigns for funnel leads
4. Multi-touch attribution modeling

---

## 🆘 Troubleshooting

### Common Issues

**Problem:** Platform user can't login
**Solution:** Check if password hash is correct, ensure user has `is_active=true` and `is_superuser=true`

**Problem:** SignUp_Sync service can't connect to database
**Solution:** Verify `ENGARDE_DATABASE_URL` is set correctly and database accepts external connections

**Problem:** Funnel events not showing up
**Solution:** Check `funnel_sources` table has active sources, verify service token is valid

**Problem:** Usage metrics show 0
**Solution:** Run `admin_usage_reports` aggregation job, verify `usage_metrics` table has data

---

## 📞 Support

For questions or issues:
1. Check this guide first
2. Review database schema in model files
3. Check API endpoint documentation
4. Test with curl commands above

---

**END OF IMPLEMENTATION GUIDE**
