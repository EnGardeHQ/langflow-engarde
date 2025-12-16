# EnGarde Demo - Quick Start Guide

Get up and running with EnGarde demo in under 5 minutes!

---

## Prerequisites

- Docker and Docker Compose installed
- Ports 3001 (frontend), 8000 (backend), 5432 (postgres) available

---

## Quick Start

### 1. Start the Platform

```bash
cd /Users/cope/EnGardeHQ
docker-compose up
```

Wait for all services to start (about 2-3 minutes).

### 2. Access the Platform

Open your browser and navigate to:
```
http://localhost:3001
```

### 3. Login with Demo Credentials

```
Email: demo@engarde.com
Password: demo123
```

### 4. You're In!

You should immediately see the dashboard with:
- **No "Create Brand" modal** (brands are pre-seeded)
- **Active Brand:** Demo Brand
- **Brand Selector:** Shows "Demo Brand" and "Demo E-commerce"

---

## Demo User Details

### Primary Demo User
- **Email:** demo@engarde.com
- **Password:** demo123
- **Brands:** Demo Brand, Demo E-commerce
- **Role:** Owner on both brands

### Test User
- **Email:** test@engarde.com
- **Password:** test123
- **Brand:** Test Brand
- **Purpose:** Automated testing

### Admin User
- **Email:** admin@engarde.com
- **Password:** admin123
- **Brand:** EnGarde Platform
- **Special:** Superuser privileges

### Publisher User
- **Email:** publisher@engarde.com
- **Password:** test123
- **Brand:** Publisher Network
- **Purpose:** Publisher features testing

---

## Testing Brand Features

### 1. View Brands
Click the brand selector dropdown in the top navigation to see all your brands.

### 2. Switch Brands
Select a different brand from the dropdown to switch context.

### 3. Manage Brand
Navigate to Settings → Brand to view/edit brand details.

---

## Verification

### Verify Brands Exist

```bash
cd /Users/cope/EnGardeHQ/production-backend
export PGPASSWORD=engarde_password
python3 scripts/verify_brands.py
```

Expected output:
```
✅ User found: Demo User
✅ User has 2 brand(s):
  - Demo Brand (owner, Active: True)
  - Demo E-commerce (owner, Active: True)
✅ Active brand: Demo Brand
```

---

## Troubleshooting

### Modal Still Appears?

1. **Check if brands exist:**
   ```bash
   python3 production-backend/scripts/verify_brands.py
   ```

2. **Manually seed if needed:**
   ```bash
   cd production-backend
   export PGPASSWORD=engarde_password
   psql -h localhost -U engarde_user -d engarde -f scripts/seed_demo_brands_simple.sql
   ```

3. **Clear browser cache** and try again

4. **Check backend logs:**
   ```bash
   docker logs engarde_backend
   ```

### Can't Connect to Database?

Ensure PostgreSQL is running:
```bash
docker-compose ps postgres
```

Should show status as "Up".

### Service Won't Start?

Check logs:
```bash
docker-compose logs backend
docker-compose logs frontend
docker-compose logs postgres
```

---

## Manual Seeding (If Needed)

### Option 1: SQL (Fastest)
```bash
cd production-backend
export PGPASSWORD=engarde_password
psql -h localhost -U engarde_user -d engarde -f scripts/seed_demo_brands_simple.sql
```

### Option 2: Python (Comprehensive)
```bash
cd production-backend
export DATABASE_URL="postgresql://engarde_user:engarde_password@localhost:5432/engarde"
python3 scripts/seed_demo_users_brands.py
```

### Option 3: Shell Script
```bash
cd production-backend
./scripts/quick_seed.sh
```

---

## API Testing

### Get Access Token

```bash
curl -X POST http://localhost:8000/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demo@engarde.com&password=demo123"
```

### Get Current Brand

```bash
TOKEN="<your-access-token>"
curl -X GET http://localhost:8000/api/brands/current \
  -H "Authorization: Bearer $TOKEN"
```

### List All Brands

```bash
curl -X GET http://localhost:8000/api/brands \
  -H "Authorization: Bearer $TOKEN"
```

---

## Environment Variables

Key environment variables for demo:

```bash
# Enable auto-seeding
ENVIRONMENT=development
SEED_DEMO_DATA=true

# Database
DATABASE_URL=postgresql://engarde_user:engarde_password@localhost:5432/engarde

# Tenant
DEFAULT_TENANT_ID=<your-tenant-id>
```

---

## Stopping the Platform

```bash
# Stop containers
docker-compose down

# Stop and remove volumes (full reset)
docker-compose down -v
```

---

## Development Mode

For local development without Docker:

### 1. Start Backend

```bash
cd production-backend
pip install -r requirements.txt
export DATABASE_URL="postgresql://engarde_user:engarde_password@localhost:5432/engarde"
uvicorn app.main:app --reload --port 8000
```

### 2. Start Frontend

```bash
cd production-frontend
npm install
npm run dev
```

### 3. Seed Database

```bash
cd production-backend
python3 scripts/seed_demo_users_brands.py
```

---

## Next Steps

1. **Explore the Dashboard** - View campaigns, analytics, and integrations
2. **Create a Campaign** - Test the campaign builder
3. **Switch Brands** - Experience multi-brand management
4. **Invite Team Members** - Test collaboration features
5. **Connect Integrations** - Link Google Ads, Meta, LinkedIn

---

## Documentation

- **Full Guide:** `/production-backend/DEMO_USERS_AND_BRANDS.md`
- **Implementation Summary:** `/BRAND_SEEDING_FIX_SUMMARY.md`
- **API Reference:** `/production-backend/BRAND_API_QUICK_REFERENCE.md`
- **Test Users Guide:** `/TEST_USERS.md`

---

## Support

Need help?

1. Check the troubleshooting section above
2. Review full documentation
3. Check logs: `docker-compose logs -f`
4. Run verification: `python3 scripts/verify_brands.py`

---

**Happy Testing!** 🚀

*Last Updated: October 6, 2025*
