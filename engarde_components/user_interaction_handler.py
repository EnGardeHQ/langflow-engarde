"""User Interaction Handler Component for Walker Agents"""

from langflow.custom import Component
from langflow.io import MessageTextInput, SecretStrInput, Output, DropdownInput, IntInput
from langflow.schema.message import Message
import httpx
import json
import os
import logging
from typing import Dict, Any, List

logger = logging.getLogger(__name__)


class UserInteractionHandlerComponent(Component):
    """
    Handles two-way user interaction with Walker Agent suggestions.

    User Actions:
    - Execute: User approves and wants to execute the suggestion
    - Pause: User wants to pause/snooze the suggestion
    - Reject: User dismisses the suggestion
    - Request Details: User wants more information

    Integration with EnGarde UI:
    - User sets communication channel preference in wizard (email, WhatsApp, in-app)
    - Suggestions are sent via NotificationAgent to user's preferred channel
    - User responds with action (Execute/Pause/Reject/Details)
    - This component polls for user responses and processes them

    Communication Channels:
    - Email: User clicks action links in email → POST to /api/v1/walker-agents/responses
    - WhatsApp: User replies with keywords → Twilio webhook → POST to responses endpoint
    - In-App: User clicks buttons in dashboard → Direct API call to responses endpoint
    """
    display_name = "User Interaction Handler"
    description = "Handle user responses to Walker Agent suggestions (Execute/Pause/Reject/Details)"
    icon = "message-square-reply"
    name = "UserInteractionHandler"

    inputs = [
        MessageTextInput(
            name="tenant_id",
            display_name="Tenant ID",
            info="UUID of the tenant",
            required=True,
        ),
        MessageTextInput(
            name="batch_id",
            display_name="Batch ID",
            info="Batch ID of suggestions to check for responses",
            required=True,
        ),
        DropdownInput(
            name="agent_type",
            display_name="Agent Type",
            options=["seo", "content", "paid_ads", "audience_intelligence"],
            value="seo",
        ),
        SecretStrInput(
            name="api_url",
            display_name="API URL",
            info="EnGarde backend API URL",
            value=os.getenv("ENGARDE_API_URL", "https://api.engarde.media"),
        ),
        SecretStrInput(
            name="api_key",
            display_name="API Key",
            info="EnGarde API authentication key",
            value=os.getenv("ENGARDE_API_KEY", ""),
        ),
        IntInput(
            name="poll_interval",
            display_name="Poll Interval (seconds)",
            info="How often to check for user responses",
            value=300,  # 5 minutes
            advanced=True,
        ),
    ]

    outputs = [
        Output(display_name="User Responses", name="responses", method="get_user_responses"),
        Output(display_name="Actions to Execute", name="actions", method="get_actions_to_execute"),
    ]

    def get_user_responses(self) -> Message:
        """
        Poll EnGarde API for user responses to suggestions.

        Endpoint: GET /api/v1/walker-agents/responses?batch_id={batch_id}

        Returns responses like:
        [
            {
                "suggestion_id": "uuid",
                "user_action": "execute",
                "responded_at": "2024-01-15T10:30:00Z",
                "channel": "email",
                "user_comment": "Great idea, let's do it"
            }
        ]
        """
        try:
            endpoint = f"{self.api_url}/api/v1/walker-agents/responses"
            params = {
                "batch_id": self.batch_id,
                "tenant_id": self.tenant_id,
                "agent_type": self.agent_type,
            }
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
            }

            with httpx.Client(timeout=30.0) as client:
                response = client.get(endpoint, params=params, headers=headers)
                response.raise_for_status()
                responses = response.json()

                logger.info(f"Retrieved {len(responses.get('responses', []))} user responses for batch {self.batch_id}")

                return Message(text=json.dumps(responses, indent=2))

        except httpx.HTTPError as e:
            logger.error(f"Failed to get user responses: {e}")
            return Message(text=json.dumps({"responses": [], "error": str(e)}))

    def get_actions_to_execute(self) -> Message:
        """
        Filter user responses to get only 'execute' actions.

        Returns list of suggestions user wants to execute.
        These can be passed to execution components (e.g., Campaign Launcher).
        """
        try:
            # Get all responses first
            responses_data = json.loads(self.get_user_responses().text)
            all_responses = responses_data.get("responses", [])

            # Filter for 'execute' actions only
            execute_actions = [
                r for r in all_responses
                if r.get("user_action") == "execute"
            ]

            result = {
                "total_responses": len(all_responses),
                "execute_count": len(execute_actions),
                "actions_to_execute": execute_actions,
            }

            logger.info(f"Found {len(execute_actions)} suggestions to execute")

            return Message(text=json.dumps(result, indent=2))

        except Exception as e:
            logger.error(f"Failed to filter execute actions: {e}")
            return Message(text=json.dumps({"actions_to_execute": [], "error": str(e)}))
