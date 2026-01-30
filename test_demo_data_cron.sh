#!/bin/bash
# Test script for demo-data-cron service
# This script helps verify the cron configuration without waiting for scheduled runs

echo "🧪 Demo Data Cron Test Script"
echo "=============================="
echo ""

# Check if Railway CLI is available
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found. Please install it first:"
    echo "   npm i -g @railway/cli"
    exit 1
fi

echo "✅ Railway CLI found"
echo ""

# Check if logged in
if ! railway whoami &> /dev/null; then
    echo "❌ Not logged in to Railway. Please run:"
    echo "   railway login"
    exit 1
fi

echo "✅ Logged in to Railway"
echo ""

# Link to the service
echo "🔗 Linking to demo-data-cron service..."
cd /Users/cope/EnGardeHQ/production-backend || exit 1
railway link -s demo-data-cron

echo ""
echo "📊 Current Service Status:"
railway status

echo ""
echo "🔍 Current Environment Variables:"
railway variables

echo ""
echo "📝 Recent Deployment Logs:"
railway logs --limit 50

echo ""
echo "=============================="
echo "Test Options:"
echo "=============================="
echo ""
echo "1. Manual Run (execute script now):"
echo "   railway run python scripts/generate_demo_data.py"
echo ""
echo "2. View Live Logs:"
echo "   railway logs --follow"
echo ""
echo "3. Check Deployment Status:"
echo "   railway status"
echo ""
echo "4. Trigger New Deployment:"
echo "   railway up"
echo ""
echo "=============================="
echo ""

read -p "Would you like to run the demo data script manually now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Running demo data generation script..."
    echo "=============================="
    railway run python scripts/generate_demo_data.py

    EXIT_CODE=$?
    echo ""
    echo "=============================="
    if [ $EXIT_CODE -eq 0 ]; then
        echo "✅ Script completed successfully!"
    else
        echo "❌ Script failed with exit code: $EXIT_CODE"
    fi
else
    echo ""
    echo "ℹ️  Skipping manual run. You can run it later with:"
    echo "   railway run python scripts/generate_demo_data.py"
fi

echo ""
echo "📚 For more information, see:"
echo "   production-backend/DEMO_DATA_CRON_SETUP.md"
echo ""
