"""EnGarde Marketing Automation Agent Components for Langflow"""

from langflow.custom import Component
from langflow.io import MessageTextInput, SecretStrInput, IntInput, Output, DropdownInput
from langflow.schema.message import Message
import httpx
import json
import os
from datetime import datetime
from typing import Dict, Any

class NotificationAgentComponent(Component):
    display_name = "Multi-Channel Notification Agent"
    description = "Sends Walker Agent suggestions via user's preferred channel (email/WhatsApp/in-app)"
    icon = "bell"

    """
    Sends notifications to users through their preferred communication channel.

    Channel Selection (configured in EnGarde UI wizard):
    - User sets preferred channel in Settings → Notifications → Walker Agents
    - Preference stored in user_preferences table with channel field
    - Backend API reads preference and sends to appropriate channel

    Email Channel:
    - Uses Brevo (formerly SendinBlue) API
    - Includes action buttons: Execute, Pause, Reject, Details
    - Each button links to: /api/v1/walker-agents/responses?action=...

    WhatsApp Channel:
    - Uses Twilio WhatsApp Business API
    - Sends formatted message with suggestion details
    - User replies with keywords: EXECUTE, PAUSE, REJECT, DETAILS
    - Twilio webhook forwards to: /api/v1/walker-agents/whatsapp-webhook

    In-App Channel:
    - WebSocket real-time notification
    - Shows in dashboard notification center
    - User clicks action buttons → Direct API call
    """

    inputs = [
        MessageTextInput(
            name="tenant_id",
            display_name="Tenant ID",
            info="UUID of the tenant",
            required=True
        ),
        MessageTextInput(
            name="message",
            display_name="Message",
            info="Notification message content",
            required=True
        ),
        DropdownInput(
            name="channel",
            display_name="Channel",
            info="Notification channel",
            options=["email", "whatsapp", "in_app", "all"],
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
        """Send multi-channel notification"""

        payload = {
            "tenant_id": self.tenant_id,
            "message": self.message,
            "channel": self.channel,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "sent_by": "engarde_agent"
        }

        api_url = os.getenv("ENGARDE_API_URL", self.api_url)
        api_key = os.getenv("ENGARDE_API_KEY", self.api_key)

        endpoint = f"{api_url}/api/v1/notifications/send"
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

