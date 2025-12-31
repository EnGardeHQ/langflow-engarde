# EnGarde Branded Langflow Docker Build

## Overview

This document describes the custom EnGarde-branded Langflow Docker image build process.

## What's Different from Standard Langflow

### ✅ EnGarde Branding Includes:

1. **Frontend Branding**
   - ✅ EnGarde logo in header (`src/frontend/src/assets/EnGardeLogo.png`)
   - ✅ Custom header component with EnGarde branding
   - ✅ Footer with "From EnGarde with Love ❤️"
   - ✅ Page title: "EnGarde - AI Campaign Builder"
   - ✅ Custom manifest with EnGarde name and description

2. **Removed Branding**
   - ❌ Langflow branding removed from UI
   - ❌ DataStax branding disabled via feature flags

3. **Container Labels**
   - Author: EnGarde Team
   - URL: https://engarde.media
   - Description: "Made with ❤️ by EnGarde"

## Build Files

### Primary Dockerfile
- **Location**: `/Users/cope/EnGardeHQ/langflow-custom/Dockerfile.engarde`
- **Base Image**: `ghcr.io/astral-sh/uv:python3.12-bookworm-slim`
- **Build Type**: Multi-stage build (builder + runtime)

### Build Process

```bash
cd /Users/cope/EnGardeHQ/langflow-custom
docker build -f Dockerfile.engarde -t cope84/engarde-langflow-branded:latest .
```

### Build Stages

1. **Builder Stage**
   - Installs system dependencies (build-essential, git, npm, gcc)
   - Installs Python dependencies with uv
   - Builds frontend from source with EnGarde customizations
   - Applies branding updates to HTML and manifest

2. **Runtime Stage**
   - Minimal Python 3.12 slim image
   - Includes Node.js for runtime
   - Copies built application from builder
   - Sets EnGarde environment variables

## Docker Images

### Tagged Versions
- `cope84/engarde-langflow-branded:latest` - Latest stable build
- `cope84/engarde-langflow-branded:1.0.0` - Version 1.0.0

## Environment Variables

```bash
LANGFLOW_HOST=0.0.0.0
LANGFLOW_PORT=7860
LANGFLOW_COMPONENTS_PATH=/app/custom_components
LANGFLOW_AUTO_LOGIN=true
```

## Frontend Customizations

### Files Modified During Build

1. **index.html**
   ```html
   <title>EnGarde - AI Campaign Builder</title>
   ```

2. **manifest.json**
   ```json
   {
     "name": "EnGarde",
     "short_name": "EnGarde",
     "description": "EnGarde - AI-powered social media campaign builder..."
   }
   ```

3. **App.tsx** (already customized in source)
   ```tsx
   <EnGardeFooter />
   ```

4. **Header Component** (already customized in source)
   ```tsx
   <img src={EnGardeLogo} alt="EnGarde" className="h-8 w-8" />
   ```

## Feature Flags

The following feature flags disable DataStax/Langflow branding:

```typescript
// src/frontend/src/customization/feature-flags.ts
ENABLE_DATASTAX_LANGFLOW = false
```

## Usage

### Run Locally
```bash
docker run -p 7860:7860 cope84/engarde-langflow-branded:latest
```

### Use in Docker Compose
```yaml
services:
  langflow:
    image: cope84/engarde-langflow-branded:latest
    ports:
      - "7860:7860"
    environment:
      - DATABASE_URL=postgresql://...
```

### Deploy to Railway
```bash
# Set the Docker image
railway variables --set RAILWAY_DOCKER_IMAGE=cope84/engarde-langflow-branded:latest

# Deploy
railway up
```

## Build Time

Expected build time: **10-30 minutes**
- Frontend build: ~15-20 minutes
- Python dependencies: ~5-10 minutes
- Docker layer operations: ~2-5 minutes

## Image Size

- **Final image size**: ~1.5-2GB (compressed)
- **Uncompressed**: ~2.5-3GB

## Comparison: Standard vs Branded

| Feature | Standard Langflow | EnGarde Branded |
|---------|------------------|-----------------|
| Logo | Langflow logo | EnGarde logo ✅ |
| Page Title | "Langflow" | "EnGarde - AI Campaign Builder" ✅ |
| Footer | None/Langflow | "From EnGarde with Love ❤️" ✅ |
| Manifest | Langflow | EnGarde ✅ |
| DataStax Refs | Enabled | Disabled ✅ |
| Build From | Pre-built image | Source code ✅ |

## Maintenance

### Updating the Image

1. Make changes to frontend in `src/frontend/`
2. Rebuild the Docker image
3. Push to Docker Hub
4. Update Railway deployment

### Version Updates

When updating to a new Langflow version:
1. Update base dependencies in `pyproject.toml`
2. Test branding customizations still apply
3. Rebuild and test locally
4. Push new versioned tag

## Troubleshooting

### Build Fails
- Check Docker has enough disk space (need ~20GB free)
- Verify npm dependencies can be installed
- Check network connectivity for package downloads

### Branding Not Showing
- Verify frontend build completed successfully
- Check browser cache (hard refresh)
- Verify manifest.json and index.html were updated

### Runtime Errors
- Check environment variables are set
- Verify database connection string
- Review container logs

## Links

- **Source**: `/Users/cope/EnGardeHQ/langflow-custom/`
- **Dockerfile**: `Dockerfile.engarde`
- **Docker Hub**: `https://hub.docker.com/r/cope84/engarde-langflow-branded`
- **Build Script**: `build-and-push-dockerhub.sh`

---

**Made with ❤️ by EnGarde**
