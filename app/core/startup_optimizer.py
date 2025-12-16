"""
Startup optimization utilities for EnGarde API.
Implements lazy loading and async initialization patterns.
"""
import asyncio
import time
from typing import Callable, List
from functools import wraps
import logging

logger = logging.getLogger(__name__)


class StartupTimer:
    """Context manager to track startup timing."""

    def __init__(self, name: str):
        self.name = name
        self.start_time = None

    def __enter__(self):
        self.start_time = time.time()
        logger.info(f"Starting: {self.name}")
        return self

    def __exit__(self, *args):
        elapsed = time.time() - self.start_time
        logger.info(f"Completed: {self.name} in {elapsed:.2f}s")


class LazyRouter:
    """Lazy-loaded router registration."""

    def __init__(self, import_path: str, router_name: str = "router"):
        self.import_path = import_path
        self.router_name = router_name
        self._router = None

    def load(self):
        """Load the router on-demand."""
        if self._router is None:
            with StartupTimer(f"Loading {self.import_path}"):
                module = __import__(self.import_path, fromlist=[self.router_name])
                self._router = getattr(module, self.router_name)
        return self._router


async def initialize_database_pool(max_retries: int = 3, retry_delay: float = 1.0):
    """
    Initialize database connection pool with retries.

    Args:
        max_retries: Maximum number of connection attempts
        retry_delay: Delay between retries in seconds
    """
    from app.core.database import engine

    for attempt in range(max_retries):
        try:
            with StartupTimer("Database connection pool initialization"):
                # Test connection
                async with engine.begin() as conn:
                    await conn.execute("SELECT 1")
                logger.info("Database connection pool initialized successfully")
                return True
        except Exception as e:
            logger.warning(f"Database connection attempt {attempt + 1}/{max_retries} failed: {e}")
            if attempt < max_retries - 1:
                await asyncio.sleep(retry_delay)
            else:
                logger.error("Failed to initialize database connection pool")
                raise
    return False


def defer_heavy_imports():
    """
    Decorator to defer heavy imports until first use.
    Use this for ML libraries, transformers, etc.
    """
    def decorator(func: Callable) -> Callable:
        _cache = {}

        @wraps(func)
        def wrapper(*args, **kwargs):
            if 'result' not in _cache:
                with StartupTimer(f"Deferred import: {func.__name__}"):
                    _cache['result'] = func(*args, **kwargs)
            return _cache['result']
        return wrapper
    return decorator


async def health_check_warmup():
    """
    Lightweight warmup to signal readiness without loading everything.
    This allows the app to respond to health checks quickly.
    """
    with StartupTimer("Health check warmup"):
        # Perform minimal initialization needed for health endpoint
        await asyncio.sleep(0.1)  # Simulate minimal setup
        logger.info("Application ready for health checks")


class RouterRegistry:
    """
    Registry for managing router loading with prioritization.
    Critical routers load immediately, deferred routers load on first request.
    """

    def __init__(self):
        self.critical_routers: List[tuple] = []
        self.deferred_routers: List[tuple] = []
        self.loaded_critical = False
        self.loaded_deferred = False

    def register_critical(self, router_path: str, prefix: str, tags: List[str]):
        """Register a critical router (loads immediately)."""
        self.critical_routers.append((router_path, prefix, tags))

    def register_deferred(self, router_path: str, prefix: str, tags: List[str]):
        """Register a deferred router (loads on first request)."""
        self.deferred_routers.append((router_path, prefix, tags))

    def load_critical(self, app):
        """Load only critical routers for fast startup."""
        if self.loaded_critical:
            return

        with StartupTimer(f"Loading {len(self.critical_routers)} critical routers"):
            for router_path, prefix, tags in self.critical_routers:
                try:
                    module_path, router_name = router_path.rsplit('.', 1)
                    module = __import__(module_path, fromlist=[router_name])
                    router = getattr(module, router_name)
                    app.include_router(router, prefix=prefix, tags=tags)
                    logger.debug(f"Loaded critical router: {prefix}")
                except Exception as e:
                    logger.error(f"Failed to load critical router {router_path}: {e}")
                    raise

        self.loaded_critical = True
        logger.info(f"Loaded {len(self.critical_routers)} critical routers")

    async def load_deferred_async(self, app):
        """Load deferred routers asynchronously after startup."""
        if self.loaded_deferred:
            return

        # await asyncio.sleep(5)  # Wait 5 seconds after startup

        with StartupTimer(f"Loading {len(self.deferred_routers)} deferred routers"):
            for router_path, prefix, tags in self.deferred_routers:
                try:
                    module_path, router_name = router_path.rsplit('.', 1)
                    module = __import__(module_path, fromlist=[router_name])
                    router = getattr(module, router_name)
                    app.include_router(router, prefix=prefix, tags=tags)
                    logger.debug(f"Loaded deferred router: {prefix}")
                except Exception as e:
                    logger.warning(f"Failed to load deferred router {router_path}: {e}")
                    # Don't raise - deferred routers are non-critical

        self.loaded_deferred = True
        logger.info(f"Loaded {len(self.deferred_routers)} deferred routers")


# Global registry instance
router_registry = RouterRegistry()


async def startup_sequence(app):
    """
    Optimized startup sequence.

    1. Health check warmup (fast)
    2. Database connection (critical)
    3. Critical routers (essential endpoints)
    4. Background task for deferred routers
    """
    logger.info("=== Starting optimized startup sequence ===")

    # Phase 1: Quick warmup
    await health_check_warmup()

    # Phase 2: Database
    await initialize_database_pool()

    # Phase 3: Critical routers only
    router_registry.load_critical(app)

    # Phase 4: Schedule deferred loading
    asyncio.create_task(router_registry.load_deferred_async(app))

    logger.info("=== Startup sequence complete (deferred loading in background) ===")


async def shutdown_sequence():
    """Clean shutdown sequence."""
    logger.info("=== Starting shutdown sequence ===")

    with StartupTimer("Closing database connections"):
        from app.core.database import engine
        await engine.dispose()

    logger.info("=== Shutdown complete ===")
