# Walker Agent Frontend Gap Analysis

**Date**: January 16, 2026
**Purpose**: Identify gaps between existing frontend components and backend requirements for Walker Agent integration

---

## Executive Summary

Two setup modals already exist in the codebase:
1. **WalkerAgentSetupModal** (`components/agents/WalkerAgentSetupModal.tsx`) - Campaign-focused setup
2. **PersonalAgentSetupWizard** (`components/agents/personal/setup-wizard.tsx`) - Personal agent activation

However, neither modal is fully integrated with the backend API endpoints required for the Walker Agent notification system. Additional pages and components are needed for ongoing management beyond the initial setup.

---

## Existing Components Analysis

### 1. WalkerAgentSetupModal.tsx
**Location**: `/Users/cope/EnGardeHQ/production-frontend/components/agents/WalkerAgentSetupModal.tsx`

**What EXISTS**:
- ✅ 4-step wizard (Campaign Details, Communication, Interaction, Integration)
- ✅ Campaign brief input
- ✅ Channel selection (Google Ads, Facebook, Instagram, LinkedIn, etc.)
- ✅ Budget allocation (total, period, equal/custom/auto-optimize)
- ✅ WhatsApp toggle + phone number input
- ✅ Email toggle + email address input
- ✅ Report frequency (daily, weekly, bi-weekly, monthly)
- ✅ Alert sensitivity (low, medium, high)
- ✅ Auto-optimization toggle
- ✅ Microservice endpoint configuration
- ✅ API credentials input

**What is MISSING** (compared to backend):
- ❌ **NO backend API integration** - calls `onSubmit(config)` but doesn't hit `/api/v1/walker-agents/notification-preferences`
- ❌ **NO tenant_id** from CurrentBrandTenantComponent - config doesn't include tenant context
- ❌ **NO agent type selection** - assumes single agent type from props
- ❌ **NO quiet hours** - missing quiet_hours_enabled, quiet_hours_start, quiet_hours_end, quiet_hours_timezone
- ❌ **NO per-agent toggles** - missing seo_enabled, content_enabled, paid_ads_enabled, audience_intelligence_enabled
- ❌ **NO notification channel priority** - missing preferred_channel field ('email' | 'whatsapp' | 'in_app' | 'all')
- ❌ **NO notification frequency mapping** - has report_frequency but backend expects 'realtime' | 'daily_digest' | 'weekly_summary'

### 2. PersonalAgentSetupWizard.tsx
**Location**: `/Users/cope/EnGardeHQ/production-frontend/components/agents/personal/setup-wizard.tsx`

**What EXISTS**:
- ✅ 4-step wizard (Connect Data, Set Goals, Channels, Review)
- ✅ Brand/workspace selection (fetches from workspaceService.listWorkspaces())
- ✅ Primary objective selection (brand_awareness, conversions)
- ✅ Monthly budget target
- ✅ ChannelPreferences component integration (Email, WhatsApp, Voice)
- ✅ Review step showing all 4 Walker Agents + En Garde Support
- ✅ Success toast on completion

**What is MISSING** (compared to backend):
- ❌ **NO backend API integration** - only simulates API call with setTimeout
- ❌ **NO notification preferences saved** - doesn't call POST `/api/v1/walker-agents/notification-preferences`
- ❌ **NO per-agent activation** - shows all 4 agents but doesn't let user toggle them individually
- ❌ **NO quiet hours** - ChannelPreferences doesn't have quiet hours UI
- ❌ **NO notification frequency selection** - ChannelPreferences doesn't expose frequency dropdown
- ❌ **NO tenant_id mapping** - brand selection uses workspace ID but doesn't map to tenant_id

### 3. ChannelPreferences.tsx
**Location**: `/Users/cope/EnGardeHQ/production-frontend/components/settings/channel-preferences.tsx`

**What EXISTS**:
- ✅ Email toggle + email address input
- ✅ WhatsApp toggle + phone number input
- ✅ Voice toggle (for web interface)
- ✅ Info tooltips explaining agent access
- ✅ "Save Preferences" button (shows toast only)

**What is MISSING** (compared to backend):
- ❌ **NO backend API integration** - handleSave() only shows toast, doesn't call API
- ❌ **NO notification frequency dropdown** - missing realtime/daily/weekly options
- ❌ **NO quiet hours UI** - missing time pickers for start/end times
- ❌ **NO per-agent toggles** - missing individual agent enable/disable checkboxes
- ❌ **NO preferred channel selection** - has individual toggles but no "preferred" radio group

### 4. WalkerAgentControlPanel.tsx
**Location**: `/Users/cope/EnGardeHQ/production-frontend/components/agents/WalkerAgentControlPanel.tsx`

**What EXISTS**:
- ✅ Agent selection dropdown with search
- ✅ Real-time metrics display (executions, success rate, response time)
- ✅ Health status monitoring
- ✅ Deploy/Execute/Test controls
- ✅ Chat tab with ChatWindow integration
- ✅ Zustand store integration (useWalkerAgentStore)
- ✅ Auto-refresh toggle
- ✅ Time range selector

**What is MISSING** (compared to backend):
- ❌ **NO suggestion management** - no UI for viewing/approving walker_agent_suggestions
- ❌ **NO action buttons** - no Execute/Pause/Reject/Details buttons for suggestions
- ❌ **NO batch tracking** - no UI for batch_id grouping
- ❌ **NO notification history** - no view of sent email/WhatsApp notifications

---

## Backend API Endpoints (from production-backend)

### Existing Endpoints ✅
- `POST /api/v1/walker-agents/suggestions` - Store suggestions
- `POST /api/v1/walker-agents/responses` - Record user responses
- `GET /api/v1/walker-agents/responses` - List responses
- `POST /api/v1/walker-agents/whatsapp-webhook` - Handle WhatsApp replies
- `POST /api/v1/notifications/send` - Send notifications
- `GET /api/brands/current` - Get current brand/tenant

### Missing Endpoints ❌
- `GET /api/v1/walker-agents/notification-preferences` - Retrieve preferences
- `POST /api/v1/walker-agents/notification-preferences` - Create preferences
- `PUT /api/v1/walker-agents/notification-preferences` - Update preferences
- `GET /api/v1/walker-agents/suggestions?tenant_id=&status=&limit=` - List suggestions with filters

---

## Database Tables (from production-backend)

### walker_agent_suggestions
18 columns including:
- `id`, `batch_id`, `tenant_id`, `agent_type`, `type`, `title`, `description`
- `estimated_revenue`, `confidence_score`, `priority`
- `action_description`, `cta_url`
- `status` (pending, approved, executing, executed, paused, rejected, failed)
- `metadata` (JSONB)
- Timestamps: `created_at`, `updated_at`, `approved_at`, `executed_at`

### walker_agent_responses
8 columns including:
- `id`, `suggestion_id`, `tenant_id`, `user_id`, `action` (execute, pause, reject, details)
- `response_channel` (email, whatsapp, in_app)
- `response_data` (JSONB), `created_at`

### walker_agent_notification_preferences
17 columns including:
- `id`, `tenant_id`, `user_id`
- `preferred_channel` (email, whatsapp, in_app, all)
- `email_address`, `whatsapp_number`
- `notification_frequency` (realtime, daily_digest, weekly_summary)
- `quiet_hours_enabled`, `quiet_hours_start`, `quiet_hours_end`, `quiet_hours_timezone`
- Per-agent toggles: `seo_enabled`, `content_enabled`, `paid_ads_enabled`, `audience_intelligence_enabled`
- Timestamps: `created_at`, `updated_at`

---

## Gap Summary

### Phase 1: Modal Updates (PRIORITY 1)

#### A. Update WalkerAgentSetupModal.tsx
**File**: `components/agents/WalkerAgentSetupModal.tsx`

**Changes Needed**:
1. Add tenant_id context (use CurrentBrandTenantComponent or context)
2. Add Step 2.5: "Agent Selection" - checkboxes for SEO, Content, Paid Ads, Audience Intelligence
3. Update Step 2 (Communication):
   - Add preferred_channel radio group
   - Add notification_frequency dropdown (realtime, daily_digest, weekly_summary)
   - Add quiet hours time pickers
4. Update onSubmit to call POST `/api/v1/walker-agents/notification-preferences`
5. Map config to backend expected format

**New Fields**:
```typescript
interface WalkerAgentConfig {
  // ... existing fields ...

  // ADD THESE:
  tenant_id: string;
  user_id: string;
  preferred_channel: 'email' | 'whatsapp' | 'in_app' | 'all';
  notification_frequency: 'realtime' | 'daily_digest' | 'weekly_summary';
  quiet_hours_enabled: boolean;
  quiet_hours_start?: string; // HH:MM format
  quiet_hours_end?: string;
  quiet_hours_timezone?: string;
  seo_enabled: boolean;
  content_enabled: boolean;
  paid_ads_enabled: boolean;
  audience_intelligence_enabled: boolean;
}
```

#### B. Update PersonalAgentSetupWizard.tsx
**File**: `components/agents/personal/setup-wizard.tsx`

**Changes Needed**:
1. Map selectedBrand (workspace ID) to tenant_id
2. Add Step 2.5: "Select Walker Agents" - checkboxes for 4 agents
3. Update Step 2 (Channels) to include notification_frequency + quiet_hours
4. Replace setTimeout simulation with real API call to POST `/api/v1/walker-agents/notification-preferences`
5. Pass tenant_id and user_id to API

#### C. Update ChannelPreferences.tsx
**File**: `components/settings/channel-preferences.tsx`

**Changes Needed**:
1. Add notification_frequency dropdown (Realtime, Daily Digest, Weekly Summary)
2. Add quiet hours section with:
   - Enable/disable toggle
   - Start time picker
   - End time picker
   - Timezone selector (auto-detect from browser)
3. Add per-agent toggles section
4. Implement handleSave() to call PUT `/api/v1/walker-agents/notification-preferences`
5. Add useEffect to fetch current preferences on mount with GET

### Phase 1: New Pages (PRIORITY 2)

#### D. Create Walker Agent Dashboard
**File**: `app/walker-agents/page.tsx` (NEW)

**Purpose**: View and manage active suggestions

**Components Needed**:
- Suggestion cards with badge (pending, approved, executing, executed, paused, rejected, failed)
- Action buttons: Execute, Pause, Reject, Details
- Batch grouping display
- Filters: status, agent_type, date range
- API integration:
  - GET `/api/v1/walker-agents/suggestions?tenant_id=&status=&limit=`
  - POST `/api/v1/walker-agents/responses` (when clicking action buttons)

**UI Sections**:
1. **Header**: "Walker Agent Suggestions" + filter controls
2. **Batch Cards**: Group suggestions by batch_id
3. **Suggestion Cards**: title, description, estimated_revenue, confidence_score, priority, action buttons
4. **Metrics**: Total suggestions, avg confidence, estimated total revenue

#### E. Create Walker Agent Settings Page
**File**: `app/walker-agents/settings/page.tsx` (NEW)

**Purpose**: Update preferences outside of setup wizard

**Components**:
- Reuse ChannelPreferences component (enhanced version)
- Add "Notification History" section showing past notifications
- Add "Response History" section showing user actions

---

## Phase 2: Enhanced Experience (PRIORITY 3)

#### F. In-App Notification Components
**Files**:
- `components/notifications/WalkerAgentNotificationBell.tsx` (NEW)
- `components/notifications/WalkerAgentNotificationPanel.tsx` (NEW)

**Purpose**: Real-time in-app notifications via WebSocket

**Features**:
- Bell icon with badge count (unread suggestions)
- Dropdown panel showing recent suggestions
- Click to view suggestion details
- Action buttons inline

**Integration**:
- WebSocket connection to backend notification service
- Subscribe to tenant-specific notification channel
- Real-time updates when Langflow triggers notifications

#### G. Chat Integration
**Existing**: WalkerAgentControlPanel already has ChatWindow component

**Enhancement Needed**:
- Add suggestion rendering in chat (show suggestion cards in chat history)
- Add quick action buttons in chat (Execute/Pause/Reject)
- Connect chat to walker_agent_suggestions table

---

## Phase 3: Advanced Features (PRIORITY 4)

#### H. Analytics Dashboard
**File**: `app/walker-agents/analytics/page.tsx` (NEW)

**Purpose**: Track Walker Agent performance

**Metrics**:
- Total suggestions generated (by agent type)
- Acceptance rate (approved / total)
- Execution success rate (executed / approved)
- Estimated revenue impact
- Response time (time to approve)
- Channel breakdown (email vs WhatsApp vs in-app)

**Charts**:
- Line chart: suggestions over time
- Bar chart: suggestions by agent type
- Pie chart: response distribution (execute/pause/reject)
- Funnel chart: suggestion → approval → execution

#### I. Batch Actions
**Component**: `components/walker-agents/BatchActionBar.tsx` (NEW)

**Purpose**: Bulk operations on suggestions

**Features**:
- Select multiple suggestions
- Batch approve
- Batch reject
- Batch pause

---

## Implementation Priority

### NOW (Phase 1A - Modal Updates)
1. ✅ Gap analysis (this document)
2. ⏳ Update WalkerAgentSetupModal with backend integration
3. ⏳ Update PersonalAgentSetupWizard with backend integration
4. ⏳ Update ChannelPreferences with full backend fields
5. ⏳ Implement missing backend API endpoints (notification preferences)

### NEXT (Phase 1B - New Pages)
6. ⏳ Create Walker Agent Dashboard page (`app/walker-agents/page.tsx`)
7. ⏳ Create Walker Agent Settings page (`app/walker-agents/settings/page.tsx`)
8. ⏳ Implement GET suggestions endpoint with filters

### THEN (Phase 2 - Enhanced Experience)
9. ⏳ Create in-app notification components (Bell + Panel)
10. ⏳ WebSocket integration for real-time notifications
11. ⏳ Enhance ChatWindow with suggestion rendering

### LATER (Phase 3 - Advanced Features)
12. ⏳ Create analytics dashboard
13. ⏳ Implement batch actions
14. ⏳ Custom prompt management (advanced users)

---

## API Integration Map

| Frontend Component | Backend Endpoint | HTTP Method | Purpose |
|-------------------|------------------|-------------|---------|
| WalkerAgentSetupModal | `/api/v1/walker-agents/notification-preferences` | POST | Save initial preferences |
| PersonalAgentSetupWizard | `/api/v1/walker-agents/notification-preferences` | POST | Save initial preferences |
| ChannelPreferences | `/api/v1/walker-agents/notification-preferences` | GET | Load current preferences |
| ChannelPreferences | `/api/v1/walker-agents/notification-preferences` | PUT | Update preferences |
| Walker Agent Dashboard | `/api/v1/walker-agents/suggestions` | GET | List suggestions |
| Walker Agent Dashboard | `/api/v1/walker-agents/responses` | POST | Record user action |
| NotificationBell | `/api/v1/walker-agents/suggestions?status=pending` | GET | Unread count |
| Analytics Dashboard | `/api/v1/walker-agents/suggestions` | GET | Aggregate stats |

---

## Next Steps

1. **Create missing backend API endpoints first** (notification preferences GET/POST/PUT)
2. **Update modals** with backend integration (WalkerAgentSetupModal, PersonalAgentSetupWizard)
3. **Enhance ChannelPreferences** component with all backend fields
4. **Create new pages** (Dashboard, Settings)
5. **Implement Phase 2 & 3** features

---

**Status**: Gap analysis complete, ready to begin implementation ✅
