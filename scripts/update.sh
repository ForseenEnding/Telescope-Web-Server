#!/bin/bash
# scripts/update.sh - Update the application

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

# Check if app is running
WAS_RUNNING=false
if [ -f "camera-webapp.pid" ]; then
    PID=$(cat camera-webapp.pid)
    if ps -p "$PID" > /dev/null 2>&1; then
        WAS_RUNNING=true
        log_info "Application is running, stopping it first..."
        ./scripts/stop.sh
    fi
fi

log_info "Updating Camera Web App..."

# Backup current .env file
if [ -f ".env" ]; then
    cp .env .env.backup
    log_info "Backed up .env file"
fi

# Pull latest changes
log_info "Pulling latest changes from repository..."
git fetch origin
git pull origin main

# Update Python dependencies
log_info "Updating Python dependencies..."
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    log_success "Python dependencies updated"
else
    log_error "Virtual environment not found"
    exit 1
fi

# Update Node.js dependencies
log_info "Updating Node.js dependencies..."
npm install
npm audit fix || true  # Fix vulnerabilities if any
log_success "Node.js dependencies updated"

# Rebuild frontend
log_info "Rebuilding frontend..."
npm run build
log_success "Frontend rebuilt"

# Update configuration if needed
if [ -f ".env.example" ] && [ -f ".env.backup" ]; then
    log_info "Checking for new configuration options..."
    
    # Simple check for new variables
    NEW_VARS=$(grep -v "^#" .env.example | grep "=" | cut -d'=' -f1 | while read var; do
        if ! grep -q "^$var=" .env.backup; then
            echo "$var"
        fi
    done)
    
    if [ -n "$NEW_VARS" ]; then
        log_warning "New configuration variables found:"
        echo "$NEW_VARS"
        log_info "Please review and update your .env file"
    fi
    
    # Restore .env file
    mv .env.backup .env
fi

# Create any new directories
mkdir -p captures previews logs

# Test the update
log_info "Testing updated installation..."
if python3 -c "import fastapi, gphoto2" 2>/dev/null && [ -f "frontend/scripts/main.js" ]; then
    log_success "Update tests passed"
else
    log_error "Update tests failed"
    exit 1
fi

log_success "Update completed successfully!"

# Restart if it was running
if [ "$WAS_RUNNING" = true ]; then
    log_info "Restarting application..."
    ./scripts/start.sh
fi

log_info "Update summary:"
echo "- Code updated from repository"
echo "- Dependencies updated"
echo "- Frontend rebuilt"
echo "- Configuration preserved"

---
