# Setup Wizard Architecture & Integration Guide

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Frontend (Next.js)                              │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                    SetupWizard Component                        │    │
│  │                                                                  │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │    │
│  │  │ Path Select  │→ │ Questionnaire│→ │   Progress   │         │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘         │    │
│  │                                              ↓                  │    │
│  │                                       ┌──────────────┐         │    │
│  │                                       │Results Review│         │    │
│  │                                       └──────────────┘         │    │
│  │                                              ↓                  │    │
│  │                                       ┌──────────────┐         │    │
│  │                                       │ Confirmation │         │    │
│  │                                       └──────────────┘         │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                     State Management                            │    │
│  │  • React Query (API cache)                                      │    │
│  │  • localStorage (wizard state)                                  │    │
│  │  • useState (component state)                                   │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                     API Integration                             │    │
│  │                                                                  │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │    │
│  │  │ React Query  │  │  WebSocket   │  │  apiClient   │         │    │
│  │  │   Hooks      │  │  useAnalysis │  │  (Axios)     │         │    │
│  │  │              │  │  Progress    │  │              │         │    │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │    │
│  └─────────┼──────────────────┼──────────────────┼─────────────────┘    │
│            │                  │                  │                      │
│            │    HTTP/HTTPS    │    WebSocket     │                      │
│            ▼                  ▼                  ▼                      │
└─────────────────────────────────────────────────────────────────────────┘
             │                  │                  │
             │                  │                  │
┌────────────┼──────────────────┼──────────────────┼─────────────────────┐
│            │                  │                  │                      │
│            │                  │                  │    Backend API       │
│            ▼                  ▼                  ▼                      │
│  ┌──────────────────────────────────────────────────────────┐         │
│  │               API Gateway / Load Balancer                 │         │
│  └──────────────────────────────────────────────────────────┘         │
│                                                                         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐       │
│  │ REST Endpoints  │  │ WebSocket Server│  │  Job Queue      │       │
│  │                 │  │                 │  │  (Redis/Bull)   │       │
│  │ /initiate       │  │ /ws/analysis/   │  │                 │       │
│  │ /status         │  │ {jobId}         │  │  • Pending      │       │
│  │ /results        │  │                 │  │  • Processing   │       │
│  │ /confirm        │  │ Broadcasts:     │  │  • Complete     │       │
│  │                 │  │ • Progress %    │  │  • Failed       │       │
│  │                 │  │ • Current step  │  │                 │       │
│  │                 │  │ • Messages      │  │                 │       │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘       │
│           │                    │                     │                 │
│           └────────────────────┼─────────────────────┘                 │
│                                │                                       │
│                                ▼                                       │
│  ┌──────────────────────────────────────────────────────────┐         │
│  │              En Garde Integration Service                 │         │
│  │                                                            │         │
│  │  • Receives questionnaire                                 │         │
│  │  • Creates analysis job                                   │         │
│  │  • Sends job to Onside                                    │         │
│  │  • Polls Onside for progress                              │         │
│  │  • Transforms data to En Garde format                     │         │
│  │  • Stores results                                         │         │
│  │  • Imports confirmed data                                 │         │
│  └───────────────────────────┬──────────────────────────────┘         │
│                               │                                        │
│                               ▼                                        │
└────────────────────────────────────────────────────────────────────────┘
                                │
                                │  HTTP/HTTPS
                                ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          Onside Platform                                │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────┐         │
│  │            SEO & Content Walker Agent                     │         │
│  │                                                            │         │
│  │  1. Website Crawler                                       │         │
│  │     • Crawl brand website                                 │         │
│  │     • Extract content, meta, headings                     │         │
│  │     • Analyze internal linking                            │         │
│  │                                                            │         │
│  │  2. Keyword Extractor                                     │         │
│  │     • TF-IDF analysis                                     │         │
│  │     • Named Entity Recognition                            │         │
│  │     • Topic modeling                                      │         │
│  │                                                            │         │
│  │  3. SERP Analyzer                                         │         │
│  │     • Query search engines for keywords                   │         │
│  │     • Collect top 100 results per keyword                 │         │
│  │     • Extract ranking positions                           │         │
│  │                                                            │         │
│  │  4. Competitor Finder                                     │         │
│  │     • Identify domains in SERP results                    │         │
│  │     • Calculate overlap percentages                       │         │
│  │     • Score relevance                                     │         │
│  │     • Categorize (primary/secondary/emerging)             │         │
│  │                                                            │         │
│  │  5. Insight Generator                                     │         │
│  │     • Market positioning analysis                         │         │
│  │     • Competitive gap analysis                            │         │
│  │     • Content opportunity identification                  │         │
│  │     • SEO health scoring                                  │         │
│  └──────────────────────────────────────────────────────────┘         │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────┐         │
│  │                   Data Processing                         │         │
│  │                                                            │         │
│  │  • Store raw scraped data                                 │         │
│  │  • Process in background                                  │         │
│  │  • Update progress via WebSocket                          │         │
│  │  • Generate final report                                  │         │
│  └──────────────────────────────────────────────────────────┘         │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Diagrams

### Automated Path Flow

```
User                Frontend              Backend API           Onside Service
│                      │                      │                      │
│  1. Open Wizard      │                      │                      │
├─────────────────────>│                      │                      │
│                      │                      │                      │
│  2. Select Automated │                      │                      │
├─────────────────────>│                      │                      │
│                      │                      │                      │
│  3. Fill Form        │                      │                      │
├─────────────────────>│                      │                      │
│                      │                      │                      │
│  4. Submit           │ POST /initiate       │                      │
│                      ├─────────────────────>│                      │
│                      │                      │                      │
│                      │                      │  Create Job          │
│                      │                      ├─────────────────────>│
│                      │                      │                      │
│                      │  { jobId, status }   │                      │
│                      │<─────────────────────┤                      │
│                      │                      │                      │
│  5. Show Progress    │ WS Connect           │                      │
│<─────────────────────┤<─────────────────────┤                      │
│                      │                      │                      │
│                      │                      │  Start Analysis      │
│                      │                      │<─────────────────────┤
│                      │                      │                      │
│                      │  Progress Update 1   │                      │
│  6. Update UI        │<─────────────────────┤                      │
│<─────────────────────┤                      │                      │
│                      │                      │  Crawling...         │
│                      │                      │<─────────────────────┤
│                      │                      │                      │
│                      │  Progress Update 2   │                      │
│  7. Update UI        │<─────────────────────┤                      │
│<─────────────────────┤                      │                      │
│                      │                      │  Analyzing...        │
│                      │                      │<─────────────────────┤
│                      │                      │                      │
│       ... (Multiple progress updates) ...   │                      │
│                      │                      │                      │
│                      │  Progress Complete   │                      │
│  8. Analysis Done    │<─────────────────────┤                      │
│<─────────────────────┤                      │                      │
│                      │                      │                      │
│  9. Fetch Results    │ GET /results/{jobId} │                      │
│                      ├─────────────────────>│                      │
│                      │                      │                      │
│                      │  { keywords, ... }   │                      │
│  10. Show Results    │<─────────────────────┤                      │
│<─────────────────────┤                      │                      │
│                      │                      │                      │
│  11. Select Items    │                      │                      │
├─────────────────────>│                      │                      │
│                      │                      │                      │
│  12. Confirm Import  │ POST /confirm        │                      │
│                      ├─────────────────────>│                      │
│                      │                      │                      │
│                      │                      │  Import to DB        │
│                      │                      ├───────┐              │
│                      │                      │       │              │
│                      │                      │<──────┘              │
│                      │                      │                      │
│                      │  { success: true }   │                      │
│  13. Success!        │<─────────────────────┤                      │
│<─────────────────────┤                      │                      │
│                      │                      │                      │
```

### Manual Path Flow

```
User                Frontend              Backend API
│                      │                      │
│  1. Open Wizard      │                      │
├─────────────────────>│                      │
│                      │                      │
│  2. Select Manual    │                      │
├─────────────────────>│                      │
│                      │                      │
│  3. Add Keywords     │                      │
├─────────────────────>│                      │
│                      │                      │
│  4. Add Competitors  │                      │
├─────────────────────>│                      │
│                      │                      │
│  5. Confirm Import   │ POST /confirm        │
│                      ├─────────────────────>│
│                      │                      │
│                      │                      │  Import to DB
│                      │                      ├───────┐
│                      │                      │       │
│                      │                      │<──────┘
│                      │                      │
│                      │  { success: true }   │
│  6. Success!         │<─────────────────────┤
│<─────────────────────┤                      │
│                      │                      │
```

---

## 📊 Component Hierarchy

```
SetupWizard (Dialog)
│
├── DialogHeader
│   ├── Title + Badge (path indicator)
│   └── Description
│
├── Progress Bar
│   ├── Current step indicator
│   └── Percentage display
│
├── Step Indicators (Visual dots)
│   └── Steps array mapping
│
└── Step Content (Dynamic)
    │
    ├── Step 0: PathSelectionStep
    │   ├── Header text
    │   ├── Path Cards (Grid)
    │   │   ├── Automated Card
    │   │   │   ├── Icon (Sparkles)
    │   │   │   ├── Title/Description
    │   │   │   ├── Estimated time
    │   │   │   ├── Benefits list
    │   │   │   └── Select button
    │   │   └── Manual Card
    │   │       ├── Icon (PenTool)
    │   │       ├── Title/Description
    │   │       ├── Estimated time
    │   │       ├── Benefits list
    │   │       └── Select button
    │   └── Continue button
    │
    ├── AUTOMATED PATH
    │   │
    │   ├── Step 1: QuestionnaireStep
    │   │   ├── Form Cards
    │   │   │   ├── Basic Info Card
    │   │   │   │   ├── Brand name (required)
    │   │   │   │   ├── Website (required)
    │   │   │   │   ├── Industry dropdown (required)
    │   │   │   │   └── Sub-industry (optional)
    │   │   │   ├── Geographic Card
    │   │   │   │   ├── Target markets (multi-badge)
    │   │   │   │   └── Primary language (dropdown)
    │   │   │   ├── Products Card
    │   │   │   │   ├── Offerings (tag input)
    │   │   │   │   └── Target audience (text)
    │   │   │   └── Analysis Preferences Card
    │   │   │       ├── Analysis depth (dropdown)
    │   │   │       └── Focus areas (multi-card)
    │   │   └── Navigation (Back/Continue)
    │   │
    │   ├── Step 2: AutomatedProgressStep
    │   │   ├── Header with status icon
    │   │   ├── Progress Card
    │   │   │   ├── Progress bar
    │   │   │   ├── Connection status
    │   │   │   ├── Completed steps (green checks)
    │   │   │   ├── Current step (loading)
    │   │   │   └── Activity log
    │   │   └── Info Card
    │   │
    │   ├── Step 3: ResultsReviewStep
    │   │   ├── Summary Cards (4 metrics)
    │   │   ├── Tabbed Interface
    │   │   │   ├── Keywords Tab
    │   │   │   │   ├── Search input
    │   │   │   │   ├── Bulk actions
    │   │   │   │   ├── Keyword cards (checkbox)
    │   │   │   │   └── Show more/less
    │   │   │   ├── Competitors Tab
    │   │   │   │   ├── Search input
    │   │   │   │   ├── Bulk actions
    │   │   │   │   ├── Competitor cards (checkbox)
    │   │   │   │   └── Show more/less
    │   │   │   ├── Insights Tab
    │   │   │   │   ├── Market position
    │   │   │   │   ├── Strengths
    │   │   │   │   ├── Opportunities
    │   │   │   │   └── Recommendations
    │   │   │   └── Opportunities Tab
    │   │   │       └── Content opportunity cards
    │   │   └── Navigation (Back/Continue)
    │   │
    │   └── Step 4: ConfirmationStep
    │       ├── Success icon
    │       ├── Metric Cards (3)
    │       ├── Keywords Breakdown Card
    │       │   ├── Priority distribution
    │       │   └── Sample keywords
    │       ├── Competitors Breakdown Card
    │       │   ├── Category distribution
    │       │   └── Sample competitors
    │       ├── "What happens next" Card
    │       └── Navigation (Back/Confirm)
    │
    └── MANUAL PATH
        │
        ├── Step 1: ManualInputStep
        │   ├── Split Cards (Grid)
        │   │   ├── Keywords Card
        │   │   │   ├── Keyword input
        │   │   │   ├── Priority select
        │   │   │   ├── Category input
        │   │   │   ├── Add button
        │   │   │   ├── CSV import
        │   │   │   └── Keywords list
        │   │   └── Competitors Card
        │   │       ├── URL input
        │   │       ├── Name input
        │   │       ├── Category select
        │   │       ├── Add button
        │   │       └── Competitors list
        │   └── Navigation (Back/Continue)
        │
        └── Step 2: ConfirmationStep
            └── (Same as automated step 4)
```

---

## 🗄️ Database Schema (Recommended)

```sql
-- Brand Analysis Jobs Table
CREATE TABLE brand_analysis_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL REFERENCES users(id),
    tenant_uuid UUID NOT NULL REFERENCES tenants(uuid),
    questionnaire JSONB NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'initiated',
    progress INTEGER DEFAULT 0,
    results JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    error_message TEXT,
    CONSTRAINT valid_status CHECK (status IN (
        'initiated', 'crawling', 'analyzing', 'processing', 'completed', 'failed'
    ))
);

CREATE INDEX idx_brand_analysis_jobs_user_id ON brand_analysis_jobs(user_id);
CREATE INDEX idx_brand_analysis_jobs_status ON brand_analysis_jobs(status);
CREATE INDEX idx_brand_analysis_jobs_tenant_uuid ON brand_analysis_jobs(tenant_uuid);

-- Discovered Keywords (before confirmation)
CREATE TABLE discovered_keywords (
    id SERIAL PRIMARY KEY,
    job_id UUID NOT NULL REFERENCES brand_analysis_jobs(id) ON DELETE CASCADE,
    keyword TEXT NOT NULL,
    source VARCHAR(100) NOT NULL,
    search_volume INTEGER,
    difficulty FLOAT,
    relevance_score FLOAT NOT NULL,
    current_ranking INTEGER,
    category VARCHAR(100),
    priority VARCHAR(20) DEFAULT 'medium',
    selected BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT valid_priority CHECK (priority IN ('low', 'medium', 'high'))
);

CREATE INDEX idx_discovered_keywords_job_id ON discovered_keywords(job_id);
CREATE INDEX idx_discovered_keywords_selected ON discovered_keywords(selected);

-- Identified Competitors (before confirmation)
CREATE TABLE identified_competitors (
    id SERIAL PRIMARY KEY,
    job_id UUID NOT NULL REFERENCES brand_analysis_jobs(id) ON DELETE CASCADE,
    domain VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    relevance_score FLOAT NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'primary',
    overlap_percentage FLOAT,
    selected BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT valid_category CHECK (category IN ('primary', 'secondary', 'emerging'))
);

CREATE INDEX idx_identified_competitors_job_id ON identified_competitors(job_id);
CREATE INDEX idx_identified_competitors_selected ON identified_competitors(selected);

-- Content Opportunities
CREATE TABLE content_opportunities (
    id SERIAL PRIMARY KEY,
    job_id UUID NOT NULL REFERENCES brand_analysis_jobs(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    estimated_traffic INTEGER,
    difficulty VARCHAR(20) NOT NULL,
    content_type VARCHAR(100),
    keywords JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT valid_difficulty CHECK (difficulty IN ('low', 'medium', 'high'))
);

CREATE INDEX idx_content_opportunities_job_id ON content_opportunities(job_id);
```

---

## 🔐 Security Considerations

### Authentication & Authorization
```typescript
// Middleware to protect wizard endpoints
export async function wizardAuthMiddleware(req: Request) {
  // 1. Verify JWT token
  const token = req.headers.get('authorization')?.replace('Bearer ', '');
  if (!token) throw new UnauthorizedException();

  // 2. Decode and validate
  const payload = await verifyJWT(token);

  // 3. Check user permissions
  if (!payload.permissions.includes('brand.setup')) {
    throw new ForbiddenException();
  }

  // 4. Verify tenant access
  const tenantId = req.headers.get('x-tenant-id');
  if (!await userHasTenantAccess(payload.userId, tenantId)) {
    throw new ForbiddenException();
  }

  return payload;
}
```

### Input Validation
```typescript
// Backend validation schema (Zod example)
import { z } from 'zod';

const QuestionnaireSchema = z.object({
  brandName: z.string().min(1).max(100),
  primaryWebsite: z.string().url(),
  industry: z.enum(['ecommerce', 'saas', 'fintech', /* ... */]),
  targetMarkets: z.array(z.string()).min(1).max(20),
  primaryLanguage: z.string().length(2),
  analysisDepth: z.enum(['quick', 'standard', 'comprehensive']),
  focusAreas: z.array(z.enum(['seo', 'content', 'social', 'technical'])).min(1),
  // ... other fields
});

// Validate before processing
const validated = QuestionnaireSchema.parse(req.body.questionnaire);
```

### Rate Limiting
```typescript
// Prevent abuse of analysis endpoint
import rateLimit from 'express-rate-limit';

const analysisLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Max 5 analyses per 15 min
  message: 'Too many analysis requests, please try again later',
  keyGenerator: (req) => req.user.id, // Per-user limit
});

app.post('/api/v1/engarde/brand-analysis/initiate', analysisLimiter, handler);
```

### WebSocket Security
```typescript
// Verify WebSocket connection
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  try {
    const payload = verifyJWT(token);
    socket.data.userId = payload.userId;
    next();
  } catch (err) {
    next(new Error('Authentication error'));
  }
});

// Room-based isolation
io.on('connection', (socket) => {
  const jobId = socket.handshake.query.jobId;

  // Verify user owns this job
  if (!await userOwnsJob(socket.data.userId, jobId)) {
    socket.disconnect();
    return;
  }

  // Join private room
  socket.join(`analysis:${jobId}`);
});
```

---

## 🧪 Testing Strategy

### Unit Tests
```typescript
// Example: Test keyword validation
describe('ManualInputStep', () => {
  it('should prevent duplicate keywords', () => {
    const { getByRole, getByText } = render(
      <ManualInputStep
        keywords={[{ keyword: 'seo tools', priority: 'high' }]}
        competitors={[]}
        onKeywordsChange={mockFn}
        onCompetitorsChange={mockFn}
        onNext={mockFn}
        onBack={mockFn}
      />
    );

    // Try to add duplicate
    const input = getByRole('textbox', { name: /keyword/i });
    fireEvent.change(input, { target: { value: 'seo tools' } });
    fireEvent.click(getByRole('button', { name: /add keyword/i }));

    // Should show error
    expect(getByText(/already exists/i)).toBeInTheDocument();
  });
});
```

### Integration Tests
```typescript
// Example: Test complete flow
describe('SetupWizard Integration', () => {
  it('should complete automated flow', async () => {
    // Mock API responses
    server.use(
      rest.post('/api/v1/engarde/brand-analysis/initiate', (req, res, ctx) => {
        return res(ctx.json({ jobId: 'test-123', status: 'initiated' }));
      }),
      rest.get('/api/v1/engarde/brand-analysis/:jobId/results', (req, res, ctx) => {
        return res(ctx.json(mockResults));
      })
    );

    const { user } = renderWithProviders(<SetupWizard isOpen onClose={mockFn} />);

    // Step 1: Select automated
    await user.click(screen.getByText('Automated Brand Analysis'));
    await user.click(screen.getByText('Continue'));

    // Step 2: Fill questionnaire
    await user.type(screen.getByLabelText(/brand name/i), 'Test Brand');
    // ... fill other fields
    await user.click(screen.getByText('Continue'));

    // Step 3: Wait for analysis (mock WebSocket)
    await waitFor(() => {
      expect(screen.getByText('Analysis Complete')).toBeInTheDocument();
    });

    // Step 4: Review results
    await user.click(screen.getByText('Select All'));
    await user.click(screen.getByText('Continue to Confirmation'));

    // Step 5: Confirm
    await user.click(screen.getByText('Confirm & Import'));

    // Verify completion
    await waitFor(() => {
      expect(mockOnComplete).toHaveBeenCalledWith({
        keywords: expect.any(Number),
        competitors: expect.any(Number),
      });
    });
  });
});
```

### E2E Tests (Playwright)
```typescript
// Example: E2E test
import { test, expect } from '@playwright/test';

test('complete wizard automated path', async ({ page }) => {
  await page.goto('/setup');

  // Open wizard
  await page.click('button:has-text("Start Setup Wizard")');

  // Select automated
  await page.click('text=Automated Brand Analysis');
  await page.click('button:has-text("Continue")');

  // Fill form
  await page.fill('input[name="brandName"]', 'E2E Test Brand');
  await page.fill('input[name="primaryWebsite"]', 'https://example.com');
  await page.selectOption('select[name="industry"]', 'saas');
  await page.click('text=United States');
  await page.selectOption('select[name="primaryLanguage"]', 'en');
  await page.selectOption('select[name="analysisDepth"]', 'standard');
  await page.click('text=SEO');

  // Submit
  await page.click('button:has-text("Continue")');

  // Wait for analysis
  await expect(page.locator('text=Analysis Complete')).toBeVisible({ timeout: 60000 });

  // Review results
  await page.click('button:has-text("Select All")');
  await page.click('button:has-text("Continue to Confirmation")');

  // Confirm import
  await page.click('button:has-text("Confirm & Import")');

  // Verify success
  await expect(page.locator('text=Successfully imported')).toBeVisible();
});
```

---

## 🚀 Deployment Workflow

### 1. Build & Test
```bash
# Install dependencies
npm install

# Type check
npm run type-check

# Lint
npm run lint

# Run tests
npm run test
npm run test:e2e

# Build
npm run build
```

### 2. Environment Configuration
```bash
# Production .env
NEXT_PUBLIC_API_URL=https://api.engarde.com
NEXT_PUBLIC_WS_URL=wss://api.engarde.com
NODE_ENV=production
```

### 3. Deploy Frontend
```bash
# Vercel
vercel --prod

# Or Docker
docker build -t engarde-frontend .
docker push engarde-frontend:latest
kubectl apply -f k8s/frontend-deployment.yaml
```

### 4. Deploy Backend
```bash
# Ensure all endpoints are implemented
# Set up WebSocket server
# Configure job queue (Redis/Bull)
# Run database migrations

# Deploy
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/websocket-deployment.yaml
```

### 5. Monitoring Setup
```typescript
// Sentry integration
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 1.0,
  beforeSend(event) {
    // Filter sensitive data
    if (event.request) {
      delete event.request.cookies;
    }
    return event;
  },
});

// Track wizard events
Sentry.addBreadcrumb({
  category: 'wizard',
  message: 'Analysis completed',
  level: 'info',
  data: { jobId, keywordCount, competitorCount },
});
```

---

## 📈 Performance Optimization

### Code Splitting
```typescript
// Lazy load heavy components
import dynamic from 'next/dynamic';

const ResultsReviewStep = dynamic(() =>
  import('./ResultsReviewStep').then((mod) => mod.ResultsReviewStep)
);

const ManualInputStep = dynamic(() =>
  import('./ManualInputStep').then((mod) => mod.ManualInputStep)
);
```

### Bundle Analysis
```bash
# Analyze bundle size
npm run build
npx @next/bundle-analyzer
```

### Caching Strategy
```typescript
// React Query cache configuration
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      cacheTime: 10 * 60 * 1000, // 10 minutes
      retry: 3,
      refetchOnWindowFocus: false,
    },
  },
});
```

---

**Document Version**: 1.0.0
**Last Updated**: December 24, 2024
**Status**: ✅ Complete
