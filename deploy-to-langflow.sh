#!/bin/bash

# Deploy Walker Agents and EnGarde Agents to Langflow Server
# This script helps deploy custom components to Langflow on Railway

set -e  # Exit on error

echo "🚀 EnGarde Custom Components Deployment Script"
echo "=============================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if in correct directory
if [ ! -d "production-backend/langflow/custom_components" ]; then
    echo -e "${RED}❌ Error: Must run from EnGardeHQ directory${NC}"
    echo "Current directory: $(pwd)"
    exit 1
fi

echo -e "${GREEN}✅ Found custom components${NC}"
echo ""

# Show what we're deploying
echo "📦 Components to deploy:"
echo "  - Walker Agents (7 components)"
echo "    └── walker_agents/"
echo "        ├── __init__.py"
echo "        └── walker_agent_components.py"
echo ""
echo "  - EnGarde Agents (6 components)"
echo "    └── engarde_agents/"
echo "        ├── __init__.py"
echo "        └── engarde_agent_components.py"
echo ""

# Ask user for deployment method
echo "📋 Deployment Options:"
echo ""
echo "1. Copy to existing Langflow repository"
echo "2. Fork official Langflow and add components"
echo "3. Create deployment package for manual upload"
echo "4. Show deployment guide"
echo ""

read -p "Choose option (1-4): " choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}Option 1: Copy to Existing Repository${NC}"
        echo ""

        read -p "Enter path to your Langflow repository: " langflow_path

        if [ ! -d "$langflow_path" ]; then
            echo -e "${RED}❌ Error: Directory not found: $langflow_path${NC}"
            exit 1
        fi

        # Try to find components directory
        if [ -d "$langflow_path/src/backend/base/langflow/components" ]; then
            target_dir="$langflow_path/src/backend/base/langflow/components"
        elif [ -d "$langflow_path/langflow/components" ]; then
            target_dir="$langflow_path/langflow/components"
        else
            echo -e "${YELLOW}⚠️  Could not auto-detect components directory${NC}"
            read -p "Enter components directory path: " target_dir
        fi

        echo ""
        echo "Target directory: $target_dir"
        echo ""

        # Copy components
        echo "📁 Copying walker_agents..."
        cp -r production-backend/langflow/custom_components/walker_agents "$target_dir/"

        echo "📁 Copying engarde_agents..."
        cp -r production-backend/langflow/custom_components/engarde_agents "$target_dir/"

        echo ""
        echo -e "${GREEN}✅ Components copied successfully!${NC}"
        echo ""
        echo "Next steps:"
        echo "1. cd $langflow_path"
        echo "2. git add ."
        echo "3. git commit -m 'Add Walker and EnGarde custom components'"
        echo "4. git push"
        echo "5. Wait for Railway to auto-deploy"
        echo ""
        ;;

    2)
        echo ""
        echo -e "${YELLOW}Option 2: Fork Official Langflow${NC}"
        echo ""

        # Check if langflow-engarde already exists
        if [ -d "langflow-engarde" ]; then
            echo -e "${YELLOW}⚠️  Directory langflow-engarde already exists${NC}"
            read -p "Remove and re-clone? (y/n): " confirm
            if [ "$confirm" = "y" ]; then
                rm -rf langflow-engarde
            else
                exit 0
            fi
        fi

        echo "📥 Cloning official Langflow..."
        git clone https://github.com/langflow-ai/langflow.git langflow-engarde

        echo "📁 Copying custom components..."
        cp -r production-backend/langflow/custom_components/walker_agents \
            langflow-engarde/src/backend/base/langflow/components/

        cp -r production-backend/langflow/custom_components/engarde_agents \
            langflow-engarde/src/backend/base/langflow/components/

        cd langflow-engarde

        echo ""
        echo -e "${GREEN}✅ Fork created with custom components!${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Create new GitHub repo: EnGardeHQ/langflow-engarde"
        echo "2. git remote set-url origin https://github.com/EnGardeHQ/langflow-engarde.git"
        echo "3. git add ."
        echo "4. git commit -m 'Fork Langflow with EnGarde custom components'"
        echo "5. git push -u origin main"
        echo "6. Update Railway service to use your fork"
        echo ""
        ;;

    3)
        echo ""
        echo -e "${YELLOW}Option 3: Create Deployment Package${NC}"
        echo ""

        # Create package
        package_name="langflow-custom-components-$(date +%Y%m%d).tar.gz"

        cd production-backend/langflow/custom_components
        tar -czf "../../../$package_name" walker_agents/ engarde_agents/
        cd ../../..

        echo -e "${GREEN}✅ Package created: $package_name${NC}"
        echo ""
        echo "Package contains:"
        tar -tzf "$package_name"
        echo ""
        echo "To deploy:"
        echo "1. Upload $package_name to your Langflow repository"
        echo "2. Extract: tar -xzf $package_name -C path/to/langflow/components/"
        echo "3. Commit and push"
        echo ""
        ;;

    4)
        echo ""
        echo "📖 Opening deployment guide..."
        echo ""

        if [ -f "DEPLOY_COMPONENTS_TO_LANGFLOW.md" ]; then
            cat DEPLOY_COMPONENTS_TO_LANGFLOW.md
        else
            echo -e "${RED}❌ Deployment guide not found${NC}"
        fi
        ;;

    *)
        echo -e "${RED}❌ Invalid option${NC}"
        exit 1
        ;;
esac

echo ""
echo "📚 Documentation:"
echo "  - Deployment Guide: DEPLOY_COMPONENTS_TO_LANGFLOW.md"
echo "  - Python Snippets: LANGFLOW_PYTHON_SNIPPETS_FOR_AGENTS.md"
echo "  - Quick Start: WALKER_AGENTS_QUICK_START.md"
echo ""
echo -e "${GREEN}✅ Done!${NC}"
