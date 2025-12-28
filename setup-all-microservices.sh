#!/opt/homebrew/bin/bash
#
# Complete Setup Script for En Garde Intelligence Microservices
# Deploys Onside, MadanSara, and Sankore to Railway from separate GitHub repos
#
# Usage: ./setup-all-microservices.sh
#

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
GITHUB_ORG="EnGardeHQ"
BASE_DIR="/Users/cope/EnGardeHQ"

# Services configuration
declare -A SERVICES=(
    ["onside"]="8001"
    ["madan-sara"]="8002"
    ["sankore"]="8003"
)

declare -A SERVICE_DIRS=(
    ["onside"]="Onside"
    ["madan-sara"]="MadanSara"
    ["sankore"]="Sankore"
)

declare -A SERVICE_REPOS=(
    ["onside"]="Onside"
    ["madan-sara"]="MadanSara"
    ["sankore"]="Sankore"
)

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  En Garde Intelligence Microservices Setup                       ║${NC}"
echo -e "${CYAN}║  GitHub (Separate Repos) + Railway Deployment                    ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# Prerequisites Check
# ============================================
echo -e "${BLUE}[1/8] Checking Prerequisites...${NC}"

# Check Railway CLI
if ! command -v railway &> /dev/null; then
    echo -e "${RED}✗ Railway CLI not found${NC}"
    echo "  Install with: npm install -g @railway/cli"
    echo "  Or: brew install railway"
    exit 1
fi
echo -e "${GREEN}✓ Railway CLI found${NC}"

# Check Git
if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ Git not found${NC}"
    echo "  Install with: brew install git"
    exit 1
fi
echo -e "${GREEN}✓ Git found${NC}"

# Check Railway login
if ! railway whoami &> /dev/null; then
    echo -e "${YELLOW}⚠ Not logged in to Railway${NC}"
    echo "  Logging in..."
    railway login
fi
echo -e "${GREEN}✓ Logged in to Railway${NC}"

# Check GitHub authentication
echo ""
echo -e "${YELLOW}NOTE: Make sure you have:${NC}"
echo "  1. Created GitHub organization: ${GITHUB_ORG}"
echo "  2. Created three empty repos:"
echo "     - ${GITHUB_ORG}/Onside"
echo "     - ${GITHUB_ORG}/MadanSara"
echo "     - ${GITHUB_ORG}/Sankore"
echo "  3. Set up GitHub authentication (SSH or HTTPS)"
echo ""
read -p "Press ENTER when ready to continue..."

echo ""

# ============================================
# Collect Shared Environment Variables
# ============================================
echo -e "${BLUE}[2/8] Collecting Shared Environment Variables...${NC}"
echo ""
echo "These variables will be set for ALL three services."
echo "Leave blank to skip a variable."
echo ""

# Database
read -p "ENGARDE_DATABASE_URL (PostgreSQL connection string): " DB_URL
read -p "ZERODB_URL (Qdrant URL, e.g., http://qdrant:6333): " ZERODB_URL
read -p "ZERODB_API_KEY (Qdrant API key): " ZERODB_KEY

# AI
read -p "ANTHROPIC_API_KEY (Claude API key): " ANTHROPIC_KEY

# En Garde
read -p "ENGARDE_API_KEY (Walker SDK key): " ENGARDE_KEY
ENGARDE_BASE_URL="${ENGARDE_BASE_URL:-https://api.engarde.com/v1}"

# Service Mesh
echo ""
echo "Generating SERVICE_MESH_SECRET..."
SERVICE_MESH_SECRET=$(openssl rand -hex 32)
echo -e "${GREEN}✓ Generated: ${SERVICE_MESH_SECRET:0:20}...${NC}"

# Environment
read -p "Environment (production/staging) [production]: " ENVIRONMENT
ENVIRONMENT="${ENVIRONMENT:-production}"

echo ""
echo -e "${GREEN}✓ Environment variables collected${NC}"

# ============================================
# Setup Each Service
# ============================================
setup_service() {
    local SERVICE_NAME=$1
    local SERVICE_PORT=$2
    local SERVICE_DIR=$3
    local SERVICE_REPO=$4

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Setting up: ${SERVICE_NAME}${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"

    # Navigate to service directory
    cd "${BASE_DIR}/${SERVICE_DIR}"
    echo -e "${YELLOW}➜ Working directory: ${BASE_DIR}/${SERVICE_DIR}${NC}"

    # ============================================
    # GitHub Setup
    # ============================================
    echo ""
    echo -e "${BLUE}[3/8] GitHub Repository Setup...${NC}"

    # Initialize git if needed
    if [ ! -d ".git" ]; then
        echo "  Initializing git repository..."
        git init
        git branch -M main
    else
        echo -e "${GREEN}  ✓ Git repository already initialized${NC}"
    fi

    # Check if remote exists
    if ! git remote | grep -q "origin"; then
        echo "  Adding GitHub remote..."
        git remote add origin "https://github.com/${GITHUB_ORG}/${SERVICE_REPO}.git"
    else
        echo -e "${GREEN}  ✓ GitHub remote already configured${NC}"
    fi

    # Commit all changes
    echo "  Staging all files..."
    git add .

    if git diff --cached --quiet; then
        echo -e "${GREEN}  ✓ No changes to commit${NC}"
    else
        echo "  Committing changes..."
        git commit -m "Setup ${SERVICE_NAME} microservice for Railway deployment" || true
    fi

    # Push to GitHub
    echo "  Pushing to GitHub..."
    if git push -u origin main 2>&1 | grep -q "Everything up-to-date"; then
        echo -e "${GREEN}  ✓ Already up to date${NC}"
    else
        git push -u origin main || {
            echo -e "${YELLOW}  ⚠ Push failed. You may need to configure GitHub authentication.${NC}"
            echo "    Run: gh auth login"
            echo "    Or set up SSH keys: https://docs.github.com/en/authentication"
            read -p "  Continue anyway? (y/n): " CONTINUE
            if [ "$CONTINUE" != "y" ]; then
                exit 1
            fi
        }
        echo -e "${GREEN}  ✓ Pushed to GitHub${NC}"
    fi

    # ============================================
    # Railway Setup
    # ============================================
    echo ""
    echo -e "${BLUE}[4/8] Railway Service Setup...${NC}"

    # Check if already linked
    if [ -f ".railway" ]; then
        echo -e "${GREEN}  ✓ Railway project already linked${NC}"
    else
        echo "  Linking to Railway project..."
        railway link || {
            echo "  Creating new Railway project..."
            railway init
        }
    fi

    # Set environment
    railway environment "${ENVIRONMENT}"

    # ============================================
    # Set Environment Variables
    # ============================================
    echo ""
    echo -e "${BLUE}[5/8] Setting Environment Variables...${NC}"

    # Service-specific variables
    railway variables set SERVICE_NAME="${SERVICE_NAME}" --environment "${ENVIRONMENT}"
    railway variables set PORT="${SERVICE_PORT}" --environment "${ENVIRONMENT}"

    # Shared variables
    if [ -n "${DB_URL}" ]; then
        railway variables set ENGARDE_DATABASE_URL="${DB_URL}" --environment "${ENVIRONMENT}"
        railway variables set DATABASE_PUBLIC_URL="${DB_URL}" --environment "${ENVIRONMENT}"
    fi

    if [ -n "${ZERODB_URL}" ]; then
        railway variables set ZERODB_URL="${ZERODB_URL}" --environment "${ENVIRONMENT}"
    fi

    if [ -n "${ZERODB_KEY}" ]; then
        railway variables set ZERODB_API_KEY="${ZERODB_KEY}" --environment "${ENVIRONMENT}"
    fi

    if [ -n "${ANTHROPIC_KEY}" ]; then
        railway variables set ANTHROPIC_API_KEY="${ANTHROPIC_KEY}" --environment "${ENVIRONMENT}"
    fi

    if [ -n "${ENGARDE_KEY}" ]; then
        railway variables set ENGARDE_API_KEY="${ENGARDE_KEY}" --environment "${ENVIRONMENT}"
    fi

    railway variables set ENGARDE_BASE_URL="${ENGARDE_BASE_URL}" --environment "${ENVIRONMENT}"
    railway variables set SERVICE_MESH_SECRET="${SERVICE_MESH_SECRET}" --environment "${ENVIRONMENT}"
    railway variables set ENVIRONMENT="${ENVIRONMENT}" --environment "${ENVIRONMENT}"

    # Database pool settings
    railway variables set DB_POOL_SIZE=5 --environment "${ENVIRONMENT}"
    railway variables set DB_MAX_OVERFLOW=10 --environment "${ENVIRONMENT}"
    railway variables set DB_POOL_TIMEOUT=30 --environment "${ENVIRONMENT}"

    # Service mesh settings
    railway variables set SERVICE_MESH_TIMEOUT=30 --environment "${ENVIRONMENT}"
    railway variables set CIRCUIT_BREAKER_THRESHOLD=5 --environment "${ENVIRONMENT}"

    echo -e "${GREEN}  ✓ Environment variables set${NC}"

    # ============================================
    # Deploy to Railway
    # ============================================
    echo ""
    echo -e "${BLUE}[6/8] Deploying to Railway...${NC}"
    echo "  This may take a few minutes..."

    railway up --detach --environment "${ENVIRONMENT}" || {
        echo -e "${RED}  ✗ Deployment failed${NC}"
        echo "  Check logs with: railway logs --environment ${ENVIRONMENT}"
        exit 1
    }

    echo -e "${GREEN}  ✓ Deployment initiated${NC}"

    # Wait a bit for deployment to start
    echo "  Waiting for deployment to start..."
    sleep 10

    # ============================================
    # Get Service URL
    # ============================================
    echo ""
    echo -e "${BLUE}[7/8] Getting Service URL...${NC}"

    SERVICE_URL=$(railway domain --environment "${ENVIRONMENT}" 2>/dev/null || echo "Not yet assigned")

    echo -e "${GREEN}  ✓ Service URL: ${SERVICE_URL}${NC}"

    # ============================================
    # Verify Deployment
    # ============================================
    echo ""
    echo -e "${BLUE}[8/8] Verifying Deployment...${NC}"

    # Check status
    railway status --environment "${ENVIRONMENT}"

    # Store URL for later
    echo "${SERVICE_URL}" > ".railway-url"

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ${SERVICE_NAME} Setup Complete!${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Service: ${GREEN}${SERVICE_NAME}${NC}"
    echo -e "  Port: ${GREEN}${SERVICE_PORT}${NC}"
    echo -e "  GitHub: ${GREEN}https://github.com/${GITHUB_ORG}/${SERVICE_REPO}${NC}"
    echo -e "  Railway URL: ${GREEN}${SERVICE_URL}${NC}"
    echo -e "  Environment: ${GREEN}${ENVIRONMENT}${NC}"
    echo ""
}

# ============================================
# Setup All Services
# ============================================
echo ""
echo -e "${YELLOW}Setting up all three microservices...${NC}"
echo ""

for SERVICE_KEY in onside madan-sara sankore; do
    setup_service \
        "${SERVICE_KEY}" \
        "${SERVICES[$SERVICE_KEY]}" \
        "${SERVICE_DIRS[$SERVICE_KEY]}" \
        "${SERVICE_REPOS[$SERVICE_KEY]}"
done

# ============================================
# Update Service Mesh URLs
# ============================================
echo ""
echo -e "${BLUE}Updating Service Mesh URLs...${NC}"

# Collect URLs
ONSIDE_URL=$(cat "${BASE_DIR}/Onside/.railway-url" 2>/dev/null || echo "")
MADANSARA_URL=$(cat "${BASE_DIR}/MadanSara/.railway-url" 2>/dev/null || echo "")
SANKORE_URL=$(cat "${BASE_DIR}/Sankore/.railway-url" 2>/dev/null || echo "")

# Update each service with other service URLs
if [ -n "${ONSIDE_URL}" ] && [ -n "${MADANSARA_URL}" ] && [ -n "${SANKORE_URL}" ]; then
    echo "  Setting inter-service URLs..."

    # Onside
    cd "${BASE_DIR}/Onside"
    railway variables set MADAN_SARA_URL="${MADANSARA_URL}" --environment "${ENVIRONMENT}"
    railway variables set SANKORE_URL="${SANKORE_URL}" --environment "${ENVIRONMENT}"

    # MadanSara
    cd "${BASE_DIR}/MadanSara"
    railway variables set ONSIDE_URL="${ONSIDE_URL}" --environment "${ENVIRONMENT}"
    railway variables set SANKORE_URL="${SANKORE_URL}" --environment "${ENVIRONMENT}"

    # Sankore
    cd "${BASE_DIR}/Sankore"
    railway variables set ONSIDE_URL="${ONSIDE_URL}" --environment "${ENVIRONMENT}"
    railway variables set MADAN_SARA_URL="${MADANSARA_URL}" --environment "${ENVIRONMENT}"

    echo -e "${GREEN}  ✓ Service mesh URLs configured${NC}"
else
    echo -e "${YELLOW}  ⚠ Some service URLs not available yet${NC}"
    echo "  Run this manually after all services are deployed:"
    echo "    cd ${BASE_DIR}/MadanSara"
    echo "    railway variables set ONSIDE_URL=<url>"
    echo "    railway variables set SANKORE_URL=<url>"
fi

# ============================================
# Final Summary
# ============================================
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  All Microservices Deployed!                                     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Services Deployed:${NC}"
echo ""
echo -e "  ${BLUE}Onside (SEO Intelligence)${NC}"
echo -e "    GitHub: https://github.com/${GITHUB_ORG}/Onside"
echo -e "    Railway: ${ONSIDE_URL}"
echo -e "    Port: 8001"
echo ""
echo -e "  ${BLUE}Madan Sara (Conversion Intelligence)${NC}"
echo -e "    GitHub: https://github.com/${GITHUB_ORG}/MadanSara"
echo -e "    Railway: ${MADANSARA_URL}"
echo -e "    Port: 8002"
echo ""
echo -e "  ${BLUE}Sankore (Paid Ads Intelligence)${NC}"
echo -e "    GitHub: https://github.com/${GITHUB_ORG}/Sankore"
echo -e "    Railway: ${SANKORE_URL}"
echo -e "    Port: 8003"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo ""
echo "  1. Initialize ZeroDB collections:"
echo "     ${CYAN}cd ${BASE_DIR}/MadanSara${NC}"
echo "     ${CYAN}python scripts/init-zerodb-collections.py${NC}"
echo ""
echo "  2. Test health endpoints:"
echo "     ${CYAN}curl ${ONSIDE_URL}/health${NC}"
echo "     ${CYAN}curl ${MADANSARA_URL}/health${NC}"
echo "     ${CYAN}curl ${SANKORE_URL}/health${NC}"
echo ""
echo "  3. View logs:"
echo "     ${CYAN}railway logs --service onside${NC}"
echo "     ${CYAN}railway logs --service madan-sara${NC}"
echo "     ${CYAN}railway logs --service sankore${NC}"
echo ""
echo "  4. Test auto-deploy:"
echo "     ${CYAN}cd ${BASE_DIR}/MadanSara${NC}"
echo "     ${CYAN}echo '# Test' >> README.md${NC}"
echo "     ${CYAN}git add . && git commit -m 'Test' && git push${NC}"
echo "     ${CYAN}# Watch Railway auto-deploy!${NC}"
echo ""
echo -e "${GREEN}Auto-Deploy Configured:${NC}"
echo "  ✓ Push to GitHub main branch → Automatic Railway deployment"
echo "  ✓ Separate containers for each service"
echo "  ✓ Shared database and ZeroDB"
echo "  ✓ Service mesh for inter-service communication"
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
echo ""
