#!/bin/bash
# scripts/start.sh - Start the application

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
PID_FILE="camera-webapp.pid"
LOG_FILE="logs/camera-webapp.log"
HOST=${HOST:-"0.0.0.0"}
PORT=${PORT:-8000}

# Create logs directory
mkdir -p logs

# Check if already running
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        log_error "Application is already running (PID: $PID)"
        log_info "Use ./scripts/stop.sh to stop it first"
        exit 1
    else
        log_info "Removing stale PID file"
        rm -f "$PID_FILE"
    fi
fi

# Activate virtual environment
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    log_info "Virtual environment activated"
else
    log_error "Virtual environment not found. Run ./scripts/install.sh first"
    exit 1
fi

# Check camera connection (optional)
log_info "Checking camera connection..."
if gphoto2 --auto-detect | grep -q "usb:"; then
    log_success "Camera detected"
else
    log_info "No camera detected (you can connect one later)"
fi

# Start the application
log_info "Starting Camera Web App on $HOST:$PORT..."

cd backend

# Start in background and save PID
nohup uvicorn main:app --host "$HOST" --port "$PORT" --log-level info > "../$LOG_FILE" 2>&1 &
echo $! > "../$PID_FILE"

# Wait a moment and check if it started successfully
sleep 3

PID=$(cat "../$PID_FILE")
if ps -p "$PID" > /dev/null 2>&1; then
    log_success "Camera Web App started successfully!"
    log_info "PID: $PID"
    log_info "Access the app at: http://localhost:$PORT"
    log_info "API documentation: http://localhost:$PORT/docs"
    log_info "Logs: tail -f $LOG_FILE"
else
    log_error "Failed to start application"
    log_info "Check logs: cat $LOG_FILE"
    rm -f "../$PID_FILE"
    exit 1
fi

---
