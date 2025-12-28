#!/usr/bin/env python3
"""
Verification script for Walker Agents database schema and seeding.

This script checks:
1. If agent_category column exists in ai_agents table
2. If Walker agents are seeded (4 agents with agent_category='walker')
3. Count of En Garde agents (agent_category='en_garde')

Usage:
    python verify_walker_agents.py [--fix]

    --fix: Automatically run migrations and seeding if needed
"""

import os
import sys
import argparse
from pathlib import Path

# Add production-backend to path
backend_path = Path(__file__).parent / "production-backend"
sys.path.insert(0, str(backend_path))

from sqlalchemy import create_engine, text, inspect
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import SQLAlchemyError


def get_database_url():
    """Get database URL from environment or default Railway settings"""
    # Try multiple environment variable sources
    db_url = (
        os.getenv("DATABASE_PUBLIC_URL") or
        os.getenv("DATABASE_URL") or
        os.getenv("ALEMBIC_DATABASE_URL")
    )

    if not db_url:
        print("❌ No database URL found in environment variables")
        print("   Please set one of: DATABASE_PUBLIC_URL, DATABASE_URL, or ALEMBIC_DATABASE_URL")
        print("\nChecking for Railway env file...")

        # Try to load from railway env backup
        railway_env = backend_path / "railway_env_backup.env"
        if railway_env.exists():
            print(f"✅ Found Railway env file: {railway_env}")
            with open(railway_env) as f:
                for line in f:
                    if line.startswith("DATABASE_URL="):
                        db_url = line.split("=", 1)[1].strip()
                        print(f"   Using DATABASE_URL from railway_env_backup.env")
                        break

    return db_url


def check_agent_category_column(engine):
    """Check if agent_category column exists in ai_agents table"""
    print("\n" + "="*80)
    print("1. CHECKING agent_category COLUMN")
    print("="*80)

    try:
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns
                WHERE table_name = 'ai_agents' AND column_name = 'agent_category'
            """))
            row = result.fetchone()

            if row:
                print("✅ agent_category column EXISTS")
                print(f"   Column: {row[0]}")
                print(f"   Type: {row[1]}")
                print(f"   Nullable: {row[2]}")
                print(f"   Default: {row[3]}")
                return True
            else:
                print("❌ agent_category column DOES NOT EXIST")
                print("   Migration needs to be run!")
                print(f"   Migration file: {backend_path}/migrations/add_agent_category_column.sql")
                return False

    except SQLAlchemyError as e:
        print(f"❌ Error checking column: {e}")
        return False


def check_walker_agents(engine):
    """Check if Walker agents are seeded"""
    print("\n" + "="*80)
    print("2. CHECKING WALKER AGENTS")
    print("="*80)

    try:
        with engine.connect() as conn:
            # Check distribution by category
            result = conn.execute(text("""
                SELECT
                    agent_category,
                    COUNT(*) as count,
                    array_agg(DISTINCT agent_type) as types
                FROM ai_agents
                GROUP BY agent_category
            """))

            print("\nAgent Distribution by Category:")
            rows = result.fetchall()

            walker_count = 0
            en_garde_count = 0

            for row in rows:
                category = row[0] or 'NULL'
                count = row[1]
                types = row[2] or []

                print(f"\n  {category}:")
                print(f"    Count: {count}")
                print(f"    Types: {', '.join(types) if types else 'None'}")

                if category == 'walker':
                    walker_count = count
                elif category == 'en_garde':
                    en_garde_count = count

            # Check specific Walker agents
            print("\n" + "-"*80)
            print("Walker Agents Detail:")
            print("-"*80)

            result = conn.execute(text("""
                SELECT id, name, agent_type, agent_category, is_system_agent
                FROM ai_agents
                WHERE agent_category = 'walker'
                ORDER BY name
            """))

            walker_agents = result.fetchall()

            if walker_agents:
                print(f"\n✅ Found {len(walker_agents)} Walker agent(s):\n")
                for agent in walker_agents:
                    id_, name, agent_type, category, is_system = agent
                    protected = "🔒 Protected" if is_system else "⚠️  Not Protected"
                    print(f"  {protected}")
                    print(f"    Name: {name}")
                    print(f"    Type: {agent_type}")
                    print(f"    ID: {id_}")
                    print()

                # Expected Walker agents
                expected_types = {
                    'paid_ads_optimization',
                    'seo_optimization',
                    'content_generation',
                    'audience_intelligence'
                }

                actual_types = {agent[2] for agent in walker_agents}
                missing_types = expected_types - actual_types

                if missing_types:
                    print(f"⚠️  WARNING: Missing Walker agent types:")
                    for t in missing_types:
                        print(f"    - {t}")
                    print(f"\n   Seed script: {backend_path}/scripts/seed_walker_agents.py")
                    return False
                else:
                    print("✅ All 4 expected Walker agent types found!")

                    # Check protection
                    unprotected = [a for a in walker_agents if not a[4]]
                    if unprotected:
                        print(f"\n⚠️  WARNING: {len(unprotected)} Walker agents are NOT protected (is_system_agent=False)")
                        return False
                    else:
                        print("✅ All Walker agents are protected (is_system_agent=True)")
                        return True
            else:
                print("❌ NO Walker agents found!")
                print(f"   Seed script needs to be run: {backend_path}/scripts/seed_walker_agents.py")
                return False

    except SQLAlchemyError as e:
        print(f"❌ Error checking Walker agents: {e}")
        return False


def check_en_garde_agents(engine):
    """Check En Garde agents count"""
    print("\n" + "="*80)
    print("3. CHECKING EN GARDE AGENTS")
    print("="*80)

    try:
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT COUNT(*)
                FROM ai_agents
                WHERE agent_category = 'en_garde'
            """))

            count = result.fetchone()[0]
            print(f"\n✅ Found {count} En Garde agent(s)")

            if count == 0:
                print("   (No En Garde agents yet - this is OK)")

            return True

    except SQLAlchemyError as e:
        print(f"❌ Error checking En Garde agents: {e}")
        return False


def run_migration(engine, migration_file):
    """Run migration SQL file"""
    print(f"\n🔧 Running migration: {migration_file.name}")

    try:
        with open(migration_file) as f:
            sql = f.read()

        with engine.begin() as conn:
            # Execute migration (split on semicolons for multiple statements)
            for statement in sql.split(';'):
                statement = statement.strip()
                if statement:
                    conn.execute(text(statement))

        print("✅ Migration completed successfully!")
        return True

    except Exception as e:
        print(f"❌ Migration failed: {e}")
        return False


def run_seed_script(script_path):
    """Run Python seed script"""
    print(f"\n🌱 Running seed script: {script_path.name}")

    try:
        # Import and run the seed script
        import subprocess
        result = subprocess.run(
            [sys.executable, str(script_path)],
            cwd=str(backend_path),
            capture_output=True,
            text=True
        )

        print(result.stdout)
        if result.stderr:
            print(result.stderr)

        if result.returncode == 0:
            print("✅ Seed script completed successfully!")
            return True
        else:
            print(f"❌ Seed script failed with exit code {result.returncode}")
            return False

    except Exception as e:
        print(f"❌ Seed script failed: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Verify Walker Agents database schema and seeding"
    )
    parser.add_argument(
        '--fix',
        action='store_true',
        help='Automatically run migrations and seeding if needed'
    )
    args = parser.parse_args()

    print("="*80)
    print("WALKER AGENTS DATABASE VERIFICATION")
    print("="*80)

    # Get database URL
    db_url = get_database_url()
    if not db_url:
        print("\n❌ Cannot proceed without database URL")
        return 1

    # Mask password in output
    masked_url = db_url
    if '@' in db_url and ':' in db_url:
        parts = db_url.split('@')
        if len(parts) == 2:
            creds = parts[0].split('//')[-1]
            if ':' in creds:
                user = creds.split(':')[0]
                masked_url = db_url.replace(creds, f"{user}:****")

    print(f"\n📊 Database URL: {masked_url}")

    # Create engine
    try:
        # Replace internal Railway URL with public URL if needed
        if 'postgres.railway.internal' in db_url:
            print("\n⚠️  WARNING: Using internal Railway URL - this may not work from local machine")
            print("   Consider using Railway CLI or running on Railway environment")

        engine = create_engine(
            db_url,
            pool_pre_ping=True,
            connect_args={"connect_timeout": 10}
        )

        # Test connection
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))

        print("✅ Database connection successful!")

    except Exception as e:
        print(f"\n❌ Database connection failed: {e}")
        print("\nPossible solutions:")
        print("  1. Ensure database is running and accessible")
        print("  2. Check DATABASE_URL is correct")
        print("  3. If using Railway, consider running this on Railway environment")
        print("  4. Try: railway run python verify_walker_agents.py")
        return 1

    # Run checks
    column_exists = check_agent_category_column(engine)
    walker_agents_ok = check_walker_agents(engine)
    en_garde_agents_ok = check_en_garde_agents(engine)

    # Summary
    print("\n" + "="*80)
    print("VERIFICATION SUMMARY")
    print("="*80)

    all_ok = column_exists and walker_agents_ok and en_garde_agents_ok

    if all_ok:
        print("\n✅ ALL CHECKS PASSED!")
        print("   - agent_category column exists")
        print("   - All 4 Walker agents are seeded and protected")
        print("   - En Garde agents count retrieved successfully")
        return 0
    else:
        print("\n⚠️  ISSUES FOUND:")

        if not column_exists:
            print("   ❌ agent_category column missing")
            migration_file = backend_path / "migrations" / "add_agent_category_column.sql"

            if args.fix and migration_file.exists():
                if run_migration(engine, migration_file):
                    column_exists = True
                    print("   ✅ Migration applied!")
                else:
                    print("   ❌ Migration failed - manual intervention required")
            else:
                print(f"      Run migration: {migration_file}")
                if not args.fix:
                    print("      Or use --fix flag to auto-apply")

        if not walker_agents_ok:
            print("   ❌ Walker agents not properly seeded")
            seed_script = backend_path / "scripts" / "seed_walker_agents.py"

            if args.fix and seed_script.exists() and column_exists:
                if run_seed_script(seed_script):
                    walker_agents_ok = True
                    print("   ✅ Walker agents seeded!")
                else:
                    print("   ❌ Seeding failed - manual intervention required")
            else:
                print(f"      Run seed script: {seed_script}")
                if not args.fix:
                    print("      Or use --fix flag to auto-seed")
                elif not column_exists:
                    print("      (Must fix column first before seeding)")

        if args.fix:
            # Re-run checks after fixes
            print("\n" + "="*80)
            print("RE-VERIFYING AFTER FIXES")
            print("="*80)

            column_exists = check_agent_category_column(engine)
            walker_agents_ok = check_walker_agents(engine)
            en_garde_agents_ok = check_en_garde_agents(engine)

            if column_exists and walker_agents_ok and en_garde_agents_ok:
                print("\n✅ ALL ISSUES RESOLVED!")
                return 0
            else:
                print("\n⚠️  Some issues remain - manual intervention may be required")
                return 1
        else:
            print("\n💡 Use --fix flag to automatically apply fixes")
            return 1


if __name__ == "__main__":
    sys.exit(main())
