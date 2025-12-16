#!/bin/bash

# Find available backend port (8000-8005)
find_available_port() {
    for port in {8000..8005}; do
        if ! lsof -i :$port > /dev/null 2>&1; then
            echo $port
            return
        fi
    done
    echo "No available ports in range 8000-8005"
    exit 1
}

# Find available frontend port (3000-3005)
find_available_frontend_port() {
    for port in {3000..3005}; do
        if ! lsof -i :$port > /dev/null 2>&1; then
            echo $port
            return
        fi
    done
    echo "No available ports in range 3000-3005"
    exit 1
}

BACKEND_PORT=$(find_available_port)
FRONTEND_PORT=$(find_available_frontend_port)

echo "Starting backend on port $BACKEND_PORT"
echo "Starting frontend on port $FRONTEND_PORT"

# Start backend
cd /Users/cope/EnGardeHQ/production-backend
python3 -m uvicorn app.main_minimal:app --host 0.0.0.0 --port $BACKEND_PORT --timeout-keep-alive 60 &
BACKEND_PID=$!

# Start frontend with correct API URL
cd /Users/cope/EnGardeHQ/production-frontend
NEXT_PUBLIC_API_URL=http://localhost:$BACKEND_PORT PORT=$FRONTEND_PORT npm run dev &
FRONTEND_PID=$!

echo "Backend running on http://localhost:$BACKEND_PORT (PID: $BACKEND_PID)"
echo "Frontend running on http://localhost:$FRONTEND_PORT (PID: $FRONTEND_PID)"
echo "Use 'kill $BACKEND_PID $FRONTEND_PID' to stop both servers"

# Wait for processes
wait
