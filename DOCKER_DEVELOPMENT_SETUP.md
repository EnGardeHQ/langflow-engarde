# EnGarde Docker Development Setup

This document provides comprehensive instructions for running the EnGarde platform using Docker for local development.

## 🚀 Quick Start

### Prerequisites

- Docker Engine 20.10+ installed and running
- Docker Compose V2 installed
- At least 4GB RAM allocated to Docker
- At least 10GB free disk space

### Start Development Environment

```bash
# Make scripts executable (first time only)
chmod +x start-dev.sh dev-tools.sh

# Start all services
./start-dev.sh

# Or start with logs visible
./start-dev.sh --logs
```

### Access the Applications

Once all services are healthy:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Database**: localhost:5432 (user: `engarde_user`, db: `engarde`)
- **Redis**: localhost:6379

## 🏗️ Architecture Overview

### Services

1. **Frontend** (Next.js)
   - Port: 3000
   - TypeScript checking bypassed for faster development
   - Hot reloading enabled
   - Volume mounted for code synchronization

2. **Backend** (FastAPI)
   - Port: 8000
   - Development dependencies only
   - Hot reloading enabled
   - Volume mounted for code synchronization

3. **PostgreSQL Database**
   - Port: 5432
   - Persistent data storage
   - Automatic initialization scripts

4. **Redis Cache**
   - Port: 6379
   - Session and cache storage
   - Persistent data storage

### Key Features

✅ **TypeScript Bypass**: Frontend development mode skips type checking for faster builds
✅ **Hot Reloading**: Both frontend and backend automatically reload on code changes
✅ **Health Checks**: All services have configured health checks
✅ **Security**: Non-root users in containers
✅ **Optimized**: Multi-stage builds and layer caching
✅ **Development Focus**: Minimal dependencies for faster startup

## 📋 Available Commands

### Using dev-tools.sh

```bash
./dev-tools.sh start      # Start development environment
./dev-tools.sh stop       # Stop all services
./dev-tools.sh restart    # Restart all services
./dev-tools.sh rebuild    # Rebuild and restart services
./dev-tools.sh logs       # Follow logs from all services
./dev-tools.sh logs-fe    # Follow frontend logs only
./dev-tools.sh logs-be    # Follow backend logs only
./dev-tools.sh shell-fe   # Access frontend container shell
./dev-tools.sh shell-be   # Access backend container shell
./dev-tools.sh shell-db   # Access database container shell
./dev-tools.sh status     # Show service status
./dev-tools.sh clean      # Clean up containers and images
./dev-tools.sh reset      # Full reset (stop, clean, rebuild)
```

### Direct Docker Compose Commands

```bash
# Start services in background
docker-compose -f docker-compose.dev.yml up -d

# View logs
docker-compose -f docker-compose.dev.yml logs -f [service_name]

# Stop services
docker-compose -f docker-compose.dev.yml down

# Rebuild services
docker-compose -f docker-compose.dev.yml build

# View service status
docker-compose -f docker-compose.dev.yml ps
```

## 🔧 Configuration

### Environment Variables

The setup uses a hierarchical environment configuration:

1. **Root .env**: Cross-service variables
2. **Frontend .env**: Frontend-specific variables
3. **Backend .env**: Backend-specific variables

Key environment variables for development:

```env
# Frontend
NEXT_TYPESCRIPT_IGNOREBUILDWRONG=1
TSC_COMPILE_ON_ERROR=true
NODE_ENV=development

# Backend
DEBUG=true
LOG_LEVEL=debug
ENVIRONMENT=development

# Database
DATABASE_URL=postgresql://engarde_user:engarde_password@postgres:5432/engarde

# API
CORS_ORIGINS=["http://localhost:3000","http://frontend:3000"]
```

### TypeScript Configuration

For development, TypeScript checking is bypassed in several ways:

1. **Environment Variables**: `NEXT_TYPESCRIPT_IGNOREBUILDWRONG=1`
2. **Build Skip**: Type checking step commented out in Dockerfile
3. **Development Config**: Custom tsconfig.dev.json with relaxed rules

## 🐛 Troubleshooting

### Common Issues

**Services not starting:**
```bash
# Check Docker is running
docker info

# Check available resources
docker system df

# Clean up and restart
./dev-tools.sh reset
```

**Port conflicts:**
```bash
# Check what's using the ports
lsof -i :3000
lsof -i :8000
lsof -i :5432

# Kill conflicting processes or change ports in docker-compose.dev.yml
```

**Build failures:**
```bash
# Clean Docker cache
docker builder prune

# Rebuild without cache
docker-compose -f docker-compose.dev.yml build --no-cache
```

**Database connection issues:**
```bash
# Wait for database to be ready
./dev-tools.sh logs-db

# Check database health
docker-compose -f docker-compose.dev.yml exec postgres pg_isready -U engarde_user
```

### Performance Optimization

**Slow startup:**
- Ensure Docker has sufficient RAM (4GB+)
- Use `./dev-tools.sh clean` periodically
- Consider using Docker volumes for node_modules

**High CPU usage:**
- Limit file watching in volumes
- Use Docker Desktop's resource limits
- Exclude unnecessary files in .dockerignore

## 📁 File Structure

```
/Users/cope/EnGardeHQ/
├── docker-compose.dev.yml          # Development orchestration
├── start-dev.sh                    # Startup script
├── dev-tools.sh                    # Development utilities
├── .env                            # Root environment variables
├── production-frontend/
│   ├── Dockerfile.dev              # Frontend development image
│   ├── .env                        # Frontend environment
│   └── ...
├── production-backend/
│   ├── Dockerfile.dev              # Backend development image
│   ├── requirements.dev.txt        # Minimal development dependencies
│   ├── .env                        # Backend environment
│   └── ...
└── DOCKER_DEVELOPMENT_SETUP.md     # This file
```

## 🔐 Security Considerations

### Development vs Production

This setup is optimized for development and includes:

- ⚠️ **Simplified authentication** for easier testing
- ⚠️ **Debug modes enabled** for better error visibility
- ⚠️ **TypeScript checking bypassed** for faster iteration
- ⚠️ **Volume mounts** for code synchronization

**DO NOT USE THIS CONFIGURATION IN PRODUCTION**

For production deployment, use:
- `docker-compose.yml` (production configuration)
- `Dockerfile` (production builds with full security)
- Proper secrets management
- SSL/TLS termination
- Resource limits

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Next.js Docker Guide](https://nextjs.org/docs/deployment#docker-image)
- [FastAPI Docker Guide](https://fastapi.tiangolo.com/deployment/docker/)

## 🤝 Contributing

When working with this setup:

1. **Always test locally** before committing
2. **Update this README** when adding new services or features
3. **Keep environment files** synchronized between team members
4. **Use the provided scripts** rather than raw Docker commands
5. **Report issues** with specific error messages and logs

---

Generated with Claude Code - Last updated: September 2025