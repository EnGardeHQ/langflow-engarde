# Hydration Errors - Quick Reference Guide

## What Were The Errors?

- **Error #418**: Server and client HTML don't match (hydration mismatch)
- **Error #423**: React had to fall back to full client-side rendering
- **Error #425**: Text content differs between server and client

## What Was Fixed?

### 1. Google Analytics Script (layout.tsx)
**Problem**: Used `document.title` and `window.location.href` during SSR
**Solution**: Removed client-only DOM APIs from gtag config

### 2. Login Page Debug Logs (login/page.tsx)
**Problem**: Console.log with timestamps in render phase
**Solution**: Moved to useEffect, runs only on client

### 3. Debug Panel Visibility (login/page.tsx)
**Problem**: `process.env.NODE_ENV` check could mismatch between SSR/client
**Solution**: Used state + useEffect pattern for client-side only rendering

### 4. BrandGuard Route Detection (BrandGuard.tsx)
**Problem**: Used `window.location.pathname` in render
**Solution**: Switched to Next.js `usePathname()` hook + mounted state

## Quick Test

```bash
# Start dev server
npm run dev

# Run verification (in another terminal)
node scripts/verify-hydration-fixes.js
```

## Expected Result

```
✅ All hydration tests passed! Application is hydration-error-free.
```

## Key Files Modified

1. `/production-frontend/app/layout.tsx` - Lines 83-98
2. `/production-frontend/app/login/page.tsx` - Lines 199-308
3. `/production-frontend/components/brands/BrandGuard.tsx` - Lines 10-103

## Prevention Rules

1. ❌ Never use `window` or `document` in render
2. ❌ Never use `Date.now()` or timestamps in render
3. ✅ Always use Next.js hooks (`usePathname`, not `window.location`)
4. ✅ Always wrap client-only code in `useEffect`
5. ✅ Test with production build before deploying

## If Errors Return

1. Open DevTools Console
2. Look for errors with #418, #423, or #425
3. Find the component causing the mismatch
4. Apply the patterns from this fix:
   - Move to useEffect
   - Use Next.js hooks
   - Add isMounted guard
   - Use suppressHydrationWarning (sparingly)

## Full Documentation

See `/Users/cope/EnGardeHQ/HYDRATION_ERRORS_FIX_SUMMARY.md` for complete details.
