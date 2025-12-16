#!/bin/bash

##############################################################################
# En Garde Build Script with Automated Version Injection
#
# This script automates the build process with proper version tracking:
# - Extracts git commit SHA (or uses 'unknown' if not in git repo)
# - Generates ISO 8601 timestamp
# - Reads version from version files
# - Exports environment variables for Docker builds
# - Triggers docker-compose build with version information
#
# Usage:
#   ./build.sh [options]
#
# Options:
#   --version VERSION    Set custom version (default: read from version files)
#   --service SERVICE    Build specific service (backend, frontend, or all)
#   --no-cache          Build without cache
#   --push              Push images after build
#   --help              Show this help message
#
# Examples:
#   ./build.sh                          # Build all services with auto-detected version
#   ./build.sh --version 1.2.0          # Build with specific version
#   ./build.sh --service frontend       # Build only frontend
#   ./build.sh --no-cache --push        # Build all without cache and push
##############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Default values
CUSTOM_VERSION=""
BUILD_SERVICE="all"
NO_CACHE=""
PUSH_IMAGES=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --version)
      CUSTOM_VERSION="$2"
      shift 2
      ;;
    --service)
      BUILD_SERVICE="$2"
      shift 2
      ;;
    --no-cache)
      NO_CACHE="--no-cache"
      shift
      ;;
    --push)
      PUSH_IMAGES=true
      shift
      ;;
    --help)
      head -n 30 "$0" | tail -n 27
      exit 0
      ;;
    *)
      echo -e "${RED}Error: Unknown option $1${NC}"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  En Garde Build Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to read version from version.json file
read_version_file() {
  local file_path="$1"
  if [[ -f "$file_path" ]]; then
    # Extract version using grep and sed for better compatibility
    version=$(grep '"version"' "$file_path" | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    echo "$version"
  else
    echo ""
  fi
}

# Determine VERSION
if [[ -n "$CUSTOM_VERSION" ]]; then
  VERSION="$CUSTOM_VERSION"
  echo -e "${YELLOW}Using custom version: $VERSION${NC}"
else
  # Try to read from frontend version.json first
  VERSION=$(read_version_file "production-frontend/version.json")

  # Fallback to backend version.json
  if [[ -z "$VERSION" ]]; then
    VERSION=$(read_version_file "production-backend/version.json")
  fi

  # Ultimate fallback
  if [[ -z "$VERSION" ]]; then
    VERSION="1.0.0"
    echo -e "${YELLOW}Warning: Could not read version from files, using default: $VERSION${NC}"
  else
    echo -e "${GREEN}Version read from file: $VERSION${NC}"
  fi
fi

# Extract GIT_COMMIT
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  GIT_COMMIT=$(git rev-parse HEAD)
  GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  echo -e "${GREEN}Git commit: ${GIT_COMMIT:0:12}...${NC}"
  echo -e "${GREEN}Git branch: $GIT_BRANCH${NC}"
else
  GIT_COMMIT="unknown"
  GIT_BRANCH="unknown"
  echo -e "${YELLOW}Warning: Not a git repository, using 'unknown' for git commit${NC}"
fi

# Generate BUILD_DATE in ISO 8601 format
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo -e "${GREEN}Build date: $BUILD_DATE${NC}"

# Export environment variables for docker-compose
export VERSION="$VERSION"
export GIT_COMMIT="$GIT_COMMIT"
export BUILD_DATE="$BUILD_DATE"

echo ""
echo -e "${BLUE}Build Configuration:${NC}"
echo -e "  VERSION:     ${GREEN}$VERSION${NC}"
echo -e "  GIT_COMMIT:  ${GREEN}${GIT_COMMIT:0:12}${NC}"
echo -e "  BUILD_DATE:  ${GREEN}$BUILD_DATE${NC}"
echo -e "  SERVICE:     ${GREEN}$BUILD_SERVICE${NC}"
echo -e "  NO_CACHE:    ${GREEN}${NO_CACHE:-disabled}${NC}"
echo -e "  PUSH:        ${GREEN}$PUSH_IMAGES${NC}"
echo ""

# Function to build service
build_service() {
  local service="$1"
  echo -e "${BLUE}Building $service...${NC}"

  if [[ -n "$NO_CACHE" ]]; then
    docker-compose build $NO_CACHE "$service"
  else
    docker-compose build "$service"
  fi

  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}Successfully built $service${NC}"
  else
    echo -e "${RED}Failed to build $service${NC}"
    exit 1
  fi
}

# Build services
if [[ "$BUILD_SERVICE" == "all" ]]; then
  echo -e "${BLUE}Building all services...${NC}"
  build_service backend
  build_service frontend
elif [[ "$BUILD_SERVICE" == "backend" ]] || [[ "$BUILD_SERVICE" == "frontend" ]]; then
  build_service "$BUILD_SERVICE"
else
  echo -e "${RED}Error: Invalid service '$BUILD_SERVICE'. Use 'backend', 'frontend', or 'all'${NC}"
  exit 1
fi

# Push images if requested
if [[ "$PUSH_IMAGES" == true ]]; then
  echo ""
  echo -e "${BLUE}Pushing images...${NC}"

  if [[ "$BUILD_SERVICE" == "all" ]] || [[ "$BUILD_SERVICE" == "backend" ]]; then
    echo -e "${BLUE}Pushing backend image...${NC}"
    docker-compose push backend
  fi

  if [[ "$BUILD_SERVICE" == "all" ]] || [[ "$BUILD_SERVICE" == "frontend" ]]; then
    echo -e "${BLUE}Pushing frontend image...${NC}"
    docker-compose push frontend
  fi

  echo -e "${GREEN}Images pushed successfully${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Build completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Version: ${GREEN}$VERSION${NC}"
echo -e "Git Commit: ${GREEN}${GIT_COMMIT:0:12}${NC}"
echo -e "Build Date: ${GREEN}$BUILD_DATE${NC}"
echo ""
echo -e "${YELLOW}To start the services, run:${NC}"
echo -e "  ${BLUE}docker-compose up -d${NC}"
echo ""
echo -e "${YELLOW}To verify version information:${NC}"
echo -e "  Frontend: ${BLUE}curl http://localhost:3001/version.json${NC}"
echo -e "  Backend:  ${BLUE}curl http://localhost:8000/api/system/version${NC}"
echo ""
