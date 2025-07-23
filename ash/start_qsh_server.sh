#!/bin/bash
# Start ash Model Server in background

echo "🚀 Starting ash Model Server..."

# Check if server is already running
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ ash server is already running on http://localhost:8080"
    exit 0
fi

# Start server in background
nohup python ash_server.py > qsh_server.log 2>&1 &
SERVER_PID=$!

# Wait a moment for server to start
sleep 3

# Check if server started successfully
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ ash server started successfully (PID: $SERVER_PID)"
    echo "📝 Logs: tail -f ash_server.log"
    echo "🛑 Stop with: kill $SERVER_PID"
else
    echo "❌ Failed to start ash server"
    echo "📝 Check logs: cat ash_server.log"
    exit 1
fi 