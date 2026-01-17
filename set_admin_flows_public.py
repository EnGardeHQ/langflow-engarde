#!/usr/bin/env python3
"""
Script to set all admin-created flows to PUBLIC access type.
This allows them to be visible to all users in the Langflow instance.

Run this via Railway CLI:
railway run python set_admin_flows_public.py
"""

import os
import sys
from sqlalchemy import create_engine, text

def main():
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        print("ERROR: DATABASE_URL environment variable not set")
        sys.exit(1)

    print(f"Connecting to database...")
    engine = create_engine(database_url)

    with engine.connect() as conn:
        # First, check if admin user exists
        admin_result = conn.execute(
            text("SELECT id, username FROM \"user\" WHERE is_superuser = true LIMIT 1")
        ).fetchone()

        if not admin_result:
            print("ERROR: No admin user found")
            sys.exit(1)

        admin_id = admin_result[0]
        admin_username = admin_result[1]
        print(f"Found admin user: {admin_username} (ID: {admin_id})")

        # Get count of admin flows
        count_result = conn.execute(
            text("SELECT COUNT(*) FROM flow WHERE user_id = :admin_id"),
            {"admin_id": admin_id}
        ).fetchone()

        admin_flow_count = count_result[0]
        print(f"\nFound {admin_flow_count} flows created by admin")

        if admin_flow_count == 0:
            print("No admin flows to update")
            return

        # List the flows that will be updated
        flows = conn.execute(
            text("""
                SELECT id, name, access_type
                FROM flow
                WHERE user_id = :admin_id
                ORDER BY name
            """),
            {"admin_id": admin_id}
        ).fetchall()

        print("\nFlows to be set to PUBLIC:")
        for flow in flows:
            flow_id, flow_name, current_access = flow
            print(f"  - {flow_name} (current: {current_access})")

        # Update all admin flows to PUBLIC
        result = conn.execute(
            text("""
                UPDATE flow
                SET access_type = 'PUBLIC'
                WHERE user_id = :admin_id
                AND access_type != 'PUBLIC'
            """),
            {"admin_id": admin_id}
        )

        conn.commit()

        updated_count = result.rowcount
        print(f"\n✅ Successfully updated {updated_count} flows to PUBLIC access")
        print(f"These flows are now visible to all users in the Langflow instance")

        # Verify the update
        public_count = conn.execute(
            text("""
                SELECT COUNT(*)
                FROM flow
                WHERE user_id = :admin_id
                AND access_type = 'PUBLIC'
            """),
            {"admin_id": admin_id}
        ).fetchone()[0]

        print(f"\nVerification: {public_count} admin flows are now PUBLIC")

if __name__ == "__main__":
    main()
