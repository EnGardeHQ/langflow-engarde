#!/bin/bash
# Script to set JWT_SECRET_KEY in Railway
# This fixes the "Could not validate credentials" error during token refresh

JWT_SECRET="a44fe15adf6a091dd88c6345d6eea0f66466a97708655f7046e8b2ec7b9cc0c3"

echo "========================================"
echo "Setting JWT_SECRET_KEY in Railway"
echo "========================================"
echo ""

# Option 1: Use Railway CLI (requires interactive login)
echo "Option 1: Using Railway CLI"
echo "Run this command manually:"
echo ""
echo "railway variables set JWT_SECRET_KEY=\"$JWT_SECRET\""
echo ""

# Option 2: Manual steps for Railway Dashboard
echo "========================================"
echo "Option 2: Using Railway Dashboard"
echo "========================================"
echo "1. Go to: https://railway.app/dashboard"
echo "2. Select your project: EnGardeHQ"
echo "3. Select service: backend (or production-backend)"
echo "4. Click on 'Variables' tab"
echo "5. Click '+ New Variable'"
echo "6. Set:"
echo "   Name: JWT_SECRET_KEY"
echo "   Value: $JWT_SECRET"
echo "7. Click 'Add'"
echo "8. Railway will automatically redeploy"
echo ""

echo "========================================"
echo "After Setting the Variable"
echo "========================================"
echo "1. Wait for Railway to redeploy (~2-3 minutes)"
echo "2. Clear browser storage (see clear-frontend-tokens.html)"
echo "3. Refresh the page and login again"
echo ""

echo "========================================"
echo "Verification"
echo "========================================"
echo "Test the refresh endpoint:"
echo ""
echo "curl -X POST https://api.engarde.media/api/auth/refresh \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"refresh_token\": \"YOUR_REFRESH_TOKEN\"}'"
echo ""
