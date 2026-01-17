"""Walker Agent Custom Components for Langflow"""

from langflow.base.io.text import TextComponent
from langflow.io import MultilineInput, Output, DropdownInput, IntInput, FloatInput, MessageTextInput, SecretStrInput, BoolInput
from langflow.schema.message import Message
from langflow.custom import Component
from typing import Dict, List, Any, Optional
import httpx
import json
from datetime import datetime
import uuid

class WalkerAgentAPIComponent(Component):
    """
    Send suggestions to EnGarde Walker Agents API.

    This component handles authentication and API communication with the
    EnGarde backend for Walker Agent suggestions.
    """
    display_name = "Walker Agent API Request"
    description = "Send suggestions to EnGarde backend API"
    icon = "send"
    name = "WalkerAgentAPI"

    inputs = [
        SecretStrInput(
            name="api_url",
            display_name="API URL",
            info="EnGarde backend API URL",
            value="${ENGARDE_API_URL}",
            required=True,
        ),
        SecretStrInput(
            name="api_key",
            display_name="API Key",
            info="Walker Agent API key (use environment variable)",
            required=True,
            placeholder="${WALKER_AGENT_API_KEY_ONSIDE_SEO}",
        ),
        DropdownInput(
            name="agent_type",
            display_name="Agent Type",
            options=["seo", "content", "paid_ads", "audience_intelligence"],
            value="seo",
            info="Type of Walker Agent",
        ),
        MessageTextInput(
            name="tenant_id",
            display_name="Tenant ID",
            info="Tenant UUID to send suggestions for",
            required=True,
        ),
        DropdownInput(
            name="priority",
            display_name="Priority",
            options=["high", "medium", "low"],
            value="high",
            info="Priority level of these suggestions",
        ),
        MultilineInput(
            name="suggestions",
            display_name="Suggestions (JSON Array)",
            info="Array of suggestion objects (from Suggestion Builder)",
            required=True,
            placeholder='[{"id": "...", "type": "...", ...}]',
        ),
        IntInput(
            name="timeout",
            display_name="Request Timeout (seconds)",
            value=30,
            info="HTTP request timeout",
        ),
        IntInput(
            name="max_retries",
            display_name="Max Retries",
            value=3,
            info="Number of retry attempts on failure",
        ),
    ]

    outputs = [
        Output(display_name="API Response", name="response", method="send_to_api"),
    ]

    def send_to_api(self) -> Message:
        """Send suggestions to Walker Agent API"""

        # Parse suggestions if it's a string
        if isinstance(self.suggestions, str):
            try:
                suggestions_list = json.loads(self.suggestions)
            except json.JSONDecodeError:
                return Message(
                    text=json.dumps({
                        "success": False,
                        "error": "Invalid JSON in suggestions field"
                    })
                )
        else:
            suggestions_list = self.suggestions

        # Ensure suggestions is a list
        if not isinstance(suggestions_list, list):
            suggestions_list = [suggestions_list]

        # Build request payload
        payload = {
            "agent_type": self.agent_type,
            "tenant_id": self.tenant_id,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "priority": self.priority,
            "suggestions": suggestions_list,
        }

        # Construct API endpoint
        api_url = self.api_url.rstrip('/')
        endpoint = f"{api_url}/api/v1/walker-agents/suggestions"

        # Set up headers
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        # Make request with retries
        last_error = None
        for attempt in range(self.max_retries):
            try:
                with httpx.Client(timeout=self.timeout) as client:
                    response = client.post(
                        endpoint,
                        json=payload,
                        headers=headers,
                    )

                    # Check if successful
                    if response.status_code in [200, 201]:
                        result = response.json()
                        result["_metadata"] = {
                            "status_code": response.status_code,
                            "attempt": attempt + 1,
                        }
                        return Message(text=json.dumps(result, indent=2))

                    # Store error for potential retry
                    last_error = f"HTTP {response.status_code}: {response.text}"

                    # Don't retry on 4xx errors (client errors)
                    if 400 <= response.status_code < 500:
                        break

            except httpx.TimeoutException:
                last_error = f"Request timeout after {self.timeout}s"
            except Exception as e:
                last_error = f"Request failed: {str(e)}"

            # Wait before retry (except on last attempt)
            if attempt < self.max_retries - 1:
                import time
                time.sleep(2 ** attempt)  # Exponential backoff

        # All retries failed
        return Message(
            text=json.dumps({
                "success": False,
                "error": last_error,
                "attempts": self.max_retries,
            })
        )


# ==============================================================================
# 4. SEO Walker Agent Component
# ==============================================================================
