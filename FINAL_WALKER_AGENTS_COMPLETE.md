# FINAL Walker Agents (1-4) - Complete with All Data Sources

**Each agent uses: Microservice + BigQuery + ZeroDB + PostgreSQL**

---

## Agent 1: SEO Walker Agent
*(See FINAL_CORRECT_ALL_AGENTS.md for complete implementation)*

---

## Agent 2: Paid Ads Walker Agent

```python
def run(tenant_id: str) -> dict:
    """
    Paid Ads Walker - Uses Sankore + BigQuery + ZeroDB + PostgreSQL
    """
    import os, httpx, json
    from datetime import datetime
    from google.cloud import bigquery
    from google.oauth2 import service_account

    # Config
    sankore_url = os.getenv("SANKORE_API_URL", "http://localhost:8001")
    bq_project = os.getenv("BIGQUERY_PROJECT_ID", "engarde-production")
    bq_dataset = os.getenv("BIGQUERY_DATASET_ID", "engarde_analytics")
    bq_creds = os.getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON")
    zerodb_url = os.getenv("ZERODB_API_BASE_URL", "https://api.ainative.studio/api/v1")
    zerodb_key = os.getenv("ZERODB_API_KEY")
    zerodb_project = os.getenv("ZERODB_PROJECT_ID")
    engarde_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    walker_key = os.getenv("WALKER_AGENT_API_KEY_SANKORE_PAID_ADS")

    print(f"[Paid Ads] Processing: {tenant_id}")

    # STEP 1: Sankore microservice
    sankore_data = {}
    try:
        resp = httpx.get(f"{sankore_url}/api/v1/ads/performance/{tenant_id}", timeout=60)
        sankore_data = resp.json() if resp.status_code == 200 else {}
    except Exception as e:
        print(f"Sankore error: {e}")

    # STEP 2: BigQuery - Historical ad performance
    bq_data = []
    try:
        if bq_creds:
            creds = service_account.Credentials.from_service_account_info(json.loads(bq_creds))
            client = bigquery.Client(credentials=creds, project=bq_project)
        else:
            client = bigquery.Client(project=bq_project)

        query = f"""
        SELECT
            campaign_id,
            platform,
            AVG(roas) as avg_roas,
            SUM(spend) as total_spend,
            SUM(revenue) as total_revenue
        FROM `{bq_project}.{bq_dataset}.campaign_metrics`
        WHERE tenant_id = @tenant_id
            AND metric_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
            AND platform IN ('google_ads', 'meta_ads', 'linkedin_ads')
        GROUP BY campaign_id, platform
        HAVING total_spend > 100
        ORDER BY avg_roas ASC
        """

        config = bigquery.QueryJobConfig(
            query_parameters=[bigquery.ScalarQueryParameter("tenant_id", "STRING", tenant_id)]
        )
        results = client.query(query, job_config=config).result()
        bq_data = [dict(row) for row in results]
    except Exception as e:
        print(f"BigQuery error: {e}")

    # STEP 3: ZeroDB - Real-time bid events
    zerodb_events = []
    try:
        resp = httpx.get(
            f"{zerodb_url}/public/projects/{zerodb_project}/events",
            params={"tenant_id": tenant_id, "event_type": "ad_bid_change", "limit": 50},
            headers={"X-API-Key": zerodb_key},
            timeout=60
        )
        if resp.status_code == 200:
            zerodb_events = resp.json().get('events', [])
    except Exception as e:
        print(f"ZeroDB error: {e}")

    # STEP 4: Generate suggestions
    suggestions = []

    # From BigQuery: Low ROI campaigns
    for campaign in bq_data:
        if campaign.get('avg_roas', 0) < 1.5:
            suggestions.append({
                "suggestion_type": "low_roi_campaign",
                "title": f"Low ROI: {campaign['platform']} campaign ({campaign.get('avg_roas', 0):.2f}x)",
                "description": f"Spent ${campaign['total_spend']:.2f}, earned ${campaign.get('total_revenue', 0):.2f}. Optimize or pause.",
                "priority": "high" if campaign.get('avg_roas', 0) < 1.0 else "medium",
                "estimated_revenue_increase": campaign['total_spend'] * 0.5,
                "confidence_score": 0.85,
                "actions": ["Review targeting", "Test new creatives", "Adjust bids"],
                "extra_data": {"source": "bigquery", "campaign_id": campaign['campaign_id']}
            })

    # From Sankore: High CPC keywords
    if sankore_data.get('expensive_keywords'):
        for kw in sankore_data['expensive_keywords'][:5]:
            if kw.get('conversions', 0) == 0:
                suggestions.append({
                    "suggestion_type": "expensive_keyword",
                    "title": f"Pause: {kw['keyword']} (${kw.get('spend', 0):.2f}, 0 conversions)",
                    "description": "Add as negative keyword to save budget.",
                    "priority": "high",
                    "estimated_revenue_increase": kw.get('spend', 0) * 30,
                    "confidence_score": 0.95,
                    "actions": ["Add negative keyword"],
                    "extra_data": {"source": "sankore", "keyword": kw['keyword']}
                })

    # From ZeroDB: Bid volatility
    if len(zerodb_events) > 20:
        suggestions.append({
            "suggestion_type": "bid_volatility",
            "title": f"{len(zerodb_events)} bid changes in last hour - review automation",
            "description": "High bid volatility detected. Check automated bidding strategy.",
            "priority": "medium",
            "estimated_revenue_increase": 1000,
            "confidence_score": 0.70,
            "actions": ["Review bid automation"],
            "extra_data": {"source": "zerodb", "event_count": len(zerodb_events)}
        })

    if not suggestions:
        suggestions.append({
            "suggestion_type": "monitoring",
            "title": "Paid ads monitoring active",
            "description": "Tracking across Sankore, BigQuery, ZeroDB",
            "priority": "low",
            "estimated_revenue_increase": 0,
            "confidence_score": 1.0,
            "actions": ["Continue monitoring"],
            "extra_data": {}
        })

    # STEP 5: Store in PostgreSQL
    batch_id = f"paid_ads_{tenant_id}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"
    results = []
    try:
        with httpx.Client(timeout=60) as client:
            for sug in suggestions:
                payload = {
                    "tenant_id": tenant_id, "agent_type": "paid_ads", "suggestion_batch_id": batch_id,
                    "priority": sug["priority"], "suggestion_type": sug["suggestion_type"],
                    "title": sug["title"], "description": sug["description"],
                    "estimated_revenue_increase": sug["estimated_revenue_increase"],
                    "confidence_score": sug["confidence_score"],
                    "actions": sug["actions"], "extra_data": sug["extra_data"]
                }
                resp = client.post(
                    f"{engarde_url}/api/v1/walker-agents/suggestions",
                    json=payload,
                    headers={"Authorization": f"Bearer {walker_key}", "Content-Type": "application/json"}
                )
                results.append({"success": resp.status_code in [200, 201]})
    except Exception as e:
        return {"success": False, "error": str(e)}

    return {
        "success": True, "tenant_id": tenant_id, "batch_id": batch_id,
        "agent_type": "paid_ads", "suggestions_generated": len(suggestions),
        "suggestions_stored": sum(1 for r in results if r["success"]),
        "data_sources": {"sankore": bool(sankore_data), "bigquery": bool(bq_data), "zerodb": bool(zerodb_events)},
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }
```

---

## Agent 3: Content Walker Agent

```python
def run(tenant_id: str) -> dict:
    """
    Content Walker - Uses Onside + BigQuery + ZeroDB + PostgreSQL
    """
    import os, httpx, json
    from datetime import datetime
    from google.cloud import bigquery
    from google.oauth2 import service_account

    # Config
    onside_url = os.getenv("ONSIDE_API_URL", "http://localhost:8000")
    bq_project = os.getenv("BIGQUERY_PROJECT_ID", "engarde-production")
    bq_dataset = os.getenv("BIGQUERY_DATASET_ID", "engarde_analytics")
    bq_creds = os.getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON")
    zerodb_url = os.getenv("ZERODB_API_BASE_URL", "https://api.ainative.studio/api/v1")
    zerodb_key = os.getenv("ZERODB_API_KEY")
    zerodb_project = os.getenv("ZERODB_PROJECT_ID")
    engarde_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    walker_key = os.getenv("WALKER_AGENT_API_KEY_ONSIDE_CONTENT")

    print(f"[Content] Processing: {tenant_id}")

    # STEP 1: Onside microservice
    onside_data = {}
    try:
        resp = httpx.get(f"{onside_url}/api/v1/content/analytics/{tenant_id}", timeout=60)
        onside_data = resp.json() if resp.status_code == 200 else {}
    except Exception as e:
        print(f"Onside error: {e}")

    # STEP 2: BigQuery - Content performance trends
    bq_data = []
    try:
        if bq_creds:
            creds = service_account.Credentials.from_service_account_info(json.loads(bq_creds))
            client = bigquery.Client(credentials=creds, project=bq_project)
        else:
            client = bigquery.Client(project=bq_project)

        query = f"""
        SELECT
            JSON_VALUE(raw_data, '$.content_topic') as topic,
            COUNT(*) as content_count,
            AVG(CAST(JSON_VALUE(raw_data, '$.engagement_rate') AS FLOAT64)) as avg_engagement
        FROM `{bq_project}.{bq_dataset}.integration_raw_data`
        WHERE tenant_id = @tenant_id
            AND integration_type = 'content_analytics'
            AND data_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
        GROUP BY topic
        HAVING content_count > 0
        ORDER BY avg_engagement DESC
        LIMIT 20
        """

        config = bigquery.QueryJobConfig(
            query_parameters=[bigquery.ScalarQueryParameter("tenant_id", "STRING", tenant_id)]
        )
        results = client.query(query, job_config=config).result()
        bq_data = [dict(row) for row in results]
    except Exception as e:
        print(f"BigQuery error: {e}")

    # STEP 3: ZeroDB - Real-time content views
    zerodb_events = []
    try:
        resp = httpx.get(
            f"{zerodb_url}/public/projects/{zerodb_project}/events",
            params={"tenant_id": tenant_id, "event_type": "content_view", "limit": 100},
            headers={"X-API-Key": zerodb_key},
            timeout=60
        )
        if resp.status_code == 200:
            zerodb_events = resp.json().get('events', [])
    except Exception as e:
        print(f"ZeroDB error: {e}")

    # STEP 4: Generate suggestions
    suggestions = []

    # From Onside: Content gaps
    if onside_data.get('content_gaps'):
        for gap in onside_data['content_gaps'][:5]:
            suggestions.append({
                "suggestion_type": "content_gap",
                "title": f"Create content: '{gap['topic']}' ({gap.get('search_volume', 0):,}/mo)",
                "description": f"High search volume, no current content. Create {gap.get('format', 'blog post')}.",
                "priority": "high" if gap.get('search_volume', 0) > 5000 else "medium",
                "estimated_revenue_increase": gap.get('search_volume', 0) * 0.1 * 10,
                "confidence_score": 0.80,
                "actions": ["Research topic", "Create content"],
                "extra_data": {"source": "onside", "topic": gap['topic']}
            })

    # From BigQuery: Low engagement topics
    if bq_data:
        low_engagement = [t for t in bq_data if t.get('avg_engagement', 0) < 0.02]
        for topic in low_engagement[:3]:
            suggestions.append({
                "suggestion_type": "low_engagement_topic",
                "title": f"Improve engagement: {topic['topic']} ({topic.get('avg_engagement', 0)*100:.1f}%)",
                "description": f"{topic['content_count']} pieces with low engagement. Refresh or consolidate.",
                "priority": "medium",
                "estimated_revenue_increase": topic['content_count'] * 200,
                "confidence_score": 0.75,
                "actions": ["Update content", "Improve formatting"],
                "extra_data": {"source": "bigquery", "topic": topic['topic']}
            })

    # From ZeroDB: Trending content
    if len(zerodb_events) > 50:
        suggestions.append({
            "suggestion_type": "trending_content",
            "title": f"{len(zerodb_events)} content views in last hour - capitalize on trend",
            "description": "High real-time engagement. Create related content quickly.",
            "priority": "high",
            "estimated_revenue_increase": 500,
            "confidence_score": 0.85,
            "actions": ["Create follow-up content"],
            "extra_data": {"source": "zerodb", "view_count": len(zerodb_events)}
        })

    if not suggestions:
        suggestions.append({
            "suggestion_type": "monitoring",
            "title": "Content monitoring active",
            "description": "Tracking across Onside, BigQuery, ZeroDB",
            "priority": "low",
            "estimated_revenue_increase": 0,
            "confidence_score": 1.0,
            "actions": ["Continue monitoring"],
            "extra_data": {}
        })

    # STEP 5: Store in PostgreSQL
    batch_id = f"content_{tenant_id}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"
    results = []
    try:
        with httpx.Client(timeout=60) as client:
            for sug in suggestions:
                payload = {
                    "tenant_id": tenant_id, "agent_type": "content", "suggestion_batch_id": batch_id,
                    "priority": sug["priority"], "suggestion_type": sug["suggestion_type"],
                    "title": sug["title"], "description": sug["description"],
                    "estimated_revenue_increase": sug["estimated_revenue_increase"],
                    "confidence_score": sug["confidence_score"],
                    "actions": sug["actions"], "extra_data": sug["extra_data"]
                }
                resp = client.post(
                    f"{engarde_url}/api/v1/walker-agents/suggestions",
                    json=payload,
                    headers={"Authorization": f"Bearer {walker_key}", "Content-Type": "application/json"}
                )
                results.append({"success": resp.status_code in [200, 201]})
    except Exception as e:
        return {"success": False, "error": str(e)}

    return {
        "success": True, "tenant_id": tenant_id, "batch_id": batch_id,
        "agent_type": "content", "suggestions_generated": len(suggestions),
        "suggestions_stored": sum(1 for r in results if r["success"]),
        "data_sources": {"onside": bool(onside_data), "bigquery": bool(bq_data), "zerodb": bool(zerodb_events)},
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }
```

---

## Agent 4: Audience Intelligence Walker Agent

```python
def run(tenant_id: str) -> dict:
    """
    Audience Intelligence - Uses MadanSara + BigQuery + ZeroDB + PostgreSQL
    """
    import os, httpx, json
    from datetime import datetime
    from google.cloud import bigquery
    from google.oauth2 import service_account

    # Config
    madansara_url = os.getenv("MADANSARA_API_URL", "http://localhost:8002")
    bq_project = os.getenv("BIGQUERY_PROJECT_ID", "engarde-production")
    bq_dataset = os.getenv("BIGQUERY_DATASET_ID", "engarde_analytics")
    bq_creds = os.getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON")
    zerodb_url = os.getenv("ZERODB_API_BASE_URL", "https://api.ainative.studio/api/v1")
    zerodb_key = os.getenv("ZERODB_API_KEY")
    zerodb_project = os.getenv("ZERODB_PROJECT_ID")
    engarde_url = os.getenv("ENGARDE_API_URL", "https://api.engarde.media")
    walker_key = os.getenv("WALKER_AGENT_API_KEY_MADANSARA_AUDIENCE_INTELLIGENCE")

    print(f"[Audience Intelligence] Processing: {tenant_id}")

    # STEP 1: MadanSara microservice
    madansara_data = {}
    try:
        resp = httpx.get(f"{madansara_url}/api/v1/audience/analytics/{tenant_id}", timeout=60)
        madansara_data = resp.json() if resp.status_code == 200 else {}
    except Exception as e:
        print(f"MadanSara error: {e}")

    # STEP 2: BigQuery - Customer segments
    bq_data = []
    try:
        if bq_creds:
            creds = service_account.Credentials.from_service_account_info(json.loads(bq_creds))
            client = bigquery.Client(credentials=creds, project=bq_project)
        else:
            client = bigquery.Client(project=bq_project)

        query = f"""
        SELECT
            JSON_VALUE(raw_data, '$.segment_name') as segment_name,
            COUNT(DISTINCT JSON_VALUE(raw_data, '$.customer_id')) as customer_count,
            AVG(CAST(JSON_VALUE(raw_data, '$.lifetime_value') AS FLOAT64)) as avg_ltv,
            AVG(CAST(JSON_VALUE(raw_data, '$.churn_probability') AS FLOAT64)) as avg_churn_prob
        FROM `{bq_project}.{bq_dataset}.integration_raw_data`
        WHERE tenant_id = @tenant_id
            AND integration_type = 'customer_segmentation'
            AND data_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
        GROUP BY segment_name
        HAVING customer_count > 10
        ORDER BY avg_churn_prob DESC
        LIMIT 10
        """

        config = bigquery.QueryJobConfig(
            query_parameters=[bigquery.ScalarQueryParameter("tenant_id", "STRING", tenant_id)]
        )
        results = client.query(query, job_config=config).result()
        bq_data = [dict(row) for row in results]
    except Exception as e:
        print(f"BigQuery error: {e}")

    # STEP 3: ZeroDB - Real-time user actions
    zerodb_events = []
    try:
        resp = httpx.get(
            f"{zerodb_url}/public/projects/{zerodb_project}/events",
            params={"tenant_id": tenant_id, "event_type": "cart_abandoned", "limit": 50},
            headers={"X-API-Key": zerodb_key},
            timeout=60
        )
        if resp.status_code == 200:
            zerodb_events = resp.json().get('events', [])
    except Exception as e:
        print(f"ZeroDB error: {e}")

    # STEP 4: Generate suggestions
    suggestions = []

    # From BigQuery: High churn segments
    for segment in bq_data:
        if segment.get('avg_churn_prob', 0) > 0.6:
            suggestions.append({
                "suggestion_type": "high_churn_segment",
                "title": f"High churn risk: {segment['segment_name']} ({segment.get('avg_churn_prob', 0)*100:.0f}%)",
                "description": f"{segment['customer_count']} customers, avg LTV ${segment.get('avg_ltv', 0):,.0f}. Launch retention campaign.",
                "priority": "critical",
                "estimated_revenue_increase": segment['customer_count'] * segment.get('avg_ltv', 0) * 0.4,
                "confidence_score": 0.85,
                "actions": ["Send retention offer", "Personalized outreach"],
                "extra_data": {"source": "bigquery", "segment": segment['segment_name']}
            })

    # From ZeroDB: Abandoned carts (real-time)
    if zerodb_events:
        total_cart_value = sum(float(e.get('cart_value', 0)) for e in zerodb_events if 'cart_value' in e)
        suggestions.append({
            "suggestion_type": "abandoned_carts",
            "title": f"{len(zerodb_events)} abandoned carts (${total_cart_value:,.0f})",
            "description": "Send recovery emails with 10% discount within 1 hour.",
            "priority": "high",
            "estimated_revenue_increase": total_cart_value * 0.20,
            "confidence_score": 0.80,
            "actions": ["Send recovery email", "Offer discount"],
            "extra_data": {"source": "zerodb", "cart_count": len(zerodb_events)}
        })

    # From MadanSara: High-value segments
    if madansara_data.get('high_value_segments'):
        for seg in madansara_data['high_value_segments'][:3]:
            suggestions.append({
                "suggestion_type": "scale_segment",
                "title": f"Scale: {seg['name']} ({seg.get('conversion_rate', 0)*100:.1f}% CVR)",
                "description": f"{seg.get('size', 0):,} members. Increase ad spend to this segment.",
                "priority": "high",
                "estimated_revenue_increase": seg.get('size', 0) * seg.get('conversion_rate', 0) * 100,
                "confidence_score": 0.75,
                "actions": ["Increase ad budget"],
                "extra_data": {"source": "madansara", "segment_id": seg['id']}
            })

    if not suggestions:
        suggestions.append({
            "suggestion_type": "monitoring",
            "title": "Audience intelligence monitoring active",
            "description": "Tracking across MadanSara, BigQuery, ZeroDB",
            "priority": "low",
            "estimated_revenue_increase": 0,
            "confidence_score": 1.0,
            "actions": ["Continue monitoring"],
            "extra_data": {}
        })

    # STEP 5: Store in PostgreSQL
    batch_id = f"audience_{tenant_id}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"
    results = []
    try:
        with httpx.Client(timeout=60) as client:
            for sug in suggestions:
                payload = {
                    "tenant_id": tenant_id, "agent_type": "audience_intelligence", "suggestion_batch_id": batch_id,
                    "priority": sug["priority"], "suggestion_type": sug["suggestion_type"],
                    "title": sug["title"], "description": sug["description"],
                    "estimated_revenue_increase": sug["estimated_revenue_increase"],
                    "confidence_score": sug["confidence_score"],
                    "actions": sug["actions"], "extra_data": sug["extra_data"]
                }
                resp = client.post(
                    f"{engarde_url}/api/v1/walker-agents/suggestions",
                    json=payload,
                    headers={"Authorization": f"Bearer {walker_key}", "Content-Type": "application/json"}
                )
                results.append({"success": resp.status_code in [200, 201]})
    except Exception as e:
        return {"success": False, "error": str(e)}

    return {
        "success": True, "tenant_id": tenant_id, "batch_id": batch_id,
        "agent_type": "audience_intelligence", "suggestions_generated": len(suggestions),
        "suggestions_stored": sum(1 for r in results if r["success"]),
        "data_sources": {"madansara": bool(madansara_data), "bigquery": bool(bq_data), "zerodb": bool(zerodb_events)},
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }
```

---

## Summary

All 4 Walker Agents now correctly use:
- ✅ **Microservice** (Onside/Sankore/MadanSara) - Domain-specific data
- ✅ **BigQuery** - Historical analytics (30-90 days)
- ✅ **ZeroDB** - Real-time operational events
- ✅ **PostgreSQL** - Cache suggestions (via EnGarde API)

**Ready for EnGarde agents (5-10) next!**

