"""EnGarde Marketing Automation Agent Components for Langflow"""

from langflow.custom import Component
from langflow.io import MessageTextInput, SecretStrInput, IntInput, Output, DropdownInput
from langflow.schema.message import Message
import httpx
import json
import os
from datetime import datetime
from typing import Dict, Any

class CampaignCreationAgentComponent(Component):
    display_name = "Campaign Creation Agent"
    description = "Automatically creates marketing campaigns via EnGarde API"
    icon = "rocket"

    inputs = [
        MessageTextInput(
            name="tenant_id",
            display_name="Tenant ID",
            info="UUID of the tenant",
            required=True
        ),
        MessageTextInput(
            name="campaign_name",
            display_name="Campaign Name",
            info="Name for the new campaign",
            required=True
        ),
        MessageTextInput(
            name="campaign_type",
            display_name="Campaign Type",
            info="Type of campaign (e.g., email, social, ads)",
            value="email"
        ),
        MessageTextInput(
            name="api_url",
            display_name="API URL",
            info="EnGarde API base URL",
            value="${ENGARDE_API_URL}",
            advanced=True
        ),
        SecretStrInput(
            name="api_key",
            display_name="API Key",
            info="EnGarde API authentication key",
            value="${ENGARDE_API_KEY}",
            advanced=True
        ),
    ]

    outputs = [
        Output(display_name="Result", name="result", method="execute"),
    ]

    def execute(self) -> Message:
        """Create a campaign via API"""

        payload = {
            "tenant_id": self.tenant_id,
            "name": self.campaign_name,
            "type": self.campaign_type,
            "status": "draft",
            "created_by": "engarde_agent",
            "created_at": datetime.utcnow().isoformat() + "Z"
        }

        api_url = os.getenv("ENGARDE_API_URL", self.api_url)
        api_key = os.getenv("ENGARDE_API_KEY", self.api_key)

        endpoint = f"{api_url}/api/v1/campaigns"
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }

        try:
            with httpx.Client(timeout=30) as client:
                response = client.post(endpoint, json=payload, headers=headers)

                if response.status_code in [200, 201]:
                    result = response.json()
                    return Message(text=json.dumps(result, indent=2))
                else:
                    error_result = {
                        "success": False,
                        "error": f"HTTP {response.status_code}: {response.text}"
                    }
                    return Message(text=json.dumps(error_result, indent=2))
        except Exception as e:
            error_result = {"success": False, "error": str(e)}
            return Message(text=json.dumps(error_result, indent=2))

