#!/bin/bash
# scripts/uninstall.sh - Remove the application

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

echo "Camera Web App Uninstaller"
echo "=========================="
echo
log_warning "This will remove the Camera Web App and its data."
echo

# Confirmation
read -p "Are you sure you want to uninstall? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Uninstall cancelled"
    exit 0
fi

# Ask about data preservation
echo
log_info "Data preservation options:"
echo "1. Keep captured images and configuration"
echo "2. Remove everything (including images)"
echo
read -p "Choose option (1 or 2): " -n 1 -r
echo

KEEP_DATA=false
if [[ $REPLY =~ ^[1]$ ]]; then
    KEEP_DATA=true
    log_info "Will preserve captured images and configuration"
else
    log_warning "Will remove all data including captured images"
fi

# Stop the application
log_info "Stopping application..."
if [ -f "camera-webapp.pid" ]; then
    ./scripts/stop.sh || true
fi

# Remove systemd service if it exists
if [ -f "/etc/systemd/system/camera-webapp.service" ]; then
    log_info "Removing systemd service..."
    sudo systemctl stop camera-webapp || true
    sudo systemctl disable camera-webapp || true
    sudo rm -f /etc/systemd/system/camera-webapp.service
    sudo systemctl daemon-reload
    log_success "Systemd service removed"
fi

# Backup data if requested
if [ "$KEEP_DATA" = true ]; then
    BACKUP_DIR="$HOME/camera-webapp-uninstall-backup-$(date +%Y%m%d_%H%M%S)"
    log_info "Creating backup at: $BACKUP_DIR"
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup important files
    [ -d "captures" ] && cp -r captures "$BACKUP_DIR/"
    [ -f ".env" ] && cp .env "$BACKUP_DIR/"
    [ -f ".env.prod" ] && cp .env.prod "$BACKUP_DIR/"
    
    log_success "Data backed up to: $BACKUP_DIR"
fi

# Remove virtual environment
if [ -d "venv" ]; then
    log_info "Removing Python virtual environment..."
    rm -rf venv
fi

# Remove node modules
if [ -d "node_modules" ]; then
    log_info "Removing Node.js modules..."
    rm -rf node_modules
fi

# Remove generated files
log_info "Removing generated files..."
rm -f camera-webapp.pid
rm -rf frontend/scripts/*.js
rm -rf frontend/scripts/*.js.map
rm -rf frontend/scripts/*.d.ts

# Remove data directories if not preserving
if [ "$KEEP_DATA" = false ]; then
    log_info "Removing data directories..."
    rm -rf captures
    rm -rf previews
    rm -rf logs
    rm -f .env
    rm -f .env.prod
fi

# Remove cache files
rm -rf __pycache__
rm -rf backend/__pycache__
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "*.pyo" -delete 2>/dev/null || true

log_success "Uninstall completed!"

if [ "$KEEP_DATA" = true ]; then
    echo
    log_info "Your data has been preserved at: $BACKUP_DIR"
    log_info "To reinstall with your data:"
    echo "1. Run the installer: ./scripts/install.sh"
    echo "2. Copy back your data: cp -r $BACKUP_DIR/* ."
fi

echo
log_info "To completely remove the directory:"
echo "cd .. && rm -rf $(basename $(pwd))"