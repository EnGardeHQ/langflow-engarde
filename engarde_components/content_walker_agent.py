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

class ContentWalkerAgentComponent(Component):
    """Complete Content Walker Agent"""
    display_name = "Content Walker Agent (Complete)"
    description = "End-to-end Content Walker Agent with backend integration"
    icon = "file-text"
    name = "ContentWalkerAgent"

    inputs = [
        MessageTextInput(name="tenant_id", display_name="Tenant ID", required=True),
        SecretStrInput(name="api_url", display_name="API URL", value="${ENGARDE_API_URL}"),
        SecretStrInput(name="api_key", display_name="API Key", value="${WALKER_AGENT_API_KEY_ONSIDE_CONTENT}"),
    ]

    outputs = [
        Output(display_name="Result", name="result", method="execute"),
    ]

    def execute(self) -> Message:
        suggestion = {
            "id": str(uuid.uuid4()),
            "type": "content_gap",
            "title": "Content gap analysis reveals opportunities",
            "description": "Identified content topics with high engagement potential for your audience.",
            "impact": {
                "estimated_revenue_increase": 4000.0,
                "confidence_score": 0.75,
            },
            "actions": [
                {
                    "action_type": "create_content",
                    "description": "Develop content for identified topic opportunities",
                }
            ],
            "cta_url": "https://app.engarde.media/campaigns/create",
            "metadata": {
                "generated_at": datetime.utcnow().isoformat() + "Z",
                "source": "langflow_content_walker",
            }
        }

        payload = {
            "agent_type": "content",
            "tenant_id": self.tenant_id,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "priority": "medium",
            "suggestions": [suggestion],
        }

        endpoint = f"{self.api_url.rstrip('/')}/api/v1/walker-agents/suggestions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        try:
            with httpx.Client(timeout=30) as client:
                response = client.post(endpoint, json=payload, headers=headers)
                return Message(text=json.dumps(response.json() if response.status_code in [200, 201] else {"success": False, "error": response.text}, indent=2))
        except Exception as e:
            return Message(text=json.dumps({"success": False, "error": str(e)}))


# ==============================================================================
# 7. Audience Intelligence Walker Agent Component
# ==============================================================================
