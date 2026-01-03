# Production-Ready EnGarde Agents - Marketing Automation

**6 EnGarde automation agents with full lakehouse, BigQuery, and ZeroDB integration**

---

## Agent 5: Campaign Creation Agent (Production-Ready)

**Purpose**: Automatically creates and configures marketing campaigns based on templates and strategies

**Data Sources**:
- Lakehouse: Campaign templates, historical campaign performance
- BigQuery: Best-performing campaign configurations
- ZeroDB: Real-time campaign performance baselines

```python
def run(tenant_id: str, campaign_name: str = None, campaign_type: str = "email") -> dict:
    """
    Production-ready Campaign Creation Agent
    Auto-creates campaigns using best-practice templates and data-driven configuration
    """
    import os
    import httpx
    import json
    from datetime import datetime, timedelta
    from google.cloud import bigquery
    from google.oauth2 import service_account
    import psycopg2
    from typing import List, Dict, Any

    # ====================CONFIGURATION ====================

    engarde_api_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    lakehouse_api_url = os.getenv("LAKEHOUSE_API_URL", "https://lakehouse.engarde.media")

    engarde_api_key = os.getenv("ENGARDE_API_KEY")
    lakehouse_api_key = os.getenv("LAKEHOUSE_API_KEY")

    bq_project_id = os.getenv("BIGQUERY_PROJECT_ID", "engarde-production")
    bq_dataset_id = os.getenv("BIGQUERY_DATASET_ID", "marketing_analytics")
    bq_credentials_json = os.getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON")

    zerodb_config = {
        "host": os.getenv("ZERODB_HOST", "zerodb.engarde.media"),
        "port": int(os.getenv("ZERODB_PORT", "5432")),
        "database": os.getenv("ZERODB_DATABASE", "engarde_operational"),
        "user": os.getenv("ZERODB_USER", "engarde_app"),
        "password": os.getenv("ZERODB_PASSWORD")
    }

    # ==================== STEP 1: FETCH TEMPLATES FROM LAKEHOUSE ====================

    print(f"[Campaign Creation] Fetching campaign templates for tenant: {tenant_id}")

    lakehouse_headers = {
        "Authorization": f"Bearer {lakehouse_api_key}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=60) as client:
            # Fetch campaign templates by type
            templates_response = client.get(
                f"{lakehouse_api_url}/api/v1/tenants/{tenant_id}/campaigns/templates?type={campaign_type}",
                headers=lakehouse_headers
            )
            templates_data = templates_response.json() if templates_response.status_code == 200 else {"templates": []}

            # Fetch tenant's brand guidelines
            brand_response = client.get(
                f"{lakehouse_api_url}/api/v1/tenants/{tenant_id}/brand/guidelines",
                headers=lakehouse_headers
            )
            brand_data = brand_response.json() if brand_response.status_code == 200 else {}

            # Fetch historical campaign performance
            history_response = client.get(
                f"{lakehouse_api_url}/api/v1/tenants/{tenant_id}/campaigns/history?type={campaign_type}",
                headers=lakehouse_headers
            )
            history_data = history_response.json() if history_response.status_code == 200 else {"campaigns": []}

    except Exception as e:
        print(f"[Campaign Creation] Lakehouse error: {str(e)}")
        templates_data = {"templates": []}
        brand_data = {}
        history_data = {"campaigns": []}

    # ==================== STEP 2: QUERY BIGQUERY FOR BEST PRACTICES ====================

    print(f"[Campaign Creation] Querying BigQuery for optimal campaign configuration")

    best_performing_configs = []

    try:
        if bq_credentials_json:
            credentials_dict = json.loads(bq_credentials_json)
            credentials = service_account.Credentials.from_service_account_info(credentials_dict)
            bq_client = bigquery.Client(credentials=credentials, project=bq_project_id)
        else:
            bq_client = bigquery.Client(project=bq_project_id)

        # Query best-performing campaign configurations
        config_query = f"""
        SELECT
            campaign_type,
            subject_line_pattern,
            send_time_hour,
            send_day_of_week,
            avg_open_rate,
            avg_click_rate,
            avg_conversion_rate,
            audience_segment,
            content_length,
            cta_count
        FROM `{bq_project_id}.{bq_dataset_id}.campaign_performance_analysis`
        WHERE tenant_id = @tenant_id
            AND campaign_type = @campaign_type
            AND avg_open_rate > 0.20
        ORDER BY avg_conversion_rate DESC
        LIMIT 10
        """

        job_config = bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter("tenant_id", "STRING", tenant_id),
                bigquery.ScalarQueryParameter("campaign_type", "STRING", campaign_type)
            ]
        )

        config_results = bq_client.query(config_query, job_config=job_config).result()
        best_performing_configs = [dict(row) for row in config_results]

    except Exception as e:
        print(f"[Campaign Creation] BigQuery error: {str(e)}")

    # ==================== STEP 3: GET BASELINE METRICS FROM ZERODB ====================

    print(f"[Campaign Creation] Fetching baseline metrics from ZeroDB")

    baseline_metrics = {}

    try:
        conn = psycopg2.connect(**zerodb_config)
        cur = conn.cursor()

        # Get industry/tenant baseline metrics
        cur.execute("""
            SELECT
                metric_name,
                metric_value,
                industry_benchmark,
                tenant_average
            FROM campaign_baseline_metrics
            WHERE tenant_id = %s
                AND campaign_type = %s
            ORDER BY updated_at DESC
            LIMIT 20
        """, (tenant_id, campaign_type))

        for row in cur.fetchall():
            baseline_metrics[row[0]] = {
                "value": float(row[1]) if row[1] else 0,
                "industry_benchmark": float(row[2]) if row[2] else 0,
                "tenant_average": float(row[3]) if row[3] else 0
            }

        cur.close()
        conn.close()

    except Exception as e:
        print(f"[Campaign Creation] ZeroDB error: {str(e)}")

    # ==================== STEP 4: BUILD OPTIMAL CAMPAIGN ====================

    print(f"[Campaign Creation] Building optimal campaign configuration")

    # Determine best configuration from BigQuery data
    if best_performing_configs:
        best_config = best_performing_configs[0]
        send_time_hour = best_config.get('send_time_hour', 10)
        send_day = best_config.get('send_day_of_week', 'Tuesday')
        target_segment = best_config.get('audience_segment', 'all_subscribers')
        content_length_target = best_config.get('content_length', 500)
        cta_count_target = best_config.get('cta_count', 2)
    else:
        # Use industry defaults
        send_time_hour = 10
        send_day = 'Tuesday'
        target_segment = 'all_subscribers'
        content_length_target = 500
        cta_count_target = 2

    # Select best template
    if templates_data.get('templates'):
        # Choose highest performing template
        templates = templates_data.get('templates', [])
        best_template = max(templates, key=lambda t: t.get('historical_conversion_rate', 0))
        template_id = best_template.get('id')
        template_name = best_template.get('name', 'Default Template')
    else:
        template_id = None
        template_name = 'New Campaign'

    # Generate campaign name if not provided
    if not campaign_name:
        campaign_name = f"{campaign_type.title()} Campaign - {datetime.utcnow().strftime('%Y-%m-%d')}"

    # Build campaign payload
    campaign_payload = {
        "tenant_id": tenant_id,
        "name": campaign_name,
        "type": campaign_type,
        "status": "draft",
        "template_id": template_id,
        "template_name": template_name,
        "configuration": {
            "send_time_hour": send_time_hour,
            "send_day_of_week": send_day,
            "target_segment": target_segment,
            "content_length_words": content_length_target,
            "cta_count": cta_count_target,
            "personalization_enabled": True,
            "ab_test_enabled": True,
            "ab_test_variants": 2
        },
        "targeting": {
            "segment": target_segment,
            "exclude_recent_recipients": True,
            "exclude_days": 7,
            "max_frequency_per_week": 3
        },
        "goals": {
            "target_open_rate": baseline_metrics.get('open_rate', {}).get('tenant_average', 0.25),
            "target_click_rate": baseline_metrics.get('click_rate', {}).get('tenant_average', 0.05),
            "target_conversion_rate": baseline_metrics.get('conversion_rate', {}).get('tenant_average', 0.02)
        },
        "brand_guidelines": {
            "primary_color": brand_data.get('primary_color', '#000000'),
            "secondary_color": brand_data.get('secondary_color', '#FFFFFF'),
            "font_family": brand_data.get('font_family', 'Arial'),
            "tone_of_voice": brand_data.get('tone_of_voice', 'professional')
        },
        "created_by": "engarde_campaign_creation_agent",
        "created_at": datetime.utcnow().isoformat() + "Z"
    }

    # ==================== STEP 5: CREATE CAMPAIGN VIA API ====================

    print(f"[Campaign Creation] Creating campaign via EnGarde API")

    engarde_headers = {
        "Authorization": f"Bearer {engarde_api_key}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=60) as client:
            response = client.post(
                f"{engarde_api_url}/api/v1/campaigns",
                json=campaign_payload,
                headers=engarde_headers
            )

            if response.status_code in [200, 201]:
                campaign_result = response.json()
                campaign_id = campaign_result.get('id')

                return {
                    "success": True,
                    "tenant_id": tenant_id,
                    "campaign_id": campaign_id,
                    "campaign_name": campaign_name,
                    "campaign_type": campaign_type,
                    "status": "draft",
                    "configuration": campaign_payload["configuration"],
                    "targeting": campaign_payload["targeting"],
                    "goals": campaign_payload["goals"],
                    "template_used": template_name,
                    "data_driven_optimizations": {
                        "send_time_optimized": bool(best_performing_configs),
                        "segment_optimized": bool(best_performing_configs),
                        "content_length_optimized": bool(best_performing_configs),
                        "template_optimized": bool(templates_data.get('templates'))
                    },
                    "created_at": datetime.utcnow().isoformat() + "Z"
                }
            else:
                return {
                    "success": False,
                    "error": f"HTTP {response.status_code}: {response.text}",
                    "tenant_id": tenant_id
                }

    except Exception as e:
        print(f"[Campaign Creation] API error: {str(e)}")
        return {
            "success": False,
            "error": str(e),
            "tenant_id": tenant_id
        }
```

---

## Agent 6: Analytics Report Agent (Production-Ready)

**Purpose**: Generates comprehensive marketing analytics reports from all data sources

**Data Sources**:
- Lakehouse: Campaign metrics, content performance
- BigQuery: Historical trends, cohort analysis, attribution modeling
- ZeroDB: Real-time KPIs, live dashboard data

```python
def run(tenant_id: str, report_type: str = "monthly", days_back: int = 30) -> dict:
    """
    Production-ready Analytics Report Agent
    Generates comprehensive data-driven marketing reports
    """
    import os
    import httpx
    import json
    from datetime import datetime, timedelta
    from google.cloud import bigquery
    from google.oauth2 import service_account
    import psycopg2
    from typing import List, Dict, Any

    # ==================== CONFIGURATION ====================

    engarde_api_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    lakehouse_api_url = os.getenv("LAKEHOUSE_API_URL", "https://lakehouse.engarde.media")

    engarde_api_key = os.getenv("ENGARDE_API_KEY")
    lakehouse_api_key = os.getenv("LAKEHOUSE_API_KEY")

    bq_project_id = os.getenv("BIGQUERY_PROJECT_ID", "engarde-production")
    bq_dataset_id = os.getenv("BIGQUERY_DATASET_ID", "marketing_analytics")
    bq_credentials_json = os.getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON")

    zerodb_config = {
        "host": os.getenv("ZERODB_HOST", "zerodb.engarde.media"),
        "port": int(os.getenv("ZERODB_PORT", "5432")),
        "database": os.getenv("ZERODB_DATABASE", "engarde_operational"),
        "user": os.getenv("ZERODB_USER", "engarde_app"),
        "password": os.getenv("ZERODB_PASSWORD")
    }

    # ==================== STEP 1: FETCH CAMPAIGN METRICS FROM LAKEHOUSE ====================

    print(f"[Analytics Report] Fetching campaign data for tenant: {tenant_id}")

    lakehouse_headers = {
        "Authorization": f"Bearer {lakehouse_api_key}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=60) as client:
            # Fetch overall campaign performance
            campaigns_response = client.get(
                f"{lakehouse_api_url}/api/v1/tenants/{tenant_id}/analytics/campaigns?days={days_back}",
                headers=lakehouse_headers
            )
            campaigns_data = campaigns_response.json() if campaigns_response.status_code == 200 else {}

            # Fetch channel performance
            channels_response = client.get(
                f"{lakehouse_api_url}/api/v1/tenants/{tenant_id}/analytics/channels?days={days_back}",
                headers=lakehouse_headers
            )
            channels_data = channels_response.json() if channels_response.status_code == 200 else {}

            # Fetch content performance
            content_response = client.get(
                f"{lakehouse_api_url}/api/v1/tenants/{tenant_id}/analytics/content?days={days_back}",
                headers=lakehouse_headers
            )
            content_data = content_response.json() if content_response.status_code == 200 else {}

    except Exception as e:
        print(f"[Analytics Report] Lakehouse error: {str(e)}")
        campaigns_data = {}
        channels_data = {}
        content_data = {}

    # ==================== STEP 2: QUERY BIGQUERY FOR TRENDS & ATTRIBUTION ====================

    print(f"[Analytics Report] Querying BigQuery for trends and attribution")

    trend_data = []
    attribution_data = []
    cohort_data = []

    try:
        if bq_credentials_json:
            credentials_dict = json.loads(bq_credentials_json)
            credentials = service_account.Credentials.from_service_account_info(credentials_dict)
            bq_client = bigquery.Client(credentials=credentials, project=bq_project_id)
        else:
            bq_client = bigquery.Client(project=bq_project_id)

        # Query performance trends
        trend_query = f"""
        SELECT
            date,
            channel,
            total_spend,
            total_revenue,
            total_conversions,
            total_clicks,
            total_impressions,
            SAFE_DIVIDE(total_revenue, total_spend) as roi,
            SAFE_DIVIDE(total_spend, total_conversions) as cost_per_conversion
        FROM `{bq_project_id}.{bq_dataset_id}.marketing_daily_summary`
        WHERE tenant_id = @tenant_id
            AND date >= DATE_SUB(CURRENT_DATE(), INTERVAL @days_back DAY)
        ORDER BY date DESC, channel
        """

        job_config = bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter("tenant_id", "STRING", tenant_id),
                bigquery.ScalarQueryParameter("days_back", "INT64", days_back)
            ]
        )

        trend_results = bq_client.query(trend_query, job_config=job_config).result()
        trend_data = [dict(row) for row in trend_results]

        # Query attribution modeling (multi-touch)
        attribution_query = f"""
        SELECT
            conversion_id,
            touchpoint_sequence,
            attributed_channel,
            attribution_weight,
            conversion_value,
            time_to_conversion_days
        FROM `{bq_project_id}.{bq_dataset_id}.attribution_analysis`
        WHERE tenant_id = @tenant_id
            AND conversion_date >= DATE_SUB(CURRENT_DATE(), INTERVAL @days_back DAY)
        """

        attribution_results = bq_client.query(attribution_query, job_config=job_config).result()
        attribution_data = [dict(row) for row in attribution_results]

        # Query cohort retention analysis
        cohort_query = f"""
        SELECT
            cohort_month,
            weeks_since_first_purchase,
            cohort_size,
            active_users,
            retention_rate,
            cumulative_revenue_per_user
        FROM `{bq_project_id}.{bq_dataset_id}.cohort_retention_analysis`
        WHERE tenant_id = @tenant_id
        ORDER BY cohort_month DESC, weeks_since_first_purchase
        LIMIT 100
        """

        cohort_results = bq_client.query(cohort_query, job_config=job_config).result()
        cohort_data = [dict(row) for row in cohort_results]

    except Exception as e:
        print(f"[Analytics Report] BigQuery error: {str(e)}")

    # ==================== STEP 3: GET REALTIME KPIs FROM ZERODB ====================

    print(f"[Analytics Report] Fetching real-time KPIs from ZeroDB")

    realtime_kpis = {}

    try:
        conn = psycopg2.connect(**zerodb_config)
        cur = conn.cursor()

        # Get current day's live metrics
        cur.execute("""
            SELECT
                metric_name,
                metric_value,
                change_vs_yesterday_pct,
                trend_direction
            FROM realtime_marketing_kpis
            WHERE tenant_id = %s
                AND updated_at >= CURRENT_DATE
            ORDER BY metric_name
        """, (tenant_id,))

        for row in cur.fetchall():
            realtime_kpis[row[0]] = {
                "value": float(row[1]) if row[1] else 0,
                "change_vs_yesterday": float(row[2]) if row[2] else 0,
                "trend": row[3]
            }

        cur.close()
        conn.close()

    except Exception as e:
        print(f"[Analytics Report] ZeroDB error: {str(e)}")

    # ==================== STEP 4: GENERATE REPORT WITH INSIGHTS ====================

    print(f"[Analytics Report] Generating comprehensive report")

    # Calculate key metrics from trend data
    total_spend = sum(row.get('total_spend', 0) for row in trend_data)
    total_revenue = sum(row.get('total_revenue', 0) for row in trend_data)
    total_conversions = sum(row.get('total_conversions', 0) for row in trend_data)
    overall_roi = total_revenue / total_spend if total_spend > 0 else 0

    # Channel performance breakdown
    channel_performance = {}
    for row in trend_data:
        channel = row.get('channel', 'unknown')
        if channel not in channel_performance:
            channel_performance[channel] = {
                "spend": 0,
                "revenue": 0,
                "conversions": 0,
                "roi": 0
            }
        channel_performance[channel]["spend"] += row.get('total_spend', 0)
        channel_performance[channel]["revenue"] += row.get('total_revenue', 0)
        channel_performance[channel]["conversions"] += row.get('total_conversions', 0)

    for channel, data in channel_performance.items():
        data["roi"] = data["revenue"] / data["spend"] if data["spend"] > 0 else 0

    # Attribution insights
    attribution_by_channel = {}
    for row in attribution_data:
        channel = row.get('attributed_channel', 'unknown')
        if channel not in attribution_by_channel:
            attribution_by_channel[channel] = {
                "total_attributed_value": 0,
                "touch_count": 0
            }
        attribution_by_channel[channel]["total_attributed_value"] += row.get('conversion_value', 0) * row.get('attribution_weight', 0)
        attribution_by_channel[channel]["touch_count"] += 1

    # Cohort retention summary
    if cohort_data:
        recent_cohort = cohort_data[0] if cohort_data else {}
        cohort_retention_week_4 = [c for c in cohort_data if c.get('weeks_since_first_purchase') == 4]
        avg_week_4_retention = sum(c.get('retention_rate', 0) for c in cohort_retention_week_4) / len(cohort_retention_week_4) if cohort_retention_week_4 else 0
    else:
        recent_cohort = {}
        avg_week_4_retention = 0

    # Build comprehensive report
    report = {
        "tenant_id": tenant_id,
        "report_type": report_type,
        "report_period": {
            "days_back": days_back,
            "start_date": (datetime.utcnow() - timedelta(days=days_back)).date().isoformat(),
            "end_date": datetime.utcnow().date().isoformat()
        },
        "executive_summary": {
            "total_marketing_spend": round(total_spend, 2),
            "total_revenue_generated": round(total_revenue, 2),
            "total_conversions": int(total_conversions),
            "overall_roi": round(overall_roi, 2),
            "cost_per_conversion": round(total_spend / total_conversions, 2) if total_conversions > 0 else 0
        },
        "channel_performance": channel_performance,
        "attribution_analysis": attribution_by_channel,
        "cohort_retention": {
            "most_recent_cohort_size": recent_cohort.get('cohort_size', 0),
            "week_4_retention_rate": round(avg_week_4_retention, 3),
            "revenue_per_user": recent_cohort.get('cumulative_revenue_per_user', 0)
        },
        "realtime_kpis": realtime_kpis,
        "trends": {
            "data_points": len(trend_data),
            "channels_tracked": len(channel_performance)
        },
        "insights": [],
        "data_sources_used": {
            "lakehouse": bool(campaigns_data or channels_data or content_data),
            "bigquery": bool(trend_data or attribution_data or cohort_data),
            "zerodb": bool(realtime_kpis)
        },
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "generated_by": "engarde_analytics_report_agent"
    }

    # Generate insights
    best_channel = max(channel_performance.items(), key=lambda x: x[1]['roi']) if channel_performance else None
    worst_channel = min(channel_performance.items(), key=lambda x: x[1]['roi']) if channel_performance else None

    if best_channel:
        report["insights"].append(f"Best performing channel: {best_channel[0]} with {best_channel[1]['roi']:.2f}x ROI")

    if worst_channel and worst_channel[1]['roi'] < 1.0:
        report["insights"].append(f"Underperforming channel: {worst_channel[0]} with {worst_channel[1]['roi']:.2f}x ROI - consider reducing budget")

    if overall_roi > 2.0:
        report["insights"].append(f"Excellent overall ROI ({overall_roi:.2f}x) - consider increasing overall marketing budget")
    elif overall_roi < 1.0:
        report["insights"].append(f"Warning: Overall ROI below 1.0 ({overall_roi:.2f}x) - immediate optimization needed")

    if avg_week_4_retention < 0.4:
        report["insights"].append(f"Low retention rate ({avg_week_4_retention:.1%}) - implement retention campaigns")

    # ==================== STEP 5: SAVE REPORT VIA API ====================

    print(f"[Analytics Report] Saving report via EnGarde API")

    engarde_headers = {
        "Authorization": f"Bearer {engarde_api_key}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=60) as client:
            response = client.post(
                f"{engarde_api_url}/api/v1/analytics/reports",
                json=report,
                headers=engarde_headers
            )

            if response.status_code in [200, 201]:
                report_result = response.json()
                report["report_id"] = report_result.get('id')
                report["report_url"] = report_result.get('url')
                report["success"] = True
                return report
            else:
                report["success"] = False
                report["error"] = f"HTTP {response.status_code}: {response.text}"
                return report

    except Exception as e:
        print(f"[Analytics Report] API error: {str(e)}")
        report["success"] = False
        report["error"] = str(e)
        return report
```

---

**Status**: Part 3 created with Agents 5-6. Continuing with remaining 4 EnGarde agents...

