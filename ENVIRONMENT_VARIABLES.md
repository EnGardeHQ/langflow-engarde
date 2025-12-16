# EnGarde Platform - Environment Variables Configuration

## Environment Variable Categories and Docker Service References

### Critical Configuration Summary

| Category | Variable | Type | Docker Service Reference | Default Value | Description |
|----------|----------|------|-------------------------|---------------|-------------|
| **🔴 CRITICAL SECRETS** | | | | | |
| Security | `SECRET_KEY` | Critical Secret | N/A | MUST CHANGE | Master application secret key |
| Security | `JWT_SECRET_KEY` | Critical Secret | N/A | MUST CHANGE | JWT token signing key |
| Security | `NEXTAUTH_SECRET` | Critical Secret | N/A | MUST CHANGE | NextAuth.js secret |
| Security | `ENCRYPTION_KEY` | Critical Secret | N/A | MUST CHANGE | Data encryption key |
| Database | `POSTGRES_PASSWORD` | Critical Secret | N/A | MUST CHANGE | PostgreSQL password |
| **🟡 DOCKER SERVICE URLS** | | | | | |
| Database | `DATABASE_URL` | Docker Service | `postgresql://engarde_user:${POSTGRES_PASSWORD}@postgres:5432/engarde` | - | PostgreSQL connection |
| Cache | `REDIS_URL` | Docker Service | `redis://redis:6379/0` | - | Redis connection |
| Backend | `NEXT_PUBLIC_API_URL` | Docker Service | `http://backend:8000` | - | Backend API URL for frontend |
| Backend | `BACKEND_URL` | Docker Service | `http://backend:8000` | - | Internal backend URL |
| Frontend | `FRONTEND_URL` | Docker Service | `http://frontend:3000` | - | Internal frontend URL |
| **🟢 SHARED CONFIGURATIONS** | | | | | |
| App | `ENVIRONMENT` | Shared | N/A | `development` | Environment mode |
| App | `DEBUG` | Shared | N/A | `false` | Debug mode |
| App | `LOG_LEVEL` | Shared | N/A | `info` | Logging level |

## Complete Environment Variables Reference

### Core Application Settings

| Variable | Required | Default | Docker Override | Description |
|----------|----------|---------|-----------------|-------------|
| `ENVIRONMENT` | Yes | `development` | - | Environment mode (development/staging/production) |
| `DEBUG` | Yes | `false` | - | Enable debug mode |
| `SECRET_KEY` | Yes | - | - | Application secret key |
| `LOG_LEVEL` | No | `info` | - | Logging level (debug/info/warning/error) |
| `API_VERSION` | No | `v1` | - | API version prefix |
| `SERVICE_NAME` | No | `engarde-platform` | - | Service identifier |

### Database Configuration

| Variable | Required | Default | Docker Override | Description |
|----------|----------|---------|-----------------|-------------|
| `DATABASE_URL` | Yes | - | `postgresql://engarde_user:${POSTGRES_PASSWORD}@postgres:5432/engarde` | PostgreSQL connection string |
| `POSTGRES_HOST` | No | `localhost` | `postgres` | PostgreSQL host |
| `POSTGRES_PORT` | No | `5432` | `5432` | PostgreSQL port |
| `POSTGRES_DB` | Yes | `engarde` | - | Database name |
| `POSTGRES_USER` | Yes | `engarde_user` | - | Database user |
| `POSTGRES_PASSWORD` | Yes | - | - | Database password |
| `DB_POOL_SIZE` | No | `10` | - | Connection pool size |
| `DB_MAX_OVERFLOW` | No | `20` | - | Max overflow connections |

### Redis Configuration

| Variable | Required | Default | Docker Override | Description |
|----------|----------|---------|-----------------|-------------|
| `REDIS_URL` | Yes | - | `redis://redis:6379/0` | Redis connection string |
| `REDIS_HOST` | No | `localhost` | `redis` | Redis host |
| `REDIS_PORT` | No | `6379` | `6379` | Redis port |
| `REDIS_DB` | No | `0` | - | Redis database number |
| `REDIS_PASSWORD` | No | - | - | Redis password (if auth enabled) |
| `REDIS_MAX_CONNECTIONS` | No | `20` | - | Max Redis connections |

### Authentication & Security

| Variable | Required | Default | Docker Override | Description |
|----------|----------|---------|-----------------|-------------|
| `JWT_SECRET_KEY` | Yes | - | - | JWT signing key |
| `JWT_ALGORITHM` | No | `HS256` | - | JWT algorithm |
| `JWT_EXPIRATION_HOURS` | No | `24` | - | JWT token expiration |
| `NEXTAUTH_SECRET` | Yes | - | - | NextAuth.js secret |
| `NEXTAUTH_URL` | Yes | - | `http://localhost:3000` | NextAuth callback URL |
| `BCRYPT_ROUNDS` | No | `12` | - | Bcrypt hash rounds |

### AI Services

| Variable | Required | Default | Docker Override | Description |
|----------|----------|---------|-----------------|-------------|
| `OPENAI_API_KEY` | No | - | - | OpenAI API key |
| `OPENAI_MODEL` | No | `gpt-4` | - | Default OpenAI model |
| `OPENAI_MAX_TOKENS` | No | `2000` | - | Max tokens per request |
| `ANTHROPIC_API_KEY` | No | - | - | Anthropic Claude API key |
| `ANTHROPIC_MODEL` | No | `claude-3-sonnet` | - | Default Anthropic model |
| `GOOGLE_AI_API_KEY` | No | - | - | Google AI API key |
| `GEMINI_API_KEY` | No | - | - | Google Gemini API key |

### Payment Integration

| Variable | Required | Default | Docker Override | Description |
|----------|----------|---------|-----------------|-------------|
| `STRIPE_PUBLISHABLE_KEY` | No | - | - | Stripe public key |
| `STRIPE_SECRET_KEY` | No | - | - | Stripe secret key |
| `STRIPE_WEBHOOK_SECRET` | No | - | - | Stripe webhook secret |
| `PAYPAL_CLIENT_ID` | No | - | - | PayPal client ID |
| `PAYPAL_CLIENT_SECRET` | No | - | - | PayPal client secret |
| `PAYPAL_MODE` | No | `sandbox` | - | PayPal mode (sandbox/live) |

### Marketplace Configuration

| Variable | Required | Default | Docker Override | Description |
|----------|----------|---------|-----------------|-------------|
| `MARKETPLACE_ENABLED` | No | `true` | - | Enable marketplace features |
| `MARKETPLACE_COMMISSION_RATE` | No | `0.15` | - | Commission rate (15%) |
| `MARKETPLACE_CREDIT_USD_RATE` | No | `0.01` | - | Credits to USD conversion |
| `MARKETPLACE_CSV_UPLOAD_PATH` | No | `/app/marketplace/csv_imports` | - | CSV upload directory |
| `MARKETPLACE_MAX_FILE_SIZE` | No | `50MB` | - | Max upload file size |
| `AGENT_APPROVAL_REQUIRED_THRESHOLD` | No | `100` | - | Auto-approval threshold |
| `AGENT_AUTO_APPROVE_FREE` | No | `true` | - | Auto-approve free agents |
| `AGENT_MAX_TAGS` | No | `10` | - | Max tags per agent |

### Frontend Configuration

| Variable | Required | Default | Docker Override | Description |
|----------|----------|---------|-----------------|-------------|
| `NEXT_PUBLIC_API_URL` | Yes | - | `http://backend:8000` | Backend API URL |
| `NEXT_PUBLIC_APP_NAME` | No | `Engarde` | - | Application name |
| `NEXT_PUBLIC_APP_VERSION` | No | `1.0.0` | - | Application version |
| `NEXT_PUBLIC_AUTH_PROVIDER` | No | `supabase` | - | Auth provider |
| `NODE_ENV` | No | `production` | - | Node environment |

### Email Configuration

| Variable | Required | Default | Docker Override | Description |
|----------|----------|---------|-----------------|-------------|
| `SMTP_HOST` | No | - | - | SMTP server host |
| `SMTP_PORT` | No | `587` | - | SMTP server port |
| `SMTP_USER` | No | - | - | SMTP username |
| `SMTP_PASSWORD` | No | - | - | SMTP password |
| `SMTP_TLS` | No | `true` | - | Enable TLS |
| `FROM_EMAIL` | No | `noreply@engarde.app` | - | Default from email |

### CORS & Security

| Variable | Required | Default | Docker Override | Description |
|----------|----------|---------|-----------------|-------------|
| `CORS_ORIGINS` | Yes | - | `http://localhost:3000,http://frontend:3000` | Allowed CORS origins |
| `CORS_ALLOW_CREDENTIALS` | No | `true` | - | Allow credentials |
| `RATE_LIMIT_PER_MINUTE` | No | `100` | - | Rate limit per minute |
| `ALLOWED_HOSTS` | No | `localhost,127.0.0.1` | - | Allowed hosts |

### Feature Flags

| Variable | Required | Default | Docker Override | Description |
|----------|----------|---------|-----------------|-------------|
| `FEATURE_AI_AGENTS` | No | `true` | - | Enable AI agents |
| `FEATURE_ANALYTICS` | No | `true` | - | Enable analytics |
| `FEATURE_MARKETPLACE` | No | `true` | - | Enable marketplace |
| `FEATURE_WEBHOOKS` | No | `true` | - | Enable webhooks |
| `FEATURE_SSO` | No | `true` | - | Enable SSO |
| `FEATURE_AUDIT_LOGGING` | No | `true` | - | Enable audit logging |

### Monitoring

| Variable | Required | Default | Docker Override | Description |
|----------|----------|---------|-----------------|-------------|
| `SENTRY_DSN` | No | - | - | Sentry error tracking DSN |
| `SENTRY_ENVIRONMENT` | No | `development` | - | Sentry environment |
| `PROMETHEUS_ENABLED` | No | `true` | - | Enable Prometheus metrics |
| `METRICS_PORT` | No | `9090` | - | Metrics port |

## Docker Compose Service Mapping

### Service URLs in Docker Network

When running in Docker Compose, use these internal service names:

| Service | Internal URL | External Port | Purpose |
|---------|--------------|---------------|---------|
| `postgres` | `postgres:5432` | `5432` | PostgreSQL database |
| `redis` | `redis:6379` | `6379` | Redis cache |
| `backend` | `backend:8000` | `8000` | FastAPI backend |
| `frontend` | `frontend:3000` | `3000` | Next.js frontend |
| `nginx` | `nginx:80` | `80` | Reverse proxy (optional) |

### Environment Variable Resolution Order

1. **Root `.env` file** - Shared cross-service values
2. **Service-specific `.env` files** - Override or extend root values
3. **Docker Compose environment** - Final override in docker-compose.yml

## Security Classification

### 🔴 Critical Secrets (MUST change in production)
- All `*_SECRET_KEY` variables
- All `*_PASSWORD` variables
- All API keys (`*_API_KEY`)
- OAuth secrets (`*_CLIENT_SECRET`)
- Webhook secrets (`*_WEBHOOK_SECRET`)

### 🟡 Service URLs (Docker network aware)
- `DATABASE_URL` - Points to `postgres` service
- `REDIS_URL` - Points to `redis` service
- `NEXT_PUBLIC_API_URL` - Points to `backend` service
- `BACKEND_URL` - Internal backend reference
- `FRONTEND_URL` - Internal frontend reference

### 🟢 Configuration Values (Safe defaults)
- Feature flags
- Rate limits
- Pool sizes
- Timeouts
- File paths