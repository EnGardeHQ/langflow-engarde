#!/bin/bash

# EnGarde Playwright MCP Server Startup Script
# This script starts the Playwright MCP server with the appropriate configuration for the EnGarde platform

set -e

# Configuration
CONFIG_FILE="/Users/cope/EnGardeHQ/playwright-testing/config/playwright-mcp.config.js"
OUTPUT_DIR="/Users/cope/EnGardeHQ/playwright-testing/reports"
SECRETS_FILE="/Users/cope/EnGardeHQ/.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting EnGarde Playwright MCP Server...${NC}"

# Check if required directories exist
if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${YELLOW}Creating output directory: $OUTPUT_DIR${NC}"
    mkdir -p "$OUTPUT_DIR"
fi

if [ ! -d "/Users/cope/EnGardeHQ/playwright-testing/screenshots" ]; then
    echo -e "${YELLOW}Creating screenshots directory${NC}"
    mkdir -p "/Users/cope/EnGardeHQ/playwright-testing/screenshots"
fi

if [ ! -d "/Users/cope/EnGardeHQ/playwright-testing/user-data" ]; then
    echo -e "${YELLOW}Creating user data directory${NC}"
    mkdir -p "/Users/cope/EnGardeHQ/playwright-testing/user-data"
fi

# Check if EnGarde services are running
echo -e "${BLUE}Checking EnGarde services...${NC}"
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}Frontend service is running on port 3000${NC}"
else
    echo -e "${YELLOW}Warning: Frontend service not detected on port 3000${NC}"
fi

if curl -s http://localhost:8000/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}Backend service is running on port 8000${NC}"
else
    echo -e "${YELLOW}Warning: Backend service not detected on port 8000${NC}"
fi

# Start the MCP server with configuration
echo -e "${BLUE}Starting Playwright MCP Server with configuration...${NC}"

npx @playwright/mcp \
    --config "$CONFIG_FILE" \
    --output-dir "$OUTPUT_DIR" \
    --secrets "$SECRETS_FILE" \
    --browser chrome \
    --viewport-size "1920,1080" \
    --timeout-action 10000 \
    --timeout-navigation 30000 \
    --caps vision,pdf \
    --save-session \
    --save-trace \
    --allowed-origins "http://localhost:3000;http://localhost:8000;https://engarde.local" \
    --blocked-origins "https://analytics.google.com;https://googletagmanager.com" \
    --block-service-workers \
    --ignore-https-errors \
    --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 EnGarde-Testing" \
    --host localhost \
    --port 3001

echo -e "${GREEN}Playwright MCP Server started successfully!${NC}"
echo -e "${BLUE}Server running on: http://localhost:3001${NC}"
echo -e "${BLUE}Output directory: $OUTPUT_DIR${NC}"