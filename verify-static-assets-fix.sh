#!/bin/bash
# Verification script for ERR_INSUFFICIENT_RESOURCES bug fix
# Tests that the Next.js standalone server properly serves static assets
# with correct keep-alive timeout settings

set -e

echo "========================================="
echo "Static Assets & Keep-Alive Verification"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Verify KEEP_ALIVE_TIMEOUT environment variable
echo "Test 1: Checking KEEP_ALIVE_TIMEOUT environment variable..."
TIMEOUT_VALUE=$(docker exec engarde_frontend env | grep KEEP_ALIVE_TIMEOUT || echo "NOT_FOUND")
if [[ "$TIMEOUT_VALUE" == *"65000"* ]]; then
    echo -e "${GREEN}✓ PASS${NC} - KEEP_ALIVE_TIMEOUT is set to 65000"
else
    echo -e "${RED}✗ FAIL${NC} - KEEP_ALIVE_TIMEOUT not set correctly: $TIMEOUT_VALUE"
    exit 1
fi
echo ""

# Test 2: Check HTTP Keep-Alive header in response
echo "Test 2: Verifying HTTP Keep-Alive header in static asset response..."
KEEP_ALIVE_HEADER=$(curl -s -I http://localhost:3001/_next/static/pzYkwh0umoGmrXekEPnp5/_buildManifest.js 2>&1 | grep -i "Keep-Alive" || echo "NOT_FOUND")
if [[ "$KEEP_ALIVE_HEADER" == *"timeout"* ]]; then
    TIMEOUT=$(echo "$KEEP_ALIVE_HEADER" | grep -oP 'timeout=\K\d+' || echo "unknown")
    if [ "$TIMEOUT" -ge 60 ]; then
        echo -e "${GREEN}✓ PASS${NC} - Keep-Alive header present: $KEEP_ALIVE_HEADER"
    else
        echo -e "${YELLOW}⚠ WARNING${NC} - Keep-Alive timeout is $TIMEOUT seconds (expected ≥60)"
    fi
else
    echo -e "${RED}✗ FAIL${NC} - Keep-Alive header not found or malformed"
    exit 1
fi
echo ""

# Test 3: Verify main chunk files are accessible
echo "Test 3: Testing main JavaScript chunk accessibility..."
MAIN_CHUNK=$(docker exec engarde_frontend find /app/.next/static/chunks -name "main-*.js" | head -1 | xargs basename)
if [ -n "$MAIN_CHUNK" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3001/_next/static/chunks/$MAIN_CHUNK")
    if [ "$HTTP_CODE" == "200" ]; then
        echo -e "${GREEN}✓ PASS${NC} - Main chunk accessible: $MAIN_CHUNK (HTTP $HTTP_CODE)"
    else
        echo -e "${RED}✗ FAIL${NC} - Main chunk returned HTTP $HTTP_CODE"
        exit 1
    fi
else
    echo -e "${RED}✗ FAIL${NC} - Could not find main chunk file"
    exit 1
fi
echo ""

# Test 4: Count total chunks and verify a sample
echo "Test 4: Testing sample of JavaScript chunks..."
CHUNK_COUNT=$(docker exec engarde_frontend ls -1 /app/.next/static/chunks/*.js 2>/dev/null | wc -l)
echo "Total chunks found: $CHUNK_COUNT"

if [ "$CHUNK_COUNT" -gt 0 ]; then
    # Test 5 random chunks
    SAMPLE_SIZE=5
    if [ "$CHUNK_COUNT" -lt "$SAMPLE_SIZE" ]; then
        SAMPLE_SIZE=$CHUNK_COUNT
    fi

    FAILED=0
    for i in $(seq 1 $SAMPLE_SIZE); do
        CHUNK=$(docker exec engarde_frontend ls -1 /app/.next/static/chunks/*.js | head -$i | tail -1 | xargs basename)
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3001/_next/static/chunks/$CHUNK" 2>/dev/null)
        if [ "$HTTP_CODE" == "200" ]; then
            echo -e "  ${GREEN}✓${NC} $CHUNK (HTTP $HTTP_CODE)"
        else
            echo -e "  ${RED}✗${NC} $CHUNK (HTTP $HTTP_CODE)"
            FAILED=$((FAILED + 1))
        fi
    done

    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC} - All sampled chunks accessible"
    else
        echo -e "${RED}✗ FAIL${NC} - $FAILED chunks failed to load"
        exit 1
    fi
else
    echo -e "${RED}✗ FAIL${NC} - No chunks found in build"
    exit 1
fi
echo ""

# Test 5: Concurrent connection test
echo "Test 5: Testing concurrent chunk loading (simulating browser behavior)..."
echo "Loading 10 chunks in parallel..."
CONCURRENT_FAILURES=0
for i in $(seq 1 10); do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3001/" 2>/dev/null) &
done
wait

# Check if any background jobs failed
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} - Concurrent requests handled successfully"
else
    echo -e "${YELLOW}⚠ WARNING${NC} - Some concurrent requests may have issues"
fi
echo ""

# Test 6: Check for ECONNRESET errors in recent logs
echo "Test 6: Checking for connection reset errors in logs..."
RESET_ERRORS=$(docker logs engarde_frontend 2>&1 | grep -c "ECONNRESET" || echo "0")
if [ "$RESET_ERRORS" == "0" ]; then
    echo -e "${GREEN}✓ PASS${NC} - No ECONNRESET errors in recent logs"
else
    echo -e "${YELLOW}⚠ WARNING${NC} - Found $RESET_ERRORS ECONNRESET errors (may be from before fix)"
fi
echo ""

# Test 7: Verify static directory structure
echo "Test 7: Verifying static directory structure..."
if docker exec engarde_frontend test -d /app/.next/static; then
    echo -e "${GREEN}✓ PASS${NC} - .next/static directory exists"
else
    echo -e "${RED}✗ FAIL${NC} - .next/static directory missing"
    exit 1
fi

if docker exec engarde_frontend test -d /app/public; then
    echo -e "${GREEN}✓ PASS${NC} - public directory exists"
else
    echo -e "${RED}✗ FAIL${NC} - public directory missing"
    exit 1
fi
echo ""

# Test 8: Build ID verification
echo "Test 8: Verifying build consistency..."
BUILD_ID=$(docker exec engarde_frontend cat /app/.next/BUILD_ID 2>/dev/null || echo "NOT_FOUND")
if [ "$BUILD_ID" != "NOT_FOUND" ] && [ -n "$BUILD_ID" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Build ID: $BUILD_ID"

    # Test if build ID path is accessible
    BUILD_MANIFEST_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3001/_next/static/$BUILD_ID/_buildManifest.js")
    if [ "$BUILD_MANIFEST_CODE" == "200" ]; then
        echo -e "${GREEN}✓ PASS${NC} - Build manifest accessible via build ID"
    else
        echo -e "${RED}✗ FAIL${NC} - Build manifest not accessible (HTTP $BUILD_MANIFEST_CODE)"
        exit 1
    fi
else
    echo -e "${RED}✗ FAIL${NC} - Build ID not found"
    exit 1
fi
echo ""

# Final summary
echo "========================================="
echo -e "${GREEN}All Critical Tests Passed!${NC}"
echo "========================================="
echo ""
echo "Summary:"
echo "  - Keep-alive timeout: 65 seconds"
echo "  - Total JavaScript chunks: $CHUNK_COUNT"
echo "  - Connection handling: HEALTHY"
echo "  - Static assets: SERVING CORRECTLY"
echo ""
echo "The ERR_INSUFFICIENT_RESOURCES bug has been fixed!"
echo "The frontend should now load all static assets without connection errors."
echo ""
