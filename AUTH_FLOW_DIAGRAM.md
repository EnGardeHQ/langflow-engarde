# Authentication Flow Diagram - Visual Breakdown

## Complete Login Flow with Timing

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         USER LOGIN FLOW - SUCCESS PATH                        │
└─────────────────────────────────────────────────────────────────────────────┘

T=0ms
  │
  ▼
┌────────────────────────────────────────┐
│  1. USER CLICKS LOGIN BUTTON           │
│  Location: /login                      │
│  File: app/login/page.tsx:143          │
└────────────────────────────────────────┘
  │
  │ validateForm()
  │ setIsSubmitting(true)
  ▼
T=50ms
┌────────────────────────────────────────┐
│  2. CALL AUTH CONTEXT LOGIN            │
│  File: contexts/AuthContext.tsx:572    │
│  Action: dispatch(LOGIN_START)         │
└────────────────────────────────────────┘
  │
  │ authService.login(credentials)
  ▼
T=100ms
┌────────────────────────────────────────┐
│  3. AUTH SERVICE MAKES API REQUEST     │
│  File: services/auth.service.ts:246    │
│  Endpoint: POST /api/auth/login        │
│  Timeout: 60s                          │
└────────────────────────────────────────┘
  │
  │ apiClient.request()
  ▼
T=150ms
┌────────────────────────────────────────┐
│  4. FRONTEND API ROUTE PROXY           │
│  File: app/api/auth/login/route.ts:28  │
│  Action: Forward to backend            │
│  Timeout: 50s                          │
└────────────────────────────────────────┘
  │
  │ fetch(backend:8000/api/token)
  ▼
T=200ms
┌────────────────────────────────────────┐
│  5. BACKEND AUTHENTICATION             │
│  File: app/routers/auth.py:206         │
│  Action: Validate credentials          │
│  - authenticate_user()                 │
│  - create_access_token()               │
│  - create_refresh_token()              │
│  - create_user_response()              │
└────────────────────────────────────────┘
  │
  │ Return auth response
  ▼
T=500ms
┌────────────────────────────────────────┐
│  6. BACKEND RETURNS TOKENS             │
│  Response:                             │
│  {                                     │
│    access_token: "eyJ...",             │
│    refresh_token: "eyJ...",            │
│    token_type: "bearer",               │
│    expires_in: 1800,                   │
│    user: { id, email, ... }            │
│  }                                     │
└────────────────────────────────────────┘
  │
  │ Frontend API route returns
  ▼
T=550ms
┌────────────────────────────────────────┐
│  7. AUTH SERVICE PROCESSES RESPONSE    │
│  File: services/auth.service.ts:265    │
│  Actions:                              │
│  - transformUser()                     │
│  - apiClient.setTokens() ✅            │
│  - localStorage.setItem(tokens) ✅     │
│  - setCurrentUser() ✅                 │
│  - localStorage.setItem(user) ✅       │
└────────────────────────────────────────┘
  │
  │ Return LoginResponse
  ▼
T=600ms
┌────────────────────────────────────────┐
│  8. AUTH CONTEXT RECEIVES RESPONSE     │
│  File: contexts/AuthContext.tsx:600    │
│  Action: dispatch(LOGIN_SUCCESS)       │
│  State Update:                         │
│  - isAuthenticated = true              │
│  - user = response.user                │
│  - tokenReady = true                   │
│  - loading = false                     │
└────────────────────────────────────────┘
  │
  │ Verify storage
  │ Get redirect path
  ▼
T=650ms
┌────────────────────────────────────────┐
│  9. AUTH CONTEXT PREPARES NAVIGATION   │
│  File: contexts/AuthContext.tsx:614    │
│  Actions:                              │
│  - const storedPath = sessionStorage   │
│  - const redirectPath = '/dashboard'   │
│  - sessionStorage.remove(path)         │
└────────────────────────────────────────┘
  │
  │ ⚠️ await new Promise(100ms) ⚠️
  ▼
T=750ms
┌────────────────────────────────────────┐
│  10. NAVIGATE TO DASHBOARD             │
│  File: contexts/AuthContext.tsx:644    │
│  Action: router.replace('/dashboard')  │
│  ⏰ 100ms delay injected                │
└────────────────────────────────────────┘
  │
  │ Next.js router transition
  ▼
T=800ms
┌────────────────────────────────────────┐
│  11. DASHBOARD PAGE BEGINS MOUNT       │
│  File: app/dashboard/page.tsx:830      │
│  Component: DashboardPage              │
│  Wrapped in: ProtectedRoute            │
└────────────────────────────────────────┘
  │
  │ React mounting phase
  ▼
T=850ms
┌────────────────────────────────────────┐
│  12. PROTECTED ROUTE MOUNTS            │
│  File: components/auth/ProtectedRoute  │
│       tsx:147                          │
│  Initial State:                        │
│  - gracePeriod = true ⏰               │
│  - showLoading = true                  │
└────────────────────────────────────────┘
  │
  │ useAuthCheck() runs
  ▼
T=900ms
┌────────────────────────────────────────┐
│  13. USE AUTH CHECK EXECUTES           │
│  File: ProtectedRoute.tsx:33           │
│  Reads from AuthContext:               │
│  - authState.isAuthenticated = ???     │
│  - authState.user = ???                │
│  - authState.initializing = false      │
│  - authState.tokenReady = ???          │
│                                        │
│  ⚠️ STATE MAY NOT BE PROPAGATED YET ⚠️ │
└────────────────────────────────────────┘
  │
  │ if (initializing) return loading
  │ Shows <AuthLoadingSpinner />
  ▼
T=1000ms
┌────────────────────────────────────────┐
│  14. LOADING SPINNER DISPLAYED         │
│  Component: AuthLoadingSpinner         │
│  Message: "Checking authentication..."│
│                                        │
│  Grace period timer running...         │
└────────────────────────────────────────┘
  │
  │ Wait for grace period
  ▼
T=1350ms
┌────────────────────────────────────────┐
│  15. GRACE PERIOD EXPIRES              │
│  File: ProtectedRoute.tsx:175          │
│  Timer: setTimeout(500ms) complete     │
│  Action: setGracePeriod(false)         │
│  ⏰ 500ms grace period ⏰               │
└────────────────────────────────────────┘
  │
  │ useEffect[gracePeriod] triggers
  ▼
T=1400ms
┌────────────────────────────────────────┐
│  16. AUTH CHECK USEEFFECT RUNS         │
│  File: ProtectedRoute.tsx:183          │
│  Checks:                               │
│  - loading = false ✅                  │
│  - gracePeriod = false ✅              │
│  - requireAuth = true ✅               │
│  - isAuthenticated = ???               │
│                                        │
│  🔍 CRITICAL CHECK POINT 🔍            │
└────────────────────────────────────────┘
  │
  │ if (!isAuthenticated) { ... }
  ▼
T=1450ms

  ┌─────────────────────────┐       ┌─────────────────────────┐
  │  SUCCESS PATH ✅         │       │  FAILURE PATH ❌         │
  │                         │       │                         │
  │  isAuthenticated=true   │       │  isAuthenticated=false  │
  │  State propagated ✅    │       │  State not ready ❌     │
  │                         │       │                         │
  │  Continue render        │       │  Redirect to login      │
  │  Show dashboard         │       │  User appears logged out│
  └─────────────────────────┘       └─────────────────────────┘
          │                                     │
          ▼                                     ▼
    ┌─────────────────┐              ┌─────────────────────┐
    │  17A. SUCCESS   │              │  17B. FAILURE       │
    │  Dashboard      │              │  Redirected to      │
    │  renders        │              │  /login             │
    │  User logged in │              │  "Logged out" bug   │
    └─────────────────┘              └─────────────────────┘
```

---

## Race Condition Detail

```
┌───────────────────────────────────────────────────────────────────────┐
│                        THE CRITICAL RACE WINDOW                         │
│                    Between T=650ms and T=1400ms                        │
└───────────────────────────────────────────────────────────────────────┘

T=650ms: LOGIN_SUCCESS dispatched
  │
  │ React batches state updates
  │ Virtual DOM diffing
  │ Component re-render scheduling
  │
  ▼
T=700ms: AuthContext updates
  │
  │ Context consumers notified
  │ useAuth() hooks receive new state
  │
  ▼
T=750ms: Navigation triggered
  │
  │ router.replace() called
  │ Next.js routing starts
  │ Old route unmounting begins
  │
  ▼
T=800ms: Dashboard mounting
  │
  │ New route components mount
  │ ProtectedRoute initializes
  │ useAuthCheck() first run
  │
  ▼
T=850ms: State may be inconsistent
  │
  │ ⚠️ React hasn't finished propagating state
  │ ⚠️ Context value may be stale
  │ ⚠️ useAuth() might return old state
  │
  ▼
T=900ms: Loading state shown
  │
  │ Grace period prevents premature checks
  │ Spinner displayed to user
  │
  ▼
T=1000ms: State propagating
  │
  │ React's reconciliation continuing
  │ Context updates flowing through tree
  │ Multiple re-renders happening
  │
  ▼
T=1200ms: State should be stable
  │
  │ By now, state should be consistent
  │ But no guarantee...
  │
  ▼
T=1350ms: Grace period ends
  │
  │ 500ms timeout completes
  │ Auth check will run next
  │
  ▼
T=1400ms: THE CRITICAL MOMENT
  │
  │ 🎲 RACE CONDITION WINDOW 🎲
  │
  ├─→ State Ready? ──→ SUCCESS ✅
  │
  └─→ State Not Ready? ──→ REDIRECT TO LOGIN ❌
      │
      └─→ User sees "logged out" bug
```

---

## Component State Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    STATE PROPAGATION PATH                      │
└──────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  AuthContext (Provider)                                       │
│  File: contexts/AuthContext.tsx                              │
│                                                              │
│  State: {                                                    │
│    isAuthenticated: true,     ← LOGIN_SUCCESS sets this     │
│    user: User,                ← From response               │
│    loading: false,            ← No longer loading           │
│    initializing: false,       ← Initialization complete     │
│    tokenReady: true,          ← Tokens stored               │
│  }                                                           │
│                                                              │
│  Context Value: { state, login, logout, ... }                │
└─────────────────────────────────────────────────────────────┘
        │
        │ React Context propagation
        ▼
┌─────────────────────────────────────────────────────────────┐
│  App Layout                                                   │
│  File: app/layout.tsx:131                                    │
│                                                              │
│  <AuthProvider>                                              │
│    <BrandProvider>                                           │
│      <BrandGuard>                                            │
│        {children}         ← Dashboard Page                   │
│      </BrandGuard>                                           │
│    </BrandProvider>                                          │
│  </AuthProvider>                                             │
└─────────────────────────────────────────────────────────────┘
        │
        │ Component tree
        ▼
┌─────────────────────────────────────────────────────────────┐
│  Dashboard Page                                               │
│  File: app/dashboard/page.tsx:830                            │
│                                                              │
│  <ProtectedRoute requireAuth={true}>                         │
│    <Dashboard />                                             │
│  </ProtectedRoute>                                           │
└─────────────────────────────────────────────────────────────┘
        │
        │ Wrapped component
        ▼
┌─────────────────────────────────────────────────────────────┐
│  ProtectedRoute                                               │
│  File: components/auth/ProtectedRoute.tsx:147                │
│                                                              │
│  const { state } = useAuth()     ← Consumes AuthContext     │
│  const { isAuthenticated, user, loading } = state            │
│                                                              │
│  useEffect(() => {                                           │
│    if (!loading && !gracePeriod) {                           │
│      if (!isAuthenticated) {                                 │
│        router.replace('/login')  ← REDIRECT POINT ❌        │
│      }                                                       │
│    }                                                         │
│  }, [loading, gracePeriod, isAuthenticated])                │
└─────────────────────────────────────────────────────────────┘
```

---

## Token Storage Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    TOKEN STORAGE LIFECYCLE                     │
└──────────────────────────────────────────────────────────────┘

Backend Response
  │
  │ { access_token, refresh_token, expires_in, user }
  ▼
┌─────────────────────────────────────┐
│  AuthService.login()                │
│  File: services/auth.service.ts     │
│                                     │
│  1. transformUser(backendUser)      │
│  2. apiClient.setTokens(...)        │
│  3. setCurrentUser(user)            │
│  4. Return LoginResponse            │
└─────────────────────────────────────┘
  │
  ├──────────────────────┬─────────────────────┐
  ▼                      ▼                     ▼
┌─────────────┐  ┌─────────────┐  ┌──────────────────┐
│ API Client  │  │ localStorage│  │ AuthContext      │
│ Memory      │  │ Tokens      │  │ User State       │
│             │  │             │  │                  │
│ tokenStorage│  │ engarde_    │  │ state.user       │
│ .accessToken│  │ tokens      │  │ state.isAuth...  │
│ .refreshTokn│  │             │  │ state.tokenReady │
│ .expiresAt  │  │ {           │  │                  │
│             │  │   access... │  │ {                │
│ ✅ Sync     │  │   refresh...│  │   id: "...",     │
│ write       │  │   expiresAt │  │   email: "...",  │
│             │  │ }           │  │   userType: "..." │
│             │  │             │  │ }                │
│             │  │ ✅ Sync     │  │                  │
│             │  │ write       │  │ ✅ Async via     │
│             │  │             │  │ dispatch()       │
└─────────────┘  └─────────────┘  └──────────────────┘
      │                  │                   │
      │                  │                   │
      ▼                  ▼                   ▼
┌────────────────────────────────────────────────┐
│  VERIFICATION CHECKS                           │
│                                                │
│  apiClient.isAuthenticated()                   │
│  ├─ Check accessToken exists                   │
│  ├─ Check expiresAt exists                     │
│  ├─ Check not expired (60s buffer)             │
│  └─ Return boolean                             │
│                                                │
│  authService.getCachedUser()                   │
│  ├─ Check tokens valid first                   │
│  ├─ Read from localStorage                     │
│  ├─ Check cache age (< 1 hour)                 │
│  └─ Return User | null                         │
│                                                │
│  ✅ Both synchronous reads                     │
│  ✅ No async delays                            │
│  ⚠️ Can be called before state propagates      │
└────────────────────────────────────────────────┘
```

---

## The Problematic Delays

```
┌───────────────────────────────────────────────────────────────┐
│                    ARTIFICIAL TIMING DELAYS                     │
│                    (Causing Race Conditions)                    │
└───────────────────────────────────────────────────────────────┘

Location 1: AuthContext.login()
File: contexts/AuthContext.tsx:641

  dispatch({ type: 'LOGIN_SUCCESS', payload: response.user })
    │
    │ State update queued...
    │
  await new Promise(resolve => setTimeout(resolve, 100))  ⏰
    │
    │ ⚠️ 100ms delay before navigation
    │ ⚠️ Doesn't guarantee state propagation
    │ ⚠️ Just adds latency
    │
  router.replace(redirectPath)

─────────────────────────────────────────────────────────────

Location 2: ProtectedRoute initialization
File: components/auth/ProtectedRoute.tsx:174-180

  const [gracePeriod, setGracePeriod] = useState(true)
    │
  useEffect(() => {
    const timer = setTimeout(() => {
      setGracePeriod(false)  ⏰
    }, 500)  // 500ms grace period
    │
    │ ⚠️ 500ms before auth checks run
    │ ⚠️ State might still not be ready
    │ ⚠️ Or state might be ready much earlier
    │
    return () => clearTimeout(timer)
  }, [])

─────────────────────────────────────────────────────────────

Total Unnecessary Delay: 600ms

⚠️ Problems:
  1. Fixed delays don't adapt to actual state propagation
  2. Too short = state not ready = logout bug
  3. Too long = poor user experience
  4. Creates false sense of reliability
```

---

## Correct State Synchronization (Recommended)

```
┌───────────────────────────────────────────────────────────────┐
│              PROPER STATE SYNCHRONIZATION APPROACH              │
│                  (No Artificial Delays)                        │
└───────────────────────────────────────────────────────────────┘

Step 1: Login Success
  │
  dispatch({ type: 'LOGIN_SUCCESS', payload: user })
  │
  ▼
Step 2: Use React 18's useTransition (Optional)
  │
  const [isPending, startTransition] = useTransition()
  │
  startTransition(() => {
    router.replace('/dashboard')
  })
  │
  ▼
Step 3: ProtectedRoute Uses Optimistic State
  │
  const { isAuthenticated } = useAuth()
  const justLoggedIn = sessionStorage.getItem('login_success')
  │
  const shouldAllow = isAuthenticated || justLoggedIn
  │
  if (shouldAllow) {
    // Clear flag after successful render
    sessionStorage.removeItem('login_success')
    return <>{children}</>
  }
  │
  ▼
Step 4: No Delays, No Grace Periods
  │
  React's concurrent features handle state updates
  │
  ✅ Fast
  ✅ Reliable
  ✅ Responsive
```

---

## Summary

The logout bug occurs due to:

1. **Race Condition Window**: 650ms-1400ms between login success and auth check
2. **Artificial Delays**: 100ms + 500ms = 600ms of unnecessary waiting
3. **Synchronous Checks**: Auth verification happens before React finishes state propagation
4. **No State Guarantees**: No mechanism to ensure state is ready before checking

**Solution**: Remove timing-based delays and use React's state management correctly.

