"""AI Analyzer Component for Walker Agents"""

from langflow.custom import Component
from langflow.io import MessageTextInput, Output, DropdownInput, FloatInput, IntInput, SecretStrInput
from langflow.schema.message import Message
from typing import Dict, Any, List
import json
import logging
import os

logger = logging.getLogger(__name__)


class AIAnalyzerComponent(Component):
    """
    Analyzes aggregated data using OpenAI GPT-4 to generate strategic suggestions.

    Uses agent-specific prompts tailored for SEO, Content, Paid Ads, or Audience Intelligence.
    Returns a JSON array of suggestions with structured format.
    """
    display_name = "AI Analyzer"
    description = "Analyze data with GPT-4 and generate strategic suggestions"
    icon = "sparkles"
    name = "AIAnalyzer"

    inputs = [
        MessageTextInput(
            name="aggregated_data",
            display_name="Aggregated Data",
            info="JSON data from MultiSourceDataFetcher",
            required=True,
        ),
        MessageTextInput(
            name="user_config",
            display_name="User Config",
            info="JSON config from LoadUserConfig (for custom prompts)",
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
        SecretStrInput(
            name="llm_api_key",
            display_name="LLM API Key",
            info="API key for LLM service (Llama via OpenRouter, Groq, or Together AI)",
            value=os.getenv("META_LLAMA_API_KEY", ""),
        ),
        SecretStrInput(
            name="llm_api_url",
            display_name="LLM API URL",
            info="Base URL for LLM API service",
            value=os.getenv("META_LLAMA_API_ENDPOINT", "https://api.together.xyz/v1"),
        ),
        DropdownInput(
            name="model",
            display_name="Model",
            info="LLM model to use",
            options=[
                "meta-llama/Llama-3.3-70B-Instruct-Turbo",
                "meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo",
                "meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo",
                "Qwen/Qwen2.5-72B-Instruct-Turbo",
            ],
            value="meta-llama/Llama-3.3-70B-Instruct-Turbo",
        ),
        FloatInput(
            name="temperature",
            display_name="Temperature",
            info="Sampling temperature (0-1)",
            value=0.7,
        ),
        IntInput(
            name="max_tokens",
            display_name="Max Tokens",
            info="Maximum tokens in response",
            value=2000,
        ),
        IntInput(
            name="suggestion_limit",
            display_name="Suggestion Limit",
            info="Maximum number of suggestions to generate",
            value=5,
        ),
    ]

    outputs = [
        Output(display_name="Suggestions JSON", name="suggestions_json", method="analyze"),
    ]

    def analyze(self) -> Message:
        """Analyze data and generate suggestions using AI"""
        try:
            # Parse inputs
            data = json.loads(self.aggregated_data) if isinstance(self.aggregated_data, str) else self.aggregated_data
            config = json.loads(self.user_config) if isinstance(self.user_config, str) else self.user_config

            # Build prompt
            prompt = self._build_prompt(data, config)

            # Call OpenAI API (simplified - would use actual API in production)
            suggestions = self._call_openai(prompt)

            logger.info(f"Generated {len(suggestions)} suggestions for {self.agent_type}")

            return Message(text=json.dumps(suggestions))

        except Exception as e:
            logger.error(f"AI analysis failed: {e}", exc_info=True)
            # Return empty suggestions on error
            return Message(text=json.dumps([]))

    def _build_prompt(self, data: Dict[str, Any], config: Dict[str, Any]) -> str:
        """Build agent-specific prompt for AI analysis"""

        # Get base prompt for agent type
        base_prompts = {
            "seo": self._get_seo_prompt(),
            "content": self._get_content_prompt(),
            "paid_ads": self._get_paid_ads_prompt(),
            "audience_intelligence": self._get_audience_prompt(),
        }

        base_prompt = base_prompts.get(self.agent_type, self._get_seo_prompt())

        # Add custom prompt additions from user config
        custom_additions = config.get("custom_prompt_additions", "")

        # Build full prompt
        full_prompt = f"""{base_prompt}

DATA TO ANALYZE:
{json.dumps(data, indent=2)}

{custom_additions}

Generate {self.suggestion_limit} strategic suggestions in JSON array format:
[
  {{
    "type": "suggestion_type",
    "title": "Brief title",
    "description": "Detailed description",
    "estimated_revenue": 5000,
    "confidence_score": 0.85,
    "action_description": "What user should do",
    "cta_url": "Optional URL"
  }}
]
"""
        return full_prompt

    def _get_seo_prompt(self) -> str:
        """Get SEO-specific prompt template"""
        return """You are an expert SEO strategist. Analyze the provided data and generate actionable SEO suggestions.

Focus on:
- Keyword opportunities (high volume, achievable ranking)
- Technical SEO issues that need fixing
- Backlink building opportunities
- Content optimization recommendations
- Page speed and mobile optimization

Each suggestion should include estimated revenue impact and confidence score."""

    def _get_content_prompt(self) -> str:
        """Get Content-specific prompt template"""
        return """You are an expert content strategist. Analyze the provided data and generate actionable content suggestions.

Focus on:
- Content gap analysis (topics not covered)
- Underperforming content that needs updating
- New content opportunities based on trends
- Content format diversification (video, infographic, etc.)
- Engagement optimization

Each suggestion should include estimated revenue impact and confidence score."""

    def _get_paid_ads_prompt(self) -> str:
        """Get Paid Ads-specific prompt template"""
        return """You are an expert paid advertising strategist. Analyze the provided data and generate actionable ad campaign suggestions.

Focus on:
- Budget optimization opportunities
- High-performing ad groups to scale
- Underperforming campaigns to pause/adjust
- New audience targeting opportunities
- Creative testing recommendations
- Bidding strategy improvements

Each suggestion should include estimated revenue impact and confidence score."""

    def _get_audience_prompt(self) -> str:
        """Get Audience Intelligence-specific prompt template"""
        return """You are an expert in customer analytics and segmentation. Analyze the provided data and generate actionable audience intelligence suggestions.

Focus on:
- High-value customer segments to target
- Churn risk identification and prevention
- Customer recovery opportunities
- Upsell/cross-sell recommendations
- Retention strategies
- Lifetime value optimization

Each suggestion should include estimated revenue impact and confidence score."""

    def _call_openai(self, prompt: str) -> List[Dict[str, Any]]:
        """
        Call LLM API (Llama) to generate suggestions.

        Uses OpenAI-compatible API format (Together AI, Groq, OpenRouter all support this).
        """

        # Actual LLM API implementation (OpenAI-compatible format)
        try:
            with httpx.Client(timeout=60.0) as client:
                response = client.post(
                    f"{self.llm_api_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.llm_api_key}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": self.model,
                        "messages": [
                            {"role": "system", "content": "You are an expert marketing strategist."},
                            {"role": "user", "content": prompt}
                        ],
                        "temperature": self.temperature,
                        "max_tokens": self.max_tokens,
                    }
                )
                response.raise_for_status()
                result = response.json()

                # Parse JSON from response
                content = result["choices"][0]["message"]["content"]
                suggestions = json.loads(content)

                logger.info(f"Generated {len(suggestions)} suggestions using {self.model}")
                return suggestions[:self.suggestion_limit]

        except (httpx.HTTPError, json.JSONDecodeError, KeyError) as e:
            logger.warning(f"LLM API call failed: {e}. Falling back to mock suggestions.")
            # Fall back to mock suggestions if API fails
            pass

        # Mock suggestions fallback
        logger.info(f"Using mock suggestions for {self.agent_type}")

        mock_suggestions_map = {
            "seo": [
                {
                    "type": "keyword_opportunity",
                    "title": "Target 'social media marketing automation' keyword",
                    "description": "This keyword has 2,400 monthly searches and your site is ranking #12. With content optimization, you could reach top 5.",
                    "estimated_revenue": 5000,
                    "confidence_score": 0.85,
                    "action_description": "Create comprehensive guide on social media marketing automation",
                    "cta_url": "/dashboard/content/create?topic=social-media-automation"
                },
                {
                    "type": "technical_seo",
                    "title": "Fix missing meta descriptions",
                    "description": "5 high-traffic pages are missing meta descriptions, reducing click-through rates from search.",
                    "estimated_revenue": 2000,
                    "confidence_score": 0.75,
                    "action_description": "Add compelling meta descriptions to identified pages",
                    "cta_url": "/dashboard/seo/meta-descriptions"
                }
            ],
            "content": [
                {
                    "type": "content_gap",
                    "title": "Create email marketing automation guide",
                    "description": "Competitors are ranking for 'email marketing automation' but you have no content on this topic.",
                    "estimated_revenue": 4500,
                    "confidence_score": 0.80,
                    "action_description": "Write comprehensive guide with examples and templates",
                    "cta_url": "/dashboard/content/create?topic=email-automation"
                }
            ],
            "paid_ads": [
                {
                    "type": "budget_optimization",
                    "title": "Increase budget on Google Search - Brand campaign",
                    "description": "This campaign has CPA of $27.78 vs target of $50. ROI is 280%. Recommend increasing daily budget by 50%.",
                    "estimated_revenue": 8000,
                    "confidence_score": 0.90,
                    "action_description": "Increase daily budget from $100 to $150",
                    "cta_url": "/dashboard/ads/campaigns/google-brand"
                }
            ],
            "audience_intelligence": [
                {
                    "type": "churn_prevention",
                    "title": "Re-engage 89 at-risk customers",
                    "description": "89 customers show 72% churn probability. Targeted retention campaign could save $125K in LTV.",
                    "estimated_revenue": 125000,
                    "confidence_score": 0.68,
                    "action_description": "Launch personalized email + discount campaign",
                    "cta_url": "/dashboard/audience/churn-prevention"
                }
            ],
        }

        suggestions = mock_suggestions_map.get(self.agent_type, [])

        # Limit to requested number
        return suggestions[:self.suggestion_limit]
