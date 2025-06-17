#!/bin/bash
# scripts/quick-start.sh - One-command setup and start

set -e

echo "🚀 Camera Web App Quick Start"
echo "============================="
echo

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -f "requirements.txt" ]; then
    echo "❌ This doesn't appear to be the camera-webapp directory"
    echo "Please run this script from the camera-webapp root directory"
    exit 1
fi

# Check if already installed
if [ -d "venv" ] && [ -f "frontend/scripts/main.js" ]; then
    echo "✅ Installation detected"
    
    # Just start if already installed
    if [ -f "camera-webapp.pid" ]; then
        PID=$(cat camera-webapp.pid)
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "✅ Application is already running!"
            echo "🌐 Access: http://localhost:8000"
            echo "📚 API Docs: http://localhost:8000/docs"
            exit 0
        fi
    fi
    
    echo "🚀 Starting application..."
    ./scripts/start.sh
else
    echo "📦 Running installation..."
    ./scripts/install.sh
    
    echo
    echo "🚀 Starting application..."
    ./scripts/start.sh
fi

echo
echo "🎉 Camera Web App is ready!"
echo "🌐 Web Interface: http://localhost:8000"
echo "📚 API Documentation: http://localhost:8000/docs"
echo "📋 Health Check: ./scripts/health-check.sh"
echo "📊 View Logs: ./scripts/logs.sh -f"
echo "🛑 Stop App: ./scripts/stop.sh"
echo
echo "💡 Tips:"
echo "- Connect your camera via USB before using"
echo "- Ensure camera is in PTP/PC mode"
echo "- Check camera permissions if connection fails"

---