#!/bin/bash

# Build and Push Custom Langflow to Docker Hub
# Run this script to build the EnGarde-branded Langflow and push to Docker Hub

set -e  # Exit on error

echo "🚀 EnGarde Langflow - Docker Hub Deployment"
echo "==========================================="
echo ""

# Configuration
DOCKER_USERNAME="${DOCKER_USERNAME:-langflowai}"
IMAGE_NAME="langflow-engarde"
VERSION="v1.0.0"

echo "📝 Configuration:"
echo "   Docker Hub User: $DOCKER_USERNAME"
echo "   Image Name: $IMAGE_NAME"
echo "   Version: $VERSION"
echo ""

# Step 1: Login to Docker Hub
echo "🔐 Step 1: Login to Docker Hub"
echo "Please enter your Docker Hub credentials:"
docker login
echo "✅ Docker login successful"
echo ""

# Step 2: Build Docker image
echo "🏗️  Step 2: Building Docker image (this may take 10-30 minutes)..."
echo "Building: $DOCKER_USERNAME/$IMAGE_NAME:latest"
docker build \
  --tag $DOCKER_USERNAME/$IMAGE_NAME:latest \
  --tag $DOCKER_USERNAME/$IMAGE_NAME:$VERSION \
  --file docker/build_and_push.Dockerfile \
  .

echo "✅ Docker image built successfully"
echo ""

# Step 3: Push to Docker Hub
echo "📤 Step 3: Pushing to Docker Hub..."
echo "Pushing: $DOCKER_USERNAME/$IMAGE_NAME:latest"
docker push $DOCKER_USERNAME/$IMAGE_NAME:latest

echo "Pushing: $DOCKER_USERNAME/$IMAGE_NAME:$VERSION"
docker push $DOCKER_USERNAME/$IMAGE_NAME:$VERSION

echo "✅ Images pushed to Docker Hub successfully"
echo ""

# Step 4: Display next steps
echo "🎉 Success! Your custom Langflow image is now on Docker Hub"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Configure Railway to use your Docker image:"
echo "   railway variables --service langflow-server --set RAILWAY_DOCKER_IMAGE=$DOCKER_USERNAME/$IMAGE_NAME:latest"
echo ""
echo "2. Deploy to Railway:"
echo "   railway up"
echo ""
echo "3. Or use Railway Dashboard:"
echo "   - Go to langflow-server service"
echo "   - Settings → Source → Docker Image"
echo "   - Enter: $DOCKER_USERNAME/$IMAGE_NAME:latest"
echo ""
echo "4. Verify deployment at: https://langflow.engarde.media"
echo ""
echo "5. Deploy all 10 agents (see FINAL_ANSWERS_AND_INSTRUCTIONS.md)"
echo ""
echo "Docker Hub URL: https://hub.docker.com/r/$DOCKER_USERNAME/$IMAGE_NAME"
echo ""
echo "✅ All done! Follow the next steps above to deploy to Railway."
