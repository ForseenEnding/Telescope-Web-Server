#!/bin/bash
# scripts/backup.sh - Backup captured images and configuration

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

# Configuration
BACKUP_DIR=${BACKUP_DIR:-"$HOME/camera-webapp-backups"}
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="camera-webapp-backup-$DATE"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# Create backup directory
mkdir -p "$BACKUP_DIR"

log_info "Creating backup: $BACKUP_NAME"

# Create backup structure
mkdir -p "$BACKUP_PATH"

# Backup captured images
if [ -d "captures" ] && [ "$(ls -A captures 2>/dev/null)" ]; then
    log_info "Backing up captured images..."
    cp -r captures "$BACKUP_PATH/"
    IMAGE_COUNT=$(find captures -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" | wc -l)
    log_success "Backed up $IMAGE_COUNT images"
else
    log_warning "No captured images to backup"
fi

# Backup preview images
if [ -d "previews" ] && [ "$(ls -A previews 2>/dev/null)" ]; then
    log_info "Backing up preview images..."
    cp -r previews "$BACKUP_PATH/"
    PREVIEW_COUNT=$(find previews -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" | wc -l)
    log_success "Backed up $PREVIEW_COUNT previews"
fi

# Backup configuration
log_info "Backing up configuration..."
[ -f ".env" ] && cp .env "$BACKUP_PATH/"
[ -f ".env.prod" ] && cp .env.prod "$BACKUP_PATH/"
[ -f "package.json" ] && cp package.json "$BACKUP_PATH/"
[ -f "requirements.txt" ] && cp requirements.txt "$BACKUP_PATH/"

# Backup logs
if [ -d "logs" ] && [ "$(ls -A logs 2>/dev/null)" ]; then
    log_info "Backing up logs..."
    cp -r logs "$BACKUP_PATH/"
fi

# Create backup info file
cat > "$BACKUP_PATH/backup-info.txt" << EOF
Camera Web App Backup
====================
Date: $(date)
Host: $(hostname)
User: $USER
Source: $(pwd)
Backup: $BACKUP_PATH

Contents:
$(find "$BACKUP_PATH" -type f | wc -l) files
$(du -sh "$BACKUP_PATH" | cut -f1) total size
EOF

# Create compressed archive
log_info "Creating compressed archive..."
cd "$BACKUP_DIR"
tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"

BACKUP_SIZE=$(du -sh "$BACKUP_NAME.tar.gz" | cut -f1)
log_success "Backup created: $BACKUP_DIR/$BACKUP_NAME.tar.gz ($BACKUP_SIZE)"

# Clean up old backups (keep last 10)
log_info "Cleaning up old backups..."
ls -t camera-webapp-backup-*.tar.gz 2>/dev/null | tail -n +11 | xargs rm -f
REMAINING=$(ls camera-webapp-backup-*.tar.gz 2>/dev/null | wc -l)
log_info "Keeping $REMAINING most recent backups"

echo
log_success "Backup completed successfully!"
log_info "Backup location: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
log_info "To restore: tar -xzf $BACKUP_NAME.tar.gz"

---
