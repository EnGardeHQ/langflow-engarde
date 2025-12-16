# En Garde Version Management System

## Overview

The En Garde application uses a comprehensive versioning system that tracks:
- **Frontend version** - Next.js application version
- **Backend version** - FastAPI application version
- **Git commit SHA** - Exact code snapshot for debugging
- **Build timestamp** - When the Docker image was built
- **Environment** - Deployment environment (production, staging, development)

This versioning system follows **Semantic Versioning (SemVer)** principles: `MAJOR.MINOR.PATCH`

## Version Files

### Frontend Version
**Location:** `/Users/cope/EnGardeHQ/production-frontend/version.json`

```json
{
  "version": "1.0.0",
  "build_date": "unknown",
  "git_commit": "unknown",
  "environment": "production"
}
```

### Backend Version
**Location:** `/Users/cope/EnGardeHQ/production-backend/version.json`

```json
{
  "version": "1.0.0",
  "build_date": "unknown",
  "git_commit": "unknown",
  "environment": "production"
}
```

## Semantic Versioning Convention

### Version Format: `MAJOR.MINOR.PATCH`

- **MAJOR** (1.x.x): Breaking changes, incompatible API changes
- **MINOR** (x.1.x): New features, backwards-compatible functionality
- **PATCH** (x.x.1): Bug fixes, backwards-compatible fixes

### Examples:

- `1.0.0` → `1.0.1` - Bug fix (increment PATCH)
- `1.0.1` → `1.1.0` - New feature (increment MINOR, reset PATCH)
- `1.1.0` → `2.0.0` - Breaking change (increment MAJOR, reset MINOR and PATCH)

## How to Update Versions

### Method 1: Manual Update (Recommended for Version Bumps)

1. **Update Frontend Version:**
   ```bash
   # Edit production-frontend/version.json
   # Change "version": "1.0.0" to "version": "1.1.0"
   ```

2. **Update Backend Version:**
   ```bash
   # Edit production-backend/version.json
   # Change "version": "1.0.0" to "version": "1.1.0"
   ```

3. **Build with new version:**
   ```bash
   ./build.sh
   ```

### Method 2: Quick Version Update Script

Create a helper script to update versions:

```bash
#!/bin/bash
# update-version.sh

NEW_VERSION=$1

if [[ -z "$NEW_VERSION" ]]; then
  echo "Usage: ./update-version.sh <version>"
  echo "Example: ./update-version.sh 1.2.0"
  exit 1
fi

# Update frontend version
sed -i.bak "s/\"version\": \".*\"/\"version\": \"$NEW_VERSION\"/" production-frontend/version.json

# Update backend version
sed -i.bak "s/\"version\": \".*\"/\"version\": \"$NEW_VERSION\"/" production-backend/version.json

echo "Version updated to $NEW_VERSION"
echo "Frontend: production-frontend/version.json"
echo "Backend: production-backend/version.json"
```

Usage:
```bash
chmod +x update-version.sh
./update-version.sh 1.2.0
```

## Build System Integration

### Automated Build with Version Injection

The `build.sh` script automatically injects version information during Docker builds:

```bash
# Basic build (reads version from version.json files)
./build.sh

# Build with custom version
./build.sh --version 1.2.0

# Build specific service
./build.sh --service frontend
./build.sh --service backend

# Build without cache
./build.sh --no-cache

# Build and push to registry
./build.sh --push
```

### Build Script Features

The build script automatically:
1. ✅ Reads version from `version.json` files
2. ✅ Extracts current git commit SHA (or uses 'unknown' if not in git repo)
3. ✅ Generates ISO 8601 timestamp
4. ✅ Exports environment variables for Docker
5. ✅ Builds Docker images with version baked in
6. ✅ Creates `public/version.json` in frontend during build
7. ✅ Creates `/app/version.json` in backend during build

### Docker Compose Integration

The `docker-compose.yml` file is configured to accept version build arguments:

```yaml
services:
  backend:
    build:
      args:
        VERSION: ${VERSION:-1.0.0}
        GIT_COMMIT: ${GIT_COMMIT:-unknown}
        BUILD_DATE: ${BUILD_DATE:-unknown}

  frontend:
    build:
      args:
        VERSION: ${VERSION:-1.0.0}
        GIT_COMMIT: ${GIT_COMMIT:-unknown}
        BUILD_DATE: ${BUILD_DATE:-unknown}
```

## Accessing Version Information

### Frontend - User Interface

The version is displayed in the application UI using the `VersionDisplay` component.

**Import and use:**

```tsx
import { FooterVersionDisplay, SidebarVersionDisplay, CornerVersionDisplay } from '@/components/layout/version-display';

// In your layout component
export default function Layout({ children }) {
  return (
    <div>
      {children}
      <FooterVersionDisplay />
    </div>
  );
}
```

**Available Components:**

1. **FooterVersionDisplay** - Full version display for footer areas
2. **SidebarVersionDisplay** - Compact version for sidebars
3. **CornerVersionDisplay** - Floating badge for dev/staging environments
4. **CompactVersionDisplay** - Minimal version badge

### Frontend - API Access

```bash
# Get frontend version
curl http://localhost:3001/version.json
```

**Example Response:**
```json
{
  "version": "1.0.0",
  "build_date": "2025-10-10T17:00:00Z",
  "git_commit": "abc123def456789",
  "environment": "production"
}
```

### Backend - API Endpoint

```bash
# Get comprehensive version info
curl http://localhost:8000/api/system/version
```

**Example Response:**
```json
{
  "backend_version": "1.0.0",
  "frontend_version": "1.0.0",
  "build_info": {
    "backend": {
      "version": "1.0.0",
      "build_date": "2025-10-10T17:00:00Z",
      "git_commit": "abc123def456789",
      "environment": "production"
    },
    "frontend": {
      "version": "1.0.0",
      "build_date": "2025-10-10T17:00:00Z",
      "git_commit": "abc123def456789",
      "environment": "production"
    }
  },
  "git_commit": "abc123def456789",
  "build_date": "2025-10-10T17:00:00Z",
  "environment": "production"
}
```

```bash
# Get system status
curl http://localhost:8000/api/system/status
```

**Example Response:**
```json
{
  "status": "operational",
  "service": "engarde-backend",
  "version": "1.0.0",
  "timestamp": 1728579600.123
}
```

## Version Display Examples

### In Application UI

The version appears in the footer or sidebar:

```
En Garde v1.0.0 (Build: abc1234)
```

Clicking "Show details" reveals:

```
Frontend Version: 1.0.0
Backend Version: 1.0.0
Build Date: 2025-10-10
Environment: production
Git Commit: abc123def456789
```

### In Docker Logs

During build:
```
Step 15/20 : RUN echo "{\"version\":\"1.0.0\",\"build_date\":\"2025-10-10T17:00:00Z\",\"git_commit\":\"abc123def456789\",\"environment\":\"production\"}" > /app/version.json
{"version":"1.0.0","build_date":"2025-10-10T17:00:00Z","git_commit":"abc123def456789","environment":"production"}
Version file generated successfully
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build with version
        run: |
          export VERSION=$(cat production-frontend/version.json | grep version | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
          export GIT_COMMIT=${{ github.sha }}
          export BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
          ./build.sh --no-cache

      - name: Verify version
        run: |
          docker run --rm engardehq-backend:latest cat /app/version.json
          docker-compose up -d
          sleep 5
          curl http://localhost:8000/api/system/version
```

### GitLab CI Example

```yaml
build:
  stage: build
  script:
    - export VERSION=$(cat production-frontend/version.json | grep version | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    - export GIT_COMMIT=$CI_COMMIT_SHA
    - export BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    - ./build.sh --no-cache --push
  tags:
    - docker
```

## Troubleshooting

### Version Not Displaying

**Problem:** Version shows as "unknown" or "1.0.0"

**Solutions:**
1. Check if `version.json` files exist:
   ```bash
   cat production-frontend/version.json
   cat production-backend/version.json
   ```

2. Rebuild with build script:
   ```bash
   ./build.sh --no-cache
   ```

3. Verify version in container:
   ```bash
   docker exec engarde_frontend cat /app/public/version.json
   docker exec engarde_backend cat /app/version.json
   ```

### Git Commit Shows "unknown"

**Problem:** Git commit is "unknown" in builds

**Cause:** Not building from git repository or git not installed

**Solution:**
- Ensure you're building from within the git repository
- For CI/CD, ensure git checkout includes full history:
  ```yaml
  - uses: actions/checkout@v3
    with:
      fetch-depth: 0  # Full history
  ```

### Build Date Format Issues

**Problem:** Build date is "unknown" or malformed

**Solution:**
- Ensure `date` command is available in build environment
- Use ISO 8601 format: `date -u +"%Y-%m-%dT%H:%M:%SZ"`
- On macOS, ensure you have GNU date or use built-in date

## Best Practices

### 1. Version Before Major Releases
Always update version numbers before deploying to production:
```bash
# Update version files to 1.1.0
./update-version.sh 1.1.0

# Build with new version
./build.sh

# Verify
curl http://localhost:8000/api/system/version
```

### 2. Tag Git Releases
After version bump, create git tag:
```bash
git tag -a v1.1.0 -m "Release version 1.1.0"
git push origin v1.1.0
```

### 3. Document Changes
Maintain a CHANGELOG.md:
```markdown
## [1.1.0] - 2025-10-10
### Added
- New dashboard analytics feature
- User preference management

### Fixed
- Authentication timeout issue
- Dashboard loading performance
```

### 4. Environment-Specific Versions
Use different version patterns for environments:
- **Production:** `1.0.0`
- **Staging:** `1.0.0-staging`
- **Development:** `1.0.0-dev`

### 5. Monitor Version Drift
Regularly check that frontend and backend versions match:
```bash
curl http://localhost:8000/api/system/version | jq '.backend_version, .frontend_version'
```

## Quick Reference

### Common Commands

```bash
# Build all services with current version
./build.sh

# Build with specific version
./build.sh --version 1.2.0

# Build without cache
./build.sh --no-cache

# Build and push to registry
./build.sh --push

# Check frontend version
curl http://localhost:3001/version.json

# Check backend version
curl http://localhost:8000/api/system/version

# Check version in running container
docker exec engarde_backend cat /app/version.json
```

### Version Update Workflow

1. Update version in both files:
   - `production-frontend/version.json`
   - `production-backend/version.json`

2. Build new images:
   ```bash
   ./build.sh --no-cache
   ```

3. Start services:
   ```bash
   docker-compose up -d
   ```

4. Verify:
   ```bash
   curl http://localhost:8000/api/system/version
   ```

5. Tag release:
   ```bash
   git tag -a v1.2.0 -m "Release 1.2.0"
   git push origin v1.2.0
   ```

## Files Modified/Created

### Created Files:
1. `/Users/cope/EnGardeHQ/production-frontend/version.json`
2. `/Users/cope/EnGardeHQ/production-backend/version.json`
3. `/Users/cope/EnGardeHQ/production-backend/app/routers/system.py`
4. `/Users/cope/EnGardeHQ/production-frontend/components/layout/version-display.tsx`
5. `/Users/cope/EnGardeHQ/build.sh`
6. `/Users/cope/EnGardeHQ/VERSION_MANAGEMENT.md` (this file)

### Modified Files:
1. `/Users/cope/EnGardeHQ/production-frontend/Dockerfile`
   - Added VERSION, GIT_COMMIT, BUILD_DATE build args (lines 114-116)
   - Added version.json generation (lines 110-113)

2. `/Users/cope/EnGardeHQ/production-backend/Dockerfile`
   - Added VERSION, GIT_COMMIT, BUILD_DATE build args (lines 85-88)
   - Added version.json generation (lines 100-103)

3. `/Users/cope/EnGardeHQ/docker-compose.yml`
   - Added build args to backend service (lines 56-59)
   - Added build args to frontend service (lines 138-140)

4. `/Users/cope/EnGardeHQ/production-backend/app/main.py`
   - Added 'system' router to system_routers list (line 137)

## Support

For questions or issues with the versioning system:
1. Check this documentation
2. Verify build script is executable: `ls -la build.sh`
3. Check Docker build logs for version injection
4. Test API endpoints manually with curl

---

**Last Updated:** 2025-10-10
**Document Version:** 1.0.0
