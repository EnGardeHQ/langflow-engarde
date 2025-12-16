#!/bin/bash

##############################################################################
# En Garde Version Update Script
#
# Quick script to update version numbers across the application
#
# Usage:
#   ./update-version.sh <new-version>
#
# Example:
#   ./update-version.sh 1.2.0
##############################################################################

set -e

NEW_VERSION=$1

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ -z "$NEW_VERSION" ]]; then
  echo -e "${RED}Error: Version number required${NC}"
  echo ""
  echo "Usage: ./update-version.sh <version>"
  echo "Example: ./update-version.sh 1.2.0"
  echo ""
  echo "Current versions:"
  if [[ -f "production-frontend/version.json" ]]; then
    FRONTEND_VERSION=$(grep '"version"' production-frontend/version.json | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    echo "  Frontend: $FRONTEND_VERSION"
  fi
  if [[ -f "production-backend/version.json" ]]; then
    BACKEND_VERSION=$(grep '"version"' production-backend/version.json | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    echo "  Backend: $BACKEND_VERSION"
  fi
  exit 1
fi

# Validate version format (basic semver check)
if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
  echo -e "${RED}Error: Invalid version format${NC}"
  echo "Version must follow semantic versioning: MAJOR.MINOR.PATCH"
  echo "Examples: 1.0.0, 1.2.3, 2.0.0-beta, 1.0.0-staging"
  exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Updating En Garde Version${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "New version: ${GREEN}$NEW_VERSION${NC}"
echo ""

# Update frontend version.json
if [[ -f "production-frontend/version.json" ]]; then
  # Create backup
  cp production-frontend/version.json production-frontend/version.json.bak

  # Update version using sed (compatible with macOS and Linux)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/\"version\": \"[^\"]*\"/\"version\": \"$NEW_VERSION\"/" production-frontend/version.json
  else
    # Linux
    sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$NEW_VERSION\"/" production-frontend/version.json
  fi

  echo -e "${GREEN}✓ Updated production-frontend/version.json${NC}"
else
  echo -e "${YELLOW}⚠ production-frontend/version.json not found${NC}"
fi

# Update backend version.json
if [[ -f "production-backend/version.json" ]]; then
  # Create backup
  cp production-backend/version.json production-backend/version.json.bak

  # Update version
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/\"version\": \"[^\"]*\"/\"version\": \"$NEW_VERSION\"/" production-backend/version.json
  else
    # Linux
    sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$NEW_VERSION\"/" production-backend/version.json
  fi

  echo -e "${GREEN}✓ Updated production-backend/version.json${NC}"
else
  echo -e "${YELLOW}⚠ production-backend/version.json not found${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Version Updated Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Updated files:"
if [[ -f "production-frontend/version.json" ]]; then
  echo -e "  ${BLUE}production-frontend/version.json${NC}"
  grep '"version"' production-frontend/version.json
fi
if [[ -f "production-backend/version.json" ]]; then
  echo -e "  ${BLUE}production-backend/version.json${NC}"
  grep '"version"' production-backend/version.json
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Review the changes"
echo -e "  2. Build new Docker images:"
echo -e "     ${BLUE}./build.sh${NC}"
echo -e "  3. Commit the version bump:"
echo -e "     ${BLUE}git add production-*/version.json${NC}"
echo -e "     ${BLUE}git commit -m 'Bump version to $NEW_VERSION'${NC}"
echo -e "  4. Tag the release:"
echo -e "     ${BLUE}git tag -a v$NEW_VERSION -m 'Release $NEW_VERSION'${NC}"
echo -e "     ${BLUE}git push origin v$NEW_VERSION${NC}"
echo ""
echo -e "${GREEN}Backup files created with .bak extension${NC}"
echo ""
