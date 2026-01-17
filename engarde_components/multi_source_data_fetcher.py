"""Multi-Source Data Fetcher Component for Walker Agents"""

from langflow.custom import Component
from langflow.io import MessageTextInput, Output, DropdownInput, IntInput, SecretStrInput
from langflow.schema.message import Message
from typing import Dict, Any
import httpx
import json
import logging

logger = logging.getLogger(__name__)


class MultiSourceDataFetcherComponent(Component):
    """
    Fetches data from multiple sources for Walker agent analysis.

    Retrieves data from:
    - Microservice API (OnSide, Sankore, MadanSara)
    - BigQuery (historical analytics - not implemented yet)
    - ZeroDB (real-time events - not implemented yet)
    - PostgreSQL cache (not implemented yet)

    Returns aggregated JSON combining all enabled data sources.
    """
    display_name = "Multi-Source Data Fetcher"
    description = "Fetch data from microservice, BigQuery, ZeroDB, and cache"
    icon = "download"
    name = "MultiSourceDataFetcher"

    inputs = [
        MessageTextInput(
            name="user_config",
            display_name="User Config",
            info="JSON config from LoadUserConfig component",
            required=True,
        ),
        MessageTextInput(
            name="tenant_id",
            display_name="Tenant ID",
            info="UUID of the tenant",
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
        IntInput(
            name="timeout",
            display_name="Request Timeout",
            info="Timeout for each API request in seconds",
            value=30,
        ),
        SecretStrInput(
            name="onside_url",
            display_name="OnSide API URL",
            info="Base URL for OnSide microservice",
            value="http://onside:8000",
        ),
        SecretStrInput(
            name="sankore_url",
            display_name="Sankore API URL",
            info="Base URL for Sankore microservice",
            value="http://sankore:8001",
        ),
        SecretStrInput(
            name="madansara_url",
            display_name="MadanSara API URL",
            info="Base URL for MadanSara microservice",
            value="http://madansara:8002",
        ),
    ]

    outputs = [
        Output(display_name="Aggregated Data", name="aggregated_data", method="fetch_data"),
    ]

    def fetch_data(self) -> Message:
        """Fetch data from all enabled sources and aggregate"""
        try:
            # Parse user config
            config = json.loads(self.user_config) if isinstance(self.user_config, str) else self.user_config
            data_sources = config.get("data_sources", {})

            aggregated = {
                "tenant_id": self.tenant_id,
                "agent_type": self.agent_type,
                "sources": {},
            }

            # 1. Fetch from microservice (always enabled)
            if data_sources.get("microservice_enabled", True):
                microservice_data = self._fetch_microservice_data()
                aggregated["sources"]["microservice"] = microservice_data

            # 2. Fetch from BigQuery (if enabled - currently returns mock)
            if data_sources.get("bigquery_enabled", False):
                bigquery_data = self._fetch_bigquery_data()
                aggregated["sources"]["bigquery"] = bigquery_data

            # 3. Fetch from ZeroDB (if enabled - currently returns mock)
            if data_sources.get("zerodb_enabled", False):
                zerodb_data = self._fetch_zerodb_data()
                aggregated["sources"]["zerodb"] = zerodb_data

            # 4. Fetch from PostgreSQL cache (if enabled - currently returns mock)
            if data_sources.get("cache_enabled", False):
                cache_data = self._fetch_cache_data()
                aggregated["sources"]["cache"] = cache_data

            logger.info(f"Fetched data from {len(aggregated['sources'])} sources for tenant {self.tenant_id}")

            return Message(text=json.dumps(aggregated))

        except Exception as e:
            logger.error(f"Failed to fetch data: {e}", exc_info=True)
            # Return minimal data structure on error
            error_response = {
                "tenant_id": self.tenant_id,
                "agent_type": self.agent_type,
                "sources": {
                    "error": str(e),
                },
            }
            return Message(text=json.dumps(error_response))

    def _fetch_microservice_data(self) -> Dict[str, Any]:
        """Fetch data from appropriate microservice based on agent type"""
        try:
            # Determine which microservice to call
            endpoint_map = {
                "seo": (self.onside_url, "/api/v1/seo/analyze"),
                "content": (self.onside_url, "/api/v1/content/analyze"),
                "paid_ads": (self.sankore_url, "/api/v1/ads/analyze"),
                "audience_intelligence": (self.madansara_url, "/api/v1/audience/analyze"),
            }

            base_url, path = endpoint_map.get(self.agent_type, (self.onside_url, "/api/v1/seo/analyze"))
            url = f"{base_url}{path}/{self.tenant_id}"

            # Make HTTP request
            with httpx.Client(timeout=self.timeout) as client:
                response = client.get(url)
                response.raise_for_status()
                return response.json()

        except httpx.HTTPError as e:
            logger.warning(f"Microservice request failed: {e}. Returning mock data.")
            return self._get_mock_microservice_data()
        except Exception as e:
            logger.error(f"Unexpected error fetching microservice data: {e}")
            return {"error": str(e)}

    def _fetch_bigquery_data(self) -> Dict[str, Any]:
        """Fetch historical analytics from BigQuery (not implemented - returns mock)"""
        logger.info("BigQuery integration not implemented yet, returning mock data")
        return {
            "note": "BigQuery integration pending",
            "mock_data": True,
            "historical_metrics": [],
        }

    def _fetch_zerodb_data(self) -> Dict[str, Any]:
        """Fetch real-time events from ZeroDB (not implemented - returns mock)"""
        logger.info("ZeroDB integration not implemented yet, returning mock data")
        return {
            "note": "ZeroDB integration pending",
            "mock_data": True,
            "realtime_events": [],
        }

    def _fetch_cache_data(self) -> Dict[str, Any]:
        """Fetch cached suggestions from PostgreSQL (not implemented - returns mock)"""
        logger.info("PostgreSQL cache integration not implemented yet, returning mock data")
        return {
            "note": "Cache integration pending",
            "mock_data": True,
            "cached_suggestions": [],
        }

    def _get_mock_microservice_data(self) -> Dict[str, Any]:
        """Return mock microservice data for development/testing"""
        mock_data_map = {
            "seo": {
                "tenant_id": self.tenant_id,
                "keywords": [
                    {"keyword": "social media marketing", "position": 5, "volume": 2400},
                    {"keyword": "content marketing strategy", "position": 12, "volume": 1600},
                ],
                "backlinks": {"total": 145, "new_this_month": 12},
                "technical_issues": ["Missing meta descriptions on 5 pages"],
            },
            "content": {
                "tenant_id": self.tenant_id,
                "content_gaps": [
                    {"topic": "Email marketing automation", "priority": "high"},
                    {"topic": "Social media analytics", "priority": "medium"},
                ],
                "top_performing": ["Blog post: 10 Marketing Tips"],
            },
            "paid_ads": {
                "tenant_id": self.tenant_id,
                "campaigns": [
                    {"name": "Google Search - Brand", "spend": 1250, "conversions": 45, "cpa": 27.78},
                ],
                "opportunities": ["Increase budget on high-performing ad group"],
            },
            "audience_intelligence": {
                "tenant_id": self.tenant_id,
                "segments": [
                    {"name": "High-value customers", "size": 234, "ltv": 5600},
                    {"name": "At-risk churn", "size": 89, "churn_probability": 0.72},
                ],
            },
        }

        return mock_data_map.get(self.agent_type, {"tenant_id": self.tenant_id, "data": "mock"})
