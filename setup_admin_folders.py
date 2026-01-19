#!/usr/bin/env python3
"""
Setup admin projects for EnGarde Langflow deployment.

This script creates shared admin projects (folders) and migrates existing flows:
1. Creates "Walker Agents" project for admin users (if not exists)
2. Creates "En Garde" project for admin users (if not exists - this likely already exists)
3. Migrates flows to appropriate projects based on naming conventions

In Langflow UI, these are called "Projects" - they're the organizational containers for flows.
In the database, they're stored in the "folder" table.

This runs on container startup to ensure admin project structure is correct.
"""

import os
import sys
import asyncio
import asyncpg
from datetime import datetime, timezone
from uuid import uuid4


async def setup_admin_folders():
    """Setup admin folders for all superusers"""

    # Get database URL from environment
    db_url = os.getenv('LANGFLOW_DATABASE_URL') or os.getenv('DATABASE_URL')

    if not db_url:
        print("WARNING: No database URL configured. Skipping admin folder setup.")
        return

    print("=" * 60)
    print("ADMIN FOLDER SETUP - Starting")
    print("=" * 60)

    try:
        # Connect to database
        conn = await asyncpg.connect(db_url)

        try:
            # Get all superuser accounts
            superusers = await conn.fetch(
                'SELECT id, username FROM "user" WHERE is_superuser = true'
            )

            if not superusers:
                print("No superuser accounts found. Skipping folder setup.")
                return

            print(f"Found {len(superusers)} superuser(s)")

            for user in superusers:
                user_id = str(user['id'])
                username = user['username']

                print(f"\nProcessing superuser: {username} (ID: {user_id})")

                # Create/verify "En Garde" folder
                engarde_folder_id = await ensure_folder_exists(
                    conn, user_id, "En Garde"
                )
                print(f"  ✓ En Garde folder: {engarde_folder_id}")

                # Create/verify "Walker Agents" folder
                walker_folder_id = await ensure_folder_exists(
                    conn, user_id, "Walker Agents"
                )
                print(f"  ✓ Walker Agents folder: {walker_folder_id}")

                # Migrate flows to appropriate folders
                await migrate_flows_to_folders(
                    conn, user_id, engarde_folder_id, walker_folder_id
                )

            print("\n" + "=" * 60)
            print("ADMIN FOLDER SETUP - Completed successfully")
            print("=" * 60)

        finally:
            await conn.close()

    except Exception as e:
        print(f"ERROR during admin folder setup: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        # Don't fail startup - just log the error
        print("Continuing with startup despite folder setup error...")


async def ensure_folder_exists(conn, user_id: str, folder_name: str) -> str:
    """
    Ensure a folder exists for a user. Create if not exists.

    Returns:
        Folder ID (UUID string)
    """
    # Check if folder exists
    folder = await conn.fetchrow(
        """
        SELECT id FROM folder
        WHERE user_id = $1 AND name = $2 AND parent_id IS NULL
        """,
        user_id, folder_name
    )

    if folder:
        return str(folder['id'])

    # Create folder
    folder_id = str(uuid4())
    await conn.execute(
        """
        INSERT INTO folder (id, name, user_id, parent_id)
        VALUES ($1, $2, $3, NULL)
        """,
        folder_id, folder_name, user_id
    )

    print(f"    Created new folder: '{folder_name}'")
    return folder_id


async def migrate_flows_to_folders(
    conn,
    user_id: str,
    engarde_folder_id: str,
    walker_folder_id: str
):
    """
    Migrate existing flows to appropriate folders based on naming conventions.

    Rules:
    - Flows with names containing "Walker", "SEO", "Content", "Paid Ads", "Audience"
      → Walker Agents folder
    - Flows with names containing "En Garde", "Campaign", "Basic"
      → En Garde folder
    - Flows already in folders → Skip
    """

    # Get flows not yet in any folder
    unorganized_flows = await conn.fetch(
        """
        SELECT id, name, folder_id
        FROM flow
        WHERE user_id = $1
        """,
        user_id
    )

    if not unorganized_flows:
        print("    No flows to migrate")
        return

    migrated_count = 0

    # Keywords for folder categorization
    walker_keywords = [
        'walker', 'seo', 'content', 'paid ads', 'paid_ads',
        'audience', 'intelligence'
    ]

    engarde_keywords = [
        'en garde', 'engarde', 'campaign', 'basic', 'simple',
        'starter', 'template'
    ]

    for flow in unorganized_flows:
        flow_id = str(flow['id'])
        flow_name = flow['name'].lower()
        current_folder_id = flow['folder_id']

        # Determine target folder
        target_folder_id = None
        target_folder_name = None

        # Check if already in correct folder
        if current_folder_id == walker_folder_id:
            continue
        if current_folder_id == engarde_folder_id:
            continue

        # Check for walker agent keywords
        if any(keyword in flow_name for keyword in walker_keywords):
            target_folder_id = walker_folder_id
            target_folder_name = "Walker Agents"
        # Check for en garde keywords
        elif any(keyword in flow_name for keyword in engarde_keywords):
            target_folder_id = engarde_folder_id
            target_folder_name = "En Garde"
        else:
            # Default: put in En Garde folder
            target_folder_id = engarde_folder_id
            target_folder_name = "En Garde"

        # Only migrate if not already in a folder
        if current_folder_id is None:
            await conn.execute(
                """
                UPDATE flow
                SET folder_id = $1
                WHERE id = $2
                """,
                target_folder_id, flow_id
            )

            print(f"    Migrated '{flow['name']}' → {target_folder_name}")
            migrated_count += 1

    if migrated_count > 0:
        print(f"    Total migrated: {migrated_count} flow(s)")
    else:
        print("    No flows needed migration")


if __name__ == "__main__":
    asyncio.run(setup_admin_folders())
