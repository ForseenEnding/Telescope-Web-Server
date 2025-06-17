#!/bin/bash
# scripts/logs.sh - View application logs

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

LOG_FILE="logs/camera-webapp.log"
LINES=${1:-50}  # Default to 50 lines

if [ ! -f "$LOG_FILE" ]; then
    echo "Log file not found: $LOG_FILE"
    echo "Application may not be running or hasn't been started yet."
    exit 1
fi

echo -e "${GREEN}Camera Web App Logs${NC}"
echo "===================="
echo

# Check if application is running
if [ -f "camera-webapp.pid" ]; then
    PID=$(cat camera-webapp.pid)
    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${GREEN}Status:${NC} Running (PID: $PID)"
    else
        echo -e "${GREEN}Status:${NC} Stopped"
    fi
else
    echo -e "${GREEN}Status:${NC} Not started"
fi

echo "Log file: $LOG_FILE"
echo "===================="
echo

# Show logs
if [ "$1" = "-f" ] || [ "$1" = "--follow" ]; then
    log_info "Following logs (Ctrl+C to exit)..."
    tail -f "$LOG_FILE"
elif [ "$1" = "-a" ] || [ "$1" = "--all" ]; then
    log_info "Showing all logs..."
    cat "$LOG_FILE"
else
    log_info "Showing last $LINES lines (use -f to follow, -a for all)..."
    tail -n "$LINES" "$LOG_FILE"
fi

---
