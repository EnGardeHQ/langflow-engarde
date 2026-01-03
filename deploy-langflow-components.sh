#!/bin/bash

# Deploy Walker Agent Custom Components to Langflow Server
# This script helps deploy custom components to Railway Langflow service

echo "🚀 Walker Agent Custom Components Deployment Script"
echo "=================================================="
echo ""

# Check if railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found. Install it first:"
    echo "   npm install -g @railway/cli"
    exit 1
fi

echo "📋 Deployment Options:"
echo ""
echo "Since Langflow is a separate Railway service, here are your options:"
echo ""
echo "Option 1: Use Langflow UI (Recommended - Easiest)"
echo "  - Copy/paste Python snippets into Python Function nodes"
echo "  - File: LANGFLOW_PYTHON_SNIPPETS_FOR_AGENTS.md"
echo "  - No deployment needed, works immediately"
echo ""
echo "Option 2: Create Langflow Fork with Custom Components"
echo "  - Fork Langflow repository"
echo "  - Add custom components to the fork"
echo "  - Deploy your fork to Railway"
echo "  - More complex but gives you custom drag-and-drop components"
echo ""
echo "Option 3: Use Railway Volumes (If Available)"
echo "  - Create a persistent volume in Railway"
echo "  - Mount it to Langflow service"
echo "  - Copy components to the volume"
echo "  - Set LANGFLOW_COMPONENTS_PATH to volume path"
echo ""

read -p "Which option would you like to proceed with? (1/2/3): " choice

case $choice in
    1)
        echo ""
        echo "✅ Option 1 Selected: Python Snippets (Recommended)"
        echo ""
        echo "📝 Instructions:"
        echo "1. Open: LANGFLOW_PYTHON_SNIPPETS_FOR_AGENTS.md"
        echo "2. Open Langflow: https://langflow.engarde.media"
        echo "3. Create a new flow"
        echo "4. Add a 'Python Function' node"
        echo "5. Copy/paste any agent code from the file"
        echo "6. Configure inputs and run!"
        echo ""
        echo "📄 Available agents in LANGFLOW_PYTHON_SNIPPETS_FOR_AGENTS.md:"
        echo "   - SEO Walker Agent"
        echo "   - Paid Ads Walker Agent"
        echo "   - Content Walker Agent"
        echo "   - Audience Intelligence Walker Agent"
        echo "   - Campaign Creation Agent"
        echo "   - Analytics Report Agent"
        echo "   - Content Approval Workflow Agent"
        echo "   - Scheduled Campaign Launcher"
        echo "   - Multi-Channel Notification Agent"
        echo "   - Performance Monitoring Agent"
        echo ""
        ;;
    2)
        echo ""
        echo "⚠️  Option 2 Selected: Fork Langflow"
        echo ""
        echo "📝 Steps to implement:"
        echo ""
        echo "1. Fork Langflow repository:"
        echo "   git clone https://github.com/langflow-ai/langflow.git langflow-engarde"
        echo "   cd langflow-engarde"
        echo ""
        echo "2. Copy custom components:"
        echo "   cp -r ../production-backend/langflow/custom_components/walker_agents \\"
        echo "     src/backend/base/langflow/components/"
        echo ""
        echo "3. Create GitHub repo and push:"
        echo "   git add ."
        echo "   git commit -m 'Add Walker Agent custom components'"
        echo "   git remote add origin YOUR_GITHUB_REPO_URL"
        echo "   git push -u origin main"
        echo ""
        echo "4. Update Railway Langflow service:"
        echo "   - Go to Railway dashboard"
        echo "   - Select langflow-server service"
        echo "   - Change source to your forked repo"
        echo "   - Redeploy"
        echo ""
        ;;
    3)
        echo ""
        echo "⚠️  Option 3 Selected: Railway Volumes"
        echo ""
        echo "📝 Steps to implement:"
        echo ""
        echo "1. Create volume in Railway:"
        echo "   - Open Railway dashboard"
        echo "   - Go to langflow-server service"
        echo "   - Click 'Variables' tab"
        echo "   - Add volume mount: /app/custom_components"
        echo ""
        echo "2. Copy components to volume (after mount):"
        echo "   railway run --service langflow-server -- mkdir -p /app/custom_components/walker_agents"
        echo ""
        echo "3. Upload the files (you'll need to use railway shell or API)"
        echo ""
        echo "4. Set environment variable:"
        echo "   railway variables --set 'LANGFLOW_COMPONENTS_PATH=/app/custom_components' --service langflow-server"
        echo ""
        echo "5. Restart Langflow:"
        echo "   railway restart --service langflow-server"
        echo ""
        echo "⚠️  Note: This option is complex and may require direct file access"
        echo ""
        ;;
    *)
        echo "❌ Invalid option selected"
        exit 1
        ;;
esac

echo ""
echo "📚 Additional Resources:"
echo "  - Custom Components README: production-backend/langflow/custom_components/README.md"
echo "  - Environment Variables Guide: LANGFLOW_ENVIRONMENT_VARIABLES_GUIDE.md"
echo "  - Architecture Rationale: WALKER_AGENTS_ARCHITECTURE_RATIONALE.md"
echo ""
echo "✅ Deployment guide complete!"
