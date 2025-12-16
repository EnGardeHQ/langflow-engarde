# Langflow Integration Setup Guide

Complete Docker and infrastructure setup for Langflow integration with EnGarde platform.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Management Scripts](#management-scripts)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## Overview

This setup provides a production-ready Langflow integration with:

- **Schema Isolation**: Separate PostgreSQL schemas (`public` for EnGarde, `langflow` for Langflow)
- **Health Checks**: Comprehensive health monitoring for all services
- **Auto-Initialization**: Automatic schema and database setup on first run
- **Management Scripts**: Easy-to-use scripts for common operations
- **Volume Persistence**: Proper data persistence for logs and application data

## Architecture

### Three-Schema PostgreSQL Design

```
┌─────────────────────────────────────────┐
│         PostgreSQL Database             │
│              (engarde)                  │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────┐    ┌──────────────┐  │
│  │   public    │    │   langflow   │  │
│  │   schema    │◄───┤    schema    │  │
│  │             │    │              │  │
│  │ EnGarde     │    │ Langflow     │  │
│  │ Tables      │    │ Tables       │  │
│  └─────────────┘    └──────────────┘  │
│         │                   │          │
│         ▼                   ▼          │
│  ┌──────────────────────────────────┐ │
│  │         audit schema             │ │
│  │    (cross-schema logging)        │ │
│  └──────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### Database Users and Permissions

- **engarde_user**: Full access to `public` schema, read-only to `langflow` schema
- **langflow_user**: Full access to `langflow` schema, read-only to `public` schema
- **Cross-schema queries**: Enabled through USAGE grants for integration

### Service Dependencies

```
PostgreSQL (with schemas)
    ▼
Redis
    ▼
Backend API ───► Langflow
    ▼              ▼
Frontend ◄────────┘
```

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- PostgreSQL client tools (for management scripts)
- 4GB+ available RAM
- 10GB+ available disk space

## Quick Start

### 1. Initial Setup

```bash
# Clone and navigate to project
cd /Users/cope/EnGardeHQ

# Copy environment template
cp .env.example .env

# Edit .env with your configuration
nano .env
```

### 2. Start Infrastructure

```bash
# Start PostgreSQL and Redis first
docker-compose up -d postgres redis

# Wait for services to be healthy
docker-compose ps

# Initialize Langflow database
./scripts/init-langflow.sh
```

### 3. Start Langflow

```bash
# Start Langflow service
docker-compose up -d langflow

# Follow startup logs
docker-compose logs -f langflow

# Wait for "Application startup complete" message
```

### 4. Validate Setup

```bash
# Run comprehensive validation
./scripts/validate-langflow.sh

# Expected output: All tests should PASS
```

### 5. Access Langflow

- **Web UI**: http://localhost:7860
- **API**: http://localhost:7860/api
- **API Docs**: http://localhost:7860/docs
- **Health**: http://localhost:7860/health

Default credentials:
- Username: `admin`
- Password: `admin` (change in production!)

## Configuration

### Environment Variables

#### Core Configuration

```bash
# Database
DATABASE_URL=postgresql://engarde_user:engarde_password@localhost:5432/engarde

# Langflow Database User
LANGFLOW_DB_USER=langflow_user
LANGFLOW_DB_PASSWORD=langflow_password
```

#### Langflow-Specific Variables

```bash
# Authentication
LANGFLOW_SUPERUSER=admin
LANGFLOW_SUPERUSER_PASSWORD=admin

# Performance
LANGFLOW_POOL_SIZE=10
LANGFLOW_MAX_OVERFLOW=20
LANGFLOW_WORKER_TIMEOUT=300
LANGFLOW_WORKERS=1

# Logging
LANGFLOW_LOG_LEVEL=info
```

### Docker Compose Configuration

The `docker-compose.yml` includes:

- **Health checks** for all services
- **Proper dependencies** with health conditions
- **Volume mounts** for persistence
- **Network isolation** via `engarde_network`
- **Schema initialization** via mounted SQL scripts

### Database Initialization

Initialization scripts run automatically on first PostgreSQL start:

1. `01-init-schemas.sql` - Creates schemas and roles
2. `02-init-db.sql` - Sets up EnGarde database
3. `03-init-langflow-schema.sql` - Configures Langflow schema

## Management Scripts

All scripts are located in `/Users/cope/EnGardeHQ/scripts/`:

### init-langflow.sh

Initialize Langflow database schema and permissions.

```bash
./scripts/init-langflow.sh
```

**What it does:**
- Verifies database connection
- Creates Langflow schema (if not exists)
- Sets up database roles and permissions
- Validates schema configuration
- Optionally runs migrations

### restart-langflow.sh

Restart Langflow service with optional rebuild.

```bash
# Simple restart
./scripts/restart-langflow.sh

# Rebuild and restart
./scripts/restart-langflow.sh --rebuild

# Rebuild, restart, and follow logs
./scripts/restart-langflow.sh --rebuild --logs
```

**Options:**
- `--rebuild, -r`: Rebuild Docker image before restarting
- `--logs, -l`: Follow logs after restart
- `--help, -h`: Show help message

### validate-langflow.sh

Comprehensive validation of Langflow setup.

```bash
./scripts/validate-langflow.sh
```

**Tests performed:**
- Docker environment validation
- Container status checks
- Database schema verification
- Service health checks
- Network configuration
- Volume configuration
- Environment variables
- Log analysis
- Integration tests

### cleanup-langflow.sh

Clean up Langflow installation.

```bash
# Basic cleanup (container and image)
./scripts/cleanup-langflow.sh

# Full cleanup (includes database)
./scripts/cleanup-langflow.sh --full

# Keep data volumes
./scripts/cleanup-langflow.sh --keep-data

# Skip confirmations
./scripts/cleanup-langflow.sh --full --yes
```

**Options:**
- `--full, -f`: Drop database schema and tables
- `--keep-data, -k`: Preserve data volumes
- `--yes, -y`: Skip confirmation prompts

## Troubleshooting

### Common Issues

#### 1. Langflow Container Fails to Start

**Symptoms:**
```
Error: container exited with code 1
```

**Solutions:**
```bash
# Check logs
docker-compose logs langflow

# Verify database schema exists
psql $DATABASE_URL -c "\dn langflow"

# Reinitialize if needed
./scripts/init-langflow.sh

# Rebuild and restart
./scripts/restart-langflow.sh --rebuild
```

#### 2. Database Connection Errors

**Symptoms:**
```
Error: could not connect to server
```

**Solutions:**
```bash
# Verify PostgreSQL is running
docker-compose ps postgres

# Check health status
docker inspect --format='{{.State.Health.Status}}' engarde_postgres

# Restart PostgreSQL
docker-compose restart postgres

# Wait for healthy status
docker-compose ps
```

#### 3. Schema Permission Errors

**Symptoms:**
```
Error: permission denied for schema langflow
```

**Solutions:**
```bash
# Verify schema permissions
psql $DATABASE_URL -c "SELECT has_schema_privilege('langflow_user', 'langflow', 'CREATE');"

# Re-run initialization
./scripts/init-langflow.sh

# Check user exists
psql $DATABASE_URL -c "\du langflow_user"
```

#### 4. Health Check Failures

**Symptoms:**
```
Health: unhealthy (or starting)
```

**Solutions:**
```bash
# Check if port is accessible
curl http://localhost:7860/health

# Verify container logs
docker-compose logs --tail=50 langflow

# Increase health check timeout in docker-compose.yml
# start_period: 60s -> 120s

# Restart service
./scripts/restart-langflow.sh
```

#### 5. Migration Conflicts

**Symptoms:**
```
Error: alembic.util.exc.CommandError: Can't locate revision
```

**Solutions:**
```bash
# Check migration status
cd production-backend
alembic -c alembic_langflow/alembic.ini current

# Stamp to current version
alembic -c alembic_langflow/alembic.ini stamp head

# Or start fresh (WARNING: deletes data)
./scripts/cleanup-langflow.sh --full
./scripts/init-langflow.sh
```

### Debug Commands

```bash
# View all Langflow-related containers
docker ps -a | grep langflow

# Inspect container
docker inspect engarde_langflow

# Execute commands in container
docker-compose exec langflow bash

# View database tables
psql $DATABASE_URL -c "\dt langflow.*"

# Check schema sizes
psql $DATABASE_URL -c "
  SELECT schemaname,
         COUNT(*) as tables,
         pg_size_pretty(SUM(pg_total_relation_size(schemaname||'.'||tablename))) as size
  FROM pg_tables
  WHERE schemaname IN ('public', 'langflow')
  GROUP BY schemaname;
"

# Monitor logs in real-time
docker-compose logs -f langflow

# Check network connectivity
docker-compose exec langflow ping postgres
```

## Advanced Usage

### Custom Components

Place custom Langflow components in:
```
/Users/cope/EnGardeHQ/production-backend/custom_components/
```

Directory structure:
```
custom_components/
├── vectorstores/
│   └── custom_vectorstore.py
├── llms/
│   └── custom_llm.py
└── tools/
    └── custom_tool.py
```

Components are automatically loaded via volume mount.

### Running Migrations Manually

```bash
cd /Users/cope/EnGardeHQ/production-backend

# Check current version
alembic -c alembic_langflow/alembic.ini current

# View migration history
alembic -c alembic_langflow/alembic.ini history

# Upgrade to latest
alembic -c alembic_langflow/alembic.ini upgrade head

# Downgrade one version
alembic -c alembic_langflow/alembic.ini downgrade -1
```

### Database Backups

```bash
# Backup Langflow schema
pg_dump $DATABASE_URL --schema=langflow > langflow_backup.sql

# Restore Langflow schema
psql $DATABASE_URL < langflow_backup.sql

# Backup entire database
pg_dump $DATABASE_URL > full_backup.sql
```

### Performance Tuning

#### Increase Connection Pool

Edit `docker-compose.yml`:
```yaml
environment:
  LANGFLOW_POOL_SIZE: 20
  LANGFLOW_MAX_OVERFLOW: 40
```

#### Increase Workers

Edit `docker-compose.yml`:
```yaml
environment:
  LANGFLOW_WORKERS: 4
```

#### Adjust Memory Limits

Edit `docker-compose.yml`:
```yaml
langflow:
  deploy:
    resources:
      limits:
        memory: 2G
      reservations:
        memory: 1G
```

### Multi-Tenant Configuration

The setup supports multi-tenancy through Row-Level Security (RLS):

```sql
-- Set tenant context
SELECT set_current_tenant_id('tenant-uuid-here');

-- Queries are now scoped to this tenant
SELECT * FROM langflow.flow;
```

### Monitoring

View real-time metrics:

```bash
# Container stats
docker stats engarde_langflow

# Database connections
psql $DATABASE_URL -c "
  SELECT datname, usename, count(*)
  FROM pg_stat_activity
  WHERE datname = 'engarde'
  GROUP BY datname, usename;
"

# Schema health check
psql $DATABASE_URL -c "SELECT * FROM check_schema_health();"
```

## Production Deployment

### Security Hardening

1. **Change default credentials**:
   ```bash
   # In .env
   LANGFLOW_SUPERUSER=your_admin_user
   LANGFLOW_SUPERUSER_PASSWORD=strong_password_here
   ```

2. **Use secrets management**:
   ```bash
   # Use Docker secrets or external secrets manager
   # Remove passwords from .env in production
   ```

3. **Enable SSL for database**:
   ```bash
   DATABASE_URL=postgresql://user:pass@host:5432/db?sslmode=require
   ```

4. **Restrict network access**:
   ```yaml
   # In docker-compose.yml, remove port exposure
   # Use nginx reverse proxy instead
   ```

### High Availability

1. **Database replication**: Use PostgreSQL streaming replication
2. **Redis cluster**: Configure Redis cluster mode
3. **Load balancing**: Deploy multiple Langflow replicas
4. **Health monitoring**: Set up external monitoring (Prometheus, Datadog)

### Backup Strategy

```bash
# Automated daily backups
0 2 * * * pg_dump $DATABASE_URL --schema=langflow > /backups/langflow_$(date +\%Y\%m\%d).sql

# Retention policy (keep 30 days)
find /backups -name "langflow_*.sql" -mtime +30 -delete
```

## Support

For issues or questions:

1. Check logs: `docker-compose logs langflow`
2. Run validation: `./scripts/validate-langflow.sh`
3. Review this documentation
4. Check Langflow official docs: https://docs.langflow.org

## File Reference

### Configuration Files
- `/Users/cope/EnGardeHQ/docker-compose.yml` - Docker services configuration
- `/Users/cope/EnGardeHQ/.env` - Environment variables
- `/Users/cope/EnGardeHQ/production-backend/Dockerfile.langflow` - Langflow Docker image

### Database Scripts
- `/Users/cope/EnGardeHQ/production-backend/scripts/init_schemas.sql` - Schema initialization
- `/Users/cope/EnGardeHQ/production-backend/scripts/init-langflow-schema.sql` - Langflow schema setup
- `/Users/cope/EnGardeHQ/production-backend/scripts/apply_rls_policies.sql` - RLS policies
- `/Users/cope/EnGardeHQ/production-backend/scripts/langflow_extensions.sql` - Schema extensions

### Management Scripts
- `/Users/cope/EnGardeHQ/scripts/init-langflow.sh` - Initialize database
- `/Users/cope/EnGardeHQ/scripts/restart-langflow.sh` - Restart service
- `/Users/cope/EnGardeHQ/scripts/validate-langflow.sh` - Validate setup
- `/Users/cope/EnGardeHQ/scripts/cleanup-langflow.sh` - Clean up installation

### Entrypoint Scripts
- `/Users/cope/EnGardeHQ/production-backend/docker/langflow/entrypoint.sh` - Container initialization

---

**Version**: 1.0.0
**Last Updated**: 2025-10-05
**Maintained By**: EnGarde DevOps Team
