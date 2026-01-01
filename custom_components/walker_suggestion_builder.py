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
