"""
Optimized database configuration with connection pooling and health checks.
"""
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from sqlalchemy.pool import NullPool, QueuePool
import os
import logging

logger = logging.getLogger(__name__)

# Get database URL from environment
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("DATABASE_URL environment variable is not set")

# Convert postgresql:// to postgresql+asyncpg:// for async support
if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)
elif DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql+asyncpg://", 1)

# Connection pool settings - adjust based on Railway plan
POOL_SIZE = int(os.getenv("DB_POOL_SIZE", "20"))
MAX_OVERFLOW = int(os.getenv("DB_MAX_OVERFLOW", "10"))
POOL_TIMEOUT = int(os.getenv("DB_POOL_TIMEOUT", "30"))
POOL_RECYCLE = int(os.getenv("DB_POOL_RECYCLE", "3600"))  # 1 hour
POOL_PRE_PING = True  # Enable connection health checks

# Determine pool class based on environment
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")
if ENVIRONMENT == "test":
    # Use NullPool for testing (no connection pooling)
    poolclass = NullPool
    pool_kwargs = {}
else:
    # Use QueuePool for production/development
    poolclass = QueuePool
    pool_kwargs = {
        "pool_size": POOL_SIZE,
        "max_overflow": MAX_OVERFLOW,
        "pool_timeout": POOL_TIMEOUT,
        "pool_recycle": POOL_RECYCLE,
        "pool_pre_ping": POOL_PRE_PING,
    }

# Create async engine with optimized settings
engine = create_async_engine(
    DATABASE_URL,
    poolclass=poolclass,
    echo=False,  # Set to True for SQL query logging (debugging only)
    future=True,
    connect_args={
        "server_settings": {
            "application_name": "engarde-api",
            "jit": "off",  # Disable JIT for faster simple queries
        },
        "command_timeout": 60,  # Query timeout in seconds
        "timeout": 10,  # Connection timeout in seconds
    },
    **pool_kwargs
)

# Create async session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

# Base class for SQLAlchemy models
Base = declarative_base()


async def get_db() -> AsyncSession:
    """
    Dependency for getting database sessions.
    Use this in FastAPI route dependencies.

    Example:
        @router.get("/users")
        async def get_users(db: AsyncSession = Depends(get_db)):
            result = await db.execute(select(User))
            return result.scalars().all()
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def check_database_connection() -> bool:
    """
    Check if database connection is healthy.
    Use this in health check endpoints.
    """
    try:
        async with engine.begin() as conn:
            await conn.execute("SELECT 1")
        return True
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        return False


async def init_db():
    """
    Initialize database tables.
    Call this during application startup if needed.
    """
    async with engine.begin() as conn:
        # Import all models here to ensure they're registered
        # from app.models import user, video, analysis, etc.

        # Create all tables
        await conn.run_sync(Base.metadata.create_all)

    logger.info("Database tables initialized")


async def close_db():
    """
    Close database connections gracefully.
    Call this during application shutdown.
    """
    await engine.dispose()
    logger.info("Database connections closed")


# Log database configuration (without sensitive info)
logger.info(f"Database configured with {poolclass.__name__}")
if poolclass == QueuePool:
    logger.info(f"Connection pool: size={POOL_SIZE}, max_overflow={MAX_OVERFLOW}")
