"""Suggestion Array Formatter Component for Walker Agents"""

from langflow.custom import Component
from langflow.io import MessageTextInput, Output, DropdownInput
from langflow.schema.message import Message
from typing import Dict, Any, List
import json
import uuid
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class SuggestionArrayFormatterComponent(Component):
    """
    Formats raw AI suggestions for API submission.

    Adds required metadata:
    - UUIDs for each suggestion
    - Batch ID (groups related suggestions)
    - Timestamps
    - Priority calculation
    - Field validation
    """
    display_name = "Suggestion Array Formatter"
    description = "Format suggestions with UUIDs, timestamps, and metadata"
    icon = "list-checks"
    name = "SuggestionArrayFormatter"

    inputs = [
        MessageTextInput(
            name="suggestions_input",
            display_name="Suggestions Input",
            info="JSON array from AIAnalyzer",
            required=True,
        ),
        DropdownInput(
            name="agent_type",
            display_name="Agent Type",
            info="Type of Walker agent",
            options=["seo", "content", "paid_ads", "audience_intelligence"],
            required=True,
            value="seo",
        ),
        MessageTextInput(
            name="tenant_id",
            display_name="Tenant ID",
            info="UUID of the tenant",
            required=True,
        ),
    ]

    outputs = [
        Output(display_name="Formatted Suggestions", name="formatted_suggestions", method="format_suggestions"),
    ]

    def format_suggestions(self) -> Message:
        """Format suggestions with metadata and validation"""
        try:
            # Parse input suggestions
            suggestions = json.loads(self.suggestions_input) if isinstance(self.suggestions_input, str) else self.suggestions_input

            if not isinstance(suggestions, list):
                suggestions = [suggestions]

            # Generate batch ID for this set of suggestions
            batch_id = str(uuid.uuid4())
            timestamp = datetime.utcnow().isoformat()

            formatted = []

            for suggestion in suggestions:
                # Add metadata to each suggestion
                formatted_suggestion = {
                    "id": str(uuid.uuid4()),
                    "batch_id": batch_id,
                    "tenant_id": self.tenant_id,
                    "agent_type": self.agent_type,
                    "type": suggestion.get("type", "general"),
                    "title": suggestion.get("title", "Untitled Suggestion"),
                    "description": suggestion.get("description", ""),
                    "estimated_revenue": float(suggestion.get("estimated_revenue", 0)),
                    "confidence_score": float(suggestion.get("confidence_score", 0.5)),
                    "priority": self._calculate_priority(
                        suggestion.get("confidence_score", 0.5),
                        suggestion.get("estimated_revenue", 0)
                    ),
                    "action_description": suggestion.get("action_description", ""),
                    "cta_url": suggestion.get("cta_url", ""),
                    "status": "pending",
                    "created_at": timestamp,
                    "metadata": {
                        "source": "walker_agent",
                        "version": "1.0.0",
                    }
                }

                formatted.append(formatted_suggestion)

            result = {
                "batch_id": batch_id,
                "tenant_id": self.tenant_id,
                "agent_type": self.agent_type,
                "suggestions_count": len(formatted),
                "suggestions": formatted,
                "created_at": timestamp,
            }

            logger.info(f"Formatted {len(formatted)} suggestions with batch_id {batch_id}")

            return Message(text=json.dumps(result))

        except Exception as e:
            logger.error(f"Failed to format suggestions: {e}", exc_info=True)
            # Return empty result on error
            error_result = {
                "batch_id": str(uuid.uuid4()),
                "tenant_id": self.tenant_id,
                "agent_type": self.agent_type,
                "suggestions_count": 0,
                "suggestions": [],
                "error": str(e),
            }
            return Message(text=json.dumps(error_result))

    def _calculate_priority(self, confidence: float, revenue: float) -> str:
        """
        Calculate priority based on confidence score and estimated revenue.

        Priority Rules:
        - High: confidence >= 0.8 AND revenue >= $5,000
        - Medium: confidence >= 0.6 AND revenue >= $1,000
        - Low: everything else
        """
        if confidence >= 0.8 and revenue >= 5000:
            return "high"
        elif confidence >= 0.6 and revenue >= 1000:
            return "medium"
        else:
            return "low"
