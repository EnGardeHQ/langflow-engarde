#!/bin/bash
# ============================================================================
# EnGarde Production Promotion Script
# ============================================================================
# Purpose: Promote staging to production after successful testing
# Usage: ./promote-to-production.sh
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
PRODUCTION_BRANCH="main"

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

# Function to prompt for confirmation
confirm() {
    read -p "$1 (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
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

# Function to verify staging is healthy
verify_staging() {
    print_info "Verifying staging environment health..."

    # Check backend
    print_info "Checking staging backend..."
    if ! curl -f -s https://staging.engarde.media/health > /dev/null 2>&1; then
        print_error "Staging backend is not healthy!"
        print_error "Fix staging issues before promoting to production"
        exit 1
    fi

    STAGING_HEALTH=$(curl -s https://staging.engarde.media/health)
    print_success "Staging backend is healthy"
    echo "$STAGING_HEALTH"
    echo ""

    # Prompt for manual verification
    if ! confirm "Have you tested all critical features in staging?"; then
        print_warning "Promotion cancelled. Please test staging thoroughly first."
        exit 0
    fi

    if ! confirm "Are there any errors in staging logs?"; then
        print_warning "Please fix staging errors before promoting to production."
        exit 0
    fi

    print_success "Staging verification passed"
}

# Function to create backup tag
create_backup_tag() {
    local DIR=$1
    local SERVICE=$2

    print_info "Creating backup tag for $SERVICE..."

    cd "$DIR" || exit 1

    # Create tag with timestamp
    TAG_NAME="backup-$(date +%Y%m%d-%H%M%S)"
    git tag -a "$TAG_NAME" -m "Backup before production deployment"
    git push origin "$TAG_NAME"

    print_success "Backup tag created: $TAG_NAME"
}

# Function to promote backend
promote_backend() {
    print_info "Promoting backend to production..."

    cd "$BACKEND_DIR" || exit 1

    # Create backup tag
    create_backup_tag "$BACKEND_DIR" "backend"

    # Switch to main branch
    git checkout "$PRODUCTION_BRANCH" || {
        print_error "Failed to checkout production branch"
        exit 1
    }

    # Pull latest
    git pull origin "$PRODUCTION_BRANCH"

    # Merge staging
    print_info "Merging staging into main..."
    git merge "$STAGING_BRANCH" --no-ff -m "chore: promote staging to production $(date +%Y-%m-%d)" || {
        print_error "Merge failed. Please resolve conflicts manually."
        exit 1
    }

    # Push to production
    print_info "Pushing to production..."
    git push origin "$PRODUCTION_BRANCH" || {
        print_error "Failed to push to production"
        exit 1
    }

    print_success "Backend code promoted to production branch"

    # Wait for Railway auto-deploy
    print_info "Waiting for Railway auto-deployment to Main service..."
    sleep 15

    # Check production health
    print_info "Checking production backend health..."
    MAX_RETRIES=12
    RETRY_COUNT=0

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -f -s https://api.engarde.media/health > /dev/null 2>&1; then
            print_success "Production backend is healthy!"
            PROD_HEALTH=$(curl -s https://api.engarde.media/health)
            echo "$PROD_HEALTH"
            break
        fi

        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
            print_error "Production health check failed!"
            print_error "ROLLING BACK..."
            rollback_backend
            exit 1
        fi

        print_info "Waiting for production to be healthy... (attempt $RETRY_COUNT/$MAX_RETRIES)"
        sleep 10
    done

    print_success "Backend promoted to production successfully"
}

# Function to promote frontend
promote_frontend() {
    print_info "Promoting frontend to production..."

    cd "$FRONTEND_DIR" || exit 1

    # Create backup tag
    create_backup_tag "$FRONTEND_DIR" "frontend"

    # Switch to main branch
    git checkout "$PRODUCTION_BRANCH" || {
        print_error "Failed to checkout production branch"
        exit 1
    }

    # Pull latest
    git pull origin "$PRODUCTION_BRANCH"

    # Merge staging
    print_info "Merging staging into main..."
    git merge "$STAGING_BRANCH" --no-ff -m "chore: promote staging to production $(date +%Y-%m-%d)" || {
        print_error "Merge failed. Please resolve conflicts manually."
        exit 1
    }

    # Push to production
    print_info "Pushing to production..."
    git push origin "$PRODUCTION_BRANCH" || {
        print_error "Failed to push to production"
        exit 1
    }

    print_success "Frontend code promoted to production branch"
    print_info "Vercel will auto-deploy to https://engarde.app"

    # Wait for Vercel
    print_info "Waiting for Vercel deployment..."
    sleep 20

    print_success "Frontend promoted to production successfully"
}

# Function to rollback backend
rollback_backend() {
    print_error "Rolling back backend..."

    cd "$BACKEND_DIR" || exit 1
    git checkout "$PRODUCTION_BRANCH"
    git reset --hard HEAD~1
    git push origin "$PRODUCTION_BRANCH" --force

    print_warning "Backend rolled back. Check Railway logs."
}

# Function to run production smoke tests
run_production_tests() {
    print_info "Running production smoke tests..."

    # Test backend health
    print_info "Testing production backend..."
    PROD_HEALTH=$(curl -s https://api.engarde.media/health)
    if echo "$PROD_HEALTH" | grep -q "running"; then
        print_success "Production backend health check passed"
        echo "$PROD_HEALTH"
    else
        print_error "Production backend health check failed!"
        echo "Response: $PROD_HEALTH"
        return 1
    fi

    # Test frontend
    print_info "Testing production frontend..."
    if curl -f -s https://engarde.app > /dev/null 2>&1; then
        print_success "Production frontend is accessible"
    else
        print_error "Production frontend is not accessible!"
        return 1
    fi

    # Test critical API endpoint
    print_info "Testing critical API endpoint..."
    if curl -f -s https://api.engarde.media/docs > /dev/null 2>&1; then
        print_success "API documentation is accessible"
    else
        print_warning "API docs not accessible (may be disabled in production)"
    fi

    print_success "Production smoke tests passed"
}

# Function to display post-deployment info
show_post_deployment_info() {
    echo ""
    echo "========================================"
    echo "  Production Deployment Complete"
    echo "========================================"
    echo ""
    echo "Production URLs:"
    echo "  Frontend: https://engarde.app"
    echo "  Backend:  https://api.engarde.media"
    echo "  API Docs: https://api.engarde.media/docs"
    echo ""
    echo "Monitoring Commands:"
    echo "  Backend:  railway logs --service Main --follow"
    echo "  Frontend: https://vercel.com/engardehq/production-frontend/deployments"
    echo ""
    echo "Health Checks:"
    echo "  curl https://api.engarde.media/health"
    echo "  curl https://engarde.app"
    echo ""
    echo "Rollback (if needed):"
    echo "  Backend:  railway rollback --service Main"
    echo "  Frontend: vercel rollback"
    echo ""
    echo "IMPORTANT: Monitor production closely for the next 30 minutes!"
    echo ""
}

# Main execution
main() {
    echo "========================================"
    echo "  EnGarde Production Promotion"
    echo "========================================"
    echo ""

    print_warning "This will promote staging to production!"
    print_warning "Make sure you have tested everything in staging."
    echo ""

    if ! confirm "Do you want to proceed with production deployment?"; then
        print_warning "Deployment cancelled"
        exit 0
    fi

    echo ""
    check_prerequisites
    verify_staging

    echo ""
    print_info "Starting production promotion..."
    echo ""

    # Promote backend
    promote_backend

    echo ""

    # Promote frontend
    promote_frontend

    echo ""

    # Run production tests
    if run_production_tests; then
        show_post_deployment_info
    else
        print_error "Production tests failed!"
        print_warning "Consider rolling back the deployment"
        exit 1
    fi
}

# Run main function
main
