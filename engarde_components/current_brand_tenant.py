"""Current Brand Tenant Component for Walker Agents"""

from langflow.custom import Component
from langflow.io import Output, SecretStrInput, MessageTextInput
from langflow.schema.message import Message
import httpx
import os
import logging
import json

logger = logging.getLogger(__name__)


class CurrentBrandTenantComponent(Component):
    """
    Retrieves the tenant ID for the currently selected brand from EnGarde dashboard.

    Integration with EnGarde Brand Selector:
    - EnGarde dashboard has BrandSelector dropdown in top navigation/header
    - When user selects a brand, tenant_id is stored in AuthContext and localStorage
    - localStorage key: 'engarde_user' contains user object with tenant_id field
    - API endpoint: GET /api/brands/current returns currently selected brand

    Multi-tenant architecture: A single user (agency) can manage multiple brands/clients.
    This component retrieves the tenant_id of whichever brand the user has currently
    selected in the EnGarde dashboard brand selector dropdown.

    Retrieval Methods (in priority order):
    1. API Lookup - Calls GET /api/brands/current (uses user's session auth)
    2. Manual Override - Allows explicit tenant_id input for testing/admin use
    3. Environment Variable - Falls back to ENGARDE_TENANT_ID if set

    When Langflow is accessed from EnGarde dashboard, the API call will automatically
    use the user's authentication context and return their currently selected brand.
    """
    display_name = "Current Brand Tenant"
    description = "Automatically retrieve tenant ID of currently selected brand"
    icon = "building"
    name = "CurrentBrandTenant"

    inputs = [
        SecretStrInput(
            name="engarde_api_url",
            display_name="EnGarde API URL",
            info="EnGarde backend API base URL",
            value=os.getenv("ENGARDE_API_URL", "https://api.engarde.media"),
        ),
        SecretStrInput(
            name="user_auth_token",
            display_name="User Auth Token",
            info="JWT token from authenticated user session (leave empty to auto-detect)",
            value="",
            advanced=True,
        ),
        MessageTextInput(
            name="manual_tenant_id",
            display_name="Manual Tenant ID Override",
            info="Optional: Manually specify tenant_id (for testing or admin use)",
            value="",
            advanced=True,
        ),
    ]

    outputs = [
        Output(display_name="Tenant ID", name="tenant_id", method="get_tenant_id"),
        Output(display_name="Brand Info", name="brand_info", method="get_brand_info"),
    ]

    def get_tenant_id(self) -> Message:
        """Retrieve tenant_id of currently selected brand"""

        # Priority 1: Manual override (for testing/admin)
        if self.manual_tenant_id and self.manual_tenant_id.strip():
            tenant_id = self.manual_tenant_id.strip()
            logger.info(f"Using manual tenant_id override: {tenant_id}")
            return Message(text=tenant_id)

        # Priority 2: API lookup for current brand
        try:
            brand_data = self._fetch_current_brand()
            if brand_data and "tenant_id" in brand_data:
                tenant_id = brand_data["tenant_id"]
                logger.info(f"Retrieved current brand tenant_id via API: {tenant_id}")
                return Message(text=tenant_id)
        except Exception as e:
            logger.warning(f"Failed to fetch current brand from API: {e}")

        # Priority 3: Environment variable fallback
        tenant_id = os.getenv("ENGARDE_TENANT_ID", "")
        if tenant_id:
            logger.info(f"Using ENGARDE_TENANT_ID from environment: {tenant_id}")
            return Message(text=tenant_id)

        # No tenant_id found - return error placeholder
        logger.error("Could not determine tenant_id. No manual override, API lookup failed, and no environment variable set.")
        return Message(text="ERROR_NO_TENANT_ID")

    def get_brand_info(self) -> Message:
        """Retrieve full brand information (name, settings, etc.)"""

        try:
            brand_data = self._fetch_current_brand()
            if brand_data:
                return Message(text=json.dumps(brand_data))
        except Exception as e:
            logger.error(f"Failed to fetch brand info: {e}")

        return Message(text=json.dumps({"error": "Could not retrieve brand info"}))

    def _fetch_current_brand(self) -> dict:
        """
        Fetch currently selected brand from EnGarde API.

        This calls the same endpoint used by the EnGarde dashboard's BrandSelector:

        Endpoint: GET /api/brands/current
        Headers: Authorization: Bearer <token>

        Backend Implementation (production-frontend/lib/api/brands.ts):
        - useCurrentBrand() hook calls this endpoint
        - Returns currently selected Brand object
        - Brand.id acts as tenant_id

        Expected Response: {
            "id": "uuid",              // This is the tenant_id
            "name": "Company Name",
            "industry": "ecommerce",
            "plan": "professional",
            ...
        }

        The Brand.id field IS the tenant_id in EnGarde's architecture.
        """

        # Get auth token (from input or environment)
        auth_token = self.user_auth_token or os.getenv("ENGARDE_USER_TOKEN", "")

        if not auth_token:
            logger.warning("No auth token available for API lookup. Set user_auth_token or ENGARDE_USER_TOKEN env var.")
            return {}

        # Call EnGarde API - same endpoint used by BrandSelector
        url = f"{self.engarde_api_url}/api/brands/current"
        headers = {
            "Authorization": f"Bearer {auth_token}",
            "Content-Type": "application/json",
        }

        try:
            with httpx.Client(timeout=10.0) as client:
                response = client.get(url, headers=headers)
                response.raise_for_status()
                brand = response.json()

                # Extract tenant_id from brand.id
                tenant_id = brand.get("id")
                brand_name = brand.get("name", "Unknown")

                logger.info(f"Successfully retrieved current brand: {brand_name} (tenant_id: {tenant_id})")

                # Return with tenant_id field for consistency
                return {
                    "tenant_id": tenant_id,
                    "brand_name": brand_name,
                    "industry": brand.get("industry"),
                    "plan": brand.get("plan"),
                    "status": brand.get("status"),
                }

        except httpx.HTTPStatusError as e:
            logger.error(f"API returned error {e.response.status_code}: {e.response.text}")
            return {}
        except httpx.RequestError as e:
            logger.error(f"Network error calling EnGarde API: {e}")
            return {}
        except Exception as e:
            logger.error(f"Unexpected error fetching current brand: {e}")
            return {}
