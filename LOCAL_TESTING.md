# EnGarde Local Testing Guide

This guide will help you set up and run the EnGarde application locally for development and testing.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Service URLs](#service-urls)
- [Test Credentials](#test-credentials)
- [Detailed Setup](#detailed-setup)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)
- [Database Management](#database-management)
- [Development Workflow](#development-workflow)

---

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

1. **Docker Desktop** (v20.10 or higher)
   - [Download for Mac](https://www.docker.com/products/docker-desktop/)
   - [Download for Windows](https://www.docker.com/products/docker-desktop/)
   - Ensure Docker Desktop is running before proceeding

2. **Docker Compose** (v2.0 or higher)
   - Usually included with Docker Desktop
   - Verify installation: `docker-compose --version`

### System Requirements

- **RAM**: Minimum 8GB, recommended 16GB
- **Disk Space**: At least 10GB free
- **CPU**: Multi-core processor recommended

### Optional

- **PostgreSQL Client** (for database access)
  - Mac: `brew install postgresql`
  - Windows: Download from [postgresql.org](https://www.postgresql.org/download/)

---

## Quick Start

The fastest way to get started is using our automated setup script:

```bash
# Make the script executable
chmod +x scripts/setup-local-testing.sh

# Run the setup script
./scripts/setup-local-testing.sh
```

This script will:
1. Check that Docker is running
2. Clean up any old containers
3. Build all Docker images
4. Start all services (postgres, redis, backend, frontend, langflow)
5. Wait for services to be healthy
6. Run database migrations
7. Seed test data
8. Display access URLs and credentials

**Estimated time**: 5-10 minutes (depending on internet speed and system resources)

---

## Service URLs

After setup completes, access the application at these URLs:

### Frontend Application
- **URL**: http://localhost:3001
- **Description**: Main user interface for EnGarde

### Backend API
- **Base URL**: http://localhost:8000
- **Swagger Docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health

### Langflow (AI Workflow Builder)
- **URL**: http://localhost:7860
- **Username**: `admin`
- **Password**: `admin`

### Database
- **Host**: localhost
- **Port**: 5432
- **Database**: engarde
- **Username**: engarde_user
- **Password**: engarde_password

### Redis
- **Host**: localhost
- **Port**: 6379

---

## Test Credentials

Use these credentials to log in to the application:

| Field    | Value                |
|----------|----------------------|
| Email    | demo@engarde.local   |
| Password | demo123              |
| Role     | Admin                |
| Tenant   | Demo Organization    |

### What's Included in Test Data

The test database includes:
- Demo user with admin privileges
- Demo organization (tenant)
- Demo brand with brand guidelines
- Sample platform connections (Google Ads, Meta, LinkedIn, Google Analytics, Shopify)
- Sample campaigns (3 active campaigns)
- Sample AI agents (Content Creator, Audience Analyzer, Campaign Optimizer)
- Sample audience segments (High-Value Customers, Cart Abandoners)

---

## Detailed Setup

If you prefer manual setup or need more control:

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd EnGardeHQ
```

### Step 2: Create Environment Files (Optional)

The application works with default values, but you can customize:

```bash
# Root .env file (optional)
cp .env.example .env

# Backend .env file (optional)
cp production-backend/.env.example production-backend/.env

# Frontend .env file (optional)
cp production-frontend/.env.example production-frontend/.env
```

### Step 3: Start Services

```bash
# Using the override for development features
docker-compose -f docker-compose.yml -f docker-compose.local.yml up -d

# Or use the standard configuration
docker-compose up -d
```

### Step 4: Wait for Services

```bash
# Watch logs to see when services are ready
docker-compose logs -f
```

Wait until you see:
- PostgreSQL: "database system is ready to accept connections"
- Backend: "Application startup complete"
- Frontend: "compiled successfully"

### Step 5: Run Migrations

```bash
docker exec engarde_backend alembic upgrade head
```

### Step 6: Seed Test Data

```bash
docker exec -i engarde_postgres psql -U engarde_user -d engarde < production-backend/scripts/seed-local-test-data.sql
```

---

## Common Tasks

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f postgres

# Last 100 lines
docker-compose logs --tail=100 backend
```

### Restart a Service

```bash
# Restart backend
docker-compose restart backend

# Restart frontend
docker-compose restart frontend

# Restart all services
docker-compose restart
```

### Stop Services

```bash
# Stop all services (keeps data)
docker-compose down

# Stop and remove volumes (destroys data)
docker-compose down -v
```

### Rebuild a Service

```bash
# Rebuild backend without cache
docker-compose build --no-cache backend

# Rebuild and restart
docker-compose up -d --build backend
```

### Access Container Shells

```bash
# Backend container
docker exec -it engarde_backend /bin/bash

# Frontend container
docker exec -it engarde_frontend /bin/sh

# PostgreSQL container
docker exec -it engarde_postgres /bin/bash

# Database shell
docker exec -it engarde_postgres psql -U engarde_user -d engarde
```

---

## Troubleshooting

### Docker Not Running

**Error**: `Cannot connect to the Docker daemon`

**Solution**:
1. Open Docker Desktop
2. Wait for it to fully start (whale icon should be stable)
3. Run the setup script again

### Port Already in Use

**Error**: `port is already allocated`

**Solution**:
```bash
# Find what's using the port
lsof -i :3001  # Frontend
lsof -i :8000  # Backend
lsof -i :5432  # PostgreSQL

# Kill the process or change the port in docker-compose.yml
```

### Services Not Healthy

**Error**: Service fails health check

**Solution**:
```bash
# Check logs for the failing service
docker-compose logs backend

# Try restarting the service
docker-compose restart backend

# If that doesn't work, rebuild
docker-compose up -d --build backend
```

### Frontend Build Fails

**Error**: Out of memory or build timeout

**Solution**:
```bash
# Increase Docker Desktop memory allocation:
# Settings > Resources > Memory (set to at least 4GB)

# Clear Docker cache
docker builder prune -a

# Rebuild
docker-compose build --no-cache frontend
```

### Database Connection Refused

**Error**: `could not connect to database`

**Solution**:
```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Check PostgreSQL logs
docker-compose logs postgres

# Restart PostgreSQL
docker-compose restart postgres

# Wait for it to be healthy
docker exec engarde_postgres pg_isready -U engarde_user
```

### Migration Errors

**Error**: Alembic migration fails

**Solution**:
```bash
# Check current migration status
docker exec engarde_backend alembic current

# Check migration history
docker exec engarde_backend alembic history

# Try running migrations again
docker exec engarde_backend alembic upgrade head

# If still failing, check logs
docker-compose logs backend
```

### Seed Data Already Exists

**Warning**: Test data already present

**Solution**:
This is normal if you've run the setup before. To reset:
```bash
# See "Reset Database" section below
```

### Cannot Access Frontend

**Error**: Browser shows "This site can't be reached"

**Solution**:
```bash
# Check frontend is running
docker ps | grep frontend

# Check frontend logs
docker-compose logs frontend

# Try accessing via different URL
# http://localhost:3001
# http://127.0.0.1:3001

# Restart frontend
docker-compose restart frontend
```

### Langflow Not Starting

**Error**: Langflow container exits

**Solution**:
```bash
# Check Langflow logs
docker-compose logs langflow

# Langflow is optional - the main app works without it
# You can disable it by commenting out the langflow service
# in docker-compose.yml
```

---

## Database Management

### Reset Database

To completely reset the database and start fresh:

```bash
# Stop all services and remove volumes
docker-compose down -v

# Run setup script again
./scripts/setup-local-testing.sh
```

### Backup Database

```bash
# Create backup
docker exec engarde_postgres pg_dump -U engarde_user engarde > backup.sql

# Create compressed backup
docker exec engarde_postgres pg_dump -U engarde_user engarde | gzip > backup.sql.gz
```

### Restore Database

```bash
# From SQL file
docker exec -i engarde_postgres psql -U engarde_user -d engarde < backup.sql

# From compressed file
gunzip -c backup.sql.gz | docker exec -i engarde_postgres psql -U engarde_user -d engarde
```

### Access Database Directly

```bash
# Using psql
docker exec -it engarde_postgres psql -U engarde_user -d engarde

# Common SQL commands:
# \dt              - List tables
# \d+ table_name   - Describe table
# \q               - Quit
# SELECT * FROM users LIMIT 10;
```

### View Database Schema

```bash
# Export schema to file
docker exec engarde_postgres pg_dump -U engarde_user -d engarde --schema-only > schema.sql
```

### Create New Migration

```bash
# After changing models, create a new migration
docker exec engarde_backend alembic revision --autogenerate -m "description of changes"

# Apply the migration
docker exec engarde_backend alembic upgrade head
```

---

## Development Workflow

### Hot Reload

The development configuration (`docker-compose.local.yml`) includes hot-reload:

**Backend**: Code changes in `production-backend/app` are automatically detected
**Frontend**: Code changes in `production-frontend/src` trigger rebuild

### Running Tests

```bash
# Backend tests
docker exec engarde_backend pytest

# Frontend tests
docker exec engarde_frontend npm test

# With coverage
docker exec engarde_backend pytest --cov=app --cov-report=html
```

### Adding API Keys

To test AI features, add your API keys:

```bash
# Edit .env file
nano .env

# Add your keys:
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_API_KEY=...

# Restart backend to pick up changes
docker-compose restart backend
```

### Debugging

```bash
# Enable debug mode
# Edit docker-compose.local.yml and set DEBUG=true

# View detailed logs
docker-compose logs -f backend | grep DEBUG

# Attach to running container for interactive debugging
docker attach engarde_backend
```

### Database Queries During Development

```bash
# Quick query
docker exec engarde_postgres psql -U engarde_user -d engarde -c "SELECT * FROM users;"

# Interactive session
docker exec -it engarde_postgres psql -U engarde_user -d engarde
```

### Monitoring Resources

```bash
# View resource usage
docker stats

# View disk usage
docker system df

# Clean up unused resources
docker system prune -a
```

---

## Advanced Configuration

### Custom Ports

Edit `docker-compose.yml` to change service ports:

```yaml
services:
  frontend:
    ports:
      - "3002:3000"  # Change host port from 3001 to 3002
```

### Development vs Production Mode

```bash
# Development (hot-reload, verbose logging)
docker-compose -f docker-compose.yml -f docker-compose.local.yml up

# Production mode
docker-compose up
```

### Resource Limits

Adjust in `docker-compose.yml`:

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '2.0'
```

---

## Getting Help

### Check Service Health

```bash
# Check all containers
docker ps

# Check specific service health
docker inspect --format='{{.State.Health.Status}}' engarde_backend

# View health check logs
docker inspect engarde_backend | grep -A 20 Health
```

### Export Logs for Support

```bash
# Export all logs
docker-compose logs > engarde-logs.txt

# Export specific service logs
docker-compose logs backend > backend-logs.txt
```

### Useful Commands Summary

```bash
# Start everything
./scripts/setup-local-testing.sh

# View logs
docker-compose logs -f

# Stop everything
docker-compose down

# Reset everything
docker-compose down -v && ./scripts/setup-local-testing.sh

# Rebuild specific service
docker-compose build --no-cache backend && docker-compose up -d backend

# Access database
docker exec -it engarde_postgres psql -U engarde_user -d engarde

# Check service status
docker ps
docker-compose ps
```

---

## Additional Resources

- **Backend API Documentation**: http://localhost:8000/docs
- **Docker Documentation**: https://docs.docker.com
- **Docker Compose Documentation**: https://docs.docker.com/compose
- **PostgreSQL Documentation**: https://www.postgresql.org/docs
- **FastAPI Documentation**: https://fastapi.tiangolo.com
- **Next.js Documentation**: https://nextjs.org/docs

---

## License

[Your License Here]

## Support

For issues or questions:
1. Check this documentation
2. Review logs: `docker-compose logs -f`
3. Open an issue on GitHub
4. Contact the development team

---

**Last Updated**: 2025-10-05
