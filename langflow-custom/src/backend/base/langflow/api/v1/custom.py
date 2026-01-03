"""
Custom SSO Login Endpoint for EnGarde Integration
Handles JWT-based SSO authentication from the main EnGarde backend
"""

from fastapi import APIRouter, HTTPException, Depends, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session
from jose import jwt, JWTError
from datetime import datetime
import os
import logging

from langflow.services.database.models.user import User
from langflow.services.database.models.user.crud import get_user_by_username
from langflow.services.deps import session_scope
from langflow.services.auth.utils import create_user_longterm_token

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/custom", tags=["custom"])


@router.get("/sso_login")
async def sso_login(
    token: str,
    request: Request,
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

        if not email:
            logger.error("Token missing email")
            raise HTTPException(status_code=400, detail="Invalid token: missing email")

        logger.info(f"Processing SSO login for: {email}, tenant: {tenant_name}")

        # Use session_scope context manager
        async with session_scope() as session:
            # Get or create user in Langflow
            user = await get_user_by_username(session, email)

            if not user:
                logger.info(f"Creating new user: {email}")
                # Create the user using Langflow's user creation logic
                # Use email as both username and password (they'll use SSO anyway)
                from langflow.services.database.models.user.model import UserCreate

                user_create = UserCreate(
                    username=email,
                    password=email,  # Dummy password, won't be used with SSO
                    is_active=True,
                    is_superuser=False,
                )

                # Create user
                user = User(
                    username=user_create.username,
                    password=user_create.password,  # This will be hashed by the model
                    is_active=user_create.is_active,
                    is_superuser=user_create.is_superuser,
                )
                session.add(user)
                await session.commit()
                await session.refresh(user)
                logger.info(f"User created successfully: {email}")
            else:
                logger.info(f"Existing user found: {email}")

            # Generate a Langflow session token
            access_token = create_user_longterm_token(user_id=user.id, db=session)
            logger.info(f"Session token generated for user: {email}")

        # Redirect to Langflow dashboard with the token
        # The frontend will pick up this token and set it in cookies/localStorage
        frontend_url = str(request.base_url).rstrip("/")
        redirect_url = f"{frontend_url}/?token={access_token}"

        logger.info(f"Redirecting user to: {redirect_url}")
        return RedirectResponse(url=redirect_url)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"SSO login failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"SSO login failed: {str(e)}")
