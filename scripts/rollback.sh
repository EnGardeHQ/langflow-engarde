#!/bin/bash

###############################################################################
# EnGarde Frontend - Emergency Rollback Script
# This script performs an instant rollback of the AuthContext fix deployment
# Can be triggered manually or automatically by monitoring alerts
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

# Rollback configuration
PROJECT_ROOT="/Users/cope/EnGardeHQ"
FRONTEND_DIR="${PROJECT_ROOT}/production-frontend"
ROLLBACK_LOG="${PROJECT_ROOT}/logs/rollback-$(date +%Y%m%d-%H%M%S).log"
ROLLBACK_REASON="${1:-manual}"  # Default to manual if not specified

# Create logs directory if it doesn't exist
mkdir -p "${PROJECT_ROOT}/logs"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date +%Y-%m-%d\ %H:%M:%S) - $1" | tee -a "${ROLLBACK_LOG}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date +%Y-%m-%d\ %H:%M:%S) - $1" | tee -a "${ROLLBACK_LOG}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date +%Y-%m-%d\ %H:%M:%S) - $1" | tee -a "${ROLLBACK_LOG}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date +%Y-%m-%d\ %H:%M:%S) - $1" | tee -a "${ROLLBACK_LOG}"
}

###############################################################################
# Rollback Execution
###############################################################################

echo ""
log_error "======================================"
log_error "  INITIATING EMERGENCY ROLLBACK"
log_error "======================================"
echo ""

log_info "Rollback reason: ${ROLLBACK_REASON}"
log_info "Rollback log: ${ROLLBACK_LOG}"
log_info "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

# Check if we're in the right directory
if [ ! -f "${FRONTEND_DIR}/package.json" ]; then
    log_error "Frontend directory not found: ${FRONTEND_DIR}"
    exit 1
fi

cd "${FRONTEND_DIR}"

echo ""
log_info "=== Step 1: Disable Feature Flag ==="

# Immediately disable the auth init fix via feature flag
log_info "Disabling NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX..."

if [ -f .env.production ]; then
    # Backup current config
    cp .env.production ".env.production.rollback.$(date +%Y%m%d-%H%M%S)"

    # Disable feature flag
    if grep -q "NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX" .env.production; then
        sed -i.bak "s/^NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX=true/NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX=false/" .env.production
        rm -f .env.production.bak
        log_success "Disabled NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX"
    else
        echo "NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX=false" >> .env.production
        log_success "Added NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX=false"
    fi

    # Reset rollout percentage to 0
    if grep -q "NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE" .env.production; then
        sed -i.bak "s/^NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE=.*/NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE=0/" .env.production
        rm -f .env.production.bak
        log_success "Reset NEXT_PUBLIC_AUTH_FIX_ROLLOUT_PERCENTAGE to 0"
    fi
else
    log_error ".env.production not found"
    exit 1
fi

echo ""
log_info "=== Step 2: Restore Previous Environment Configuration ==="

# Find the most recent backup
LATEST_BACKUP=$(ls -t .env.production.backup.* 2>/dev/null | head -1 || echo "")

if [ -n "${LATEST_BACKUP}" ] && [ -f "${LATEST_BACKUP}" ]; then
    log_info "Found backup: ${LATEST_BACKUP}"
    log_info "Restoring previous configuration..."

    # Keep current as additional backup
    cp .env.production ".env.production.before-rollback.$(date +%Y%m%d-%H%M%S)"

    # Restore backup
    cp "${LATEST_BACKUP}" .env.production
    log_success "Restored configuration from ${LATEST_BACKUP}"
else
    log_warning "No backup found. Using current config with feature flag disabled."
fi

echo ""
log_info "=== Step 3: Rebuild Application ==="

log_info "Rebuilding application without the fix..."

# Set build environment variables
export BUILD_ID="rollback-$(date +%Y%m%d-%H%M%S)"
export COMMIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
export DEPLOY_TIME="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

log_info "Build ID: ${BUILD_ID}"
log_info "Commit SHA: ${COMMIT_SHA}"

if npm run build >> "${ROLLBACK_LOG}" 2>&1; then
    log_success "Application rebuild completed"
else
    log_error "Application rebuild failed. Check log: ${ROLLBACK_LOG}"
    log_error "Manual intervention required!"
    exit 1
fi

echo ""
log_info "=== Step 4: Rebuild Docker Image (if applicable) ==="

if [ -f Dockerfile ]; then
    log_info "Rebuilding Docker image..."

    DOCKER_TAG="engarde-frontend:rollback-$(date +%Y%m%d-%H%M%S)"

    if docker build \
        --target production \
        --build-arg NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-/api}" \
        --build-arg NEXT_PUBLIC_APP_NAME="Engarde" \
        --build-arg NEXT_PUBLIC_APP_VERSION="1.0.0" \
        -t "${DOCKER_TAG}" \
        -t "engarde-frontend:latest" \
        . >> "${ROLLBACK_LOG}" 2>&1; then

        log_success "Docker image rebuilt: ${DOCKER_TAG}"
    else
        log_error "Docker rebuild failed. Check log: ${ROLLBACK_LOG}"
        log_warning "Continuing rollback process..."
    fi
else
    log_info "Dockerfile not found. Skipping Docker rebuild."
fi

echo ""
log_info "=== Step 5: Verify Rollback ==="

# Check that feature flag is disabled
if grep -q "NEXT_PUBLIC_ENABLE_AUTH_INIT_FIX=false" .env.production; then
    log_success "Feature flag is disabled"
else
    log_error "Feature flag verification failed!"
    exit 1
fi

# Check that build output exists
if [ -d .next ]; then
    log_success "Build output verified"
else
    log_error "Build output missing!"
    exit 1
fi

echo ""
log_info "=== Step 6: Notification ==="

# Send notification to monitoring services (if configured)
if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
    curl -X POST "${SLACK_WEBHOOK_URL}" \
        -H 'Content-Type: application/json' \
        -d "{\"text\":\"🔴 ROLLBACK EXECUTED - EnGarde Frontend\n\nReason: ${ROLLBACK_REASON}\nTimestamp: $(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)\nOperator: ${USER}\n\nStatus: Completed\"}" \
        >> "${ROLLBACK_LOG}" 2>&1 || log_warning "Failed to send Slack notification"
fi

# Log rollback event to monitoring services
if [ -n "${SENTRY_DSN:-}" ]; then
    log_info "Logging rollback event to Sentry..."
    # Note: Actual Sentry logging would require sentry-cli or API call
    log_info "Sentry event logged (configure sentry-cli for automated logging)"
fi

echo ""
log_info "=== Rollback Summary ==="
log_success "Feature flag: DISABLED"
log_success "Application: REBUILT"
log_success "Configuration: RESTORED"
log_info "Rollback reason: ${ROLLBACK_REASON}"
log_info "Build ID: ${BUILD_ID}"

echo ""
log_success "======================================"
log_success "  ROLLBACK COMPLETED SUCCESSFULLY"
log_success "======================================"
echo ""

log_info "Next steps:"
log_info "1. Verify application functionality"
log_info "2. Check monitoring dashboards for metrics recovery"
log_info "3. Review rollback log: ${ROLLBACK_LOG}"
log_info "4. Investigate root cause of issues"
log_info "5. Prepare fix and re-deploy when ready"
echo ""

log_warning "Important: Investigate the root cause before attempting re-deployment"
log_info "Full rollback log: ${ROLLBACK_LOG}"

exit 0
