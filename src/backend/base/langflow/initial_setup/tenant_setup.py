"""
Tenant-based folder management for Langflow
Creates and manages separate folders for each brand/tenant
"""

from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from langflow.services.database.models.folder.model import Folder
from langflow.schema.folder import FolderRead
import logging

logger = logging.getLogger(__name__)


async def get_or_create_tenant_folder(
    db: AsyncSession,
    user_id: UUID,
    tenant_id: str,
    tenant_name: str
) -> FolderRead:
    """
    Get or create a folder for a specific tenant/brand.
    
    Args:
        db: Database session
        user_id: User's UUID
        tenant_id: Tenant/brand identifier (e.g., "staging" or tenant UUID)
        tenant_name: Display name for the folder (e.g., "Acme Corp" or "Staging/Testing")
    
    Returns:
        FolderRead: The folder for this tenant
    """
    try:
        # Store tenant_id in description field for lookup
        # Format: "tenant:{tenant_id}"
        tenant_marker = f"tenant:{tenant_id}"
        
        # Check if folder already exists for this tenant
        stmt = select(Folder).where(
            Folder.user_id == user_id,
            Folder.description == tenant_marker
        )
        result = await db.execute(stmt)
        existing_folder = result.scalar_one_or_none()
        
        if existing_folder:
            logger.info(f"Found existing folder for tenant {tenant_id}: {existing_folder.id}")
            return FolderRead.model_validate(existing_folder)
        
        # Create new folder for this tenant
        new_folder = Folder(
            name=tenant_name,
            description=tenant_marker,
            user_id=user_id
        )
        
        db.add(new_folder)
        await db.commit()
        await db.refresh(new_folder)
        
        logger.info(f"Created new folder for tenant {tenant_id}: {new_folder.id}")
        return FolderRead.model_validate(new_folder)
        
    except Exception as e:
        logger.error(f"Failed to get/create tenant folder for {tenant_id}: {e}")
        await db.rollback()
        raise
