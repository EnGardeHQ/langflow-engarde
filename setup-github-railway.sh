#!/bin/bash
# Script to setup GitHub repository for Railway deployment under EnGardeHQ organization

set -e

echo "🚀 Setting up GitHub repository for Railway deployment"
echo ""

cd /Users/cope/EnGardeHQ/easyappointments-source

# Check if we're in the right directory
if [ ! -f "Dockerfile" ] || [ ! -f "railway.json" ]; then
    echo "❌ Error: Dockerfile or railway.json not found!"
    echo "   Make sure you're in the easyappointments-source directory"
    exit 1
fi

echo "📋 Current git status:"
git status --short
echo ""

echo "🔗 Current remote:"
git remote -v
echo ""

echo "⚠️  IMPORTANT: Before running this script, make sure you have:"
echo "   1. Created the repository on GitHub:"
echo "      https://github.com/organizations/EnGardeHQ/repositories/new"
echo "      Repository name: easyappointments-railway"
echo "   2. Have push access to EnGardeHQ organization"
echo ""

read -p "Have you created the GitHub repository? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please create the repository first, then run this script again."
    exit 1
fi

echo ""
echo "🔄 Updating git remote..."

# Remove old remote
git remote remove origin 2>/dev/null || echo "  (No existing origin remote)"

# Add new remote
git remote add origin https://github.com/EnGardeHQ/easyappointments-railway.git

echo "✅ Remote updated to: https://github.com/EnGardeHQ/easyappointments-railway.git"
echo ""

echo "📤 Pushing to GitHub..."
echo "   (You may be prompted for GitHub credentials)"
echo ""

git push -u origin main

echo ""
echo "✅ Successfully pushed to GitHub!"
echo ""
echo "Next steps:"
echo "1. Go to Railway Dashboard: https://railway.app/"
echo "2. Create New Project → Deploy from GitHub repo"
echo "3. Select: EnGardeHQ / easyappointments-railway"
echo "4. Railway will automatically build and deploy"
echo ""
echo "See GITHUB_RAILWAY_SETUP.md for detailed instructions"
