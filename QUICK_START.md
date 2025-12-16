# EnGarde Docker Development - Quick Start

## TL;DR - Get Started in 30 Seconds

```bash
# Start development environment with hot-reload
./dev-start.sh --watch
```

That's it! Your development environment is now running with automatic hot-reload.

## What You Get

- **Frontend**: http://localhost:3000 (Next.js with Fast Refresh)
- **Backend**: http://localhost:8000 (FastAPI with auto-reload)
- **API Docs**: http://localhost:8000/docs
- **Hot-Reload**: Edit code, see changes instantly (no rebuilds!)

## How Hot-Reload Works

### Backend (Python/FastAPI)
1. Edit any `.py` file in `production-backend/app/`
2. Uvicorn detects the change and reloads automatically
3. Changes appear in ~1 second

### Frontend (Next.js)
1. Edit any file in:
   - `production-frontend/app/` (pages/layouts)
   - `production-frontend/components/` (React components)
   - `production-frontend/styles/` (CSS/styles)
2. Next.js Fast Refresh updates the browser automatically
3. Changes appear instantly without page reload

## Common Commands

```bash
# Start (with automatic watch)
./dev-start.sh --watch

# Start fresh (remove old containers)
./dev-start.sh --clean --watch

# View logs
docker compose -f docker-compose.dev.yml logs -f backend
docker compose -f docker-compose.dev.yml logs -f frontend

# Stop everything
docker compose -f docker-compose.dev.yml down

# Restart a single service
docker compose -f docker-compose.dev.yml restart backend
```

## Troubleshooting

### Changes not showing up?

```bash
# Restart watch mode
docker compose -f docker-compose.dev.yml watch
```

### Frontend errors?

```bash
# Rebuild frontend
docker compose -f docker-compose.dev.yml up --build frontend
```

### Backend errors?

```bash
# Rebuild backend
docker compose -f docker-compose.dev.yml up --build backend
```

### Database issues?

```bash
# Recreate database
docker compose -f docker-compose.dev.yml down -v
docker compose -f docker-compose.dev.yml up --build
```

## What's Different from Production?

| Feature | Development | Production |
|---------|-------------|------------|
| Code sync | Live bind mounts | Copied into image |
| Reload | Automatic | Manual restart |
| Logging | Debug/verbose | Info only |
| CORS | Permissive | Strict |
| Security | Relaxed | Hardened |
| Performance | Good | Optimized |

## Full Documentation

For detailed information, see [DEVELOPMENT.md](./DEVELOPMENT.md)

## Requirements

- Docker Desktop 4.24+ or Docker Engine with Compose v2.22+
- 8GB RAM available for Docker
- 10GB free disk space

## Need Help?

1. Check logs: `docker compose -f docker-compose.dev.yml logs`
2. Check Docker: `docker info`
3. Read full guide: [DEVELOPMENT.md](./DEVELOPMENT.md)
