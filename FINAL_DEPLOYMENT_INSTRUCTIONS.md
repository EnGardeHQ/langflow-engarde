#!/bin/bash

# Update microservice URLs in all agent files to production URLs
# Run this script to update localhost URLs to production URLs

set -e

echo "🔧 Updating microservice URLs to production endpoints..."

# Files to update
FILES=(
    "FINAL_WALKER_AGENTS_COMPLETE.md"
    "FINAL_ENGARDE_AGENTS_COMPLETE.md"
    "FINAL_COMPLETE_MASTER_GUIDE.md"
    "FINAL_CORRECT_ALL_AGENTS.md"
)

# Backup files
echo "📦 Creating backups..."
for file in "${FILES[@]}"; do
    if [ -f "/Users/cope/EnGardeHQ/$file" ]; then
        cp "/Users/cope/EnGardeHQ/$file" "/Users/cope/EnGardeHQ/${file}.backup"
        echo "  ✓ Backed up $file"
    fi
done

# Update URLs using sed
echo "🔄 Updating URLs..."

# Update Onside
sed -i.tmp 's|ONSIDE_API_URL=http://localhost:8000|ONSIDE_API_URL=https://onside-production.up.railway.app|g' /Users/cope/EnGardeHQ/FINAL_*.md
sed -i.tmp 's|"http://localhost:8000"|"https://onside-production.up.railway.app"|g' /Users/cope/EnGardeHQ/FINAL_*.md
sed -i.tmp 's|os\.getenv("ONSIDE_API_URL", "http://localhost:8000")|os.getenv("ONSIDE_API_URL", "https://onside-production.up.railway.app")|g' /Users/cope/EnGardeHQ/FINAL_*.md

# Update Sankore
sed -i.tmp 's|SANKORE_API_URL=http://localhost:8001|SANKORE_API_URL=https://sankore-production.up.railway.app|g' /Users/cope/EnGardeHQ/FINAL_*.md
sed -i.tmp 's|"http://localhost:8001"|"https://sankore-production.up.railway.app"|g' /Users/cope/EnGardeHQ/FINAL_*.md
sed -i.tmp 's|os\.getenv("SANKORE_API_URL", "http://localhost:8001")|os.getenv("SANKORE_API_URL", "https://sankore-production.up.railway.app")|g' /Users/cope/EnGardeHQ/FINAL_*.md

# Update MadanSara
sed -i.tmp 's|MADANSARA_API_URL=http://localhost:8002|MADANSARA_API_URL=https://madansara-production.up.railway.app|g' /Users/cope/EnGardeHQ/FINAL_*.md
sed -i.tmp 's|"http://localhost:8002"|"https://madansara-production.up.railway.app"|g' /Users/cope/EnGardeHQ/FINAL_*.md
sed -i.tmp 's|os\.getenv("MADANSARA_API_URL", "http://localhost:8002")|os.getenv("MADANSARA_API_URL", "https://madansara-production.up.railway.app")|g' /Users/cope/EnGardeHQ/FINAL_*.md

# Clean up .tmp files
rm -f /Users/cope/EnGardeHQ/*.tmp

echo "✅ URLs updated successfully!"
echo ""
echo "Updated production URLs:"
echo "  - Onside: https://onside-production.up.railway.app"
echo "  - Sankore: https://sankore-production.up.railway.app"
echo "  - MadanSara: https://madansara-production.up.railway.app"
echo ""
echo "Backup files created with .backup extension"
echo "To restore backups: mv FILE.backup FILE"
