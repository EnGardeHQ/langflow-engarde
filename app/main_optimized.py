"""
Optimized main application entry point for EnGarde API.
Implements fast startup with deferred router loading.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging
import os

from app.core.startup_optimizer import (
    startup_sequence,
    shutdown_sequence,
    router_registry,
    StartupTimer
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup and shutdown.
    This replaces @app.on_event("startup") and @app.on_event("shutdown")
    """
    # Startup
    with StartupTimer("Total application startup"):
        await startup_sequence(app)

    yield

    # Shutdown
    with StartupTimer("Total application shutdown"):
        await shutdown_sequence()


# Create FastAPI app
app = FastAPI(
    title="EnGarde API",
    description="AI-powered fencing training and analysis platform",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if os.getenv("ENVIRONMENT") != "production" else None,
    redoc_url="/redoc" if os.getenv("ENVIRONMENT") != "production" else None,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("ALLOWED_ORIGINS", "*").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ===== ROUTER REGISTRATION =====
# Register routers based on priority

# CRITICAL ROUTERS - Load immediately (essential for app to function)
critical_routers = [
    ("production_backend.app.api.routes.health.router", "/health", ["health"]),
    ("production_backend.app.api.routes.auth.router", "/api/auth", ["authentication"]),
    ("production_backend.app.api.routes.users.router", "/api/users", ["users"]),
    ("production_backend.app.api.routes.debug.router", "/api/debug", ["debug"]),
]

for router_path, prefix, tags in critical_routers:
    router_registry.register_critical(router_path, prefix, tags)

# DEFERRED ROUTERS - Load in background after startup
deferred_routers = [
    ("production_backend.app.api.routes.videos.router", "/api/videos", ["videos"]),
    ("production_backend.app.api.routes.analysis.router", "/api/analysis", ["analysis"]),
    ("production_backend.app.api.routes.training.router", "/api/training", ["training"]),
    ("production_backend.app.api.routes.competitions.router", "/api/competitions", ["competitions"]),
    ("production_backend.app.api.routes.athletes.router", "/api/athletes", ["athletes"]),
    # Add remaining 57+ routers here
]

for router_path, prefix, tags in deferred_routers:
    router_registry.register_deferred(router_path, prefix, tags)


# ===== HEALTH CHECK ENDPOINT =====
# This endpoint is registered immediately (not through router system)
# to ensure health checks pass quickly

@app.get("/health", tags=["health"])
async def health_check():
    """
    Lightweight health check endpoint.
    Returns immediately without waiting for all routers to load.
    """
    return {
        "status": "healthy",
        "environment": os.getenv("ENVIRONMENT", "development"),
        "critical_routers_loaded": router_registry.loaded_critical,
        "deferred_routers_loaded": router_registry.loaded_deferred,
    }


@app.get("/", tags=["root"])
async def root():
    """Root endpoint."""
    return {
        "message": "EnGarde API",
        "version": "1.0.0",
        "docs": "/docs" if os.getenv("ENVIRONMENT") != "production" else "disabled"
    }


# ===== STARTUP LOG =====
logger.info(f"EnGarde API initialized")
logger.info(f"ENVIRONMENT: {os.getenv('ENVIRONMENT', 'development')}")
logger.info(f"Critical routers registered: {len(critical_routers)}")
logger.info(f"Deferred routers registered: {len(deferred_routers)}")
