#!/bin/bash

echo "=== Docker Build Monitor ==="
echo ""

# Check if build is running
if ps aux | grep -q "[d]ocker buildx build"; then
    echo "✅ Build is RUNNING"
    echo ""

    # Show process details
    echo "Process info:"
    ps aux | grep "[d]ocker buildx build" | head -1
    echo ""

    # Check log file
    if [ -f /tmp/docker-push.log ]; then
        lines=$(wc -l < /tmp/docker-push.log)
        echo "Log file: /tmp/docker-push.log ($lines lines)"
        echo ""
        echo "Last 20 lines:"
        tail -20 /tmp/docker-push.log
    else
        echo "⚠️  Log file not yet created"
    fi
else
    echo "❌ Build is NOT running"
    echo ""

    # Check if it completed
    if [ -f /tmp/docker-push.log ]; then
        echo "Checking log file for completion status..."
        if grep -q "ERROR" /tmp/docker-push.log; then
            echo "❌ Build FAILED"
            echo ""
            grep -A 5 "ERROR" /tmp/docker-push.log | tail -20
        elif grep -q "pushing.*done" /tmp/docker-push.log; then
            echo "✅ Build COMPLETED and pushed to Docker Hub!"
        else
            echo "⚠️  Build status unknown"
            tail -20 /tmp/docker-push.log
        fi
    fi
fi

echo ""
echo "=== To monitor live ==="
echo "tail -f /tmp/docker-push.log"
