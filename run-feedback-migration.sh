#!/bin/bash

# Walker Agent Feedback Migration Runner
# This script runs the database migration for feedback collection features

set -e  # Exit on error

echo "=================================================="
echo "Walker Agent Feedback Migration"
echo "=================================================="
echo ""

# Check if DATABASE_PUBLIC_URL is set
if [ -z "$DATABASE_PUBLIC_URL" ]; then
    echo "❌ ERROR: DATABASE_PUBLIC_URL environment variable is not set"
    echo ""
    echo "Please set it using one of these methods:"
    echo ""
    echo "Option 1 - Temporary (current session):"
    echo "  export DATABASE_PUBLIC_URL='postgresql://user:password@host:port/database'"
    echo ""
    echo "Option 2 - Run directly:"
    echo "  DATABASE_PUBLIC_URL='postgresql://...' ./run-feedback-migration.sh"
    echo ""
    echo "Option 3 - Railway CLI:"
    echo "  railway variables | grep DATABASE_PUBLIC_URL"
    echo "  export DATABASE_PUBLIC_URL=\$(railway variables | grep DATABASE_PUBLIC_URL | cut -d'=' -f2)"
    echo ""
    exit 1
fi

echo "✓ DATABASE_PUBLIC_URL is set"
echo ""

# Check if migration file exists
MIGRATION_FILE="database-setup/walker_feedback_enhancements.sql"
if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ ERROR: Migration file not found: $MIGRATION_FILE"
    exit 1
fi

echo "✓ Migration file found: $MIGRATION_FILE"
echo ""

# Ask for confirmation
echo "This will run the following changes:"
echo "  - Add 4 columns to chat_sessions table"
echo "  - Create 2 database views for analytics"
echo "  - Create 3 database functions"
echo "  - Create 2 triggers"
echo "  - Create 7 indexes"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Migration cancelled."
    exit 0
fi

echo ""
echo "Running migration..."
echo "=================================================="

# Run the migration
psql "$DATABASE_PUBLIC_URL" -f "$MIGRATION_FILE"

MIGRATION_EXIT_CODE=$?

echo "=================================================="
echo ""

if [ $MIGRATION_EXIT_CODE -eq 0 ]; then
    echo "✅ Migration completed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Add walker_feedback router to backend (see WALKER_FEEDBACK_QUICK_START.md)"
    echo "  2. Integrate ConversationFeedbackModal into your chat UI"
    echo "  3. Test with a sample conversation"
    echo ""
    echo "Verification query:"
    echo "  psql \$DATABASE_PUBLIC_URL -c \"SELECT * FROM should_prompt_feedback('tenant-id', 'conversation-id');\""
else
    echo "❌ Migration failed with exit code: $MIGRATION_EXIT_CODE"
    echo ""
    echo "Common issues:"
    echo "  - Insufficient permissions: Grant CREATE, ALTER permissions"
    echo "  - Objects already exist: Check if previous migration ran partially"
    echo "  - Connection error: Verify DATABASE_PUBLIC_URL is correct"
    echo ""
    echo "To troubleshoot, run:"
    echo "  psql \$DATABASE_PUBLIC_URL -c \"SELECT version();\""
    exit $MIGRATION_EXIT_CODE
fi
