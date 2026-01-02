# syntax=docker/dockerfile:1
# ============================================================================
# EnGarde Langflow - Custom Branded Build
# ============================================================================
# Purpose: Full custom Langflow build with EnGarde branding
# - Removes Langflow/DataStax branding
# - Adds EnGarde logo, favicon, and "Made with ❤️ by EnGarde" footer
# - Builds frontend from source with customizations
# ============================================================================

################################
# BUILDER-BASE
# Used to build deps + create our virtual environment
################################

# Use a Python image with uv pre-installed
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

# Install the project into `/app`
WORKDIR /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

# Set RUSTFLAGS for reqwest unstable features needed by apify-client v2.0.0
ENV RUSTFLAGS='--cfg reqwest_unstable'

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y \
    # deps for building python deps
    build-essential \
    git \
    # npm for frontend build
    npm \
    # gcc for Python extensions
    gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy files first to avoid permission issues with bind mounts
COPY ./uv.lock /app/uv.lock
COPY ./README.md /app/README.md
COPY ./pyproject.toml /app/pyproject.toml
COPY ./src/backend/base/README.md /app/src/backend/base/README.md
COPY ./src/backend/base/uv.lock /app/src/backend/base/uv.lock
COPY ./src/backend/base/pyproject.toml /app/src/backend/base/pyproject.toml
COPY ./src/lfx/README.md /app/src/lfx/README.md
COPY ./src/lfx/pyproject.toml /app/src/lfx/pyproject.toml

# Install Python dependencies
RUN --mount=type=cache,target=/root/.cache/uv,id=uv-cache \
    RUSTFLAGS='--cfg reqwest_unstable' \
    uv sync --frozen --no-install-project --no-editable --extra postgresql

# Copy backend source
COPY ./src /app/src

################################
# FRONTEND BUILD with ENGARDE BRANDING
################################
COPY src/frontend /tmp/src/frontend
COPY engarde-branding /tmp/engarde-branding
WORKDIR /tmp/src/frontend

# Update index.html with EnGarde branding
RUN sed -i 's/<title>Langflow<\/title>/<title>EnGarde - AI Campaign Builder<\/title>/g' index.html

# Update manifest.json with EnGarde branding
RUN sed -i 's/"name": "Langflow"/"name": "EnGarde"/g' public/manifest.json && \
    sed -i 's/"short_name": "Langflow"/"short_name": "EnGarde"/g' public/manifest.json && \
    sed -i 's/"description": "Langflow is a low-code builder.*"/"description": "EnGarde - AI-powered social media campaign builder and management platform"/g' public/manifest.json

# Replace logos and favicon with EnGarde assets
RUN cp /tmp/engarde-branding/logo.png src/assets/logo_dark.png && \
    cp /tmp/engarde-branding/logo.png src/assets/logo_light.png && \
    cp /tmp/engarde-branding/favicon.ico public/favicon.ico

# Update welcome message
RUN find src/pages/MainPage/pages -name "empty-page.tsx" -exec sed -i 's/Welcome to Langflow/Welcome to EnGarde'\''s Agent Suite/g' {} \;

# Build frontend with EnGarde customizations
RUN --mount=type=cache,target=/root/.npm,id=npm-cache \
    npm ci \
    && ESBUILD_BINARY_PATH="" NODE_OPTIONS="--max-old-space-size=12288" JOBS=1 npm run build \
    && cp -r build /app/src/backend/langflow/frontend \
    && rm -rf /tmp/src/frontend /tmp/engarde-branding

################################
# FINAL PYTHON SYNC
################################
WORKDIR /app

RUN --mount=type=cache,target=/root/.cache/uv,id=uv-cache \
    RUSTFLAGS='--cfg reqwest_unstable' \
    uv sync --frozen --no-editable --extra postgresql

################################
# RUNTIME
# Setup user, utilities and copy the virtual environment only
################################
FROM python:3.12.3-slim AS runtime

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y curl git libpq5 gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && useradd user -u 1000 -g 0 --no-create-home --home-dir /app/data

COPY --from=builder --chown=1000 /app/.venv /app/.venv

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

# EnGarde branding in container labels
LABEL org.opencontainers.image.title="EnGarde AI Campaign Builder"
LABEL org.opencontainers.image.authors="EnGarde Team <team@engarde.media>"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.url=https://engarde.media
LABEL org.opencontainers.image.source=https://github.com/EnGardeHQ/langflow-custom
LABEL org.opencontainers.image.description="EnGarde - AI-powered social media campaign builder. Made with ❤️ by EnGarde"
LABEL org.opencontainers.image.vendor="EnGarde"

# Create startup script that uses Railway's PORT variable
RUN echo '#!/bin/bash\n\
    PORT=${PORT:-7860}\n\
    echo "Starting Langflow on port $PORT"\n\
    exec langflow run --host 0.0.0.0 --port $PORT' > /app/start.sh && \
    chmod +x /app/start.sh && \
    chown user:root /app/start.sh

USER user
WORKDIR /app

ENV LANGFLOW_HOST=0.0.0.0
# ENV LANGFLOW_PORT=7860  <-- REMOVED to avoid conflict with Railway PORT

COPY ["En Garde Components", "/app/components/En Garde Components"]
ENV LANGFLOW_COMPONENTS_PATH="/app/components"
ENV LANGFLOW_AUTO_LOGIN=true

# Expose port for Railway (uses dynamic PORT variable)
EXPOSE 7860

CMD ["/app/start.sh"]
