#!/bin/bash
# ============================================================================
# EnGarde Staging Deployment Script
# ============================================================================
# Purpose: Deploy backend and frontend to staging environment
# Usage: ./deploy-to-staging.sh [backend|frontend|all]
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_DIR="/Users/cope/EnGardeHQ/production-backend"
FRONTEND_DIR="/Users/cope/EnGardeHQ/production-frontend"
STAGING_BRANCH="staging"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    if ! command_exists railway; then
        print_error "Railway CLI not found. Install with: npm i -g @railway/cli"
        exit 1
    fi

    if ! command_exists git; then
        print_error "Git not found. Please install Git."
        exit 1
    fi

    print_success "All prerequisites met"
}

# Function to deploy backend to staging
deploy_backend() {
    print_info "Starting backend deployment to staging..."

    cd "$BACKEND_DIR" || exit 1

    # Check if on staging branch
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" != "$STAGING_BRANCH" ]; then
        print_warning "Not on staging branch. Switching..."
        git checkout "$STAGING_BRANCH" || {
            print_error "Failed to switch to staging branch"
            exit 1
        }
    fi

    # Pull latest changes
    print_info "Pulling latest changes from origin/$STAGING_BRANCH..."
    git pull origin "$STAGING_BRANCH" || {
        print_error "Failed to pull latest changes"
        exit 1
    }

    # Deploy to Railway
    print_info "Deploying to Railway 'Main Copy' service..."
    railway link --service "Main Copy" 2>/dev/null || print_warning "Already linked or manual linking required"

    railway up --service "Main Copy" --detach || {
        print_error "Railway deployment failed"
        exit 1
    }

    print_success "Backend deployment initiated"

    # Wait for deployment
    print_info "Waiting for deployment to complete..."
    sleep 10

    # Check health
    print_info "Checking staging backend health..."
    MAX_RETRIES=12
    RETRY_COUNT=0

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -f -s https://staging.engarde.media/health > /dev/null 2>&1; then
            print_success "Backend is healthy!"
            HEALTH_DATA=$(curl -s https://staging.engarde.media/health)
            echo "$HEALTH_DATA"
            break
        fi

        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
            print_error "Backend health check failed after $MAX_RETRIES attempts"
            print_info "Check logs with: railway logs --service 'Main Copy'"
            exit 1
        fi

        print_info "Waiting for backend to start... (attempt $RETRY_COUNT/$MAX_RETRIES)"
        sleep 10
    done

    print_success "Backend deployment completed successfully"
}

# Function to deploy frontend to staging
deploy_frontend() {
    print_info "Starting frontend deployment to staging..."

    cd "$FRONTEND_DIR" || exit 1

    # Check if on staging branch
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" != "$STAGING_BRANCH" ]; then
        print_warning "Not on staging branch. Switching..."
        git checkout "$STAGING_BRANCH" || {
            # Create staging branch if it doesn't exist
            print_info "Creating staging branch..."
            git checkout -b "$STAGING_BRANCH"
        }
    fi

    # Pull latest changes
    print_info "Pulling latest changes from origin/$STAGING_BRANCH..."
    git pull origin "$STAGING_BRANCH" 2>/dev/null || print_info "No remote staging branch yet"

    # Push to trigger Vercel deployment
    print_info "Pushing to staging branch to trigger Vercel deployment..."
    git push origin "$STAGING_BRANCH" || {
        print_error "Failed to push to staging branch"
        exit 1
    }

    print_success "Frontend deployment triggered on Vercel"
    print_info "Monitor deployment at: https://vercel.com/engardehq/production-frontend/deployments"

    # Wait a bit for Vercel to start
    print_info "Waiting for Vercel deployment to start..."
    sleep 15

    print_success "Frontend deployment initiated"
}

# Function to run staging tests
run_staging_tests() {
    print_info "Running staging environment tests..."

    # Test backend health
    print_info "Testing backend health endpoint..."
    HEALTH_RESPONSE=$(curl -s https://staging.engarde.media/health)
    if echo "$HEALTH_RESPONSE" | grep -q "running"; then
        print_success "Backend health check passed"
    else
        print_error "Backend health check failed"
        echo "Response: $HEALTH_RESPONSE"
    fi

    # Test backend API docs
    print_info "Testing API documentation endpoint..."
    if curl -f -s https://staging.engarde.media/docs > /dev/null 2>&1; then
        print_success "API docs accessible"
    else
        print_warning "API docs not accessible (may be disabled)"
    fi

    # Test CORS
    print_info "Testing CORS configuration..."
    CORS_TEST=$(curl -s -I https://staging.engarde.media/health \
        -H "Origin: https://staging-frontend.vercel.app" | grep -i "access-control-allow-origin")

    if [ -n "$CORS_TEST" ]; then
        print_success "CORS configured correctly"
    else
        print_warning "CORS headers not found - may need configuration"
    fi

    print_success "Staging tests completed"
}

# Function to display deployment info
show_deployment_info() {
    echo ""
    echo "========================================"
    echo "  Staging Deployment Complete"
    echo "========================================"
    echo ""
    echo "URLs:"
    echo "  Backend:  https://staging.engarde.media"
    echo "  Frontend: https://staging-frontend.vercel.app"
    echo ""
    echo "Monitoring:"
    echo "  Backend Logs:  railway logs --service 'Main Copy' --follow"
    echo "  Vercel Logs:   https://vercel.com/engardehq/production-frontend/deployments"
    echo ""
    echo "Health Checks:"
    echo "  curl https://staging.engarde.media/health"
    echo ""
    echo "Next Steps:"
    echo "  1. Test all critical features in staging"
    echo "  2. Review logs for any errors"
    echo "  3. If tests pass, promote to production with: ./promote-to-production.sh"
    echo ""
}

# Main execution
main() {
    DEPLOY_TARGET="${1:-all}"

    echo "========================================"
    echo "  EnGarde Staging Deployment"
    echo "========================================"
    echo ""

    check_prerequisites

    case "$DEPLOY_TARGET" in
        backend)
            deploy_backend
            ;;
        frontend)
            deploy_frontend
            ;;
        all)
            deploy_backend
            echo ""
            deploy_frontend
            echo ""
            run_staging_tests
            ;;
        *)
            print_error "Invalid argument. Use: backend, frontend, or all"
            exit 1
            ;;
    esac

    show_deployment_info
}

# Run main function
main "$@"
