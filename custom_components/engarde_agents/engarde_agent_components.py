"""
EnGarde Marketing Automation Agent Components for Langflow

These components provide marketing automation workflows for EnGarde platform.
"""

from langflow.custom import Component
from langflow.io import MessageTextInput, SecretStrInput, IntInput, Output, DropdownInput
from langflow.schema.message import Message
import httpx
import json
import os
from datetime import datetime
from typing import Dict, Any


class CampaignCreationAgentComponent(Component):
    display_name = "Campaign Creation Agent"
    description = "Automatically creates marketing campaigns via EnGarde API"
    icon = "rocket"

    inputs = [
        MessageTextInput(
            name="tenant_id",
            display_name="Tenant ID",
            info="UUID of the tenant",
            required=True
        ),
        MessageTextInput(
            name="campaign_name",
            display_name="Campaign Name",
            info="Name for the new campaign",
            required=True
        ),
        MessageTextInput(
            name="campaign_type",
            display_name="Campaign Type",
            info="Type of campaign (e.g., email, social, ads)",
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
        """Create a campaign via API"""

        payload = {
            "tenant_id": self.tenant_id,
            "name": self.campaign_name,
            "type": self.campaign_type,
            "status": "draft",
            "created_by": "engarde_agent",
            "created_at": datetime.utcnow().isoformat() + "Z"
        }

        api_url = os.getenv("ENGARDE_API_URL", self.api_url)
        api_key = os.getenv("ENGARDE_API_KEY", self.api_key)

        endpoint = f"{api_url}/api/v1/campaigns"
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


class AnalyticsReportAgentComponent(Component):
    display_name = "Analytics Report Agent"
    description = "Fetches analytics data and generates insights"
    icon = "bar-chart"

    inputs = [
        MessageTextInput(
            name="tenant_id",
            display_name="Tenant ID",
            info="UUID of the tenant",
            required=True
        ),
        IntInput(
            name="days_back",
            display_name="Days Back",
            info="Number of days to look back for analytics",
            value=30
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
        """Fetch analytics data"""

        api_url = os.getenv("ENGARDE_API_URL", self.api_url)
        api_key = os.getenv("ENGARDE_API_KEY", self.api_key)

        endpoint = f"{api_url}/api/v1/analytics/{self.tenant_id}?days={self.days_back}"
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }

        try:
            with httpx.Client(timeout=30) as client:
                response = client.get(endpoint, headers=headers)

                if response.status_code == 200:
                    result = response.json()

                    # Add insights
                    result["insights"] = {
                        "generated_at": datetime.utcnow().isoformat() + "Z",
                        "period_days": self.days_back,
                        "summary": "Analytics data retrieved successfully"
                    }

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


class ContentApprovalAgentComponent(Component):
    display_name = "Content Approval Agent"
    description = "Handles content approval workflow"
    icon = "check-circle"

    inputs = [
        MessageTextInput(
            name="content_id",
            display_name="Content ID",
            info="UUID of the content to approve/reject",
            required=True
        ),
        DropdownInput(
            name="action",
            display_name="Action",
            info="Approve or reject",
            options=["approve", "reject"],
            value="approve"
        ),
        MessageTextInput(
            name="notes",
            display_name="Notes",
            info="Optional notes for approval/rejection",
            value=""
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
        """Approve or reject content"""

        payload = {
            "action": self.action,
            "notes": self.notes,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "approved_by": "engarde_agent"
        }

        api_url = os.getenv("ENGARDE_API_URL", self.api_url)
        api_key = os.getenv("ENGARDE_API_KEY", self.api_key)

        endpoint = f"{api_url}/api/v1/content/{self.content_id}/{self.action}"
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


class CampaignLauncherAgentComponent(Component):
    display_name = "Scheduled Campaign Launcher"
    description = "Launches scheduled/draft campaigns"
    icon = "play"

    inputs = [
        MessageTextInput(
            name="campaign_id",
            display_name="Campaign ID",
            info="UUID of the campaign to launch",
            required=True
        ),
        MessageTextInput(
            name="launch_time",
            display_name="Launch Time",
            info="ISO 8601 timestamp for launch (or 'now')",
            value="now"
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
        """Launch a campaign"""

        launch_timestamp = datetime.utcnow().isoformat() + "Z" if self.launch_time == "now" else self.launch_time

        payload = {
            "status": "active",
            "launched_at": launch_timestamp,
            "launched_by": "engarde_agent"
        }

        api_url = os.getenv("ENGARDE_API_URL", self.api_url)
        api_key = os.getenv("ENGARDE_API_KEY", self.api_key)

        endpoint = f"{api_url}/api/v1/campaigns/{self.campaign_id}/launch"
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


class NotificationAgentComponent(Component):
    display_name = "Multi-Channel Notification Agent"
    description = "Sends notifications via email, WhatsApp, or in-app"
    icon = "bell"

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


class PerformanceMonitoringAgentComponent(Component):
    display_name = "Performance Monitoring Agent"
    description = "Monitors campaign performance and triggers alerts"
    icon = "activity"

    inputs = [
        MessageTextInput(
            name="campaign_id",
            display_name="Campaign ID",
            info="UUID of the campaign to monitor",
            required=True
        ),
        IntInput(
            name="threshold_clicks",
            display_name="Click Threshold",
            info="Alert if clicks below this number",
            value=100
        ),
        IntInput(
            name="threshold_conversions",
            display_name="Conversion Threshold",
            info="Alert if conversions below this number",
            value=10
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
        """Monitor campaign performance"""

        api_url = os.getenv("ENGARDE_API_URL", self.api_url)
        api_key = os.getenv("ENGARDE_API_KEY", self.api_key)

        endpoint = f"{api_url}/api/v1/campaigns/{self.campaign_id}/metrics"
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }

        try:
            with httpx.Client(timeout=30) as client:
                response = client.get(endpoint, headers=headers)

                if response.status_code == 200:
                    metrics = response.json()

                    # Check thresholds
                    alerts = []
                    if metrics.get("clicks", 0) < self.threshold_clicks:
                        alerts.append(f"Clicks ({metrics.get('clicks', 0)}) below threshold ({self.threshold_clicks})")

                    if metrics.get("conversions", 0) < self.threshold_conversions:
                        alerts.append(f"Conversions ({metrics.get('conversions', 0)}) below threshold ({self.threshold_conversions})")

                    result = {
                        "success": True,
                        "campaign_id": self.campaign_id,
                        "metrics": metrics,
                        "alerts": alerts,
                        "alert_triggered": len(alerts) > 0,
                        "checked_at": datetime.utcnow().isoformat() + "Z"
                    }

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
