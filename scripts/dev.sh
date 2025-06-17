#!/bin/bash
# scripts/dev.sh - Development mode startup

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Activate virtual environment
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    log_info "Virtual environment activated"
else
    log_error "Virtual environment not found. Run ./scripts/install.sh first"
    exit 1
fi

log_info "Starting development environment..."

# Function to cleanup background processes
cleanup() {
    log_info "Stopping development servers..."
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    exit 0
}

# Set trap for cleanup
trap cleanup SIGINT SIGTERM

# Start TypeScript watch in background
log_info "Starting TypeScript compiler in watch mode..."
npm run watch &
FRONTEND_PID=$!

# Wait a moment for initial compilation
sleep 3

# Start backend with reload
log_info "Starting backend with auto-reload..."
log_success "Development environment ready!"
echo
log_info "Frontend: TypeScript watch mode active"
log_info "Backend: http://localhost:8000 (auto-reload enabled)"
log_info "API Docs: http://localhost:8000/docs"
echo
log_warning "Press Ctrl+C to stop all development servers"
echo

cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!

# Wait for both processes
wait

---
