"""
EnGarde Custom Components for Langflow
Walker Agent components for social media campaign intelligence
"""

# Import new modular components
from .load_user_config import LoadUserConfigComponent
from .multi_source_data_fetcher import MultiSourceDataFetcherComponent
from .ai_analyzer import AIAnalyzerComponent
from .suggestion_array_formatter import SuggestionArrayFormatterComponent
from .current_brand_tenant import CurrentBrandTenantComponent
from .user_interaction_handler import UserInteractionHandlerComponent

# Import existing components
from .tenant_id_input import TenantIDInputComponent
from .walker_suggestion_builder import WalkerSuggestionBuilderComponent
from .walker_agent_api import WalkerAgentAPIComponent
from .seo_walker_agent import SEOWalkerAgentComponent
from .paid_ads_walker_agent import PaidAdsWalkerAgentComponent
from .content_walker_agent import ContentWalkerAgentComponent
from .audience_intelligence_walker_agent import AudienceIntelligenceWalkerAgentComponent
from .campaign_creation_agent import CampaignCreationAgentComponent
from .campaign_launcher_agent import CampaignLauncherAgentComponent
from .content_approval_agent import ContentApprovalAgentComponent
from .notification_agent import NotificationAgentComponent
from .analytics_report_agent import AnalyticsReportAgentComponent
from .performance_monitoring_agent import PerformanceMonitoringAgentComponent

__all__ = [
    # New modular components (flow building blocks)
    "LoadUserConfigComponent",
    "MultiSourceDataFetcherComponent",
    "AIAnalyzerComponent",
    "SuggestionArrayFormatterComponent",
    "CurrentBrandTenantComponent",
    "UserInteractionHandlerComponent",
    # Existing helper components
    "TenantIDInputComponent",
    "WalkerSuggestionBuilderComponent",
    "WalkerAgentAPIComponent",
    # Complete agent components
    "SEOWalkerAgentComponent",
    "PaidAdsWalkerAgentComponent",
    "ContentWalkerAgentComponent",
    "AudienceIntelligenceWalkerAgentComponent",
    "CampaignCreationAgentComponent",
    "CampaignLauncherAgentComponent",
    "ContentApprovalAgentComponent",
    "NotificationAgentComponent",
    "AnalyticsReportAgentComponent",
    "PerformanceMonitoringAgentComponent",
]
