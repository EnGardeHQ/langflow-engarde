#!/bin/bash
# EasyAppointments Railway Rebuild Commands
# Docker Hub Username: cope84

set -e

echo "🚀 Starting Railway Production Rebuild for EasyAppointments"
echo ""

# Navigate to source directory
cd /Users/cope/EnGardeHQ/easyappointments-source

echo "📁 Current directory: $(pwd)"
echo ""

# Step 1: Clean previous builds
echo "🧹 Step 1: Cleaning previous builds..."
docker rmi cope84/easyappointments:latest 2>/dev/null || echo "  (No existing image to remove)"
docker image prune -f
echo "✅ Cleanup complete"
echo ""

# Step 2: Rebuild with --no-cache
echo "🔨 Step 2: Building Docker image for Railway production..."
echo "  This may take 5-10 minutes..."
docker build --no-cache -t cope84/easyappointments:latest .
echo "✅ Build complete"
echo ""

# Step 3: Push to Docker Hub
echo "📤 Step 3: Pushing image to Docker Hub..."
echo "  This may take 5-15 minutes depending on internet speed..."
docker push cope84/easyappointments:latest
echo "✅ Push complete"
echo ""

echo "🎉 Rebuild complete!"
echo ""
echo "Next steps:"
echo "1. Go to Railway dashboard"
echo "2. Navigate to your EasyAppointments service"
echo "3. Click 'Deployments' → 'Redeploy'"
echo "   OR delete and recreate the service with image: cope84/easyappointments:latest"
echo ""
echo "Image name for Railway: cope84/easyappointments:latest"
