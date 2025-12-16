#!/bin/bash

# EnGarde Playwright MCP Setup Verification Script
# This script verifies that all components are properly installed and configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 EnGarde Playwright MCP Setup Verification${NC}"
echo "=================================================="

# Check Node.js version
echo -e "${BLUE}📋 Checking Node.js version...${NC}"
NODE_VERSION=$(node --version)
echo "Node.js version: $NODE_VERSION"

if [[ "$NODE_VERSION" < "v18.0.0" ]]; then
    echo -e "${RED}❌ Node.js version 18.0.0 or higher is required${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Node.js version is compatible${NC}"
fi

echo ""

# Check npm version
echo -e "${BLUE}📋 Checking npm version...${NC}"
NPM_VERSION=$(npm --version)
echo "npm version: $NPM_VERSION"
echo -e "${GREEN}✅ npm is available${NC}"

echo ""

# Check if we're in the right directory
echo -e "${BLUE}📁 Checking project directory...${NC}"
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ package.json not found. Please run this script from the playwright-testing directory${NC}"
    exit 1
fi

if grep -q "engarde-playwright-testing" package.json; then
    echo -e "${GREEN}✅ In correct project directory${NC}"
else
    echo -e "${RED}❌ Not in the EnGarde Playwright testing directory${NC}"
    exit 1
fi

echo ""

# Check if dependencies are installed
echo -e "${BLUE}📦 Checking dependencies installation...${NC}"
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠️ Dependencies not installed. Running npm install...${NC}"
    npm install
fi

# Verify @playwright/test is installed
if [ -d "node_modules/@playwright/test" ]; then
    echo -e "${GREEN}✅ @playwright/test is installed${NC}"
else
    echo -e "${RED}❌ @playwright/test is not installed${NC}"
    exit 1
fi

# Verify @playwright/mcp is available globally
if npm list -g @playwright/mcp > /dev/null 2>&1; then
    echo -e "${GREEN}✅ @playwright/mcp is installed globally${NC}"
else
    echo -e "${YELLOW}⚠️ @playwright/mcp not found globally, but it's available via npx${NC}"
fi

echo ""

# Check Playwright version
echo -e "${BLUE}🎭 Checking Playwright versions...${NC}"
PLAYWRIGHT_VERSION=$(npx playwright --version)
echo "Playwright version: $PLAYWRIGHT_VERSION"

MCP_VERSION=$(npx @playwright/mcp --version)
echo "Playwright MCP version: $MCP_VERSION"
echo -e "${GREEN}✅ Playwright components are available${NC}"

echo ""

# Check if browser binaries are installed
echo -e "${BLUE}🌐 Checking browser installations...${NC}"
if npx playwright install --dry-run > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Browser binaries are installed${NC}"
else
    echo -e "${YELLOW}⚠️ Some browser binaries may be missing. Running installation...${NC}"
    npx playwright install
fi

echo ""

# Test configuration files
echo -e "${BLUE}⚙️ Checking configuration files...${NC}"

CONFIG_FILES=(
    "config/playwright.config.js"
    "config/playwright-mcp.config.js"
    "config/global-setup.js"
    "config/global-teardown.js"
)

for config_file in "${CONFIG_FILES[@]}"; do
    if [ -f "$config_file" ]; then
        echo -e "${GREEN}✅ $config_file exists${NC}"
    else
        echo -e "${RED}❌ $config_file is missing${NC}"
        exit 1
    fi
done

echo ""

# Test that tests are discoverable
echo -e "${BLUE}🧪 Checking test discovery...${NC}"
TEST_COUNT=$(npx playwright test --list 2>/dev/null | grep -c "Total:" | tail -1)
if [ "$TEST_COUNT" -gt 0 ]; then
    TOTAL_TESTS=$(npx playwright test --list 2>/dev/null | tail -1 | sed 's/.*Total: \([0-9]*\).*/\1/')
    echo -e "${GREEN}✅ Discovered $TOTAL_TESTS tests${NC}"
else
    echo -e "${RED}❌ No tests discovered${NC}"
    exit 1
fi

echo ""

# Test directory structure
echo -e "${BLUE}📁 Checking directory structure...${NC}"

REQUIRED_DIRS=(
    "tests/auth"
    "tests/tournaments"
    "tests/scoring"
    "config"
    "reports"
    "screenshots"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅ $dir directory exists${NC}"
    else
        echo -e "${RED}❌ $dir directory is missing${NC}"
        exit 1
    fi
done

echo ""

# Test MCP server can start (basic check)
echo -e "${BLUE}🚀 Testing MCP server...${NC}"
if npx @playwright/mcp --help > /dev/null 2>&1; then
    echo -e "${GREEN}✅ MCP server can be invoked${NC}"
else
    echo -e "${RED}❌ MCP server cannot be started${NC}"
    exit 1
fi

echo ""

# Check for startup script
echo -e "${BLUE}📜 Checking startup script...${NC}"
if [ -f "start-mcp-server.sh" ] && [ -x "start-mcp-server.sh" ]; then
    echo -e "${GREEN}✅ MCP startup script is available and executable${NC}"
else
    echo -e "${YELLOW}⚠️ MCP startup script may need chmod +x start-mcp-server.sh${NC}"
fi

echo ""

# Check EnGarde services (optional)
echo -e "${BLUE}🎯 Checking EnGarde services (optional)...${NC}"

if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend service appears to be running on port 3000${NC}"
else
    echo -e "${YELLOW}⚠️ Frontend service not detected on port 3000${NC}"
    echo -e "${YELLOW}   Note: Start the EnGarde frontend before running tests${NC}"
fi

if curl -s http://localhost:8000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend service appears to be running on port 8000${NC}"
else
    echo -e "${YELLOW}⚠️ Backend service not detected on port 8000${NC}"
    echo -e "${YELLOW}   Note: Start the EnGarde backend before running tests${NC}"
fi

echo ""

# Final summary
echo "=================================================="
echo -e "${GREEN}🎉 Setup Verification Complete!${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Start EnGarde services if not already running:"
echo "   - Frontend: npm run dev:frontend (port 3000)"
echo "   - Backend: npm run dev:backend (port 8000)"
echo ""
echo "2. Start the MCP server:"
echo "   ./start-mcp-server.sh"
echo ""
echo "3. Run tests:"
echo "   npm test                    # Run all tests"
echo "   npm run test:headed        # Run with visible browser"
echo "   npm run test:auth          # Run authentication tests"
echo "   npm run test:ui            # Run with UI mode"
echo ""
echo "4. View test reports:"
echo "   npm run test:report        # Open HTML report"
echo ""
echo -e "${GREEN}✅ Your Playwright MCP testing environment is ready!${NC}"