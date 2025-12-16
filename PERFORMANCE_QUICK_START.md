# Performance Quick Start Guide
**Target: 100% Faster Page Loads in 6 Weeks**

## TL;DR

This guide provides immediate actionable steps to start performance optimization. See `PERFORMANCE_IMPLEMENTATION_ROADMAP.md` for full details.

---

## Week 1: Quick Wins (35-40% improvement)

### Day 1-2: Database Indexes

```bash
cd /Users/cope/EnGardeHQ/production-backend

# Create migration
alembic revision -m "add_performance_indexes"

# Add indexes to migration file (see roadmap Section 2.1)
# Run migration
alembic upgrade head

# Verify indexes created
psql -d engarde_db -c "\di"
```

**Expected Impact:** 15-20% overall improvement

---

### Day 2-3: Image Optimization

```bash
cd /Users/cope/EnGardeHQ/production-frontend

# Install sharp-cli
npm install -g sharp-cli

# Run optimization script (create from roadmap Section 2.2)
chmod +x scripts/optimize-images.sh
./scripts/optimize-images.sh

# Verify savings
du -sh public/*.{png,webp}
```

**Expected Impact:** 8-10% overall improvement

---

### Day 3-4: Font Optimization

```bash
# Reduce font variants from 37 to 4 essential weights
# Edit: /Users/cope/EnGardeHQ/production-frontend/app/fonts.ts
# See roadmap Section 2.3 for implementation

# Subset fonts (optional but recommended)
pip install fonttools brotli
./scripts/subset-fonts.sh
```

**Expected Impact:** 6-8% overall improvement

---

### Day 4-5: React Query & Pagination

```bash
# Already optimized in lib/react-query.ts ✓
# Add pagination to campaigns endpoint
# Edit: /Users/cope/EnGardeHQ/production-backend/app/routers/campaigns.py
# See roadmap Section 2.5
```

**Expected Impact:** 10-13% overall improvement

---

## Week 2-3: Medium Effort (30-35% improvement)

### Priority Actions:

1. **Split Landing Page** (Day 6-8)
   - Break 1,083-line component into 6 smaller components
   - Implement lazy loading with Suspense
   - Expected: 10-12% improvement

2. **Fix N+1 Queries** (Day 8-10)
   - Add eager loading with `selectinload()` and `joinedload()`
   - Implement DataLoader pattern for batch queries
   - Expected: 12-15% improvement

3. **Auth Caching** (Day 10-12)
   - Add Redis caching to auth endpoints
   - Expected: 5-7% improvement

4. **Modal Lazy Loading** (Day 12-14)
   - Already implemented in dashboard.tsx ✓
   - Expected: 3-5% improvement

---

## Week 4-6: Advanced (25-30% improvement)

### Priority Actions:

1. **Bundle Optimization** (Day 15-18)
   - Configure webpack code splitting
   - Tree shake Chakra UI
   - Expected: 8-10% improvement

2. **Provider Refactor** (Day 18-22)
   - Consolidate 6 nested providers into 1
   - Expected: 4-6% improvement

3. **Virtual Scrolling** (Day 22-25)
   - Implement for large lists (1000+ items)
   - Expected: 5-7% improvement

4. **Service Worker + CDN** (Day 25-30)
   - Add offline caching
   - Integrate CDN for assets
   - Expected: 8-13% improvement

---

## Measurement Commands

### Before Starting

```bash
cd /Users/cope/EnGardeHQ/production-frontend

# Install performance tools
npm install --save-dev lighthouse chrome-launcher

# Run baseline test
npm run test:performance -- --baseline

# OR use Lighthouse directly
lighthouse http://localhost:3003 --view
```

### After Each Phase

```bash
# Run comparison test
npm run test:performance -- --compare baseline

# Analyze bundle
ANALYZE=true npm run build
```

---

## Key Metrics to Track

| Metric | Baseline | Target | Current |
|--------|----------|--------|---------|
| FCP | 2.5s | 1.2s | _____ |
| LCP | 4.2s | 2.1s | _____ |
| TTI | 5.8s | 2.9s | _____ |
| Bundle | 1.0GB | 250MB | _____ |
| Auth API | 400ms | <150ms | _____ |
| Campaign List | 1200ms | <300ms | _____ |
| Dashboard | 2500ms | <500ms | _____ |

---

## Quick Wins Checklist

- [ ] Day 1-2: Database indexes created
- [ ] Day 2-3: Images optimized to WebP/AVIF
- [ ] Day 3-4: Fonts reduced and subsetted
- [ ] Day 4-5: Pagination implemented
- [ ] Day 5: Performance baseline measured
- [ ] Week 1 Complete: 35-40% improvement ✓

---

## Rollback Commands

```bash
# Database indexes
alembic downgrade -1

# Code changes
git revert <commit-hash>

# Environment rollback
export ENABLE_VIRTUAL_SCROLLING=false
export ENABLE_LAZY_MODALS=false
```

---

## Monitoring Setup

```bash
# Check DataDog (already configured)
# Monitor these alerts:
# - API response time > 1s
# - Error rate > 1%
# - Database query time > 500ms

# Add Web Vitals reporting (already in codebase)
# Check: /components/performance-monitor.tsx
```

---

## Need Help?

- Full roadmap: `PERFORMANCE_IMPLEMENTATION_ROADMAP.md`
- Code examples: See roadmap sections 2-4
- Architecture diagram: `docs/architecture/`
- Team Slack: #performance-optimization

---

## Success Criteria

**Phase 1 Complete:**
- ✓ All database indexes created
- ✓ Images < 100KB total
- ✓ Fonts < 500KB total
- ✓ Pagination working
- ✓ 35-40% improvement measured

**Phase 2 Complete:**
- ✓ Landing page split into components
- ✓ N+1 queries eliminated
- ✓ Auth caching implemented
- ✓ 65-75% cumulative improvement

**Phase 3 Complete:**
- ✓ Bundle < 300MB
- ✓ Service worker active
- ✓ CDN integrated
- ✓ 90-105% cumulative improvement (TARGET MET!)

---

**Last Updated:** 2025-11-03
**Quick Start Guide Version:** 1.0
