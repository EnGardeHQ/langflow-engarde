"""Current User Tenant Component for Walker Agents"""

from langflow.custom import Component
from langflow.io import Output, SecretStrInput
from langflow.schema.message import Message
import os
import logging

logger = logging.getLogger(__name__)


class CurrentUserTenantComponent(Component):
    """
    Retrieves the tenant ID for the currently authenticated user.

    This component automatically gets the tenant_id from the user's session,
    eliminating the need for manual input. Perfect for multi-tenant Walker Agent
    installations where each user should only see/manage their own tenant's data.

    In production, this would query Langflow's user session or database to get
    the tenant_id that was stored during SSO login.
    """
    display_name = "Current User Tenant"
    description = "Automatically retrieve tenant ID from authenticated user session"
    icon = "user-check"
    name = "CurrentUserTenant"

    inputs = [
        SecretStrInput(
            name="database_url",
            display_name="Database URL",
            info="Langflow database connection string (to lookup user metadata)",
            value=os.getenv("DATABASE_PUBLIC_URL", ""),
            advanced=True,
        ),
    ]

    outputs = [
        Output(display_name="Tenant ID", name="tenant_id", method="get_tenant_id"),
    ]

    def get_tenant_id(self) -> Message:
        """
        Retrieve tenant_id from current user's session.

        IMPORTANT: This is a simplified implementation that returns a placeholder.

        In production, this should:
        1. Access Langflow's current request context to get authenticated user
        2. Query the user record from Langflow database
        3. Extract tenant_id from user metadata/custom fields

        This requires modifying the SSO endpoint to store tenant_id in user record.
        """

        # TODO: Implement actual session/database lookup
        # For now, return environment variable or placeholder

        tenant_id = os.getenv("ENGARDE_TENANT_ID", "")

        if not tenant_id:
            logger.warning(
                "ENGARDE_TENANT_ID not set. In production, this should retrieve "
                "tenant_id from the authenticated user's session/database record."
            )
            tenant_id = "00000000-0000-0000-0000-000000000000"  # Placeholder

        logger.info(f"Retrieved tenant_id: {tenant_id}")

        return Message(text=tenant_id)
