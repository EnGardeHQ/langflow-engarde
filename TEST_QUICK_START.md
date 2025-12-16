# Test Suite Quick Start Guide

**Fast reference for running the comprehensive authentication and brand management tests.**

---

## Quick Commands

### Run All Tests (Recommended)

```bash
# Make script executable (first time only)
chmod +x /Users/cope/EnGardeHQ/scripts/run-all-tests.sh

# Run all tests
/Users/cope/EnGardeHQ/scripts/run-all-tests.sh
```

### Run Backend Tests Only

```bash
cd /Users/cope/EnGardeHQ/production-backend

# Authentication tests
pytest tests/test_auth_comprehensive.py -v --cov

# Brand tests
pytest tests/test_brands_comprehensive.py -v --cov

# Both with coverage
pytest tests/test_auth_comprehensive.py tests/test_brands_comprehensive.py \
  --cov=app.routers.zerodb_auth \
  --cov=app.services.zerodb_auth \
  --cov=app.routers.brands \
  --cov=app.models.brand_models \
  --cov-report=html \
  --cov-report=term
```

### Run Frontend Tests Only

```bash
cd /Users/cope/EnGardeHQ/production-frontend

# All tests with coverage
npm test -- --coverage

# Auth tests only
npm test -- auth-comprehensive.test.tsx

# Brand tests only
npm test -- brands-comprehensive.test.tsx
```

### Run E2E Tests Only

```bash
cd /Users/cope/EnGardeHQ/production-frontend

# Make sure backend is running first
# docker-compose up -d

# Run E2E tests
npx playwright test e2e/auth-brand-integration.spec.ts

# With UI mode
npx playwright test --ui

# Headed mode (see browser)
npx playwright test --headed
```

---

## View Coverage Reports

### Backend Coverage

```bash
# Open in browser
open /Users/cope/EnGardeHQ/production-backend/coverage/auth-html/index.html
open /Users/cope/EnGardeHQ/production-backend/coverage/brand-html/index.html
```

### Frontend Coverage

```bash
# Open in browser
open /Users/cope/EnGardeHQ/production-frontend/coverage/lcov-report/index.html
```

### E2E Test Report

```bash
# Open Playwright report
npx playwright show-report
```

---

## Test File Locations

```
Backend Tests:
  /Users/cope/EnGardeHQ/production-backend/tests/test_auth_comprehensive.py
  /Users/cope/EnGardeHQ/production-backend/tests/test_brands_comprehensive.py

Frontend Tests:
  /Users/cope/EnGardeHQ/production-frontend/__tests__/auth-comprehensive.test.tsx
  /Users/cope/EnGardeHQ/production-frontend/__tests__/brands-comprehensive.test.tsx

E2E Tests:
  /Users/cope/EnGardeHQ/production-frontend/e2e/auth-brand-integration.spec.ts
```

---

## Prerequisites

### Backend Tests
- Python 3.11+
- PostgreSQL running (docker-compose up -d postgres)
- Dependencies installed (pip install -r requirements.txt)
- pytest installed (pip install pytest pytest-cov)

### Frontend Tests
- Node.js 20+
- Dependencies installed (npm ci)
- Jest and React Testing Library included

### E2E Tests
- Backend running on http://localhost:8000
- Frontend running on http://localhost:3001
- Playwright installed (npx playwright install)

---

## Common Test Patterns

### Run Specific Test

```bash
# Backend
pytest tests/test_auth_comprehensive.py::TestPasswordHashing::test_hash_password -v

# Frontend
npm test -- -t "should successfully login"

# E2E
npx playwright test -g "should successfully login"
```

### Run in Watch Mode

```bash
# Frontend only
npm test -- --watch
```

### Debug Tests

```bash
# Backend
pytest tests/test_auth_comprehensive.py --pdb

# Frontend
npm test -- --no-coverage

# E2E
npx playwright test --debug
```

---

## Test Coverage Breakdown

### Backend Authentication (test_auth_comprehensive.py)
- **100+ tests** covering:
  - Password hashing (bcrypt)
  - JWT token generation/validation
  - Login flows
  - Auth middleware
  - Token refresh
  - ZeroDB integration
  - Rate limiting
  - Security

### Backend Brands (test_brands_comprehensive.py)
- **100+ tests** covering:
  - Brand CRUD operations
  - Brand switching
  - Permissions & access control
  - Slug generation
  - Demo data seeding
  - Multi-tenant isolation
  - Validation

### Frontend Auth (auth-comprehensive.test.tsx)
- **60+ tests** covering:
  - Login form behavior
  - Error handling
  - Token storage
  - Token refresh
  - Logout flow
  - Route guards
  - Context state

### Frontend Brands (brands-comprehensive.test.tsx)
- **60+ tests** covering:
  - Brand modal
  - Brand selection
  - Brand switching
  - Brand creation
  - BrandGuard component
  - Context state
  - API integration

### E2E Integration (auth-brand-integration.spec.ts)
- **40+ tests** covering:
  - Full login flow
  - Brand selection journey
  - Token refresh during session
  - Error recovery
  - Logout
  - Session persistence
  - Performance

---

## Troubleshooting

### Backend Tests Fail

**Database Connection:**
```bash
# Start PostgreSQL
docker-compose up -d postgres

# Check connection
psql -h localhost -U engarde_user -d engarde
```

**Import Errors:**
```bash
# Reinstall dependencies
cd production-backend
pip install -r requirements.txt
pip install pytest pytest-cov pytest-asyncio
```

### Frontend Tests Timeout

**Increase Timeout:**
```javascript
// In test file
jest.setTimeout(30000)
```

**Clear Cache:**
```bash
cd production-frontend
npm test -- --clearCache
```

### E2E Tests Can't Connect

**Check Servers:**
```bash
# Backend
curl http://localhost:8000/docs

# Frontend
curl http://localhost:3001
```

**Start Servers:**
```bash
# Backend
cd /Users/cope/EnGardeHQ
docker-compose up -d

# Frontend
cd production-frontend
npm run dev
```

---

## CI/CD

Tests run automatically on:
- Push to main/develop/staging
- Pull requests
- Daily at 6 AM UTC

**View Results:**
- GitHub Actions: Repository → Actions tab
- Coverage: https://codecov.io (if configured)

---

## Need Help?

1. Check [TEST_SUITE_DOCUMENTATION.md](/Users/cope/EnGardeHQ/TEST_SUITE_DOCUMENTATION.md)
2. Review test output for specific errors
3. Check logs: `docker logs engarde_backend`
4. Verify environment variables
5. Create GitHub issue with `[testing]` label

---

## Test Statistics

```
Total Test Files:     5
Total Test Cases:     350+
Backend Coverage:     100% (target)
Frontend Coverage:    100% (target)
E2E Scenarios:        40+
Avg Execution Time:   ~5 minutes
```

---

**Last Updated:** October 6, 2025
