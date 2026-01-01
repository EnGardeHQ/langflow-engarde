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

class SEOWalkerAgentComponent(Component):
    """
    Complete SEO Walker Agent flow in a single component.

    This all-in-one component handles:
    - Tenant ID input
    - SEO suggestion generation
    - API request to backend
    """
    display_name = "SEO Walker Agent (Complete)"
    description = "End-to-end SEO Walker Agent with backend integration"
    icon = "search"
    name = "SEOWalkerAgent"

    inputs = [
        MessageTextInput(
            name="tenant_id",
            display_name="Tenant ID",
            info="Tenant UUID to analyze",
            required=True,
        ),
        SecretStrInput(
            name="api_url",
            display_name="API URL",
            value="${ENGARDE_API_URL}",
        ),
        SecretStrInput(
            name="api_key",
            display_name="API Key",
            value="${WALKER_AGENT_API_KEY_ONSIDE_SEO}",
        ),
    ]

    outputs = [
        Output(display_name="Result", name="result", method="execute"),
    ]

    def execute(self) -> Message:
        """Execute complete SEO Walker Agent flow"""

        # Generate SEO suggestion (template for now)
        suggestion = {
            "id": str(uuid.uuid4()),
            "type": "keyword_opportunity",
            "title": "High-value SEO opportunity identified",
            "description": "Our analysis shows potential for keyword optimization in your content strategy. Focus on long-tail keywords with high search volume and low competition.",
            "impact": {
                "estimated_revenue_increase": 5000.0,
                "confidence_score": 0.85,
            },
            "actions": [
                {
                    "action_type": "create_content",
                    "description": "Create targeted content for identified keyword opportunities",
                }
            ],
            "cta_url": "https://app.engarde.media/campaigns/create",
            "metadata": {
                "generated_at": datetime.utcnow().isoformat() + "Z",
                "source": "langflow_seo_walker",
            }
        }

        # Build API payload
        payload = {
            "agent_type": "seo",
            "tenant_id": self.tenant_id,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "priority": "high",
            "suggestions": [suggestion],
        }

        # Send to API
        endpoint = f"{self.api_url.rstrip('/')}/api/v1/walker-agents/suggestions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        try:
            with httpx.Client(timeout=30) as client:
                response = client.post(endpoint, json=payload, headers=headers)

                if response.status_code in [200, 201]:
                    return Message(text=json.dumps(response.json(), indent=2))
                else:
                    return Message(
                        text=json.dumps({
                            "success": False,
                            "error": f"HTTP {response.status_code}: {response.text}"
                        })
                    )
        except Exception as e:
            return Message(
                text=json.dumps({
                    "success": False,
                    "error": str(e)
                })
            )


# ==============================================================================
# 5. Paid Ads Walker Agent Component
# ==============================================================================
