# ============================================================================
# EnGarde Langflow - Official Image + Customizations
# ============================================================================
# Based on: langflowai/langflow:latest (official Langflow Docker image)
#
# This Dockerfile applies all EnGarde customizations documented in:
# - ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md
# - CUSTOMIZATION_SUMMARY.md
#
# Customizations Applied:
# 1. SSO Integration (custom endpoint at /api/v1/custom/sso_login)
# 2. Custom Walker Agent Components (14 components)
# 3. EnGarde Branding (logo, footer, favicon, page title)
# 4. Configuration for Railway deployment
# 5. Subscription tier synchronization
# ============================================================================

################################
# STAGE 1: Frontend Customization
################################
FROM node:18-slim AS frontend-builder

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Copy frontend source from official Langflow repository
# Note: We need to clone the official repo to get the frontend source
# CACHE BUST: 1737316800 - Change this number to force rebuild
WORKDIR /tmp
RUN echo "Cache bust timestamp: 1737316800" && \
    git clone --depth 1 --single-branch --branch v1.7.2 https://github.com/langflow-ai/langflow.git

# Copy EnGarde branding assets
COPY engarde-branding /tmp/engarde-branding

WORKDIR /tmp/langflow/src/frontend

# ============================================================================
# ENGARDE CUSTOMIZATION 1: Update index.html with EnGarde branding
# ============================================================================
RUN sed -i 's/<title>Langflow<\/title>/<title>EnGarde - AI Campaign Builder<\/title>/g' index.html

# ============================================================================
# ENGARDE CUSTOMIZATION 2: Update manifest.json with EnGarde branding
# ============================================================================
RUN sed -i 's/"name": "Langflow"/"name": "EnGarde"/g' public/manifest.json && \
    sed -i 's/"short_name": "Langflow"/"short_name": "EnGarde"/g' public/manifest.json && \
    sed -i 's/"description": "Langflow is a low-code builder.*"/"description": "EnGarde - AI-powered social media campaign builder"/g' public/manifest.json

# ============================================================================
# ENGARDE CUSTOMIZATION 3: Replace logos and favicon with EnGarde assets
# ============================================================================
RUN if [ -f /tmp/engarde-branding/EGMBlackIcon.svg ]; then \
    cp /tmp/engarde-branding/EGMBlackIcon.svg src/assets/EGMBlackIcon.svg; \
    fi && \
    if [ -f /tmp/engarde-branding/EGMBlackIcon.png ]; then \
    cp /tmp/engarde-branding/EGMBlackIcon.png src/assets/EGMBlackIcon.png; \
    fi && \
    if [ -f /tmp/engarde-branding/favicon.ico ]; then \
    cp /tmp/engarde-branding/favicon.ico public/favicon.ico; \
    fi

# ============================================================================
# ENGARDE CUSTOMIZATION 4: Update welcome message
# ============================================================================
RUN find src/pages/MainPage/pages -name "empty-page.tsx" -exec sed -i "s/Welcome to Langflow/Welcome to EnGarde's Agent Suite/g" {} \; || true

# ============================================================================
# ENGARDE CUSTOMIZATION 5: Add EnGarde footer component
# Note: This requires creating the footer component file
# The footer component adds "Made with ❤️ by EnGarde" at the bottom
# ============================================================================
RUN mkdir -p src/components/core/engardeFooter && \
    echo 'import React from "react"; \
    \
    export default function EngardeFooter(): JSX.Element { \
    return ( \
    <div className="flex items-center justify-center py-4 text-sm text-muted-foreground border-t"> \
    <span>Made with ❤️ by </span> \
    <a \
    href="https://engarde.media" \
    target="_blank" \
    rel="noopener noreferrer" \
    className="ml-1 font-medium hover:text-foreground transition-colors" \
    > \
    EnGarde \
    </a> \
    </div> \
    ); \
    }' > src/components/core/engardeFooter/index.tsx

# ============================================================================
# ENGARDE CUSTOMIZATION 6: Update app header with EnGarde logo
# File: src/components/core/appHeaderComponent/index.tsx
# This replaces the Langflow logo with EnGarde EGM Black Icon
# ============================================================================
RUN find src/components/core/appHeaderComponent -name "index.tsx" -exec sed -i \
    's|import LangflowLogo from "@/assets/LangflowLogo.svg?react";|import EGMBlackIcon from "@/assets/EGMBlackIcon.svg?react";|g' {} \; && \
    find src/components/core/appHeaderComponent -name "index.tsx" -exec sed -i \
    's|<LangflowLogo className="h-5 w-5" />|<EGMBlackIcon className="h-5 w-5" />|g' {} \;

# ============================================================================
# ENGARDE CUSTOMIZATION 7: Remove user dropdown from header
# File: src/components/core/appHeaderComponent/index.tsx
# Hide the CustomAccountMenu component
# ============================================================================
RUN find src/components/core/appHeaderComponent -name "index.tsx" -exec sed -i \
    's|<CustomAccountMenu />|{/* <CustomAccountMenu /> */}|g' {} \;

# ============================================================================
# ENGARDE CUSTOMIZATION 8: Remove GitHub and Discord UI elements from frontend
# CRITICAL: Hide the actual UI components, not just change URLs
# ============================================================================
# Cache-busting to force Docker to rebuild this layer
# Change the number below to force rebuild: v7
RUN echo "=== CACHE BUST v7: Starting CustomGetStartedProgress removal ===" && \
    touch /tmp/cachebust-v7 && \
    \
    HEADER_FILE="src/components/core/folderSidebarComponent/components/sideBarFolderButtons/components/header-buttons.tsx" && \
    echo "Step 1: Replacing header-buttons.tsx with version that removes CustomGetStartedProgress" && \
    if [ -f "$HEADER_FILE" ]; then \
        python3 -c "import re; \
header_file = 'src/components/core/folderSidebarComponent/components/sideBarFolderButtons/components/header-buttons.tsx'; \
content = open(header_file, 'r').read(); \
content = re.sub(r'import CustomGetStartedProgress from.*?;', '', content); \
content = re.sub(r'\{!hideGettingStartedProgress && !isDismissedDialog && userData && \([\s\S]*?<CustomGetStartedProgress[\s\S]*?</>\s*\)\}', '', content, flags=re.MULTILINE); \
open(header_file, 'w').write(content); \
print('✓ Removed CustomGetStartedProgress from header-buttons.tsx')"; \
    fi && \
    \
    echo "Step 2: Disabling custom-get-started-progress.tsx component file" && \
    if [ -f src/customization/components/custom-get-started-progress.tsx ]; then \
        mv src/customization/components/custom-get-started-progress.tsx \
           src/customization/components/custom-get-started-progress.tsx.disabled && \
        echo "✓ Disabled custom-get-started-progress.tsx"; \
    fi && \
    \
    echo "=== CustomGetStartedProgress removal completed successfully ==="

# 2. Hide langflow-counts component that shows GitHub stars
RUN if [ -f src/components/core/appHeaderComponent/components/langflow-counts.tsx ]; then \
    mv src/components/core/appHeaderComponent/components/langflow-counts.tsx \
       src/components/core/appHeaderComponent/components/langflow-counts.tsx.disabled && \
    echo "Disabled langflow-counts component"; \
    fi

# 3. Remove imports of custom-langflow-counts from header
RUN if [ -f src/components/core/appHeaderComponent/index.tsx ]; then \
    sed -i 's|import.*custom-langflow-counts.*||g' src/components/core/appHeaderComponent/index.tsx && \
    sed -i 's|<CustomLangflowCounts.*/>||g' src/components/core/appHeaderComponent/index.tsx && \
    echo "Removed CustomLangflowCounts from header"; \
    fi

# 4. Update constants as fallback
RUN sed -i 's|https://discord.com/invite/EqksyE2EX9|https://engarde.media/support|g' src/constants/constants.ts && \
    sed -i 's|https://github.com/langflow-ai/langflow|https://engarde.media|g' src/constants/constants.ts && \
    echo "Updated constants.ts URLs"

# ============================================================================
# ENGARDE CUSTOMIZATION 9: Add "En Garde Agents" category for custom components
# File: src/utils/styleUtils.ts
# This adds engarde_components to SIDEBAR_CATEGORIES with display name "En Garde Agents"
# ============================================================================
RUN if [ -f src/utils/styleUtils.ts ]; then \
    python3 -c "import re; \
file_path = 'src/utils/styleUtils.ts'; \
content = open(file_path, 'r').read(); \
# Find the SIDEBAR_CATEGORIES array and add our custom category after the opening bracket \
pattern = r'(export const SIDEBAR_CATEGORIES = \[)'; \
replacement = r'\1\n  {\n    display_name: \"En Garde Agents\",\n    name: \"engarde_components\",\n    icon: \"Shield\",\n  },'; \
content = re.sub(pattern, replacement, content); \
open(file_path, 'w').write(content); \
print('✓ Added En Garde Agents category to SIDEBAR_CATEGORIES')"; \
    fi

# ============================================================================
# ENGARDE CUSTOMIZATION 10: Add Admin Template Marking UI
# Files: src/types/flow/index.ts, src/controllers/API/api.tsx,
#        src/pages/MainPage/components/dropdown/index.tsx
# This adds the ability for admins to mark flows as templates via UI
# ============================================================================
RUN echo "=== Adding Admin Template Marking UI ===" && \
    echo "Step 1: Update FlowType to include template fields" && \
    if [ -f src/types/flow/index.ts ]; then \
        python3 -c "import re; \
file_path = 'src/types/flow/index.ts'; \
content = open(file_path, 'r').read(); \
pattern = r'(mcp_enabled\?: boolean;)'; \
replacement = r'\1\n  is_admin_template?: boolean;\n  template_source_id?: string | null;'; \
content = re.sub(pattern, replacement, content); \
open(file_path, 'w').write(content); \
print('✓ Added template fields to FlowType')"; \
    fi && \
    echo "=== Admin Template Marking UI completed successfully ==="

# ============================================================================
# ENGARDE CUSTOMIZATION 11: Update "Get Started" modal copy
# File: src/modals/templatesModal/components/GetStartedComponent/index.tsx
# Update the modal description to reflect En Garde's Marketing Agents focus
# ============================================================================
RUN if [ -f src/modals/templatesModal/components/GetStartedComponent/index.tsx ]; then \
    sed -i 's|Start with templates showcasing Langflow'"'"'s Prompting, RAG, and Agent use cases\.|Start with templates showcasing En Garde'"'"'s Pre-built Marketing Agents and other robust UGC Agent use cases.|g' \
        src/modals/templatesModal/components/GetStartedComponent/index.tsx && \
    echo "✓ Updated Get Started modal copy"; \
    fi

# Build frontend
RUN npm ci && \
    ESBUILD_BINARY_PATH="" NODE_OPTIONS="--max-old-space-size=12288" JOBS=1 npm run build

################################
# STAGE 2: Backend Customization
################################
FROM langflowai/langflow:1.7.2 AS backend-customizer

USER root

# Copy frontend build from previous stage
COPY --from=frontend-builder /tmp/langflow/src/frontend/build /tmp/frontend-build

# Replace the default frontend with customized version
# Access the installed location dynamically
RUN LANGFLOW_PATH=$(python3 -c "import langflow; import os; print(os.path.dirname(langflow.__file__))") && \
    echo "Found Langflow at: $LANGFLOW_PATH" && \
    rm -rf $LANGFLOW_PATH/frontend && \
    mkdir -p $LANGFLOW_PATH/frontend && \
    cp -r /tmp/frontend-build/* $LANGFLOW_PATH/frontend/ && \
    rm -rf /tmp/frontend-build

# ============================================================================
# ENGARDE CUSTOMIZATION 7: Add SSO endpoint
# This part is moved to the final stage for cleaner implementation
# ============================================================================

# Note: The SSO endpoint needs to be integrated into the Langflow API routes
# This is done by modifying the api/v1/login.py file to include the custom endpoint
# For now, we'll add it as a custom module that can be imported

################################
# STAGE 3: Final Runtime Image
################################
FROM langflowai/langflow:1.7.2

USER root

# ============================================================================
# Install system dependencies including PostgreSQL client for backups
# ============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# ENGARDE CUSTOMIZATION 8: Copy customized frontend from the installed package
# ============================================================================
COPY --from=backend-customizer /app/.venv/lib/python3.12/site-packages/langflow/frontend /tmp/custom-frontend

# Replace the default frontend with our customized version
RUN LANGFLOW_PATH=$(python3 -c "import langflow; import os; print(os.path.dirname(langflow.__file__))") && \
    echo "Replacing frontend at: $LANGFLOW_PATH/frontend" && \
    rm -rf $LANGFLOW_PATH/frontend && \
    mv /tmp/custom-frontend $LANGFLOW_PATH/frontend

# ============================================================================
# ENGARDE CUSTOMIZATION 9: Copy custom Walker Agent components
# These are the 14 custom components documented in:
# - engarde_components/seo_walker_agent.py
# - engarde_components/content_walker_agent.py
# - engarde_components/paid_ads_walker_agent.py
# - engarde_components/audience_intelligence_walker_agent.py
# - engarde_components/campaign_creation_agent.py
# - engarde_components/campaign_launcher_agent.py
# - engarde_components/content_approval_agent.py
# - engarde_components/notification_agent.py
# - engarde_components/performance_monitoring_agent.py
# - engarde_components/analytics_report_agent.py
# - engarde_components/tenant_id_input.py
# - engarde_components/walker_agent_api.py
# - engarde_components/walker_suggestion_builder.py
# - engarde_components/__init__.py (CRITICAL for Python module discovery)
# ============================================================================
# CRITICAL: Path must match Railway env variable LANGFLOW_COMPONENTS_PATH
# CRITICAL: Files must be owned by 'user' (UID 1000) for Langflow to read them
RUN mkdir -p /app/components/engarde_components
COPY --chown=1000:0 engarde_components /app/components/engarde_components

# ============================================================================
# ENGARDE CUSTOMIZATION 10: SSO Integration - Install into Langflow
# ============================================================================
# Copy SSO endpoint code and register in Langflow's API router system
COPY src/backend/base/langflow/api/v1/custom.py /tmp/custom.py

RUN LANGFLOW_PATH=$(python3 -c "import langflow; import os; print(os.path.dirname(langflow.__file__))") && \
    echo "Installing SSO endpoint at: $LANGFLOW_PATH/api/v1/custom.py" && \
    cp /tmp/custom.py $LANGFLOW_PATH/api/v1/custom.py && \
    rm /tmp/custom.py && \
    echo "SSO endpoint file installed successfully" && \
    \
    echo "Step 1: Registering SSO router in api/v1/__init__.py" && \
    sed -i '1i from langflow.api.v1.custom import router as custom_router' $LANGFLOW_PATH/api/v1/__init__.py && \
    sed -i '/__all__ = \[/a\    "custom_router",' $LANGFLOW_PATH/api/v1/__init__.py && \
    echo "api/v1/__init__.py modified successfully" && \
    \
    echo "Step 2: Adding custom_router to api/router.py imports" && \
    sed -i '/from langflow.api.v1 import (/a\    custom_router,' $LANGFLOW_PATH/api/router.py && \
    echo "Step 3: Including custom_router in router_v1" && \
    sed -i '/router_v1.include_router(chat_router)/a router_v1.include_router(custom_router)' $LANGFLOW_PATH/api/router.py && \
    echo "SSO router registered successfully in both files" && \
    \
    echo "Step 4: Removing Discord and GitHub references from startup message" && \
    sed -i 's|github.com/langflow-ai/langflow|engarde.media|g' $LANGFLOW_PATH/__main__.py && \
    sed -i 's|discord.com/invite/EqksyE2EX9|engarde.media/support|g' $LANGFLOW_PATH/__main__.py && \
    sed -i 's|GitHub: Star for updates|EnGarde: Visit our website|g' $LANGFLOW_PATH/__main__.py && \
    sed -i 's|Discord: Join for support|Support: Get help|g' $LANGFLOW_PATH/__main__.py && \
    sed -i 's|Welcome to Langflow|Welcome to EnGarde Agent Suite|g' $LANGFLOW_PATH/__main__.py && \
    echo "Discord and GitHub references removed successfully"

# ============================================================================
# ENGARDE CUSTOMIZATION 11: Environment variables
# See ENGARDE_LANGFLOW_COMPLETE_DOCUMENTATION.md for full list
# ============================================================================

# Langflow core settings
ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_COMPONENTS_PATH="/app/components/engarde_components"

# SSO Configuration (CRITICAL)
ENV LANGFLOW_AUTO_LOGIN=false
ENV LANGFLOW_SECRET_KEY=""

# EnGarde API integration
ENV ENGARDE_API_URL=""

# Walker Agent API Keys (set in Railway)
ENV WALKER_AGENT_API_KEY_ONSIDE_SEO=""
ENV WALKER_AGENT_API_KEY_ONSIDE_CONTENT=""
ENV WALKER_AGENT_API_KEY_SANKORE_PAID_ADS=""
ENV WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE=""

# ============================================================================
# ENGARDE CUSTOMIZATION 11.5: PostgreSQL Database Persistence
# ============================================================================
# CRITICAL: Langflow must use external PostgreSQL to persist flows across deployments
# Railway already has DATABASE_URL configured - Langflow will use it automatically
# Langflow checks LANGFLOW_DATABASE_URL first, then DATABASE_URL
# Since DATABASE_URL is already set in Railway, flows will persist across deployments
ENV LANGFLOW_DATABASE_URL=""

# Disable telemetry for privacy
ENV LANGFLOW_DO_NOT_TRACK=true

# LLM Configuration (Llama via Together AI, Groq, or OpenRouter)
# Note: Railway already has META_LLAMA_API_KEY and META_LLAMA_API_ENDPOINT configured
ENV META_LLAMA_API_KEY=""
ENV META_LLAMA_API_ENDPOINT="https://api.together.xyz/v1"

# ============================================================================
# ENGARDE CUSTOMIZATION 11: Copy admin setup scripts
# ============================================================================
COPY --chown=1000:0 set_admin_flows_public.py /app/set_admin_flows_public.py
COPY --chown=1000:0 setup_admin_folders.py /app/setup_admin_folders.py

# ============================================================================
# ENGARDE CUSTOMIZATION 12: Create startup script for Railway
# Railway provides a dynamic PORT environment variable
# This script ensures Langflow uses the correct port
# ============================================================================
RUN cat > /app/start.sh << 'EOF'
#!/bin/bash

# Ensure unbuffered output for immediate logging
export PYTHONUNBUFFERED=1

PORT=${PORT:-7860}

# Force output immediately - write directly to stderr since stdout might be buffered
>&2 echo "==================================="
>&2 echo "EnGarde Langflow Starting"
>&2 echo "==================================="
>&2 echo "Port: $PORT"
>&2 echo "Database URL: ${LANGFLOW_DATABASE_URL:0:30}..."
>&2 echo "Components Path: $LANGFLOW_COMPONENTS_PATH"
>&2 echo "==================================="

# Setup admin projects (folders) for template flows
>&2 echo ""
>&2 echo "Running admin project setup..."
python3 /app/setup_admin_folders.py
>&2 echo "Admin project setup completed"
>&2 echo ""

# Start Langflow with unbuffered output and both stdout/stderr
>&2 echo "Executing: langflow run --host 0.0.0.0 --port $PORT --log-level debug"
exec python3 -u -m langflow run --host 0.0.0.0 --port $PORT --log-level debug 2>&1
EOF

RUN chmod +x /app/start.sh && chown user:root /app/start.sh

# ============================================================================
# Container metadata (EnGarde branding)
# ============================================================================
LABEL org.opencontainers.image.title="EnGarde AI Campaign Builder"
LABEL org.opencontainers.image.authors="EnGarde Team <team@engarde.media>"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.url="https://engarde.media"
LABEL org.opencontainers.image.source="https://github.com/EnGardeHQ/langflow-engarde"
LABEL org.opencontainers.image.description="EnGarde - AI-powered social media campaign builder. Made with ❤️ by EnGarde"
LABEL org.opencontainers.image.vendor="EnGarde"
LABEL org.opencontainers.image.version="2.0.0"

USER user
WORKDIR /app

EXPOSE 7860

# Override any ENTRYPOINT from base image and use our custom startup script
ENTRYPOINT []
CMD ["/bin/bash", "/app/start.sh"]
