# EnGarde Development - Quick Start Guide

## Get Started in 30 Seconds

```bash
# 1. Start the development environment
./scripts/dev-start.sh

# 2. Wait 1-2 minutes, then open your browser
# Frontend: http://localhost:3000
# Backend API: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

That's it! You're ready to code.

## Hot Reload is Enabled

Just edit your files - changes apply automatically:
- **Backend**: Edit `production-backend/app/*.py` - auto-reloads
- **Frontend**: Edit `production-frontend/app/**/*.tsx` - Fast Refresh

No need to restart anything!

## Essential Commands

```bash
# View logs
./scripts/dev-logs.sh

# Check if everything is healthy
./scripts/dev-health.sh

# Stop for the day (keeps your data)
./scripts/dev-stop.sh

# Having issues? Rebuild
./scripts/dev-rebuild.sh

# Nuclear option (deletes all data!)
./scripts/dev-reset.sh
```

## Common Issues

**Services won't start?**
```bash
./scripts/dev-health.sh --verbose  # See what's wrong
./scripts/dev-logs.sh              # Check logs
```

**Something broken?**
```bash
# Try restart
./scripts/dev-stop.sh && ./scripts/dev-start.sh

# Still broken? Rebuild
./scripts/dev-rebuild.sh

# Still broken? Reset
./scripts/dev-reset.sh --yes && ./scripts/dev-start.sh
```

**Need help?**
```bash
./scripts/dev-start.sh --help      # Each script has help
```

## Daily Workflow

**Morning**:
```bash
./scripts/dev-start.sh
# Wait 1-2 minutes
# Start coding
```

**While Working**:
```bash
# Just edit files - they auto-reload!
# Check logs if needed: ./scripts/dev-logs.sh
```

**Evening**:
```bash
./scripts/dev-stop.sh
# Your data is preserved for tomorrow
```

## After Git Pull

**Code only changed?**
```bash
./scripts/dev-start.sh  # Hot-reload handles it
```

**Dependencies changed?** (package.json, requirements.txt)
```bash
./scripts/dev-rebuild.sh  # 5-10 minutes
```

**Database changed?**
```bash
./scripts/dev-reset.sh    # Deletes data!
./scripts/dev-start.sh
```

## Service URLs

When running:
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- PostgreSQL: localhost:5432
- Redis: localhost:6379

## File Structure

```
EnGardeHQ/
├── scripts/
│   ├── dev-start.sh         # Start environment
│   ├── dev-stop.sh          # Stop environment
│   ├── dev-logs.sh          # View logs
│   ├── dev-health.sh        # Check health
│   ├── dev-rebuild.sh       # Rebuild everything
│   └── dev-reset.sh         # Nuclear reset
│
├── production-backend/
│   └── app/                 # Edit Python here (auto-reloads)
│
├── production-frontend/
│   └── app/                 # Edit TypeScript here (Fast Refresh)
│
└── docker-compose.dev.yml   # Development config
```

## Need More Details?

- **Full docs**: `./scripts/DEV_SCRIPTS_README.md`
- **Quick reference**: `./scripts/DEV_QUICK_REFERENCE.md`
- **Summary**: `./DEVELOPMENT_SCRIPTS_SUMMARY.md`

## First Time Setup

1. Make sure Docker Desktop is running
2. Run `./scripts/dev-start.sh`
3. Wait for services to start (first time takes 5-10 minutes to build)
4. Open http://localhost:3000

## Tips

- **Keep data**: Use `./scripts/dev-stop.sh` (NOT --clean)
- **Check health first**: Run `./scripts/dev-health.sh` when debugging
- **Watch logs**: Use `./scripts/dev-logs.sh -g "error"` to see errors
- **Hot reload works**: Just edit files, they auto-reload
- **Rebuild when needed**: After dependency or Dockerfile changes

---

**Happy coding!** 🚀

For detailed documentation, see `./scripts/DEV_SCRIPTS_README.md`
