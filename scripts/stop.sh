#!/bin/bash
# scripts/stop.sh - Stop the application

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

PID_FILE="camera-webapp.pid"

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
    log_error "PID file not found. Application may not be running."
    
    # Try to find and kill any running uvicorn processes
    log_info "Searching for running camera webapp processes..."
    PIDS=$(pgrep -f "uvicorn.*main:app" || true)
    
    if [ -n "$PIDS" ]; then
        log_warning "Found running processes: $PIDS"
        read -p "Kill these processes? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kill $PIDS
            log_success "Processes terminated"
        fi
    else
        log_info "No running processes found"
    fi
    exit 0
fi

# Read PID and check if process is running
PID=$(cat "$PID_FILE")
log_info "Found PID: $PID"

if ps -p "$PID" > /dev/null 2>&1; then
    log_info "Stopping Camera Web App (PID: $PID)..."
    
    # Try graceful shutdown first
    kill "$PID"
    
    # Wait for graceful shutdown
    for i in {1..10}; do
        if ! ps -p "$PID" > /dev/null 2>&1; then
            log_success "Application stopped gracefully"
            break
        fi
        sleep 1
    done
    
    # Force kill if still running
    if ps -p "$PID" > /dev/null 2>&1; then
        log_warning "Graceful shutdown failed, forcing termination..."
        kill -9 "$PID"
        sleep 2
        
        if ps -p "$PID" > /dev/null 2>&1; then
            log_error "Failed to stop process $PID"
            exit 1
        else
            log_success "Process terminated forcefully"
        fi
    fi
else
    log_warning "Process $PID not found (may have already stopped)"
fi

# Clean up PID file
rm -f "$PID_FILE"
log_success "Cleanup completed"

---
