# Environment Variables Migration - Complete

## Summary

All hardcoded API endpoints have been replaced with environment variables that automatically detect local settings. The application now properly uses configuration from `.env` files and auto-derives dependent URLs.

## Changes Made

### 1. Updated Configuration Files

#### `.env.example` (/Users/cope/EnGardeHQ/production-frontend/.env.example)
- Added `NEXT_PUBLIC_WS_URL` for WebSocket connections
- Added `NEXT_PUBLIC_LANGFLOW_URL` for Langflow integration
- Added comprehensive documentation for each environment variable
- Added examples for local, Docker, and production configurations

#### `.env.local` (/Users/cope/EnGardeHQ/production-frontend/.env.local)
- Updated with all new environment variables
- Added WebSocket URL configuration
- Added Langflow URL configuration
- Maintained existing secrets and authentication tokens

#### `.env.local.example` (/Users/cope/EnGardeHQ/production-frontend/.env.local.example)
- Added WebSocket and Langflow URL configurations
- Added inline documentation for environment-specific values

### 2. Updated Core Configuration

#### `lib/config/environment.ts` (/Users/cope/EnGardeHQ/production-frontend/lib/config/environment.ts)
- Enhanced `getEnvironmentConfig()` to use environment variables with sensible defaults
- API URL now defaults to `http://localhost:8000` in development, empty string in production
- Improved environment detection logic

### 3. Updated Services

#### `services/websocket-real.service.ts` (/Users/cope/EnGardeHQ/production-frontend/services/websocket-real.service.ts)
- Replaced hardcoded `ws://localhost:8000/ws` with environment variable
- Added automatic WebSocket URL derivation from API URL
- Automatically converts HTTP to WS and HTTPS to WSS
- Proper fallback logic:
  1. Check `NEXT_PUBLIC_WS_URL`
  2. Derive from `NEXT_PUBLIC_API_URL`
  3. Default to `ws://localhost:8000/ws`

### 4. Updated Components

#### `components/workflow/AuthenticatedLangflowIframe.tsx` (/Users/cope/EnGardeHQ/production-frontend/components/workflow/AuthenticatedLangflowIframe.tsx)
- Replaced hardcoded `http://localhost:8000/langflow` with environment variable
- Added `getLangflowUrl()` helper function
- Checks `NEXT_PUBLIC_LANGFLOW_URL` first
- Falls back to deriving from `NEXT_PUBLIC_API_URL`
- Applied to both iframe setup and "Open in New Tab" functionality

#### `components/workflow/LangflowWorkflowBuilder.tsx` (/Users/cope/EnGardeHQ/production-frontend/components/workflow/LangflowWorkflowBuilder.tsx)
- Replaced hardcoded Langflow URL with environment variable
- Added `getLangflowUrl()` helper in `openInLangflow()` function
- Consistent URL derivation logic across the component

### 5. Already Correct

#### `next.config.js` (/Users/cope/EnGardeHQ/production-frontend/next.config.js)
- Already using `process.env.NEXT_PUBLIC_API_URL` in rewrites
- No changes needed

## Environment Variable Configuration

### Required Variables

```bash
# Minimum required for the application to work
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_APP_NAME=Engarde
NEXTAUTH_SECRET=your-secret-here
```

### Optional Variables (Auto-derived if not set)

```bash
# WebSocket URL - auto-derived from API URL if not set
NEXT_PUBLIC_WS_URL=ws://localhost:8000/ws

# Langflow URL - auto-derived from API URL if not set
NEXT_PUBLIC_LANGFLOW_URL=http://localhost:8000/langflow
```

## Auto-Detection Logic

The application now intelligently detects and derives URLs:

### WebSocket URL Derivation
```typescript
// Priority order:
1. NEXT_PUBLIC_WS_URL (if set)
2. Derive from NEXT_PUBLIC_API_URL:
   - https:// → wss://
   - http:// → ws://
   - Add /ws endpoint
3. Default: ws://localhost:8000/ws
```

### Langflow URL Derivation
```typescript
// Priority order:
1. NEXT_PUBLIC_LANGFLOW_URL (if set)
2. Derive from NEXT_PUBLIC_API_URL:
   - Add /langflow endpoint
3. Default: http://localhost:8000/langflow
```

## Configuration by Environment

### Local Development
```bash
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_WS_URL=ws://localhost:8000/ws
NEXT_PUBLIC_LANGFLOW_URL=http://localhost:8000/langflow
```

### Docker Environment
```bash
NEXT_PUBLIC_API_URL=http://backend:8000
NEXT_PUBLIC_WS_URL=ws://backend:8000/ws
NEXT_PUBLIC_LANGFLOW_URL=http://backend:8000/langflow
```

### Production Environment
```bash
NEXT_PUBLIC_API_URL=https://api.yourdomain.com
NEXT_PUBLIC_WS_URL=wss://api.yourdomain.com/ws
NEXT_PUBLIC_LANGFLOW_URL=https://api.yourdomain.com/langflow
```

## Benefits

1. **No More Hardcoded URLs**: All endpoints are configurable via environment variables
2. **Auto-Detection**: WebSocket and Langflow URLs automatically derived from API URL
3. **Environment-Specific**: Easy to configure for local, Docker, or production
4. **Secure Defaults**: Sensible fallbacks ensure the app works out of the box
5. **Protocol Conversion**: Automatically converts HTTP/HTTPS to WS/WSS
6. **Single Source of Truth**: Set `NEXT_PUBLIC_API_URL` and everything else follows

## Migration Guide for Developers

### For Existing .env.local Files

1. Ensure `NEXT_PUBLIC_API_URL` is set correctly
2. Optionally add `NEXT_PUBLIC_WS_URL` and `NEXT_PUBLIC_LANGFLOW_URL`
3. If not added, they will be auto-derived from `NEXT_PUBLIC_API_URL`

### For New Deployments

1. Copy `.env.example` to `.env.local`
2. Set `NEXT_PUBLIC_API_URL` to your backend URL
3. Generate secrets with `openssl rand -base64 32`
4. Configure other services as needed

### For Docker Deployments

1. Update `docker-compose.yml` with:
   ```yaml
   environment:
     - NEXT_PUBLIC_API_URL=http://backend:8000
   ```
2. WebSocket and Langflow URLs will be auto-derived

### For Production Deployments

1. Set environment variables in your hosting platform:
   ```bash
   NEXT_PUBLIC_API_URL=https://api.yourdomain.com
   ```
2. All other URLs will be automatically derived

## Files Modified

1. `/Users/cope/EnGardeHQ/production-frontend/.env.example`
2. `/Users/cope/EnGardeHQ/production-frontend/.env.local`
3. `/Users/cope/EnGardeHQ/production-frontend/.env.local.example`
4. `/Users/cope/EnGardeHQ/production-frontend/lib/config/environment.ts`
5. `/Users/cope/EnGardeHQ/production-frontend/services/websocket-real.service.ts`
6. `/Users/cope/EnGardeHQ/production-frontend/components/workflow/AuthenticatedLangflowIframe.tsx`
7. `/Users/cope/EnGardeHQ/production-frontend/components/workflow/LangflowWorkflowBuilder.tsx`

## Testing

To verify the changes work correctly:

1. **Local Development**:
   ```bash
   cd /Users/cope/EnGardeHQ/production-frontend
   npm run dev
   # Check console for "🔍 Environment Detection Debug" logs
   # Verify API URL, WS URL, and Langflow URL are correct
   ```

2. **Docker Environment**:
   ```bash
   docker-compose up
   # Check logs for environment configuration
   # Verify backend:8000 is being used
   ```

3. **Check Browser Console**:
   - Look for environment configuration logs
   - Verify WebSocket connection attempts use correct URL
   - Check network tab for API requests

## Backward Compatibility

The changes are fully backward compatible:
- Existing deployments will continue to work
- Default values match previous hardcoded values
- Auto-derivation ensures URLs are always set
- No breaking changes to the API

## Future Improvements

Consider adding these environment variables in the future:
- `NEXT_PUBLIC_ANALYTICS_URL` for analytics endpoint
- `NEXT_PUBLIC_GRAPHQL_URL` if using GraphQL
- `NEXT_PUBLIC_STORAGE_URL` for file storage endpoints

## Support

If you encounter issues:
1. Check `.env.local` exists and has correct values
2. Verify environment variables are loaded (check browser console)
3. Ensure `NEXT_PUBLIC_API_URL` is set correctly
4. Check network tab in DevTools for actual URLs being used
5. Review environment detection logs in console

## Completion Status

All tasks completed successfully:
- ✅ Updated .env.example with proper API and WebSocket URL variables
- ✅ Updated environment.ts to use environment variables for API URL
- ✅ Updated websocket-real.service.ts to use environment variable for WebSocket URL
- ✅ Updated AuthenticatedLangflowIframe.tsx to use environment variable for Langflow URL
- ✅ Updated LangflowWorkflowBuilder.tsx to use environment variable for Langflow URL
- ✅ Updated next.config.js (already using environment variables correctly)
- ✅ Updated .env.local.example with complete configuration

The application now properly auto-detects local settings with environment variables!
