"""
Custom SSO Login Endpoint for EnGarde Integration
Handles JWT-based SSO authentication from the main EnGarde backend
"""

from fastapi import APIRouter, HTTPException, Depends, Request, Response
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session
from sqlalchemy import text
from jose import jwt, JWTError
from datetime import datetime, timedelta, timezone
from uuid import UUID
import os
import logging
import json

from langflow.services.database.models.user import User
from langflow.services.database.models.user.crud import get_user_by_username, update_user_last_login_at
from langflow.services.deps import session_scope, get_settings_service
from langflow.services.auth.utils import create_token, create_user_tokens
from langflow.initial_setup.setup import get_or_create_default_folder

# Import template sync service
import sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
from langflow.services.engarde_template_sync import TemplateSyncService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/custom", tags=["custom"])


@router.get("/sso_login")
async def sso_login(
    token: str,
    request: Request,
    response: Response,
):
    """
    SSO login endpoint that accepts a JWT token from the main EnGarde backend.

    This endpoint:
    1. Validates the JWT token using the shared secret
    2. Creates or retrieves the user in Langflow
    3. Generates a Langflow session token
    4. Redirects to the Langflow dashboard with the session token
    """
    try:
        logger.info("SSO login attempt received")

        # Get the shared secret key
        secret_key = os.getenv("LANGFLOW_SECRET_KEY")
        if not secret_key:
            logger.error("LANGFLOW_SECRET_KEY not configured")
            raise HTTPException(status_code=500, detail="SSO not configured")

        # Decode and validate the JWT token
        try:
            payload = jwt.decode(token, secret_key, algorithms=["HS256"])
            logger.info(f"Token decoded successfully for user: {payload.get('email')}")
        except JWTError as e:
            logger.error(f"Invalid token: {e}")
            raise HTTPException(status_code=401, detail="Invalid SSO token")

        # Check token expiration
        exp = payload.get("exp")
        if exp and datetime.utcfromtimestamp(exp) < datetime.utcnow():
            logger.error("Token has expired")
            raise HTTPException(status_code=401, detail="SSO token expired")

        # Extract user information from token
        email = payload.get("email")
        tenant_id = payload.get("tenant_id")
        tenant_name = payload.get("tenant_name", "EnGarde")
        user_role = payload.get("role", "user")  # admin, superuser, user, agency

        if not email:
            logger.error("Token missing email")
            raise HTTPException(status_code=400, detail="Invalid token: missing email")

        logger.info(f"Processing SSO login for: {email}, tenant: {tenant_name}, role: {user_role}")

        # Map EnGarde roles to Langflow permissions
        # superuser and admin get is_superuser=True in Langflow
        is_superuser = user_role in ["superuser", "admin"]
        # All SSO users are active by default
        is_active = True

        # Use session_scope context manager
        async with session_scope() as session:
            # Get or create user in Langflow
            user = await get_user_by_username(session, email)

            if not user:
                logger.info(f"Creating new user: {email} with role: {user_role}")
                # Create user directly with required fields
                user = User(
                    username=email,
                    password=email,  # Dummy password, will be hashed by the model
                    is_active=is_active,
                    is_superuser=is_superuser,
                )
                session.add(user)
                await session.commit()
                await session.refresh(user)
                logger.info(f"User created successfully: {email} (superuser: {is_superuser})")
            else:
                logger.info(f"Existing user found: {email}")
                # Update user permissions if role changed
                if user.is_superuser != is_superuser or user.is_active != is_active:
                    logger.info(f"Updating user permissions: superuser={is_superuser}, active={is_active}")
                    user.is_superuser = is_superuser
                    user.is_active = is_active
                    session.add(user)
                    await session.commit()
                    await session.refresh(user)

            # Generate a Langflow session tokens (access + refresh)
            # This function also updates last_login_at
            tokens = await create_user_tokens(user_id=user.id, db=session, update_last_login=True)

            # Create default project for user if it doesn't exist
            _ = await get_or_create_default_folder(session, user.id)

            # Sync EnGarde templates for non-admin users
            try:
                sync_service = TemplateSyncService(session)
                sync_result = await sync_service.sync_user_templates(
                    user_id=user.id,
                    is_superuser=user.is_superuser
                )
                if sync_result["status"] == "success":
                    sync_info = sync_result["sync_results"]
                    logger.info(
                        f"Template sync completed for {email}: "
                        f"{len(sync_info.get('new_flows_added', []))} new flows, "
                        f"{len(sync_info.get('updates_available', []))} updates available"
                    )
            except Exception as e:
                # Don't fail login if template sync fails
                logger.error(f"Template sync failed for {email}: {e}", exc_info=True)

            logger.info(f"Session tokens generated for user: {email}")

        # Use Langflow's built-in URL param SSO support but ALSO set cookies
        # to ensure iframe authentication works correctly (SameSite=None, Secure)
        frontend_url = str(request.base_url).rstrip("/")
        redirect_url = f"{frontend_url}/?access_token={tokens['access_token']}"

        logger.info(f"SSO successful for {email}, redirecting to: {redirect_url}")

        # Create redirect response
        redirect_response = RedirectResponse(url=redirect_url, status_code=302)

        # Set cookies with manual Partitioned attribute injection
        # Starlette/FastAPI doesn't fully support 'partitioned' arg in all versions yet

        # Set cookies with manual Partitioned attribute injection for Chrome (CHIPS) support
        # We manually construct the Set-Cookie header because Starlette/FastAPI's set_cookie
        # does not support the 'Partitioned' attribute in the version used.
        
        # 1. Refresh Token (HttpOnly)
        refresh_cookie = (
            f"refresh_token_lf={tokens['refresh_token']}; "
            "Path=/; "
            "Max-Age=2592000; "  # 30 days
            "HttpOnly; "
            "Secure; "
            "SameSite=None; "
            "Partitioned"
        )
        redirect_response.headers.append("Set-Cookie", refresh_cookie)

        # 2. Access Token (Not HttpOnly - readable by frontend if needed, though we inject mainly for auth)
        # Note: Frontend usually expects this in document.cookie or localStorage, but this cookie
        # allows initial auth request to succeed if middleware checks cookies.
        access_cookie = (
            f"access_token_lf={tokens['access_token']}; "
            "Path=/; "
            "Max-Age=3600; "     # 1 hour
            "Secure; "
            "SameSite=None; "
            "Partitioned"
        )
        redirect_response.headers.append("Set-Cookie", access_cookie)

        return redirect_response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"SSO login failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"SSO login failed: {str(e)}")


@router.get("/engarde-templates/updates")
async def get_template_updates(
    request: Request,
):
    """
    Get list of available template updates for the current user.

    Returns templates that have newer versions available compared to
    the user's current copies.
    """
    try:
        # Get user from request (assumes authentication middleware)
        # In production, you'd extract user_id from JWT token or session
        user_id = request.state.user_id if hasattr(request.state, 'user_id') else None

        if not user_id:
            raise HTTPException(status_code=401, detail="Authentication required")

        async with session_scope() as session:
            sync_service = TemplateSyncService(session)
            updates = await sync_service.get_available_updates(UUID(user_id))

            return {
                "status": "success",
                "updates_available": updates,
                "count": len(updates)
            }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get template updates: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to get updates: {str(e)}")


@router.post("/engarde-templates/sync")
async def sync_templates(
    request: Request,
):
    """
    Manually trigger template synchronization for the current user.

    This endpoint allows users to force a sync without logging out and back in.
    Useful for immediately getting new templates after admin updates.
    """
    try:
        user_id = request.state.user_id if hasattr(request.state, 'user_id') else None
        is_superuser = request.state.is_superuser if hasattr(request.state, 'is_superuser') else False

        if not user_id:
            raise HTTPException(status_code=401, detail="Authentication required")

        async with session_scope() as session:
            sync_service = TemplateSyncService(session)
            sync_result = await sync_service.sync_user_templates(
                user_id=UUID(user_id),
                is_superuser=is_superuser,
                force_sync=False
            )

            return sync_result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Template sync failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Sync failed: {str(e)}")


@router.post("/engarde-templates/migrate")
async def migrate_template(
    request: Request,
    user_flow_id: str,
    preserve_settings: bool = True
):
    """
    Migrate a user's flow to the latest template version.

    Args:
        user_flow_id: UUID of the user's flow to migrate
        preserve_settings: Whether to preserve custom settings (default: True)

    This endpoint:
    1. Gets the user's current flow
    2. Gets the latest admin template version
    3. Copies the new template structure
    4. Optionally preserves user's custom settings
    5. Updates the user's flow with new version
    """
    try:
        user_id = request.state.user_id if hasattr(request.state, 'user_id') else None

        if not user_id:
            raise HTTPException(status_code=401, detail="Authentication required")

        async with session_scope() as session:
            # Get user's current flow
            result = await session.execute(
                text("""
                    SELECT id, name, template_source_id, template_version, custom_settings, data
                    FROM flow
                    WHERE id = :flow_id AND user_id = :user_id
                """),
                {"flow_id": user_flow_id, "user_id": str(user_id)}
            )
            user_flow = result.fetchone()

            if not user_flow:
                raise HTTPException(status_code=404, detail="Flow not found")

            if not user_flow[2]:  # template_source_id
                raise HTTPException(status_code=400, detail="Flow is not a template copy")

            # Get latest admin template
            result = await session.execute(
                text("""
                    SELECT id, name, data, description, template_version, updated_at
                    FROM flow
                    WHERE id = :template_id AND is_admin_template = true
                """),
                {"template_id": str(user_flow[2])}
            )
            admin_template = result.fetchone()

            if not admin_template:
                raise HTTPException(status_code=404, detail="Admin template not found")

            # Check if update is needed
            current_version = user_flow[3] or "1.0.0"
            latest_version = admin_template[4] or "1.0.0"

            if current_version == latest_version:
                return {
                    "status": "up_to_date",
                    "message": "Flow is already on the latest version",
                    "current_version": current_version
                }

            # Perform migration
            now = datetime.now(timezone.utc)
            new_data = admin_template[2]  # New template data

            # Preserve custom settings if requested
            if preserve_settings and user_flow[4]:  # custom_settings
                # In a full implementation, you would merge custom_settings into new_data
                # For now, we'll keep custom_settings separate
                logger.info(f"Preserving custom settings for flow {user_flow_id}")

            # Update user's flow with new template
            await session.execute(
                text("""
                    UPDATE flow
                    SET data = :data,
                        template_version = :version,
                        last_synced_at = :synced_at,
                        updated_at = :updated_at
                    WHERE id = :flow_id
                """),
                {
                    "data": json.dumps(new_data) if isinstance(new_data, dict) else new_data,
                    "version": latest_version,
                    "synced_at": now,
                    "updated_at": now,
                    "flow_id": user_flow_id
                }
            )
            await session.commit()

            logger.info(f"Migrated flow {user_flow_id} from {current_version} to {latest_version}")

            return {
                "status": "success",
                "message": "Flow migrated successfully",
                "flow_id": user_flow_id,
                "flow_name": user_flow[1],
                "previous_version": current_version,
                "new_version": latest_version,
                "settings_preserved": preserve_settings
            }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Migration failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Migration failed: {str(e)}")


@router.get("/engarde-templates/admin")
async def list_admin_templates(
    request: Request,
):
    """
    List all admin template flows (admin only).

    Returns metadata about all templates including:
    - Template details (name, version, description)
    - Usage statistics (number of users with this template)
    - Last update timestamp
    """
    try:
        is_superuser = request.state.is_superuser if hasattr(request.state, 'is_superuser') else False

        if not is_superuser:
            raise HTTPException(status_code=403, detail="Admin access required")

        async with session_scope() as session:
            # Get all admin templates with user counts
            result = await session.execute(
                text("""
                    SELECT
                        f.id,
                        f.name,
                        f.description,
                        f.template_version,
                        f.updated_at,
                        COUNT(uf.id) as user_count
                    FROM flow f
                    LEFT JOIN flow uf ON uf.template_source_id = f.id
                    WHERE f.is_admin_template = true
                    GROUP BY f.id, f.name, f.description, f.template_version, f.updated_at
                    ORDER BY f.name
                """)
            )

            templates = []
            for row in result.fetchall():
                # Determine category based on name
                category = "walker_agents" if "Walker Agent" in row[1] else "engarde_flows"

                templates.append({
                    "template_id": str(row[0]),
                    "name": row[1],
                    "description": row[2],
                    "version": row[3] or "1.0.0",
                    "category": category,
                    "user_count": row[5],
                    "last_updated": row[4].isoformat() if row[4] else None
                })

            return {
                "status": "success",
                "templates": templates,
                "total_count": len(templates)
            }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to list admin templates: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to list templates: {str(e)}")
