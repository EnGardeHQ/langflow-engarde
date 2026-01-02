"""EnGarde Marketing Automation Agent Components for Langflow"""

from langflow.custom import Component
from langflow.io import MessageTextInput, SecretStrInput, IntInput, Output, DropdownInput
from langflow.schema.message import Message
import httpx
import json
import os
from datetime import datetime
from typing import Dict, Any

class CampaignLauncherAgentComponent(Component):
    display_name = "Scheduled Campaign Launcher"
    description = "Launches scheduled/draft campaigns"
    icon = "play"

    inputs = [
        MessageTextInput(
            name="campaign_id",
            display_name="Campaign ID",
            info="UUID of the campaign to launch",
            required=True
        ),
        MessageTextInput(
            name="launch_time",
            display_name="Launch Time",
            info="ISO 8601 timestamp for launch (or 'now')",
            value="now"
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
        """Launch a campaign"""

        launch_timestamp = datetime.utcnow().isoformat() + "Z" if self.launch_time == "now" else self.launch_time

        payload = {
            "status": "active",
            "launched_at": launch_timestamp,
            "launched_by": "engarde_agent"
        }

        api_url = os.getenv("ENGARDE_API_URL", self.api_url)
        api_key = os.getenv("ENGARDE_API_KEY", self.api_key)

        endpoint = f"{api_url}/api/v1/campaigns/{self.campaign_id}/launch"
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

