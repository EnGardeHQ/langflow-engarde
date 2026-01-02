"""EnGarde Marketing Automation Agent Components for Langflow"""

from langflow.custom import Component
from langflow.io import MessageTextInput, SecretStrInput, IntInput, Output, DropdownInput
from langflow.schema.message import Message
import httpx
import json
import os
from datetime import datetime
from typing import Dict, Any

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
