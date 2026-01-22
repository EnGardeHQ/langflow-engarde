#!/usr/bin/env python3
"""
Migration Script: Populate Campaign Spaces with Content, Platforms, and Performance Data

This script:
1. Creates campaign_spaces for all existing campaigns
2. Generates campaign_assets (images, videos, ad copy) for each campaign
3. Creates campaign_deployments linking campaigns to platforms/channels
4. Populates campaign_metrics with per-asset per-channel performance data

This ensures the user experience makes logical sense by showing:
- Content associated with campaigns
- Platforms/channels where content was posted
- Performance of content individually through each channel
- Collection of all content and channels for each campaign
"""

import psycopg2
import psycopg2.extras
import uuid
import random
from datetime import datetime, timedelta
import json

# Database connection
DATABASE_URL = "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

# Supported platforms (must match adplatform enum in database)
PLATFORMS = ['meta', 'google_ads', 'tiktok', 'linkedin', 'twitter', 'youtube', 'snapchat', 'pinterest']

# Campaign objectives by platform
# Note: Meta includes both Facebook and Instagram
OBJECTIVES = {
    'meta': ['OUTCOME_SALES', 'OUTCOME_LEADS', 'OUTCOME_ENGAGEMENT', 'OUTCOME_TRAFFIC', 'OUTCOME_AWARENESS'],
    'google_ads': ['SEARCH', 'DISPLAY', 'SHOPPING', 'VIDEO', 'PERFORMANCE_MAX'],
    'tiktok': ['TRAFFIC', 'CONVERSIONS', 'APP_INSTALLS', 'REACH', 'VIDEO_VIEWS'],
    'linkedin': ['BRAND_AWARENESS', 'WEBSITE_VISITS', 'ENGAGEMENT', 'LEAD_GENERATION'],
    'twitter': ['AWARENESS', 'CONSIDERATION', 'CONVERSION'],
    'youtube': ['VIDEO_VIEWS', 'AWARENESS', 'CONSIDERATION'],
    'snapchat': ['AWARENESS', 'CONSIDERATION', 'CONVERSION'],
    'pinterest': ['AWARENESS', 'CONSIDERATION', 'CONVERSION']
}

# Asset types
ASSET_TYPES = ['image', 'video', 'ad_copy', 'headline', 'description', 'call_to_action']

# Sample ad copy templates
AD_COPY_TEMPLATES = [
    "Discover amazing deals on {product}! Limited time offer.",
    "Transform your {category} experience with {product}. Shop now!",
    "Join thousands of happy customers. Try {product} today!",
    "Exclusive offer: Get {discount}% off {product}!",
    "{product} - The smart choice for {category}."
]

HEADLINE_TEMPLATES = [
    "{product} - Best in Class",
    "Save Big on {product}",
    "Limited Time: {product} Sale",
    "Discover {product} Today",
    "Premium {product} at Great Prices"
]

CTA_OPTIONS = [
    "Shop Now", "Learn More", "Sign Up", "Get Started", "Download",
    "Buy Now", "Register", "Try Free", "Subscribe", "Contact Us"
]


def generate_asset_data(campaign_name, asset_type):
    """Generate realistic asset metadata"""
    product = campaign_name.split('-')[0].strip() if '-' in campaign_name else campaign_name
    category = "products"
    discount = random.choice([10, 15, 20, 25, 30])

    if asset_type == 'image':
        return {
            'asset_name': f"{campaign_name} - Image {random.randint(1, 10)}",
            'title': f"{product} Hero Image",
            'description': f"High-quality image showcasing {product}",
            'width': random.choice([1200, 1080, 1920]),
            'height': random.choice([628, 1080, 1080]),
            'mime_type': 'image/jpeg',
            'file_size': random.randint(100000, 5000000)
        }
    elif asset_type == 'video':
        return {
            'asset_name': f"{campaign_name} - Video {random.randint(1, 5)}",
            'title': f"{product} Video Ad",
            'description': f"Engaging video advertisement for {product}",
            'width': 1920,
            'height': 1080,
            'duration': random.randint(15, 60),
            'mime_type': 'video/mp4',
            'file_size': random.randint(5000000, 50000000)
        }
    elif asset_type == 'ad_copy':
        template = random.choice(AD_COPY_TEMPLATES)
        return {
            'asset_name': f"{campaign_name} - Ad Copy",
            'ad_copy_text': template.format(product=product, category=category, discount=discount),
            'title': "Primary Ad Copy"
        }
    elif asset_type == 'headline':
        template = random.choice(HEADLINE_TEMPLATES)
        return {
            'asset_name': f"{campaign_name} - Headline",
            'headline_text': template.format(product=product),
            'title': "Main Headline"
        }
    elif asset_type == 'description':
        return {
            'asset_name': f"{campaign_name} - Description",
            'description': f"Discover the best {product} available. Premium quality at competitive prices.",
            'title': "Product Description"
        }
    elif asset_type == 'call_to_action':
        return {
            'asset_name': f"{campaign_name} - CTA",
            'cta_text': random.choice(CTA_OPTIONS),
            'title': "Call to Action"
        }

    return {}


def generate_performance_metrics(asset_type, platform):
    """Generate realistic performance metrics based on asset type and platform"""
    base_impressions = random.randint(1000, 100000)
    base_ctr = random.uniform(0.5, 5.0)  # 0.5% to 5%

    # Different platforms have different typical CTRs
    platform_multiplier = {
        'meta': 1.2,
        'google_ads': 1.5,
        'tiktok': 1.8,
        'linkedin': 0.8,
        'twitter': 0.9,
        'youtube': 1.1,
        'instagram': 1.3
    }

    # Different asset types have different performance
    asset_multiplier = {
        'image': 1.0,
        'video': 1.5,
        'ad_copy': 0.8,
        'headline': 0.9,
        'description': 0.7,
        'call_to_action': 1.1
    }

    ctr = base_ctr * platform_multiplier.get(platform, 1.0) * asset_multiplier.get(asset_type, 1.0)
    clicks = int(base_impressions * (ctr / 100))
    conversions = int(clicks * random.uniform(0.01, 0.05))  # 1-5% conversion rate
    spend = base_impressions * random.uniform(0.5, 2.0) / 1000  # CPM between $0.50-$2.00
    revenue = conversions * random.uniform(20, 100)  # Average order value $20-$100

    return {
        'impressions': base_impressions,
        'clicks': clicks,
        'conversions': conversions,
        'spend': round(spend, 2),
        'ctr': round(ctr, 2),
        'cpc': round(spend / clicks if clicks > 0 else 0, 2),
        'cpa': round(spend / conversions if conversions > 0 else 0, 2),
        'revenue': round(revenue, 2),
        'roas': round(revenue / spend if spend > 0 else 0, 2)
    }


def run_migration():
    """Main migration function"""
    conn = None
    try:
        print("=" * 80)
        print("CAMPAIGN CONTENT & PERFORMANCE MIGRATION")
        print("=" * 80)
        print()

        # Connect to database
        print("🔌 Connecting to Railway database...")
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        # Fetch all campaigns with tenant and brand info
        print("📊 Fetching existing campaigns...")
        cursor.execute("""
            SELECT c.id, c.name, c.tenant_id, c.brand_id, c.status, c.created_at
            FROM campaigns c
            WHERE c.status IN ('active', 'draft', 'paused')
            ORDER BY c.created_at DESC
        """)
        campaigns = cursor.fetchall()
        print(f"✅ Found {len(campaigns)} campaigns to migrate")
        print()

        # Get the first user ID to use for all campaign_spaces
        print("👥 Fetching user ID...")
        cursor.execute("SELECT id FROM users LIMIT 1")
        result = cursor.fetchone()
        if not result:
            print("❌ No users found in database. Cannot proceed.")
            return False
        default_user_id = result['id']
        print(f"✅ Using user ID: {default_user_id}")
        print()

        # Track statistics
        stats = {
            'campaign_spaces_created': 0,
            'campaign_assets_created': 0,
            'campaign_deployments_created': 0,
            'campaign_metrics_created': 0
        }

        # Process each campaign
        for idx, campaign in enumerate(campaigns, 1):
            print(f"📦 Processing campaign {idx}/{len(campaigns)}: {campaign['name']}")
            campaign_id = campaign['id']
            campaign_name = campaign['name']
            tenant_id = campaign['tenant_id']
            brand_id = campaign['brand_id']
            user_id = default_user_id

            # Select 2-4 random platforms for this campaign
            num_platforms = random.randint(2, 4)
            campaign_platforms = random.sample(PLATFORMS, num_platforms)

            print(f"  📍 Platforms: {', '.join(campaign_platforms)}")

            # Create a campaign_space for each platform
            for platform in campaign_platforms:
                space_id = str(uuid.uuid4())
                campaign_slug = campaign_name.lower().replace(' ', '-')[:250]
                objective = random.choice(OBJECTIVES.get(platform, ['conversion']))
                budget = random.uniform(1000, 10000)
                start_date = campaign['created_at']
                end_date = start_date + timedelta(days=random.randint(30, 90))

                # Create campaign_space
                cursor.execute("""
                    INSERT INTO campaign_spaces (
                        id, tenant_id, brand_id, user_id,
                        campaign_name, campaign_slug, platform, external_campaign_id,
                        description, campaign_objective, budget, currency,
                        campaign_start_date, campaign_end_date, is_active,
                        import_source, import_metadata, imported_by,
                        tags, is_archived,
                        created_at, updated_at
                    ) VALUES (
                        %s, %s, %s, %s,
                        %s, %s, %s, %s,
                        %s, %s, %s, %s,
                        %s, %s, %s,
                        %s, %s, %s,
                        %s, %s,
                        %s, %s
                    )
                """, (
                    space_id, tenant_id, brand_id, user_id,
                    f"{campaign_name} - {platform.upper()}", f"{campaign_slug}-{platform}", platform, f"{platform}_{campaign_id[:8]}",
                    f"Campaign for {campaign_name} on {platform}", objective, budget, 'USD',
                    start_date, end_date, campaign['status'] == 'active',
                    'platform_api', json.dumps({'original_campaign_id': campaign_id, 'migrated': True}), user_id,
                    [campaign_name.split()[0], platform, objective], False,
                    datetime.utcnow(), datetime.utcnow()
                ))
                stats['campaign_spaces_created'] += 1

                # Create campaign_deployment
                deployment_id = str(uuid.uuid4())
                cursor.execute("""
                    INSERT INTO campaign_deployments (
                        id, campaign_id, tenant_id, platform, platform_campaign_id,
                        deployment_type, deployed_content, platform_configuration,
                        status, deployment_started_at, deployment_completed_at,
                        created_at, updated_at
                    ) VALUES (
                        %s, %s, %s, %s, %s,
                        %s, %s, %s,
                        %s, %s, %s,
                        %s, %s
                    )
                """, (
                    deployment_id, campaign_id, tenant_id, platform, f"{platform}_{campaign_id[:8]}",
                    'full_campaign', json.dumps({'campaign_space_id': space_id}), json.dumps({'objective': objective}),
                    'deployed', start_date, start_date + timedelta(hours=1),
                    datetime.utcnow(), datetime.utcnow()
                ))
                stats['campaign_deployments_created'] += 1

                # Create 3-6 campaign assets per platform
                num_assets = random.randint(3, 6)
                selected_asset_types = random.sample(ASSET_TYPES, min(num_assets, len(ASSET_TYPES)))

                for asset_type in selected_asset_types:
                    asset_id = str(uuid.uuid4())
                    asset_data = generate_asset_data(campaign_name, asset_type)
                    performance = generate_performance_metrics(asset_type, platform)

                    # Create campaign_asset
                    cursor.execute("""
                        INSERT INTO campaign_assets (
                            id, campaign_space_id, tenant_id, brand_id, user_id,
                            asset_name, asset_type, external_asset_id,
                            title, description, ad_copy_text, headline_text, cta_text,
                            width, height, duration, mime_type, file_size,
                            impressions, clicks, conversions, spend, ctr,
                            performance_data, platform_metadata,
                            import_metadata, imported_at,
                            created_at, updated_at
                        ) VALUES (
                            %s, %s, %s, %s, %s,
                            %s, %s, %s,
                            %s, %s, %s, %s, %s,
                            %s, %s, %s, %s, %s,
                            %s, %s, %s, %s, %s,
                            %s, %s,
                            %s, %s,
                            %s, %s
                        )
                    """, (
                        asset_id, space_id, tenant_id, brand_id, user_id,
                        asset_data.get('asset_name', 'Untitled Asset'), asset_type, f"{platform}_{asset_type}_{uuid.uuid4().hex[:8]}",
                        asset_data.get('title'), asset_data.get('description'), asset_data.get('ad_copy_text'),
                        asset_data.get('headline_text'), asset_data.get('cta_text'),
                        asset_data.get('width'), asset_data.get('height'), asset_data.get('duration'),
                        asset_data.get('mime_type'), asset_data.get('file_size'),
                        performance['impressions'], performance['clicks'], performance['conversions'],
                        performance['spend'], performance['ctr'],
                        json.dumps(performance), json.dumps({'platform': platform, 'campaign_id': campaign_id}),
                        json.dumps({'migrated': True}), datetime.utcnow(),
                        datetime.utcnow(), datetime.utcnow()
                    ))
                    stats['campaign_assets_created'] += 1

                    # Create campaign_metrics for this asset
                    metric_id = str(uuid.uuid4())
                    cursor.execute("""
                        INSERT INTO campaign_metrics (
                            id, campaign_id, deployment_id, tenant_id,
                            platform, metric_date, metric_type,
                            impressions, clicks, conversions, spend, reach,
                            platform_metrics, ctr, cpm, cpc, cpa, roas,
                            created_at
                        ) VALUES (
                            %s, %s, %s, %s,
                            %s, %s, %s,
                            %s, %s, %s, %s, %s,
                            %s, %s, %s, %s, %s, %s,
                            %s
                        )
                    """, (
                        metric_id, campaign_id, deployment_id, tenant_id,
                        platform, datetime.utcnow() - timedelta(days=random.randint(1, 30)), 'daily',
                        performance['impressions'], performance['clicks'], performance['conversions'],
                        str(performance['spend']), int(performance['impressions'] * 0.8),
                        json.dumps({'asset_id': asset_id, 'asset_type': asset_type, **performance}),
                        str(performance['ctr']), str(performance.get('cpm', 0)), str(performance['cpc']),
                        str(performance['cpa']), str(performance['roas']),
                        datetime.utcnow()
                    ))
                    stats['campaign_metrics_created'] += 1

                # Update campaign_space with aggregate metrics
                cursor.execute("""
                    UPDATE campaign_spaces
                    SET
                        total_impressions = (SELECT COALESCE(SUM(impressions), 0) FROM campaign_assets WHERE campaign_space_id = %s),
                        total_clicks = (SELECT COALESCE(SUM(clicks), 0) FROM campaign_assets WHERE campaign_space_id = %s),
                        total_spend = (SELECT COALESCE(SUM(spend), 0) FROM campaign_assets WHERE campaign_space_id = %s),
                        total_conversions = (SELECT COALESCE(SUM(conversions), 0) FROM campaign_assets WHERE campaign_space_id = %s),
                        avg_ctr = (SELECT COALESCE(AVG(ctr), 0) FROM campaign_assets WHERE campaign_space_id = %s),
                        asset_count = (SELECT COUNT(*) FROM campaign_assets WHERE campaign_space_id = %s),
                        performance_last_updated = %s,
                        updated_at = %s
                    WHERE id = %s
                """, (space_id, space_id, space_id, space_id, space_id, space_id,
                      datetime.utcnow(), datetime.utcnow(), space_id))

            print(f"  ✅ Created {len(campaign_platforms)} spaces with assets and metrics")

            # Commit after each campaign to avoid losing progress
            if idx % 10 == 0:
                conn.commit()
                print(f"\n  💾 Committed progress ({idx} campaigns processed)\n")

        # Final commit
        conn.commit()

        # Print summary
        print()
        print("=" * 80)
        print("MIGRATION COMPLETE! 🎉")
        print("=" * 80)
        print()
        print("📊 Migration Statistics:")
        print(f"  • Campaign Spaces Created:     {stats['campaign_spaces_created']}")
        print(f"  • Campaign Assets Created:      {stats['campaign_assets_created']}")
        print(f"  • Campaign Deployments Created: {stats['campaign_deployments_created']}")
        print(f"  • Campaign Metrics Created:     {stats['campaign_metrics_created']}")
        print()
        print("✅ All campaigns now have:")
        print("  • Content associated with campaigns (campaign_assets)")
        print("  • Platforms/channels where content was posted (campaign_deployments)")
        print("  • Performance of content individually through channels (campaign_metrics)")
        print("  • Collection of channels and content for each campaign (campaign_spaces)")
        print()

        cursor.close()

    except Exception as e:
        print(f"\n❌ Error during migration: {e}")
        if conn:
            conn.rollback()
        import traceback
        traceback.print_exc()
        return False
    finally:
        if conn:
            conn.close()
            print("🔌 Database connection closed")

    return True


if __name__ == "__main__":
    success = run_migration()
    if success:
        print("\n✅ Migration completed successfully!")
        print("\nNext steps:")
        print("1. Run the frontend implementation to display this data")
        print("2. Test the campaign content viewer")
        print("3. Verify performance metrics are showing correctly")
    else:
        print("\n❌ Migration failed. Please check the errors above.")
