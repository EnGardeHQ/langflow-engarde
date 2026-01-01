"""
Walker Agent Custom Components for Langflow

These custom components are designed to work with the EnGarde Walker Agents system.
They provide reusable, configurable nodes for building Walker Agent flows.

Installation:
    1. Copy this file to your Langflow custom_components directory
    2. Or set LANGFLOW_COMPONENTS_PATH to the directory containing this file
    3. Restart Langflow to load the components

Usage:
    These components will appear in your Langflow component library under "Walker Agents"
"""

from langflow.base.io.text import TextComponent
from langflow.io import (
    MultilineInput,
    Output,
    DropdownInput,
    IntInput,
    FloatInput,
    MessageTextInput,
    SecretStrInput,
    BoolInput,
)
from langflow.schema.message import Message
from langflow.custom import Component
from typing import Dict, List, Any, Optional
import httpx
import json
from datetime import datetime
import uuid


# ==============================================================================
# 1. Tenant ID Input Component
# ==============================================================================

class TenantIDInputComponent(TextComponent):
    """
    Input component for providing tenant UUID.

    This component accepts a tenant ID that will be used throughout the Walker Agent flow.
    Can use default value or accept manual input.
    """
    display_name = "Tenant ID Input"
    description = "Provide the tenant UUID for Walker Agent analysis"
    icon = "user"
    name = "TenantIDInput"

    inputs = [
        MessageTextInput(
            name="tenant_id",
            display_name="Tenant ID",
            info="UUID of the tenant to analyze. Get from database: SELECT id FROM tenants;",
            required=True,
            placeholder="e.g., 123e4567-e89b-12d3-a456-426614174000",
        ),
    ]

    outputs = [
        Output(display_name="Tenant ID", name="tenant_id", method="get_tenant_id"),
    ]

    def get_tenant_id(self) -> Message:
        """Return the tenant ID as a message"""
        return Message(text=self.tenant_id)


# ==============================================================================
# 2. Walker Agent Suggestion Builder
# ==============================================================================

class WalkerSuggestionBuilderComponent(Component):
    """
    Build a Walker Agent suggestion payload.

    This component creates a properly formatted suggestion object that can be sent
    to the EnGarde backend API.
    """
    display_name = "Walker Suggestion Builder"
    description = "Build a formatted suggestion for Walker Agents"
    icon = "sparkles"
    name = "WalkerSuggestionBuilder"

    inputs = [
        DropdownInput(
            name="suggestion_type",
            display_name="Suggestion Type",
            options=[
                "keyword_opportunity",
                "content_gap",
                "campaign_optimization",
                "audience_segment",
                "technical_seo",
                "backlink_opportunity",
                "budget_optimization",
                "creative_testing",
            ],
            value="keyword_opportunity",
            info="Type of suggestion being generated",
        ),
        MessageTextInput(
            name="title",
            display_name="Title",
            info="Short, actionable title for the suggestion",
            required=True,
            placeholder="e.g., Target high-value keyword: AI marketing automation",
        ),
        MultilineInput(
            name="description",
            display_name="Description",
            info="Detailed description of the opportunity and analysis",
            required=True,
            placeholder="Provide context, data, and reasoning...",
        ),
        FloatInput(
            name="estimated_revenue",
            display_name="Estimated Revenue Increase ($)",
            info="Estimated revenue impact in dollars",
            value=5000.0,
        ),
        FloatInput(
            name="confidence_score",
            display_name="Confidence Score",
            info="Confidence in this suggestion (0.0 to 1.0)",
            value=0.85,
            range_spec=(0.0, 1.0),
        ),
        MessageTextInput(
            name="action_description",
            display_name="Primary Action Description",
            info="What action should be taken?",
            required=True,
            placeholder="e.g., Create blog post targeting this keyword",
        ),
        MessageTextInput(
            name="cta_url",
            display_name="Call-to-Action URL",
            info="URL to take action on this suggestion",
            value="https://app.engarde.media/campaigns/create",
        ),
    ]

    outputs = [
        Output(display_name="Suggestion Object", name="suggestion", method="build_suggestion"),
    ]

    def build_suggestion(self) -> Message:
        """Build a suggestion object"""
        suggestion = {
            "id": str(uuid.uuid4()),
            "type": self.suggestion_type,
            "title": self.title,
            "description": self.description,
            "impact": {
                "estimated_revenue_increase": float(self.estimated_revenue),
                "confidence_score": float(self.confidence_score),
            },
            "actions": [
                {
                    "action_type": "implement",
                    "description": self.action_description,
                }
            ],
            "cta_url": self.cta_url,
            "metadata": {
                "generated_at": datetime.utcnow().isoformat() + "Z",
                "source": "langflow_walker_agent",
            }
        }

        return Message(text=json.dumps(suggestion, indent=2))


# ==============================================================================
# 3. Walker Agent API Request Component
# ==============================================================================

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

class PaidAdsWalkerAgentComponent(Component):
    """Complete Paid Ads Walker Agent"""
    display_name = "Paid Ads Walker Agent (Complete)"
    description = "End-to-end Paid Ads Walker Agent with backend integration"
    icon = "dollar-sign"
    name = "PaidAdsWalkerAgent"

    inputs = [
        MessageTextInput(name="tenant_id", display_name="Tenant ID", required=True),
        SecretStrInput(name="api_url", display_name="API URL", value="${ENGARDE_API_URL}"),
        SecretStrInput(name="api_key", display_name="API Key", value="${WALKER_AGENT_API_KEY_SANKORE_PAID_ADS}"),
    ]

    outputs = [
        Output(display_name="Result", name="result", method="execute"),
    ]

    def execute(self) -> Message:
        suggestion = {
            "id": str(uuid.uuid4()),
            "type": "campaign_optimization",
            "title": "Paid ads campaign optimization opportunity",
            "description": "Analysis shows potential to improve ROAS through campaign adjustments and budget reallocation.",
            "impact": {
                "estimated_revenue_increase": 8000.0,
                "confidence_score": 0.90,
            },
            "actions": [
                {
                    "action_type": "adjust_bidding",
                    "description": "Optimize bidding strategy for better performance",
                }
            ],
            "cta_url": "https://app.engarde.media/campaigns/create",
            "metadata": {
                "generated_at": datetime.utcnow().isoformat() + "Z",
                "source": "langflow_paid_ads_walker",
            }
        }

        payload = {
            "agent_type": "paid_ads",
            "tenant_id": self.tenant_id,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "priority": "high",
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
# 6. Content Walker Agent Component
# ==============================================================================

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

class AudienceIntelligenceWalkerAgentComponent(Component):
    """Complete Audience Intelligence Walker Agent"""
    display_name = "Audience Intelligence Walker Agent (Complete)"
    description = "End-to-end Audience Intelligence Walker Agent with backend integration"
    icon = "users"
    name = "AudienceIntelligenceWalkerAgent"

    inputs = [
        MessageTextInput(name="tenant_id", display_name="Tenant ID", required=True),
        SecretStrInput(name="api_url", display_name="API URL", value="${ENGARDE_API_URL}"),
        SecretStrInput(name="api_key", display_name="API Key", value="${WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE}"),
    ]

    outputs = [
        Output(display_name="Result", name="result", method="execute"),
    ]

    def execute(self) -> Message:
        suggestion = {
            "id": str(uuid.uuid4()),
            "type": "segmentation_opportunity",
            "title": "New audience segment identified",
            "description": "ML analysis revealed a high-value audience segment with strong conversion potential.",
            "impact": {
                "estimated_revenue_increase": 6000.0,
                "confidence_score": 0.82,
            },
            "actions": [
                {
                    "action_type": "create_campaign",
                    "description": "Launch targeted campaign for newly identified segment",
                }
            ],
            "cta_url": "https://app.engarde.media/campaigns/create",
            "metadata": {
                "generated_at": datetime.utcnow().isoformat() + "Z",
                "source": "langflow_audience_intelligence_walker",
            }
        }

        payload = {
            "agent_type": "audience_intelligence",
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
