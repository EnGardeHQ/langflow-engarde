"""
EnGarde Template Synchronization Service

Handles synchronization of admin template flows to non-admin user folders.
"""

from typing import List, Dict, Any, Optional
from datetime import datetime, timezone
from sqlalchemy import select, and_, or_, text
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
import logging
import json
from uuid import UUID, uuid4

logger = logging.getLogger(__name__)


class TemplateSyncService:
    """Service for synchronizing EnGarde template flows to user folders"""

    ENGARDE_FOLDER_NAME = "En Garde"
    WALKER_AGENTS_SUBFOLDER = "Walker Agents"
    ENGARDE_FLOWS_SUBFOLDER = "En Garde Flows"

    def __init__(self, session: AsyncSession):
        self.session = session

    async def sync_user_templates(
        self,
        user_id: UUID,
        is_superuser: bool = False,
        force_sync: bool = False
    ) -> Dict[str, Any]:
        """
        Sync admin templates to user's En Garde folder.

        Args:
            user_id: User's UUID
            is_superuser: Whether user is admin/superuser
            force_sync: Force re-sync even if up-to-date

        Returns:
            Dict with sync results
        """
        try:
            logger.info(f"Starting template sync for user {user_id} (superuser: {is_superuser})")

            # Skip sync for admin users - they manage the templates directly
            if is_superuser:
                logger.info("User is admin, skipping template sync")
                return {
                    "status": "skipped",
                    "reason": "Admin users manage templates directly",
                    "sync_results": {}
                }

            # 1. Ensure user has En Garde folder structure
            engarde_folder, subfolders = await self._ensure_folder_structure(user_id)

            # 2. Get all admin templates
            admin_templates = await self._get_admin_templates()
            logger.info(f"Found {len(admin_templates)} admin templates")

            # 3. Get user's existing template copies
            user_templates = await self._get_user_templates(user_id)
            logger.info(f"User has {len(user_templates)} existing template copies")

            # 4. Sync templates
            sync_results = await self._perform_sync(
                user_id,
                engarde_folder,
                subfolders,
                admin_templates,
                user_templates,
                force_sync
            )

            logger.info(f"Sync completed for user {user_id}: {sync_results}")

            return {
                "status": "success",
                "sync_results": sync_results
            }

        except Exception as e:
            logger.error(f"Template sync failed for user {user_id}: {e}", exc_info=True)
            return {
                "status": "error",
                "error": str(e),
                "sync_results": {}
            }

    async def _ensure_folder_structure(self, user_id: UUID) -> tuple:
        """
        Ensure user has En Garde folder with subfolders.

        Returns:
            Tuple of (engarde_folder_id, {subfolder_name: folder_id})
        """
        # Check if En Garde folder exists
        result = await self.session.execute(
            text("""
                SELECT id FROM folder
                WHERE user_id = :user_id
                AND name = :folder_name
            """),
            {"user_id": str(user_id), "folder_name": self.ENGARDE_FOLDER_NAME}
        )
        engarde_folder = result.fetchone()

        if not engarde_folder:
            # Create En Garde folder
            folder_id = uuid4()
            await self.session.execute(
                text("""
                    INSERT INTO folder (id, name, user_id, created_at, updated_at)
                    VALUES (:id, :name, :user_id, :created_at, :updated_at)
                """),
                {
                    "id": str(folder_id),
                    "name": self.ENGARDE_FOLDER_NAME,
                    "user_id": str(user_id),
                    "created_at": datetime.now(timezone.utc),
                    "updated_at": datetime.now(timezone.utc)
                }
            )
            await self.session.commit()
            logger.info(f"Created En Garde folder for user {user_id}")
            engarde_folder_id = folder_id
        else:
            engarde_folder_id = UUID(engarde_folder[0])

        # Ensure subfolders exist
        subfolders = {}
        for subfolder_name in [self.WALKER_AGENTS_SUBFOLDER, self.ENGARDE_FLOWS_SUBFOLDER]:
            result = await self.session.execute(
                text("""
                    SELECT id FROM folder
                    WHERE user_id = :user_id
                    AND name = :folder_name
                    AND parent_id = :parent_id
                """),
                {
                    "user_id": str(user_id),
                    "folder_name": subfolder_name,
                    "parent_id": str(engarde_folder_id)
                }
            )
            subfolder = result.fetchone()

            if not subfolder:
                # Create subfolder
                subfolder_id = uuid4()
                await self.session.execute(
                    text("""
                        INSERT INTO folder (id, name, user_id, parent_id, created_at, updated_at)
                        VALUES (:id, :name, :user_id, :parent_id, :created_at, :updated_at)
                    """),
                    {
                        "id": str(subfolder_id),
                        "name": subfolder_name,
                        "user_id": str(user_id),
                        "parent_id": str(engarde_folder_id),
                        "created_at": datetime.now(timezone.utc),
                        "updated_at": datetime.now(timezone.utc)
                    }
                )
                await self.session.commit()
                logger.info(f"Created subfolder '{subfolder_name}' for user {user_id}")
                subfolders[subfolder_name] = subfolder_id
            else:
                subfolders[subfolder_name] = UUID(subfolder[0])

        return engarde_folder_id, subfolders

    async def _get_admin_templates(self) -> List[Dict[str, Any]]:
        """Get all admin template flows"""
        result = await self.session.execute(
            text("""
                SELECT f.id, f.name, f.data, f.description, f.template_version, f.updated_at, u.username
                FROM flow f
                JOIN "user" u ON f.user_id = u.id
                WHERE f.is_admin_template = true
                AND u.is_superuser = true
                ORDER BY f.name
            """)
        )

        templates = []
        for row in result.fetchall():
            templates.append({
                "id": UUID(row[0]),
                "name": row[1],
                "data": row[2],
                "description": row[3],
                "version": row[4] or "1.0.0",  # Default version
                "updated_at": row[5],
                "admin_username": row[6]
            })

        return templates

    async def _get_user_templates(self, user_id: UUID) -> Dict[UUID, Dict[str, Any]]:
        """
        Get user's existing template copies.

        Returns:
            Dict mapping template_source_id to user flow data
        """
        result = await self.session.execute(
            text("""
                SELECT id, name, template_source_id, template_version, last_synced_at
                FROM flow
                WHERE user_id = :user_id
                AND template_source_id IS NOT NULL
            """),
            {"user_id": str(user_id)}
        )

        user_templates = {}
        for row in result.fetchall():
            template_source_id = UUID(row[2])
            user_templates[template_source_id] = {
                "flow_id": UUID(row[0]),
                "name": row[1],
                "version": row[3],
                "last_synced_at": row[4]
            }

        return user_templates

    async def _perform_sync(
        self,
        user_id: UUID,
        engarde_folder_id: UUID,
        subfolders: Dict[str, UUID],
        admin_templates: List[Dict[str, Any]],
        user_templates: Dict[UUID, Dict[str, Any]],
        force_sync: bool
    ) -> Dict[str, Any]:
        """Perform the actual template synchronization"""

        new_flows_added = []
        updates_available = []
        up_to_date_count = 0

        for template in admin_templates:
            template_id = template["id"]
            template_name = template["name"]
            template_version = template["version"]

            # Determine which subfolder this template belongs to
            if "Walker Agent" in template_name:
                target_folder_id = subfolders[self.WALKER_AGENTS_SUBFOLDER]
                folder_name = self.WALKER_AGENTS_SUBFOLDER
            else:
                target_folder_id = subfolders[self.ENGARDE_FLOWS_SUBFOLDER]
                folder_name = self.ENGARDE_FLOWS_SUBFOLDER

            # Check if user already has this template
            if template_id in user_templates:
                user_template = user_templates[template_id]
                user_version = user_template["version"] or "1.0.0"

                if template_version != user_version or force_sync:
                    updates_available.append({
                        "user_flow_id": str(user_template["flow_id"]),
                        "template_id": str(template_id),
                        "flow_name": template_name,
                        "current_version": user_version,
                        "latest_version": template_version
                    })
                else:
                    up_to_date_count += 1
            else:
                # Create new copy of template for user
                new_flow = await self._copy_template_to_user(
                    user_id,
                    template,
                    target_folder_id
                )

                new_flows_added.append({
                    "flow_id": str(new_flow["id"]),
                    "name": template_name,
                    "template_version": template_version,
                    "folder": folder_name
                })

        return {
            "new_flows_added": new_flows_added,
            "updates_available": updates_available,
            "up_to_date_count": up_to_date_count,
            "total_templates": len(admin_templates)
        }

    async def _copy_template_to_user(
        self,
        user_id: UUID,
        template: Dict[str, Any],
        folder_id: UUID
    ) -> Dict[str, Any]:
        """Copy admin template flow to user's folder"""

        new_flow_id = uuid4()
        now = datetime.now(timezone.utc)

        await self.session.execute(
            text("""
                INSERT INTO flow (
                    id, user_id, name, description, data, folder_id,
                    is_admin_template, template_source_id, template_version, last_synced_at,
                    created_at, updated_at
                )
                VALUES (
                    :id, :user_id, :name, :description, :data, :folder_id,
                    false, :template_source_id, :template_version, :last_synced_at,
                    :created_at, :updated_at
                )
            """),
            {
                "id": str(new_flow_id),
                "user_id": str(user_id),
                "name": template["name"],
                "description": template["description"],
                "data": json.dumps(template["data"]) if isinstance(template["data"], dict) else template["data"],
                "folder_id": str(folder_id),
                "template_source_id": str(template["id"]),
                "template_version": template["version"],
                "last_synced_at": now,
                "created_at": now,
                "updated_at": now
            }
        )
        await self.session.commit()

        logger.info(f"Copied template '{template['name']}' to user {user_id} (flow_id: {new_flow_id})")

        return {
            "id": new_flow_id,
            "name": template["name"],
            "version": template["version"]
        }

    async def get_available_updates(self, user_id: UUID) -> List[Dict[str, Any]]:
        """Get list of templates that have updates available for user"""

        result = await self.session.execute(
            text("""
                SELECT
                    uf.id as user_flow_id,
                    uf.name as flow_name,
                    uf.template_version as current_version,
                    uf.template_source_id as template_id,
                    af.template_version as latest_version,
                    af.updated_at as template_updated_at
                FROM flow uf
                JOIN flow af ON uf.template_source_id = af.id
                WHERE uf.user_id = :user_id
                AND uf.template_source_id IS NOT NULL
                AND (uf.template_version IS NULL OR uf.template_version != af.template_version)
            """),
            {"user_id": str(user_id)}
        )

        updates = []
        for row in result.fetchall():
            updates.append({
                "user_flow_id": str(row[0]),
                "flow_name": row[1],
                "current_version": row[2] or "1.0.0",
                "template_id": str(row[3]),
                "latest_version": row[4] or "1.0.0",
                "template_updated_at": row[5].isoformat() if row[5] else None
            })

        return updates
