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
