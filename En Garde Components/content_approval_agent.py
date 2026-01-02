"""EnGarde Marketing Automation Agent Components for Langflow"""

from langflow.custom import Component
from langflow.io import MessageTextInput, SecretStrInput, IntInput, Output, DropdownInput
from langflow.schema.message import Message
import httpx
import json
import os
from datetime import datetime
from typing import Dict, Any

class ContentApprovalAgentComponent(Component):
    display_name = "Content Approval Agent"
    description = "Handles content approval workflow"
    icon = "check-circle"

    inputs = [
        MessageTextInput(
            name="content_id",
            display_name="Content ID",
            info="UUID of the content to approve/reject",
            required=True
        ),
        DropdownInput(
            name="action",
            display_name="Action",
            info="Approve or reject",
            options=["approve", "reject"],
            value="approve"
        ),
        MessageTextInput(
            name="notes",
            display_name="Notes",
            info="Optional notes for approval/rejection",
            value=""
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
        """Approve or reject content"""

        payload = {
            "action": self.action,
            "notes": self.notes,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "approved_by": "engarde_agent"
        }

        api_url = os.getenv("ENGARDE_API_URL", self.api_url)
        api_key = os.getenv("ENGARDE_API_KEY", self.api_key)

        endpoint = f"{api_url}/api/v1/content/{self.content_id}/{self.action}"
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

