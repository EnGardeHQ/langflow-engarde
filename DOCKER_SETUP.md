# EnGarde Platform - Docker Compose Setup

This Docker Compose configuration provides a complete development and production environment for the EnGarde marketing automation platform.

## Architecture

The platform consists of the following services:

- **Frontend**: Next.js 13.5.6 application (Node.js 18)
- **Backend**: FastAPI application (Python 3.11)
- **PostgreSQL**: Version 15 database
- **Redis**: Version 7 cache
- **Nginx**: Reverse proxy (optional, for production)

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 4GB of available RAM
- 10GB of available disk space

## Quick Start

### 1. Clone the repositories (if not already done)

```bash
git clone https://github.com/EnGardeHQ/production-frontend.git
git clone https://github.com/EnGardeHQ/production-backend.git
```

### 2. Set up environment variables

```bash
cp .env.example .env
```

Edit the `.env` file and update the following required variables:
- `SECRET_KEY`: Backend secret key for JWT tokens
- `NEXTAUTH_SECRET`: Frontend authentication secret
- Add your AI service API keys if needed (OpenAI, Anthropic, etc.)

### 3. Start the services

**Development mode:**
```bash
docker-compose up -d
```

**Production mode with Nginx:**
```bash
docker-compose --profile production up -d
```

### 4. Access the application

- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Documentation: http://localhost:8000/docs
- PostgreSQL: localhost:5432
- Redis: localhost:6379

If using Nginx (production profile):
- Main application: http://localhost

## Service Details

### Frontend (Next.js)
- **Port**: 3000
- **Build**: Multi-stage Dockerfile with Node.js 18
- **Features**: Server-side rendering, API routes, real-time updates
- **Environment Variables**:
  - `NEXT_PUBLIC_API_URL`: Backend API URL
  - `NEXTAUTH_SECRET`: Authentication secret
  - `NEXT_PUBLIC_APP_NAME`: Application name

### Backend (FastAPI)
- **Port**: 8000
- **Build**: Multi-stage Dockerfile with Python 3.11
- **Features**: RESTful API, WebSocket support, async operations
- **Workers**: 4 Gunicorn workers with Uvicorn
- **Environment Variables**:
  - `DATABASE_URL`: PostgreSQL connection string
  - `REDIS_URL`: Redis connection string
  - `SECRET_KEY`: JWT secret key

### Database (PostgreSQL)
- **Port**: 5432
- **Version**: 15-alpine
- **Credentials**:
  - Database: `engarde`
  - User: `engarde_user`
  - Password: `engarde_password` (change in production!)
- **Initialization**: Automatically runs SQL scripts from `production-backend/scripts/`

### Cache (Redis)
- **Port**: 6379
- **Version**: 7-alpine
- **Persistence**: Data volume mounted at `/data`

## Common Commands

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
```

### Restart services
```bash
# All services
docker-compose restart

# Specific service
docker-compose restart backend
```

### Stop services
```bash
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v
```

### Rebuild after code changes
```bash
# Rebuild specific service
docker-compose build backend
docker-compose build frontend

# Rebuild and restart
docker-compose up -d --build backend
```

### Run database migrations
```bash
docker-compose exec backend alembic upgrade head
```

### Access service shells
```bash
# Backend shell
docker-compose exec backend /bin/sh

# Frontend shell
docker-compose exec frontend /bin/sh

# PostgreSQL shell
docker-compose exec postgres psql -U engarde_user -d engarde
```

## Development Workflow

1. **Make code changes** in your local `production-frontend/` or `production-backend/` directories

2. **Frontend changes** (Next.js):
   - Changes are automatically detected via hot reload
   - No restart needed for most changes

3. **Backend changes** (FastAPI):
   - The backend uses Uvicorn with reload enabled in development
   - Changes are automatically detected

4. **Database schema changes**:
   ```bash
   # Create migration
   docker-compose exec backend alembic revision --autogenerate -m "Description"
   
   # Apply migration
   docker-compose exec backend alembic upgrade head
   ```

## Production Deployment

For production deployment:

1. **Update environment variables** in `.env`:
   - Set strong passwords and secrets
   - Configure external service API keys
   - Set `NODE_ENV=production`

2. **Build production images**:
   ```bash
   docker-compose build --no-cache
   ```

3. **Use production profile** with Nginx:
   ```bash
   docker-compose --profile production up -d
   ```

4. **Configure SSL** (if using Nginx):
   - Add SSL certificates to `./ssl/` directory
   - Uncomment HTTPS configuration in `nginx.conf`

5. **Set up monitoring** and logging as needed

## Health Checks

All services include health checks:

- **Frontend**: http://localhost:3000/api/health
- **Backend**: http://localhost:8000/health
- **PostgreSQL**: `pg_isready` command
- **Redis**: `redis-cli ping` command

Check service health:
```bash
docker-compose ps
```

## Troubleshooting

### Services won't start
- Check logs: `docker-compose logs [service-name]`
- Ensure ports are not already in use
- Verify environment variables are set correctly

### Database connection issues
- Wait for PostgreSQL to be fully initialized (check health status)
- Verify DATABASE_URL is correct
- Check PostgreSQL logs: `docker-compose logs postgres`

### Frontend can't connect to backend
- Ensure backend is running and healthy
- Check CORS settings in backend
- Verify NEXT_PUBLIC_API_URL is correct

### Permission issues
- Ensure directories have correct permissions
- The containers run as non-root users for security

## Security Considerations

⚠️ **Important for Production:**

1. Change all default passwords in `.env`
2. Use strong secrets for `SECRET_KEY` and `NEXTAUTH_SECRET`
3. Configure firewall rules to restrict database access
4. Enable SSL/TLS for all external connections
5. Regularly update base images for security patches
6. Implement rate limiting and DDoS protection
7. Use secrets management service for sensitive data
8. Enable audit logging for compliance

## Support

For issues or questions:
- Frontend repository: https://github.com/EnGardeHQ/production-frontend
- Backend repository: https://github.com/EnGardeHQ/production-backend
- Email: support@engardehq.com