#!/usr/bin/env python3
"""
Run team member limits migration directly on Railway database
"""
import psycopg2
import os

# Database connection
DATABASE_URL = "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

def run_migration():
    conn = None
    try:
        print("🔌 Connecting to Railway database...")
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()

        print("📊 Checking if max_team_members column exists...")
        cursor.execute("""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = 'plan_tier_configs'
            AND column_name = 'max_team_members';
        """)

        if cursor.fetchone():
            print("⚠️  Column max_team_members already exists! Skipping migration.")
            cursor.close()
            conn.close()
            return

        print("➕ Adding max_team_members column to plan_tier_configs table...")

        # Add the column with default value
        cursor.execute("""
            ALTER TABLE plan_tier_configs
            ADD COLUMN max_team_members INTEGER NOT NULL DEFAULT 1;
        """)

        print("✅ Column added successfully!")

        print("🔄 Updating values based on tier_id...")

        # Update values based on tier_id
        cursor.execute("""
            UPDATE plan_tier_configs
            SET max_team_members = CASE tier_id
                WHEN 'starter' THEN 1
                WHEN 'professional' THEN 3
                WHEN 'business' THEN 5
                WHEN 'enterprise' THEN -1
                ELSE 1
            END;
        """)

        rows_updated = cursor.rowcount
        print(f"✅ Updated {rows_updated} plan tier configs with team member limits!")

        # Verify the changes
        print("\n📋 Verification - Current plan tier limits:")
        cursor.execute("""
            SELECT tier_id, tier_name, max_team_members
            FROM plan_tier_configs
            ORDER BY sort_order;
        """)

        results = cursor.fetchall()
        if results:
            print(f"{'Tier ID':<15} {'Tier Name':<20} {'Max Team Members'}")
            print("-" * 60)
            for tier_id, tier_name, max_members in results:
                members_text = "Unlimited" if max_members == -1 else str(max_members)
                print(f"{tier_id:<15} {tier_name:<20} {members_text}")
        else:
            print("⚠️  No plan tiers found! You may need to seed the plan_tier_configs table.")

        # Commit the changes
        conn.commit()
        print("\n✅ Migration completed successfully!")

        cursor.close()

    except Exception as e:
        print(f"❌ Error running migration: {e}")
        if conn:
            conn.rollback()
        import traceback
        traceback.print_exc()
    finally:
        if conn:
            conn.close()
            print("\n🔌 Database connection closed")

if __name__ == "__main__":
    print("=" * 60)
    print("TEAM MEMBER LIMITS MIGRATION")
    print("=" * 60)
    print()
    run_migration()
