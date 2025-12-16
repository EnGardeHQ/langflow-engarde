#!/bin/bash
# ============================================================================
# Restart Langflow Service
# ============================================================================
# Purpose: Rebuild and restart Langflow service with fresh configuration
# Author: EnGarde DevOps Team
# Usage: ./scripts/restart-langflow.sh [--rebuild] [--logs]
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Parse arguments
REBUILD=false
FOLLOW_LOGS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --rebuild|-r)
            REBUILD=true
            shift
            ;;
        --logs|-l)
            FOLLOW_LOGS=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --rebuild, -r    Rebuild Docker image before restarting"
            echo "  --logs, -l       Follow logs after restart"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Simple restart"
            echo "  $0 --rebuild          # Rebuild image and restart"
            echo "  $0 --rebuild --logs   # Rebuild, restart, and follow logs"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Change to project root
cd "$PROJECT_ROOT"

# ============================================================================
# Functions
# ============================================================================

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ============================================================================
# Check Docker
# ============================================================================

print_header "Checking Docker Environment"

if ! command -v docker &> /dev/null; then
    print_error "Docker not found. Please install Docker."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "docker-compose not found. Please install docker-compose."
    exit 1
fi

print_success "Docker and docker-compose are available"

# ============================================================================
# Stop Langflow Service
# ============================================================================

print_header "Stopping Langflow Service"

if docker ps -a --format '{{.Names}}' | grep -q '^engarde_langflow$'; then
    print_info "Stopping existing Langflow container..."
    docker-compose stop langflow
    docker-compose rm -f langflow
    print_success "Langflow container stopped and removed"
else
    print_info "No existing Langflow container found"
fi

# ============================================================================
# Rebuild Image (if requested)
# ============================================================================

if [ "$REBUILD" = true ]; then
    print_header "Rebuilding Langflow Image"

    print_info "Building new Langflow image..."
    docker-compose build --no-cache langflow

    print_success "Langflow image rebuilt successfully"

    # Show image info
    IMAGE_ID=$(docker images | grep engarde.*langflow | awk '{print $3}' | head -1)
    if [ ! -z "$IMAGE_ID" ]; then
        IMAGE_SIZE=$(docker images | grep "$IMAGE_ID" | awk '{print $7 " " $8}')
        print_info "Image ID: $IMAGE_ID"
        print_info "Image Size: $IMAGE_SIZE"
    fi
fi

# ============================================================================
# Verify Dependencies
# ============================================================================

print_header "Verifying Dependencies"

# Check if postgres is running
if ! docker-compose ps postgres | grep -q "Up"; then
    print_warning "PostgreSQL container is not running"
    print_info "Starting PostgreSQL..."
    docker-compose up -d postgres

    # Wait for postgres to be healthy
    print_info "Waiting for PostgreSQL to be healthy..."
    MAX_WAIT=30
    WAIT_COUNT=0
    while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
        if docker-compose ps postgres | grep -q "healthy"; then
            break
        fi
        sleep 2
        WAIT_COUNT=$((WAIT_COUNT + 1))
        echo -n "."
    done
    echo ""

    if [ $WAIT_COUNT -eq $MAX_WAIT ]; then
        print_error "PostgreSQL did not become healthy in time"
        exit 1
    fi
    print_success "PostgreSQL is running and healthy"
else
    print_success "PostgreSQL is already running"
fi

# Check if redis is running
if ! docker-compose ps redis | grep -q "Up"; then
    print_warning "Redis container is not running"
    print_info "Starting Redis..."
    docker-compose up -d redis
    sleep 5
    print_success "Redis is running"
else
    print_success "Redis is already running"
fi

# ============================================================================
# Start Langflow Service
# ============================================================================

print_header "Starting Langflow Service"

print_info "Starting Langflow container..."
docker-compose up -d langflow

# Wait for container to start
sleep 5

# Check if container is running
if docker-compose ps langflow | grep -q "Up"; then
    print_success "Langflow container is running"
else
    print_error "Langflow container failed to start"
    print_info "Checking logs..."
    docker-compose logs --tail=50 langflow
    exit 1
fi

# ============================================================================
# Wait for Health Check
# ============================================================================

print_header "Waiting for Langflow Health Check"

print_info "Waiting for Langflow to become healthy..."
MAX_WAIT=60
WAIT_COUNT=0

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    # Check Docker health status
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' engarde_langflow 2>/dev/null || echo "unknown")

    if [ "$HEALTH_STATUS" = "healthy" ]; then
        print_success "Langflow is healthy!"
        break
    fi

    # Also check HTTP endpoint
    if curl -f http://localhost:7860/health &> /dev/null; then
        print_success "Langflow health endpoint is responding!"
        break
    fi

    sleep 2
    WAIT_COUNT=$((WAIT_COUNT + 1))
    echo -n "."
done
echo ""

if [ $WAIT_COUNT -eq $MAX_WAIT ]; then
    print_warning "Health check did not pass within ${MAX_WAIT} seconds"
    print_info "Service may still be starting up. Check logs for details."
else
    print_success "Langflow is fully operational"
fi

# ============================================================================
# Display Status
# ============================================================================

print_header "Service Status"

# Container status
echo -e "${BLUE}Container Status:${NC}"
docker-compose ps langflow

# Health status
echo -e "\n${BLUE}Health Status:${NC}"
HEALTH=$(docker inspect --format='{{.State.Health.Status}}' engarde_langflow 2>/dev/null || echo "no health check")
echo "  Status: $HEALTH"

# Port bindings
echo -e "\n${BLUE}Port Bindings:${NC}"
docker port engarde_langflow 2>/dev/null || echo "  No ports exposed"

# Recent logs
echo -e "\n${BLUE}Recent Logs (last 10 lines):${NC}"
docker-compose logs --tail=10 langflow

# ============================================================================
# Show Access Information
# ============================================================================

print_header "Access Information"

echo -e "${GREEN}Langflow is ready!${NC}\n"
echo -e "${BLUE}Access Points:${NC}"
echo "  Web UI:     http://localhost:7860"
echo "  API:        http://localhost:7860/api"
echo "  Health:     http://localhost:7860/health"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  View logs:           docker-compose logs -f langflow"
echo "  Stop service:        docker-compose stop langflow"
echo "  Restart service:     docker-compose restart langflow"
echo "  Execute command:     docker-compose exec langflow <command>"
echo "  Validate setup:      ./scripts/validate-langflow.sh"
echo ""

# ============================================================================
# Follow Logs (if requested)
# ============================================================================

if [ "$FOLLOW_LOGS" = true ]; then
    print_header "Following Logs (Ctrl+C to exit)"
    docker-compose logs -f langflow
fi

print_success "Langflow restart complete!"
