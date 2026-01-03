# Production-Ready Langflow Agents - Part 2

**Continuation of PRODUCTION_READY_LANGFLOW_AGENTS.md**

---

## Agent 3: Content Walker Agent (Production-Ready)

**Purpose**: Analyzes content performance and identifies gaps for content marketing optimization

**Data Sources**:
- Lakehouse: Content inventory, engagement metrics
- BigQuery: Historical content performance, topic trends
- ZeroDB: Real-time content interactions, social shares

```python
def run(tenant_id: str) -> dict:
    """
    Production-ready Content Walker Agent
    Fetches real data from lakehouse, BigQuery, and ZeroDB
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

    engarde_api_key = os.getenv("WALKER_AGENT_API_KEY_ONSIDE_CONTENT")
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

    # ==================== STEP 1: FETCH FROM LAKEHOUSE ====================

    print(f"[Content Walker] Fetching lakehouse data for tenant: {tenant_id}")

    lakehouse_headers = {
        "Authorization": f"Bearer {lakehouse_api_key}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=60) as client:
            # Fetch content inventory
            content_inventory_response = client.get(
                f"{lakehouse_api_url}/api/v1/tenants/{tenant_id}/content/inventory",
                headers=lakehouse_headers
            )
            content_inventory = content_inventory_response.json() if content_inventory_response.status_code == 200 else {"content_pieces": []}

            # Fetch blog post performance
            blog_performance_response = client.get(
                f"{lakehouse_api_url}/api/v1/tenants/{tenant_id}/content/blog-performance",
                headers=lakehouse_headers
            )
            blog_performance = blog_performance_response.json() if blog_performance_response.status_code == 200 else {"posts": []}

            # Fetch social media content performance
            social_content_response = client.get(
                f"{lakehouse_api_url}/api/v1/tenants/{tenant_id}/content/social-performance",
                headers=lakehouse_headers
            )
            social_content = social_content_response.json() if social_content_response.status_code == 200 else {"posts": []}

            # Fetch content calendar
            content_calendar_response = client.get(
                f"{lakehouse_api_url}/api/v1/tenants/{tenant_id}/content/calendar",
                headers=lakehouse_headers
            )
            content_calendar = content_calendar_response.json() if content_calendar_response.status_code == 200 else {"scheduled": []}

    except Exception as e:
        print(f"[Content Walker] Lakehouse error: {str(e)}")
        content_inventory = {"content_pieces": []}
        blog_performance = {"posts": []}
        social_content = {"posts": []}
        content_calendar = {"scheduled": []}

    # ==================== STEP 2: QUERY BIGQUERY ====================

    print(f"[Content Walker] Querying BigQuery for content analytics")

    historical_topic_trends = []
    competitor_content = []

    try:
        if bq_credentials_json:
            credentials_dict = json.loads(bq_credentials_json)
            credentials = service_account.Credentials.from_service_account_info(credentials_dict)
            bq_client = bigquery.Client(credentials=credentials, project=bq_project_id)
        else:
            bq_client = bigquery.Client(project=bq_project_id)

        # Query topic trends over time
        topic_query = f"""
        SELECT
            topic,
            category,
            date,
            search_volume,
            social_mentions,
            engagement_rate,
            avg_time_on_page,
            bounce_rate
        FROM `{bq_project_id}.{bq_dataset_id}.content_topic_trends`
        WHERE tenant_id = @tenant_id
            AND date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
        ORDER BY date DESC, search_volume DESC
        """

        job_config = bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter("tenant_id", "STRING", tenant_id)
            ]
        )

        topic_results = bq_client.query(topic_query, job_config=job_config).result()
        historical_topic_trends = [dict(row) for row in topic_results]

        # Query competitor content analysis
        competitor_query = f"""
        SELECT
            competitor_name,
            content_title,
            content_type,
            topic,
            publish_date,
            estimated_traffic,
            social_shares,
            backlinks,
            content_score
        FROM `{bq_project_id}.{bq_dataset_id}.competitor_content_analysis`
        WHERE tenant_id = @tenant_id
            AND publish_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
            AND content_score > 70
        ORDER BY estimated_traffic DESC
        LIMIT 50
        """

        competitor_results = bq_client.query(competitor_query, job_config=job_config).result()
        competitor_content = [dict(row) for row in competitor_results]

    except Exception as e:
        print(f"[Content Walker] BigQuery error: {str(e)}")

    # ==================== STEP 3: QUERY ZERODB ====================

    print(f"[Content Walker] Querying ZeroDB for real-time content data")

    realtime_engagement = []
    content_gaps = []

    try:
        conn = psycopg2.connect(**zerodb_config)
        cur = conn.cursor()

        # Get real-time engagement metrics (last 7 days)
        cur.execute("""
            SELECT
                content_id,
                content_title,
                content_type,
                pageviews,
                unique_visitors,
                avg_time_on_page,
                bounce_rate,
                social_shares,
                comments,
                conversions
            FROM realtime_content_engagement
            WHERE tenant_id = %s
                AND recorded_at >= NOW() - INTERVAL '7 days'
            GROUP BY content_id, content_title, content_type
            ORDER BY pageviews DESC
            LIMIT 100
        """, (tenant_id,))

        realtime_engagement = [
            {
                "content_id": row[0],
                "content_title": row[1],
                "content_type": row[2],
                "pageviews": int(row[3]) if row[3] else 0,
                "unique_visitors": int(row[4]) if row[4] else 0,
                "avg_time_on_page": float(row[5]) if row[5] else 0,
                "bounce_rate": float(row[6]) if row[6] else 0,
                "social_shares": int(row[7]) if row[7] else 0,
                "comments": int(row[8]) if row[8] else 0,
                "conversions": int(row[9]) if row[9] else 0
            }
            for row in cur.fetchall()
        ]

        # Identify content gaps (topics with search volume but no content)
        cur.execute("""
            SELECT
                topic,
                search_volume,
                competition_level,
                trend_direction,
                missing_content_types
            FROM content_gap_analysis
            WHERE tenant_id = %s
                AND search_volume > 500
                AND has_content = false
            ORDER BY search_volume DESC
            LIMIT 50
        """, (tenant_id,))

        content_gaps = [
            {
                "topic": row[0],
                "search_volume": int(row[1]) if row[1] else 0,
                "competition_level": row[2],
                "trend_direction": row[3],
                "missing_content_types": row[4]
            }
            for row in cur.fetchall()
        ]

        cur.close()
        conn.close()

    except Exception as e:
        print(f"[Content Walker] ZeroDB error: {str(e)}")

    # ==================== STEP 4: ANALYZE & GENERATE SUGGESTIONS ====================

    print(f"[Content Walker] Analyzing data and generating suggestions")

    suggestions = []

    # Analysis 1: Content gaps from ZeroDB
    if content_gaps:
        for gap in content_gaps[:15]:
            suggestions.append({
                "title": f"Content gap: Create content about '{gap.get('topic', 'N/A')}'",
                "description": f"High search volume ({gap.get('search_volume', 0):,}/month) for topic '{gap.get('topic')}' but you have no content. Competition: {gap.get('competition_level', 'N/A')}. Trend: {gap.get('trend_direction', 'N/A')}. Consider creating: {gap.get('missing_content_types', 'blog post')}.",
                "priority": "high" if gap.get('search_volume', 0) > 5000 else "medium",
                "estimated_impact": f"Potential to gain {int(gap.get('search_volume', 0) * 0.1):,} monthly organic visitors",
                "category": "content_gaps",
                "data_source": "zerodb_content_gap_analysis"
            })

    # Analysis 2: Low-performing content from real-time engagement
    if realtime_engagement:
        low_performers = [
            content for content in realtime_engagement
            if content.get('bounce_rate', 0) > 0.7 and content.get('pageviews', 0) > 100
        ]

        if low_performers:
            for content in low_performers[:10]:
                suggestions.append({
                    "title": f"Improve underperforming content: {content.get('content_title', 'N/A')[:50]}",
                    "description": f"This {content.get('content_type', 'content')} has high bounce rate ({content.get('bounce_rate', 0)*100:.1f}%) despite {content.get('pageviews', 0):,} pageviews. Average time on page: {content.get('avg_time_on_page', 0):.1f}s. Update content, improve readability, add multimedia, and enhance CTAs.",
                    "priority": "medium",
                    "estimated_impact": f"Reduce bounce rate to <50%, increase engagement by 30-40%",
                    "category": "content_optimization",
                    "data_source": "zerodb_realtime_engagement"
                })

    # Analysis 3: Trending topics from BigQuery
    if historical_topic_trends:
        # Group by topic and detect trends
        topic_performance = {}
        for row in historical_topic_trends:
            topic = row.get('topic', 'Unknown')
            if topic not in topic_performance:
                topic_performance[topic] = {
                    "search_volumes": [],
                    "engagement_rates": [],
                    "category": row.get('category', 'General')
                }
            topic_performance[topic]["search_volumes"].append(row.get('search_volume', 0))
            topic_performance[topic]["engagement_rates"].append(row.get('engagement_rate', 0))

        # Find growing topics
        for topic, data in topic_performance.items():
            if len(data["search_volumes"]) >= 4:
                recent_avg = sum(data["search_volumes"][:7]) / 7 if len(data["search_volumes"]) >= 7 else sum(data["search_volumes"]) / len(data["search_volumes"])
                older_avg = sum(data["search_volumes"][-7:]) / 7 if len(data["search_volumes"]) >= 7 else recent_avg

                if recent_avg > older_avg * 1.3:  # 30% growth
                    suggestions.append({
                        "title": f"Trending topic alert: Create more content about '{topic}'",
                        "description": f"Search volume for '{topic}' ({data['category']}) has grown {((recent_avg/older_avg - 1) * 100):.0f}% recently. Current volume: {int(recent_avg):,}/month. Capitalize on this trend by creating comprehensive content.",
                        "priority": "high",
                        "estimated_impact": f"Capture growing audience, potential {int(recent_avg * 0.15):,} monthly visitors",
                        "category": "trending_topics",
                        "data_source": "bigquery_topic_trends"
                    })

    # Analysis 4: Competitor content opportunities
    if competitor_content:
        high_performing_competitor_content = competitor_content[:10]
        for comp_content in high_performing_competitor_content:
            suggestions.append({
                "title": f"Competitor insight: Create better content than '{comp_content.get('content_title', 'N/A')[:40]}'",
                "description": f"{comp_content.get('competitor_name', 'Competitor')} published '{comp_content.get('content_title', 'N/A')}' about {comp_content.get('topic', 'N/A')}. It has {comp_content.get('estimated_traffic', 0):,} monthly traffic and {comp_content.get('social_shares', 0):,} social shares. Create a more comprehensive version to capture this audience.",
                "priority": "medium",
                "estimated_impact": f"Potential to capture {int(comp_content.get('estimated_traffic', 0) * 0.3):,} of competitor's traffic",
                "category": "competitor_analysis",
                "data_source": "bigquery_competitor_content"
            })

    # Analysis 5: Content calendar gaps from lakehouse
    if content_calendar:
        scheduled_count = len(content_calendar.get('scheduled', []))
        # Check for gaps in next 30 days
        if scheduled_count < 12:  # Less than 3 posts per week
            suggestions.append({
                "title": f"Content calendar gap: Only {scheduled_count} posts scheduled for next 30 days",
                "description": f"Your content calendar has only {scheduled_count} pieces scheduled for the next month. Consistent publishing (3-4x/week) is critical for audience growth. Plan and schedule more content to maintain momentum.",
                "priority": "high",
                "estimated_impact": "Maintain audience engagement and SEO momentum",
                "category": "content_planning",
                "data_source": "lakehouse_content_calendar"
            })

    # Analysis 6: Social content performance
    if social_content:
        social_posts = social_content.get('posts', [])
        if social_posts:
            # Calculate average engagement
            total_engagement = sum(post.get('total_engagement', 0) for post in social_posts)
            avg_engagement = total_engagement / len(social_posts) if social_posts else 0

            low_engagement_posts = [
                post for post in social_posts
                if post.get('total_engagement', 0) < avg_engagement * 0.5
            ]

            if low_engagement_posts:
                suggestions.append({
                    "title": f"Low social engagement: {len(low_engagement_posts)} posts underperforming",
                    "description": f"Found {len(low_engagement_posts)} social posts with engagement below 50% of average ({avg_engagement:.0f}). Review posting times, hashtags, visuals, and copy. Test different formats (video, carousel, stories).",
                    "priority": "medium",
                    "estimated_impact": "Increase social engagement by 40-60%",
                    "category": "social_media_optimization",
                    "data_source": "lakehouse_social_performance"
                })

    # ==================== STEP 5: SEND TO ENGARDE API ====================

    print(f"[Content Walker] Sending {len(suggestions)} suggestions to EnGarde API")

    batch_id = f"content_{tenant_id}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"

    engarde_headers = {
        "Authorization": f"Bearer {engarde_api_key}",
        "Content-Type": "application/json"
    }

    results = []

    try:
        with httpx.Client(timeout=60) as client:
            for idx, suggestion in enumerate(suggestions, 1):
                payload = {
                    "tenant_id": tenant_id,
                    "batch_id": batch_id,
                    "agent_type": "content_strategy",
                    "microservice": "onside",
                    "title": suggestion["title"],
                    "description": suggestion["description"],
                    "priority": suggestion["priority"],
                    "estimated_impact": suggestion.get("estimated_impact", ""),
                    "category": suggestion.get("category", "general"),
                    "metadata": {
                        "data_source": suggestion.get("data_source", ""),
                        "generated_at": datetime.utcnow().isoformat() + "Z",
                        "sequence_number": idx
                    }
                }

                response = client.post(
                    f"{engarde_api_url}/api/v1/walker-agents/suggestions",
                    json=payload,
                    headers=engarde_headers
                )

                if response.status_code in [200, 201]:
                    results.append({"success": True, "suggestion": suggestion["title"]})
                else:
                    results.append({
                        "success": False,
                        "suggestion": suggestion["title"],
                        "error": f"HTTP {response.status_code}"
                    })

    except Exception as e:
        print(f"[Content Walker] API error: {str(e)}")
        return {
            "success": False,
            "error": str(e),
            "tenant_id": tenant_id
        }

    # ==================== STEP 6: RETURN RESULTS ====================

    successful = sum(1 for r in results if r.get("success"))

    return {
        "success": True,
        "tenant_id": tenant_id,
        "batch_id": batch_id,
        "agent_type": "content_strategy",
        "microservice": "onside",
        "suggestions_generated": len(suggestions),
        "suggestions_stored": successful,
        "data_sources_used": {
            "lakehouse": bool(content_inventory or blog_performance or social_content or content_calendar),
            "bigquery": bool(historical_topic_trends or competitor_content),
            "zerodb": bool(realtime_engagement or content_gaps)
        },
        "execution_timestamp": datetime.utcnow().isoformat() + "Z",
        "results": results
    }
```

---

## Agent 4: Audience Intelligence Walker Agent (Production-Ready)

**Purpose**: Analyzes audience behavior and segments to improve targeting and personalization

**Data Sources**:
- Lakehouse: Audience demographics, behavior patterns
- BigQuery: Historical segmentation, customer journey analytics
- ZeroDB: Real-time user interactions, session data

```python
def run(tenant_id: str) -> dict:
    """
    Production-ready Audience Intelligence Walker Agent
    Fetches real data from lakehouse, BigQuery, and ZeroDB
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

    engarde_api_key = os.getenv("WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE")
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

    # ==================== STEP 1: FETCH FROM LAKEHOUSE ====================

    print(f"[Audience Intelligence] Fetching lakehouse data for tenant: {tenant_id}")

    lakehouse_headers = {
        "Authorization": f"Bearer {lakehouse_api_key}",
        "Content-Type": "application/json"
    }

    try:
        with httpx.Client(timeout=60) as client:
            # Fetch audience demographics
            demographics_response = client.get(
                f"{lakehouse_api_url}/api/v1/tenants/{tenant_id}/audience/demographics",
                headers=lakehouse_headers
            )
            demographics_data = demographics_response.json() if demographics_response.status_code == 200 else {}

            # Fetch audience segments
            segments_response = client.get(
                f"{lakehouse_api_url}/api/v1/tenants/{tenant_id}/audience/segments",
                headers=lakehouse_headers
            )
            segments_data = segments_response.json() if segments_response.status_code == 200 else {"segments": []}

            # Fetch customer lifetime value data
            clv_response = client.get(
                f"{lakehouse_api_url}/api/v1/tenants/{tenant_id}/audience/clv",
                headers=lakehouse_headers
            )
            clv_data = clv_response.json() if clv_response.status_code == 200 else {"customers": []}

            # Fetch engagement patterns
            engagement_response = client.get(
                f"{lakehouse_api_url}/api/v1/tenants/{tenant_id}/audience/engagement-patterns",
                headers=lakehouse_headers
            )
            engagement_data = engagement_response.json() if engagement_response.status_code == 200 else {}

    except Exception as e:
        print(f"[Audience Intelligence] Lakehouse error: {str(e)}")
        demographics_data = {}
        segments_data = {"segments": []}
        clv_data = {"customers": []}
        engagement_data = {}

    # ==================== STEP 2: QUERY BIGQUERY ====================

    print(f"[Audience Intelligence] Querying BigQuery for customer journey data")

    customer_journey_data = []
    churn_risk_data = []

    try:
        if bq_credentials_json:
            credentials_dict = json.loads(bq_credentials_json)
            credentials = service_account.Credentials.from_service_account_info(credentials_dict)
            bq_client = bigquery.Client(credentials=credentials, project=bq_project_id)
        else:
            bq_client = bigquery.Client(project=bq_project_id)

        # Query customer journey paths
        journey_query = f"""
        SELECT
            user_id,
            journey_stage,
            touchpoint_sequence,
            time_in_stage_days,
            conversion_probability,
            last_interaction_date,
            total_touchpoints
        FROM `{bq_project_id}.{bq_dataset_id}.customer_journey_analysis`
        WHERE tenant_id = @tenant_id
            AND last_interaction_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
        ORDER BY conversion_probability DESC
        """

        job_config = bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter("tenant_id", "STRING", tenant_id)
            ]
        )

        journey_results = bq_client.query(journey_query, job_config=job_config).result()
        customer_journey_data = [dict(row) for row in journey_results]

        # Query churn risk analysis
        churn_query = f"""
        SELECT
            user_id,
            segment,
            churn_probability,
            days_since_last_activity,
            lifetime_value,
            engagement_score,
            purchase_frequency,
            avg_order_value
        FROM `{bq_project_id}.{bq_dataset_id}.churn_risk_analysis`
        WHERE tenant_id = @tenant_id
            AND churn_probability > 0.3
        ORDER BY churn_probability DESC, lifetime_value DESC
        LIMIT 1000
        """

        churn_results = bq_client.query(churn_query, job_config=job_config).result()
        churn_risk_data = [dict(row) for row in churn_results]

    except Exception as e:
        print(f"[Audience Intelligence] BigQuery error: {str(e)}")

    # ==================== STEP 3: QUERY ZERODB ====================

    print(f"[Audience Intelligence] Querying ZeroDB for real-time behavior")

    realtime_sessions = []
    behavioral_triggers = []

    try:
        conn = psycopg2.connect(**zerodb_config)
        cur = conn.cursor()

        # Get active sessions and behavior (last 24 hours)
        cur.execute("""
            SELECT
                user_id,
                session_id,
                device_type,
                pages_viewed,
                time_on_site,
                products_viewed,
                cart_actions,
                search_queries,
                referrer_source
            FROM realtime_user_sessions
            WHERE tenant_id = %s
                AND session_start >= NOW() - INTERVAL '24 hours'
            ORDER BY time_on_site DESC
            LIMIT 500
        """, (tenant_id,))

        realtime_sessions = [
            {
                "user_id": row[0],
                "session_id": row[1],
                "device_type": row[2],
                "pages_viewed": int(row[3]) if row[3] else 0,
                "time_on_site": int(row[4]) if row[4] else 0,
                "products_viewed": row[5],
                "cart_actions": row[6],
                "search_queries": row[7],
                "referrer_source": row[8]
            }
            for row in cur.fetchall()
        ]

        # Get behavioral triggers (abandoned carts, high-intent behaviors)
        cur.execute("""
            SELECT
                trigger_type,
                user_id,
                user_segment,
                trigger_timestamp,
                trigger_value,
                recommended_action
            FROM behavioral_triggers
            WHERE tenant_id = %s
                AND trigger_timestamp >= NOW() - INTERVAL '48 hours'
                AND action_taken = false
            ORDER BY trigger_timestamp DESC
            LIMIT 200
        """, (tenant_id,))

        behavioral_triggers = [
            {
                "trigger_type": row[0],
                "user_id": row[1],
                "user_segment": row[2],
                "trigger_timestamp": row[3].isoformat() if row[3] else None,
                "trigger_value": float(row[4]) if row[4] else 0,
                "recommended_action": row[5]
            }
            for row in cur.fetchall()
        ]

        cur.close()
        conn.close()

    except Exception as e:
        print(f"[Audience Intelligence] ZeroDB error: {str(e)}")

    # ==================== STEP 4: ANALYZE & GENERATE SUGGESTIONS ====================

    print(f"[Audience Intelligence] Analyzing audience data and generating suggestions")

    suggestions = []

    # Analysis 1: High churn risk users from BigQuery
    if churn_risk_data:
        high_risk_high_value = [
            user for user in churn_risk_data
            if user.get('churn_probability', 0) > 0.6 and user.get('lifetime_value', 0) > 500
        ]

        if high_risk_high_value:
            total_at_risk_value = sum(user.get('lifetime_value', 0) for user in high_risk_high_value)
            suggestions.append({
                "title": f"Critical: {len(high_risk_high_value)} high-value customers at risk of churning",
                "description": f"Identified {len(high_risk_high_value)} high-value customers (${total_at_risk_value:,.0f} total LTV) with >60% churn probability. Average {high_risk_high_value[0].get('days_since_last_activity', 0):.0f} days since last activity. Launch re-engagement campaign with personalized offers immediately.",
                "priority": "critical",
                "estimated_impact": f"Retain ${total_at_risk_value * 0.4:,.0f} in customer lifetime value",
                "category": "churn_prevention",
                "data_source": "bigquery_churn_risk"
            })

    # Analysis 2: Behavioral triggers from ZeroDB
    if behavioral_triggers:
        abandoned_carts = [t for t in behavioral_triggers if t.get('trigger_type') == 'abandoned_cart']
        if abandoned_carts:
            total_cart_value = sum(t.get('trigger_value', 0) for t in abandoned_carts)
            suggestions.append({
                "title": f"Recover {len(abandoned_carts)} abandoned carts (${total_cart_value:,.0f})",
                "description": f"Found {len(abandoned_carts)} abandoned carts in last 48 hours worth ${total_cart_value:,.0f}. Send personalized recovery emails with limited-time discount (10-15% off) to recover sales. Typical recovery rate: 15-25%.",
                "priority": "high",
                "estimated_impact": f"Recover ${total_cart_value * 0.20:,.0f} in revenue (20% recovery rate)",
                "category": "conversion_optimization",
                "data_source": "zerodb_behavioral_triggers"
            })

    # Analysis 3: Customer journey bottlenecks from BigQuery
    if customer_journey_data:
        # Find users stuck in consideration stage
        stuck_users = [
            user for user in customer_journey_data
            if user.get('journey_stage') == 'consideration' and user.get('time_in_stage_days', 0) > 14
        ]

        if stuck_users:
            suggestions.append({
                "title": f"Journey bottleneck: {len(stuck_users)} users stuck in consideration stage",
                "description": f"{len(stuck_users)} users have been in consideration stage for >14 days. Send educational content, case studies, comparison guides, or schedule demo calls to move them toward purchase. Average conversion probability: {(sum(u.get('conversion_probability', 0) for u in stuck_users) / len(stuck_users)):.1%}.",
                "priority": "high",
                "estimated_impact": f"Convert {len(stuck_users) * 0.15:.0f} users by providing decision-support content",
                "category": "customer_journey_optimization",
                "data_source": "bigquery_customer_journey"
            })

    # Analysis 4: Segment opportunities from lakehouse
    if segments_data:
        segments = segments_data.get('segments', [])
        high_potential_segments = [
            seg for seg in segments
            if seg.get('avg_conversion_rate', 0) > 0.05 and seg.get('size', 0) > 100
        ]

        for segment in high_potential_segments[:5]:
            suggestions.append({
                "title": f"High-potential segment: {segment.get('name', 'N/A')} ({segment.get('size', 0):,} users)",
                "description": f"Segment '{segment.get('name')}' has {segment.get('avg_conversion_rate', 0)*100:.1f}% conversion rate and {segment.get('size', 0):,} members. Characteristics: {segment.get('key_characteristics', 'N/A')}. Create targeted campaigns for this segment to maximize ROI.",
                "priority": "medium",
                "estimated_impact": f"Potential {int(segment.get('size', 0) * segment.get('avg_conversion_rate', 0) * 1.3)} additional conversions with targeted messaging",
                "category": "segmentation",
                "data_source": "lakehouse_audience_segments"
            })

    # Analysis 5: Device and channel preferences from realtime sessions
    if realtime_sessions:
        device_counts = {}
        for session in realtime_sessions:
            device = session.get('device_type', 'unknown')
            device_counts[device] = device_counts.get(device, 0) + 1

        if device_counts:
            dominant_device = max(device_counts.items(), key=lambda x: x[1])
            device_pct = (dominant_device[1] / len(realtime_sessions)) * 100

            if device_pct > 60:
                suggestions.append({
                    "title": f"Optimize for {dominant_device[0]}: {device_pct:.0f}% of traffic",
                    "description": f"{device_pct:.0f}% of your users are on {dominant_device[0]} devices. Ensure your website, emails, and landing pages are fully optimized for {dominant_device[0]} experience. Test load times, CTAs, and form submissions on this device type.",
                    "priority": "medium",
                    "estimated_impact": "Improve conversion rate by 10-15% through device-specific optimization",
                    "category": "user_experience",
                    "data_source": "zerodb_realtime_sessions"
                })

    # Analysis 6: Engagement patterns from lakehouse
    if engagement_data:
        best_engagement_time = engagement_data.get('peak_engagement_time', 'N/A')
        best_engagement_day = engagement_data.get('peak_engagement_day', 'N/A')

        if best_engagement_time != 'N/A':
            suggestions.append({
                "title": f"Optimize send times: Peak engagement at {best_engagement_time} on {best_engagement_day}",
                "description": f"Your audience engages most at {best_engagement_time} on {best_engagement_day}. Schedule email campaigns, social posts, and push notifications for this time window to maximize open rates and engagement.",
                "priority": "medium",
                "estimated_impact": "Increase email open rates by 20-30% and engagement by 15-25%",
                "category": "timing_optimization",
                "data_source": "lakehouse_engagement_patterns"
            })

    # ==================== STEP 5: SEND TO ENGARDE API ====================

    print(f"[Audience Intelligence] Sending {len(suggestions)} suggestions to EnGarde API")

    batch_id = f"audience_{tenant_id}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"

    engarde_headers = {
        "Authorization": f"Bearer {engarde_api_key}",
        "Content-Type": "application/json"
    }

    results = []

    try:
        with httpx.Client(timeout=60) as client:
            for idx, suggestion in enumerate(suggestions, 1):
                payload = {
                    "tenant_id": tenant_id,
                    "batch_id": batch_id,
                    "agent_type": "audience_intelligence",
                    "microservice": "madansara",
                    "title": suggestion["title"],
                    "description": suggestion["description"],
                    "priority": suggestion["priority"],
                    "estimated_impact": suggestion.get("estimated_impact", ""),
                    "category": suggestion.get("category", "general"),
                    "metadata": {
                        "data_source": suggestion.get("data_source", ""),
                        "generated_at": datetime.utcnow().isoformat() + "Z",
                        "sequence_number": idx
                    }
                }

                response = client.post(
                    f"{engarde_api_url}/api/v1/walker-agents/suggestions",
                    json=payload,
                    headers=engarde_headers
                )

                if response.status_code in [200, 201]:
                    results.append({"success": True, "suggestion": suggestion["title"]})
                else:
                    results.append({
                        "success": False,
                        "suggestion": suggestion["title"],
                        "error": f"HTTP {response.status_code}"
                    })

    except Exception as e:
        print(f"[Audience Intelligence] API error: {str(e)}")
        return {
            "success": False,
            "error": str(e),
            "tenant_id": tenant_id
        }

    # ==================== STEP 6: RETURN RESULTS ====================

    successful = sum(1 for r in results if r.get("success"))

    return {
        "success": True,
        "tenant_id": tenant_id,
        "batch_id": batch_id,
        "agent_type": "audience_intelligence",
        "microservice": "madansara",
        "suggestions_generated": len(suggestions),
        "suggestions_stored": successful,
        "data_sources_used": {
            "lakehouse": bool(demographics_data or segments_data or clv_data or engagement_data),
            "bigquery": bool(customer_journey_data or churn_risk_data),
            "zerodb": bool(realtime_sessions or behavioral_triggers)
        },
        "execution_timestamp": datetime.utcnow().isoformat() + "Z",
        "results": results
    }
```

---

**Status**: 4 Walker Agents complete. Continuing with 6 EnGarde Agents...

