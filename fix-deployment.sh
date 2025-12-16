#!/bin/bash

# Docker Deployment Fix Script
# Fixes critical issues and rebuilds containers with latest code
# Generated: 2025-10-08

set -e  # Exit on error

echo "========================================"
echo "Docker Deployment Fix Script"
echo "========================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running from correct directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please run this script from the EnGardeHQ directory."
    exit 1
fi

print_status "Starting deployment fix process..."
echo ""

# Step 1: Fix Langflow Container
echo "Step 1: Fixing Langflow Container"
echo "-----------------------------------"

print_warning "Stopping Langflow container..."
docker-compose stop langflow 2>/dev/null || true

print_warning "Removing Langflow container and volumes..."
docker-compose rm -f langflow 2>/dev/null || true

# Recreate volumes with proper permissions
print_warning "Recreating Langflow volumes..."
docker volume rm langflow_logs 2>/dev/null || true
docker volume rm langflow_data 2>/dev/null || true

print_status "Langflow cleanup complete"
echo ""

# Step 2: Check for uncommitted changes
echo "Step 2: Checking for Uncommitted Changes"
echo "-----------------------------------------"

if [ -d "production-backend/.git" ]; then
    cd production-backend
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "Uncommitted changes found in backend"
        echo ""
        read -p "Do you want to commit these changes? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git add .
            git commit -m "fix: sync uncommitted backend changes for deployment"
            print_status "Backend changes committed"
        else
            print_warning "Skipping backend commit - build will use uncommitted files"
        fi
    else
        print_status "No uncommitted changes in backend"
    fi
    cd ..
fi

if [ -d "production-frontend/.git" ]; then
    cd production-frontend
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "Uncommitted changes found in frontend"
        echo ""
        read -p "Do you want to commit these changes? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git add .
            git commit -m "fix: sync uncommitted frontend changes for deployment"
            print_status "Frontend changes committed"
        else
            print_warning "Skipping frontend commit - build will use uncommitted files"
        fi
    else
        print_status "No uncommitted changes in frontend"
    fi
    cd ..
fi

echo ""

# Step 3: Rebuild containers
echo "Step 3: Rebuilding Containers"
echo "------------------------------"

print_warning "This will rebuild backend, frontend, and langflow containers..."
echo ""
read -p "Continue with rebuild? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Stopping affected containers..."
    docker-compose stop backend frontend langflow

    print_status "Rebuilding backend (no cache)..."
    docker-compose build --no-cache backend

    print_status "Rebuilding frontend (no cache)..."
    docker-compose build --no-cache frontend

    print_status "Rebuilding langflow (no cache)..."
    docker-compose build --no-cache langflow

    print_status "Starting containers..."
    docker-compose up -d backend frontend langflow

    echo ""
    print_status "Waiting for containers to be healthy..."
    sleep 10

    # Check container status
    echo ""
    echo "Container Status:"
    docker-compose ps

    echo ""
    print_status "Rebuild complete!"
else
    print_warning "Rebuild cancelled"
    exit 0
fi

echo ""

# Step 4: Verify deployment
echo "Step 4: Verifying Deployment"
echo "-----------------------------"

# Check backend health
echo -n "Checking backend health... "
if curl -sf http://localhost:8000/health > /dev/null; then
    print_status "Backend is healthy"
else
    print_error "Backend health check failed"
fi

# Check frontend
echo -n "Checking frontend... "
if curl -sf http://localhost:3001 > /dev/null; then
    print_status "Frontend is accessible"
else
    print_error "Frontend check failed"
fi

# Check langflow (might take time to start)
echo -n "Checking langflow (may take 30-60s to start)... "
sleep 5
if docker-compose ps langflow | grep -q "Up"; then
    print_status "Langflow container is running"
else
    print_warning "Langflow may still be starting - check logs with: docker logs engarde_langflow"
fi

echo ""

# Step 5: Check for errors in logs
echo "Step 5: Checking Recent Logs"
echo "----------------------------"

print_status "Backend logs (last 10 lines):"
docker logs engarde_backend --tail 10 2>&1 | sed 's/^/  /'

echo ""
print_status "Frontend logs (last 10 lines):"
docker logs engarde_frontend --tail 10 2>&1 | sed 's/^/  /'

echo ""
print_status "Langflow logs (last 10 lines):"
docker logs engarde_langflow --tail 10 2>&1 | sed 's/^/  /' || print_warning "Langflow not ready yet"

echo ""

# Step 6: Optional cleanup
echo "Step 6: Docker Cleanup (Optional)"
echo "---------------------------------"

print_warning "You have significant reclaimable Docker storage (~49GB)"
echo ""
read -p "Do you want to clean up unused Docker resources? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Removing unused images..."
    docker image prune -a -f

    print_status "Removing build cache..."
    docker builder prune -a -f

    print_status "Cleanup complete!"
    echo ""
    docker system df
else
    print_warning "Skipping cleanup - you can run it later with: docker system prune -af"
fi

echo ""
echo "========================================"
print_status "Deployment Fix Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Monitor container health: docker-compose ps"
echo "2. Check logs if issues occur: docker-compose logs -f [service-name]"
echo "3. Access services:"
echo "   - Frontend: http://localhost:3001"
echo "   - Backend API: http://localhost:8000"
echo "   - Backend Docs: http://localhost:8000/docs"
echo "   - Langflow: http://localhost:7860"
echo ""
echo "Full report available at: /Users/cope/EnGardeHQ/DOCKER_DEPLOYMENT_STATUS_REPORT.md"
echo ""
