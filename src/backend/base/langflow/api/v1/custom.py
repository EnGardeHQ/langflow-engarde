"""
Custom SSO Login Endpoint for EnGarde Integration
Handles JWT-based SSO authentication from the main EnGarde backend
"""

from fastapi import APIRouter, HTTPException, Depends, Request, Response
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session
from jose import jwt, JWTError
from datetime import datetime, timedelta
import os
import logging

from langflow.services.database.models.user import User
from langflow.services.database.models.user.crud import get_user_by_username, update_user_last_login_at
from langflow.services.deps import session_scope, get_settings_service
from langflow.services.auth.utils import create_token, create_user_tokens
from langflow.initial_setup.setup import get_or_create_default_folder

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
