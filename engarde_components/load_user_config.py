"""Load User Config Component for Walker Agents"""

from langflow.custom import Component
from langflow.io import MessageTextInput, Output, DropdownInput, SecretStrInput, BoolInput
from langflow.schema.message import Message
from typing import Dict, Any
import json
import os
import logging

logger = logging.getLogger(__name__)


class LoadUserConfigComponent(Component):
    """
    Loads user-specific Walker agent configuration from database.

    This component retrieves customized settings for a specific tenant and agent type,
    including data source preferences, AI model settings, and custom prompt additions.
    Creates default configuration if none exists.
    """
    display_name = "Load User Config"
    description = "Load user-specific Walker agent configuration with defaults"
    icon = "database"
    name = "LoadUserConfig"

    inputs = [
        MessageTextInput(
            name="tenant_id",
            display_name="Tenant ID",
            info="UUID of the tenant to load config for",
            required=True,
            placeholder="e.g., 123e4567-e89b-12d3-a456-426614174000",
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
            name="flow_version",
            display_name="Flow Version",
            info="Semantic version of this flow (e.g., 1.0.0)",
            value="1.0.0",
        ),
        SecretStrInput(
            name="database_url",
            display_name="Database URL",
            info="PostgreSQL connection string",
            value=os.getenv("DATABASE_PUBLIC_URL", ""),
        ),
        BoolInput(
            name="create_if_missing",
            display_name="Create If Missing",
            info="Create default config if user config doesn't exist",
            value=True,
        ),
    ]

    outputs = [
        Output(display_name="Config", name="config", method="load_config"),
    ]

    def load_config(self) -> Message:
        """Load user configuration or create default"""
        try:
            # For now, return a default configuration structure
            # In production, this would query the database
            config = self._create_default_config()

            logger.info(f"Loaded config for tenant {self.tenant_id}, agent {self.agent_type}")

            return Message(text=json.dumps(config))

        except Exception as e:
            logger.error(f"Failed to load config: {e}", exc_info=True)
            # Return minimal config on error
            fallback_config = self._create_minimal_config()
            return Message(text=json.dumps(fallback_config))

    def _create_default_config(self) -> Dict[str, Any]:
        """Create default configuration for user"""
        return {
            "version": self.flow_version,
            "tenant_id": self.tenant_id,
            "agent_type": self.agent_type,
            "data_sources": {
                "microservice_enabled": True,
                "bigquery_enabled": False,  # Not implemented yet
                "zerodb_enabled": False,    # Not implemented yet
                "cache_enabled": False,     # Not implemented yet
            },
            "ai_settings": {
                "model": "gpt-4",
                "temperature": 0.7,
                "max_tokens": 2000,
                "suggestion_limit": 5,
            },
            "custom_prompt_additions": "",
            "filters": {
                "min_confidence_score": 0.6,
                "min_revenue_increase": 1000,
            },
            "notification_preferences": {
                "email_enabled": True,
                "whatsapp_enabled": False,
                "chat_enabled": True,
            },
        }

    def _create_minimal_config(self) -> Dict[str, Any]:
        """Create minimal fallback configuration"""
        return {
            "version": self.flow_version,
            "tenant_id": self.tenant_id,
            "agent_type": self.agent_type,
            "data_sources": {
                "microservice_enabled": True,
                "bigquery_enabled": False,
                "zerodb_enabled": False,
                "cache_enabled": False,
            },
            "ai_settings": {
                "model": "gpt-4",
                "temperature": 0.7,
                "max_tokens": 2000,
                "suggestion_limit": 5,
            },
        }
