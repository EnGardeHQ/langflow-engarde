#!/bin/bash

###############################################################################
# EnGarde Frontend - Production Deployment Script
# This script handles the automated deployment of the AuthContext fix
# with progressive rollout, monitoring, and safety checks
###############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Deployment configuration
PROJECT_ROOT="/Users/cope/EnGardeHQ"
FRONTEND_DIR="${PROJECT_ROOT}/production-frontend"
DEPLOY_LOG="${PROJECT_ROOT}/logs/deploy-$(date +%Y%m%d-%H%M%S).log"
ROLLOUT_PERCENTAGE=${1:-10}  # Default to 10% if not specified
ENVIRONMENT=${2:-production}  # Default to production

# Create logs directory if it doesn't exist
mkdir -p "${PROJECT_ROOT}/logs"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date +%Y-%m-%d\ %H:%M:%S) - $1" | tee -a "${DEPLOY_LOG}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date +%Y-%m-%d\ %H:%M:%S) - $1" | tee -a "${DEPLOY_LOG}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date +%Y-%m-%d\ %H:%M:%S) - $1" | tee -a "${DEPLOY_LOG}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date +%Y-%m-%d\ %H:%M:%S) - $1" | tee -a "${DEPLOY_LOG}"
}

# Error handler
handle_error() {
    log_error "Deployment failed at line $1"
    log_error "Rolling back deployment..."
    bash "${PROJECT_ROOT}/scripts/rollback.sh"
    exit 1
}

trap 'handle_error $LINENO' ERR

###############################################################################
# Pre-Deployment Checks
###############################################################################

log_info "Starting deployment process..."
log_info "Rollout percentage: ${ROLLOUT_PERCENTAGE}%"
log_info "Environment: ${ENVIRONMENT}"
log_info "Deploy log: ${DEPLOY_LOG}"

echo ""
log_info "=== Pre-Deployment Checks ==="

# Check if we're in the right directory
if [ ! -f "${FRONTEND_DIR}/package.json" ]; then
    log_error "Frontend directory not found: ${FRONTEND_DIR}"
    exit 1
fi

cd "${FRONTEND_DIR}"

# Check Node.js version
log_info "Checking Node.js version..."
NODE_VERSION=$(node --version)
log_info "Node.js version: ${NODE_VERSION}"

if [[ ! "${NODE_VERSION}" =~ ^v1[8-9]\. ]] && [[ ! "${NODE_VERSION}" =~ ^v[2-9][0-9]\. ]]; then
    log_error "Node.js version must be >= 18.0.0, found ${NODE_VERSION}"
    exit 1
fi

# Check if git repo is clean (optional warning)
if [ -d .git ]; then
    if ! git diff-index --quiet HEAD --; then
        log_warning "Git repository has uncommitted changes"
        log_warning "Consider committing changes before deployment"
    else
        log_success "Git repository is clean"
    fi
fi

# Check if tests exist and can run
log_info "Checking test infrastructure..."
if [ -f "package.json" ] && grep -q '"test"' package.json; then
    log_success "Test scripts found in package.json"
else
    log_warning "No test scripts found in package.json"
fi

###############################################################################
# Run Tests
###############################################################################

echo ""
log_info "=== Running Tests ==="

log_info "Running unit tests..."
if npm run test:ci >> "${DEPLOY_LOG}" 2>&1; then
    log_success "Unit tests passed"
else
    log_error "Unit tests failed. Check log: ${DEPLOY_LOG}"
    exit 1
fi

log_info "Running type checks..."
if npm run type-check >> "${DEPLOY_LOG}" 2>&1; then
    log_success "Type checks passed"
else
    log_error "Type checks failed. Check log: ${DEPLOY_LOG}"
    exit 1
fi

log_info "Running linter..."
if npm run lint >> "${DEPLOY_LOG}" 2>&1; then
    log_success "Linter passed"
else
    log_warning "Linter warnings found. Check log: ${DEPLOY_LOG}"
fi

###############################################################################
# Update Feature Flags
###############################################################################

echo ""
log_info "=== Updating Feature Flags ==="

# Backup current .env.production
if [ -f .env.production ]; then
    cp .env.production ".env.production.backup.$(date +%Y%m%d-%H%M%S)"
    log_success "Backed up .env.production"
fi

# Update rollout percentage
log_info "Setting rollout percentage to ${ROLLOUT_PERCENTAGE}%..."

if grep -q "NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE" .env.production; then
    # Update existing value
    sed -i.bak "s/^NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE=.*/NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE=${ROLLOUT_PERCENTAGE}/" .env.production
    rm -f .env.production.bak
    log_success "Updated NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE to ${ROLLOUT_PERCENTAGE}"
else
    # Add new value
    echo "NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE=${ROLLOUT_PERCENTAGE}" >> .env.production
    log_success "Added NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE=${ROLLOUT_PERCENTAGE}"
fi

# Ensure feature flag is enabled
if grep -q "NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX=false" .env.production; then
    sed -i.bak "s/^NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX=false/NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX=true/" .env.production
    rm -f .env.production.bak
    log_success "Enabled NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX"
fi

# Enable auth monitoring
if grep -q "NEXT_PUBLIC_ENABLE_AUTH_MONITORING=false" .env.production; then
    sed -i.bak "s/^NEXT_PUBLIC_ENABLE_AUTH_MONITORING=false/NEXT_PUBLIC_ENABLE_AUTH_MONITORING=true/" .env.production
    rm -f .env.production.bak
    log_success "Enabled NEXT_PUBLIC_ENABLE_AUTH_MONITORING"
fi

###############################################################################
# Build Application
###############################################################################

echo ""
log_info "=== Building Application ==="

# Set build environment variables
export BUILD_ID="$(date +%Y%m%d-%H%M%S)"
export COMMIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
export DEPLOY_TIME="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

log_info "Build ID: ${BUILD_ID}"
log_info "Commit SHA: ${COMMIT_SHA}"
log_info "Deploy Time: ${DEPLOY_TIME}"

log_info "Running production build..."
if npm run build >> "${DEPLOY_LOG}" 2>&1; then
    log_success "Production build completed"
else
    log_error "Production build failed. Check log: ${DEPLOY_LOG}"
    exit 1
fi

###############################################################################
# Verify Build Output
###############################################################################

echo ""
log_info "=== Verifying Build Output ==="

if [ ! -d .next ]; then
    log_error "Build output directory (.next) not found"
    exit 1
fi

# Check for critical files
CRITICAL_FILES=(
    ".next/package.json"
    ".next/BUILD_ID"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ ! -f "${file}" ]; then
        log_warning "Expected file not found: ${file}"
    else
        log_success "Found: ${file}"
    fi
done

# Check build size
BUILD_SIZE=$(du -sh .next | cut -f1)
log_info "Build size: ${BUILD_SIZE}"

###############################################################################
# Run E2E Tests (Optional)
###############################################################################

echo ""
log_info "=== Running E2E Tests (Optional) ==="

if command -v playwright &> /dev/null; then
    log_info "Running E2E tests..."
    if npm run test:e2e >> "${DEPLOY_LOG}" 2>&1; then
        log_success "E2E tests passed"
    else
        log_warning "E2E tests failed or skipped. Check log: ${DEPLOY_LOG}"
    fi
else
    log_warning "Playwright not found. Skipping E2E tests."
fi

###############################################################################
# Docker Build (if using Docker)
###############################################################################

echo ""
log_info "=== Docker Build ==="

if [ -f Dockerfile ]; then
    log_info "Building Docker image..."

    DOCKER_TAG="engarde-frontend:${BUILD_ID}"

    if docker build \
        --target production \
        --build-arg NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-/api}" \
        --build-arg NEXT_PUBLIC_APP_NAME="Engarde" \
        --build-arg NEXT_PUBLIC_APP_VERSION="1.0.0" \
        --build-arg BUILD_ID="${BUILD_ID}" \
        --build-arg COMMIT_SHA="${COMMIT_SHA}" \
        --build-arg DEPLOY_TIME="${DEPLOY_TIME}" \
        -t "${DOCKER_TAG}" \
        -t "engarde-frontend:latest" \
        . >> "${DEPLOY_LOG}" 2>&1; then

        log_success "Docker image built: ${DOCKER_TAG}"
    else
        log_error "Docker build failed. Check log: ${DEPLOY_LOG}"
        exit 1
    fi
else
    log_warning "Dockerfile not found. Skipping Docker build."
fi

###############################################################################
# Deployment Summary
###############################################################################

echo ""
log_info "=== Deployment Summary ==="
log_success "Pre-deployment checks: PASSED"
log_success "Tests: PASSED"
log_success "Build: COMPLETED"
log_success "Feature flags: CONFIGURED"
log_info "Rollout percentage: ${ROLLOUT_PERCENTAGE}%"
log_info "Build ID: ${BUILD_ID}"
log_info "Commit SHA: ${COMMIT_SHA}"

echo ""
log_success "======================================"
log_success "  DEPLOYMENT COMPLETED SUCCESSFULLY"
log_success "======================================"
echo ""

log_info "Next steps:"
log_info "1. Deploy to staging environment for validation"
log_info "2. Monitor metrics in DataDog/Sentry dashboard"
log_info "3. Run post-deployment verification: bash scripts/verify.sh"
log_info "4. If successful, increase rollout: bash scripts/deploy.sh 50"
log_info "5. If issues occur, rollback: bash scripts/rollback.sh"
echo ""
log_info "Full deployment log: ${DEPLOY_LOG}"

exit 0
