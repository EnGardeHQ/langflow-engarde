"""
Monitoring and metrics collection for Railway deployment.
"""
import time
import logging
import os
from typing import Optional
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
import psutil

logger = logging.getLogger(__name__)


class MetricsMiddleware(BaseHTTPMiddleware):
    """
    Middleware to track request metrics.
    Logs slow requests and provides performance insights.
    """

    def __init__(self, app, slow_request_threshold: float = 1.0):
        super().__init__(app)
        self.slow_request_threshold = slow_request_threshold

    async def dispatch(self, request: Request, call_next):
        start_time = time.time()

        # Process request
        response = await call_next(request)

        # Calculate duration
        duration = time.time() - start_time

        # Log slow requests
        if duration > self.slow_request_threshold:
            logger.warning(
                f"Slow request: {request.method} {request.url.path} "
                f"took {duration:.2f}s (threshold: {self.slow_request_threshold}s)"
            )

        # Add timing header
        response.headers["X-Process-Time"] = f"{duration:.4f}"

        return response


class HealthCheckMetrics:
    """
    Collect and report health metrics for monitoring.
    """

    @staticmethod
    def get_system_metrics() -> dict:
        """Get system-level metrics."""
        try:
            cpu_percent = psutil.cpu_percent(interval=0.1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')

            return {
                "cpu_percent": cpu_percent,
                "memory_percent": memory.percent,
                "memory_available_mb": memory.available / (1024 * 1024),
                "disk_percent": disk.percent,
                "disk_free_gb": disk.free / (1024 * 1024 * 1024),
            }
        except Exception as e:
            logger.error(f"Failed to get system metrics: {e}")
            return {}

    @staticmethod
    async def get_database_metrics() -> dict:
        """Get database connection pool metrics."""
        try:
            from app.core.database_optimized import engine

            pool = engine.pool
            return {
                "pool_size": pool.size(),
                "checked_in": pool.checkedin(),
                "checked_out": pool.checkedout(),
                "overflow": pool.overflow(),
                "total_connections": pool.size() + pool.overflow(),
            }
        except Exception as e:
            logger.error(f"Failed to get database metrics: {e}")
            return {}

    @staticmethod
    def get_worker_metrics() -> dict:
        """Get Gunicorn worker metrics."""
        try:
            process = psutil.Process()
            return {
                "pid": process.pid,
                "cpu_percent": process.cpu_percent(interval=0.1),
                "memory_mb": process.memory_info().rss / (1024 * 1024),
                "num_threads": process.num_threads(),
                "create_time": process.create_time(),
            }
        except Exception as e:
            logger.error(f"Failed to get worker metrics: {e}")
            return {}


async def detailed_health_check() -> dict:
    """
    Comprehensive health check with detailed metrics.
    Use this for /health/detailed endpoint.
    """
    from app.core.database_optimized import check_database_connection
    from app.core.startup_optimizer import router_registry

    db_healthy = await check_database_connection()

    return {
        "status": "healthy" if db_healthy else "unhealthy",
        "timestamp": time.time(),
        "environment": os.getenv("ENVIRONMENT", "development"),
        "components": {
            "database": "healthy" if db_healthy else "unhealthy",
            "critical_routers": "loaded" if router_registry.loaded_critical else "loading",
            "deferred_routers": "loaded" if router_registry.loaded_deferred else "loading",
        },
        "metrics": {
            "system": HealthCheckMetrics.get_system_metrics(),
            "database": await HealthCheckMetrics.get_database_metrics(),
            "worker": HealthCheckMetrics.get_worker_metrics(),
        }
    }


class StartupHealthCheck:
    """
    Track startup progress for health checks during initialization.
    """

    def __init__(self):
        self.start_time = time.time()
        self.stages = {
            "initialized": False,
            "database_connected": False,
            "critical_routers_loaded": False,
            "ready": False,
        }

    def mark_stage(self, stage: str):
        """Mark a startup stage as complete."""
        if stage in self.stages:
            self.stages[stage] = True
            elapsed = time.time() - self.start_time
            logger.info(f"Startup stage '{stage}' completed at {elapsed:.2f}s")

    def is_ready(self) -> bool:
        """Check if application is ready to serve traffic."""
        return self.stages.get("ready", False)

    def get_status(self) -> dict:
        """Get current startup status."""
        elapsed = time.time() - self.start_time
        return {
            "startup_time_seconds": elapsed,
            "stages": self.stages,
            "ready": self.is_ready(),
        }


# Global startup tracker
startup_tracker = StartupHealthCheck()


# Logging configuration for production
def configure_production_logging():
    """Configure structured logging for production."""
    if os.getenv("ENVIRONMENT") == "production":
        # JSON structured logging
        log_format = '{"time": "%(asctime)s", "level": "%(levelname)s", "logger": "%(name)s", "message": "%(message)s"}'
    else:
        # Human-readable logging
        log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'

    logging.basicConfig(
        level=os.getenv("LOG_LEVEL", "INFO"),
        format=log_format,
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    # Silence noisy loggers
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.error").setLevel(logging.INFO)
