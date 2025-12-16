#!/bin/bash
# Emergency Rollback Script for Authentication Fix
# Date: 2025-10-29
# Purpose: Roll back broken authentication changes

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=================================================="
echo "EnGarde Authentication Rollback Script"
echo "=================================================="
echo ""
echo "This script will:"
echo "  1. Backup current broken state"
echo "  2. Roll back backend to stable image (Oct 10, 2025)"
echo "  3. Keep frontend container but flag for manual auth code revert"
echo "  4. Restart services"
echo ""
echo "Project Directory: $PROJECT_DIR"
echo ""

# Confirm with user
read -p "Do you want to proceed with rollback? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Rollback cancelled."
    exit 0
fi

echo ""
echo "Step 1: Backing up current broken state..."
echo "=================================================="

# Tag current broken images
echo "Tagging current images as broken..."
docker tag engarde-backend:dev engarde-backend:dev-broken-20251029 2>/dev/null || echo "Backend image already tagged or not found"
docker tag engarde-frontend:dev engarde-frontend:dev-broken-20251029 2>/dev/null || echo "Frontend image already tagged or not found"

# Backup broken auth files
echo "Backing up broken authentication files..."
mkdir -p "$PROJECT_DIR/backups/auth-broken-20251029"

if [ -f "$PROJECT_DIR/production-frontend/lib/api/client.ts" ]; then
    cp "$PROJECT_DIR/production-frontend/lib/api/client.ts" \
       "$PROJECT_DIR/backups/auth-broken-20251029/client.ts.broken"
    echo "  ✓ Backed up client.ts"
fi

if [ -f "$PROJECT_DIR/production-frontend/contexts/AuthContext.tsx" ]; then
    cp "$PROJECT_DIR/production-frontend/contexts/AuthContext.tsx" \
       "$PROJECT_DIR/backups/auth-broken-20251029/AuthContext.tsx.broken"
    echo "  ✓ Backed up AuthContext.tsx"
fi

echo ""
echo "Step 2: Rolling back backend to stable image..."
echo "=================================================="

cd "$PROJECT_DIR"

# Stop backend container
echo "Stopping backend container..."
docker compose -f docker-compose.dev.yml stop backend

# Check if stable backend image exists
if docker image inspect engardehq-backend:latest >/dev/null 2>&1; then
    echo "Using stable backend image: engardehq-backend:latest (Oct 10, 2025)"
    docker tag engardehq-backend:latest engarde-backend:dev
    echo "  ✓ Backend image rolled back"
else
    echo "  ⚠ WARNING: Stable backend image not found (engardehq-backend:latest)"
    echo "  Backend will use current image. Consider using older engarde-backend-dev:latest"

    # Alternative: Use 6-week-old image
    if docker image inspect engarde-backend-dev:latest >/dev/null 2>&1; then
        read -p "Use 6-week-old backup image instead? (yes/no): " USE_OLD
        if [ "$USE_OLD" = "yes" ]; then
            docker tag engarde-backend-dev:latest engarde-backend:dev
            echo "  ✓ Using 6-week-old backend image"
        fi
    fi
fi

# Restart backend
echo "Starting backend container..."
docker compose -f docker-compose.dev.yml up -d backend

echo ""
echo "Step 3: Frontend status check..."
echo "=================================================="

echo "⚠ MANUAL ACTION REQUIRED:"
echo ""
echo "The frontend container needs authentication code reverted."
echo "You have two options:"
echo ""
echo "Option A: Manual Code Revert (Recommended)"
echo "  Edit these files to restore login success flag:"
echo "  1. $PROJECT_DIR/production-frontend/lib/api/client.ts"
echo "  2. $PROJECT_DIR/production-frontend/contexts/AuthContext.tsx"
echo "  See: $PROJECT_DIR/DOCKER_ROLLBACK_STRATEGY.md (Option 2)"
echo ""
echo "Option B: Use 6-week-old frontend image"
echo "  docker tag engarde-frontend-dev:latest engarde-frontend:dev"
echo "  docker compose -f docker-compose.dev.yml up -d frontend"
echo ""

read -p "Do you want to use 6-week-old frontend image now? (yes/no): " USE_OLD_FRONTEND
if [ "$USE_OLD_FRONTEND" = "yes" ]; then
    if docker image inspect engarde-frontend-dev:latest >/dev/null 2>&1; then
        echo "Using 6-week-old frontend image..."
        docker tag engarde-frontend-dev:latest engarde-frontend:dev
        docker compose -f docker-compose.dev.yml stop frontend
        docker compose -f docker-compose.dev.yml up -d frontend
        echo "  ✓ Frontend rolled back to 6-week-old image"
    else
        echo "  ⚠ 6-week-old frontend image not found"
    fi
else
    echo "  Skipping frontend image rollback"
    echo "  Frontend code changes required - see documentation"
fi

echo ""
echo "Step 4: Verifying services..."
echo "=================================================="

echo "Waiting for services to start..."
sleep 5

# Check container status
echo ""
echo "Container Status:"
docker compose -f docker-compose.dev.yml ps

echo ""
echo "Backend Health Check:"
if curl -f http://localhost:8000/health >/dev/null 2>&1; then
    echo "  ✓ Backend is healthy"
else
    echo "  ✗ Backend health check failed"
    echo "  Check logs: docker logs engarde_backend_dev"
fi

echo ""
echo "Frontend Health Check:"
if curl -f http://localhost:3000/ >/dev/null 2>&1; then
    echo "  ✓ Frontend is responding"
else
    echo "  ✗ Frontend health check failed"
    echo "  Check logs: docker logs engarde_frontend_dev"
fi

echo ""
echo "=================================================="
echo "Rollback Complete!"
echo "=================================================="
echo ""
echo "Next Steps:"
echo "  1. Test authentication: http://localhost:3000/login"
echo "  2. If frontend auth still broken, revert code manually"
echo "  3. See: $PROJECT_DIR/DOCKER_ROLLBACK_STRATEGY.md"
echo ""
echo "Monitoring Commands:"
echo "  Backend logs:  docker logs -f engarde_backend_dev"
echo "  Frontend logs: docker logs -f engarde_frontend_dev"
echo "  All services:  docker compose -f docker-compose.dev.yml logs -f"
echo ""
echo "Test Authentication:"
echo "  curl -X POST http://localhost:8000/api/auth/login \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"email\":\"test@example.com\",\"password\":\"password\"}'"
echo ""
echo "Backup Location: $PROJECT_DIR/backups/auth-broken-20251029/"
echo ""
