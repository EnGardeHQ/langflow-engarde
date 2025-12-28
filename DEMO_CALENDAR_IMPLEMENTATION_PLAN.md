# Demo Calendar Implementation Plan

## Overview
Implement a self-hosted calendar scheduler using EasyAppointments (https://github.com/alextselegidis/easyappointments) integrated with Google Calendar (Gmail + Workspace) while maintaining En Garde branding.

## Step-by-Step Implementation

### Phase 1: Frontend Button Updates ✅ (In Progress)
1. Update landing page buttons to route to `/demo`
   - "Start Free Trial" → Keep going to `#pricing` section (as requested)
   - "Schedule a Demo" (in pricing section) → `/demo`
   - "Watch Demo" → `/demo`
   - "Schedule a Demo" (in CTA section) → `/demo`
   - "Get Started" (header) → `/demo`

### Phase 2: Demo Page Setup
1. Create/update `/demo` page with embedded calendar
2. Add loading states and error handling
3. Style to match En Garde branding

### Phase 3: EasyAppointments Backend Setup
1. Set up EasyAppointments as a Docker container or separate service
2. Configure database (MySQL/PostgreSQL)
3. Set up environment variables
4. Configure Google Calendar integration:
   - Personal Gmail calendar
   - Business Google Workspace calendar
   - Handle calendar conflict detection

### Phase 4: API Integration
1. Create proxy endpoints in backend to EasyAppointments API
2. Handle authentication and CORS
3. Implement calendar sync logic

### Phase 5: Branding & Styling
1. Customize EasyAppointments theme to match En Garde colors
2. Embed calendar widget/iframe with custom styling
3. Ensure responsive design

### Phase 6: Testing & Deployment
1. Test calendar booking flow
2. Verify Google Calendar sync
3. Test conflict detection
4. Deploy to production

## Technical Details

### EasyAppointments Requirements
- PHP 7.4+ or 8.x
- MySQL 5.7+ or PostgreSQL 10+
- Apache/Nginx web server
- Google Calendar API credentials

### Google Calendar Integration
- OAuth 2.0 setup for both calendars
- Calendar API access tokens
- Sync service to check conflicts

### Architecture Options
1. **Option A**: Separate Docker container for EasyAppointments
   - Pros: Isolated, easy to maintain
   - Cons: Additional infrastructure

2. **Option B**: Embedded iframe/widget
   - Pros: Simple integration
   - Cons: Less control over styling

3. **Option C**: API-based integration
   - Pros: Full control, custom UI
   - Cons: More development time

## Next Steps
1. ✅ Update frontend buttons (current step)
2. Create demo page structure
3. Set up EasyAppointments Docker container
4. Configure Google Calendar OAuth
5. Implement API proxy
6. Style and brand
