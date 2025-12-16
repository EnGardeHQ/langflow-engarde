# Environment Variables - Quick Reference

## TL;DR

All hardcoded endpoints have been replaced with environment variables. Just set `NEXT_PUBLIC_API_URL` and everything else auto-configures!

## Minimum Configuration

```bash
# Only these 3 variables are required:
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_APP_NAME=Engarde
NEXTAUTH_SECRET=your-secret-here
```

WebSocket and Langflow URLs will automatically derive from `NEXT_PUBLIC_API_URL`.

## All Environment Variables

### Core Configuration
```bash
# Backend API URL (REQUIRED)
NEXT_PUBLIC_API_URL=http://localhost:8000

# WebSocket URL (auto-derived if not set)
NEXT_PUBLIC_WS_URL=ws://localhost:8000/ws

# Langflow URL (auto-derived if not set)
NEXT_PUBLIC_LANGFLOW_URL=http://localhost:8000/langflow
```

### Auto-Derivation Examples

If you only set:
```bash
NEXT_PUBLIC_API_URL=https://api.example.com
```

The application automatically derives:
```bash
NEXT_PUBLIC_WS_URL=wss://api.example.com/ws
NEXT_PUBLIC_LANGFLOW_URL=https://api.example.com/langflow
```

## Environment-Specific Configuration

### Local Development
```bash
NEXT_PUBLIC_API_URL=http://localhost:8000
```

### Docker
```bash
NEXT_PUBLIC_API_URL=http://backend:8000
```

### Production
```bash
NEXT_PUBLIC_API_URL=https://api.yourdomain.com
```

## Quick Setup

1. Copy the example file:
   ```bash
   cd /Users/cope/EnGardeHQ/production-frontend
   cp .env.example .env.local
   ```

2. Edit `.env.local` and set your backend URL:
   ```bash
   NEXT_PUBLIC_API_URL=http://localhost:8000
   ```

3. Generate secrets:
   ```bash
   openssl rand -base64 32
   ```

4. Done! WebSocket and Langflow URLs auto-configure.

## Verification

Check if environment variables are loaded:
```bash
cd /Users/cope/EnGardeHQ/production-frontend
npm run dev
```

Look for console output:
```
🔍 Environment Detection Debug: {
  nodeEnv: 'development',
  apiUrl: 'http://localhost:8000',
  ...
}
```

## Files to Check

- `.env.local` - Your local configuration
- `.env.example` - Template with all available variables
- `.env.local.example` - Complete example with documentation

## Troubleshooting

### Issue: WebSocket not connecting
**Solution**: Check `NEXT_PUBLIC_WS_URL` or ensure `NEXT_PUBLIC_API_URL` is correct

### Issue: Langflow not loading
**Solution**: Check `NEXT_PUBLIC_LANGFLOW_URL` or ensure `NEXT_PUBLIC_API_URL` is correct

### Issue: API requests failing
**Solution**: Verify `NEXT_PUBLIC_API_URL` points to running backend

### Issue: Environment variables not loading
**Solution**:
1. Restart dev server (`npm run dev`)
2. Check `.env.local` exists in `/Users/cope/EnGardeHQ/production-frontend`
3. Ensure variables start with `NEXT_PUBLIC_` for client-side access

## Key Files Modified

1. `lib/config/environment.ts` - Environment detection
2. `services/websocket-real.service.ts` - WebSocket configuration
3. `components/workflow/AuthenticatedLangflowIframe.tsx` - Langflow integration
4. `components/workflow/LangflowWorkflowBuilder.tsx` - Workflow builder
5. `.env.example` - Configuration template
6. `.env.local` - Your local config
7. `.env.local.example` - Comprehensive example

## Need Help?

See full documentation: `/Users/cope/EnGardeHQ/ENVIRONMENT_VARIABLES_MIGRATION.md`
