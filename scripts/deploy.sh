#!/bin/bash
# scripts/deploy.sh - Production deployment script

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

# Configuration
DEPLOY_USER=${DEPLOY_USER:-"camera"}
DEPLOY_HOST=${DEPLOY_HOST:-"localhost"}
DEPLOY_PATH=${DEPLOY_PATH:-"/opt/camera-webapp"}
SERVICE_NAME="camera-webapp"

deploy_local() {
    log_info "Deploying locally..."
    
    # Stop application if running
    if [ -f "camera-webapp.pid" ]; then
        ./scripts/stop.sh
    fi
    
    # Set production environment
    export DEBUG=false
    export HOST=0.0.0.0
    export PORT=8000
    
    # Build frontend for production
    log_info "Building frontend for production..."
    npm run build
    
    # Create production .env if it doesn't exist
    if [ ! -f ".env.prod" ]; then
        cp .env.example .env.prod
        log_warning "Created .env.prod - please configure it for production"
    fi
    
    # Install production service (systemd)
    if command -v systemctl &> /dev/null; then
        log_info "Creating systemd service..."
        
        cat > /tmp/camera-webapp.service << EOF
[Unit]
Description=Camera Web App
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
Environment=PATH=$(pwd)/venv/bin
EnvironmentFile=$(pwd)/.env.prod
ExecStart=$(pwd)/venv/bin/uvicorn backend.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
        
        sudo mv /tmp/camera-webapp.service /etc/systemd/system/
        sudo systemctl daemon-reload
        sudo systemctl enable camera-webapp
        
        log_success "Systemd service created and enabled"
        log_info "Use 'sudo systemctl start camera-webapp' to start"
        log_info "Use 'sudo systemctl status camera-webapp' to check status"
    else
        log_warning "Systemd not available - manual startup required"
    fi
    
    log_success "Local deployment completed!"
}

deploy_remote() {
    log_info "Deploying to remote server: $DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH"
    
    # Create deployment package
    log_info "Creating deployment package..."
    
    # Build frontend
    npm run build
    
    # Create temporary deployment directory
    TEMP_DIR=$(mktemp -d)
    log_info "Using temporary directory: $TEMP_DIR"
    
    # Copy necessary files
    cp -r backend "$TEMP_DIR/"
    cp -r frontend "$TEMP_DIR/"
    cp requirements.txt "$TEMP_DIR/"
    cp .env.example "$TEMP_DIR/"
    cp -r scripts "$TEMP_DIR/"
    
    # Create archive
    cd "$TEMP_DIR"
    tar -czf camera-webapp.tar.gz *
    cd - > /dev/null
    
    # Upload to remote server
    log_info "Uploading to remote server..."
    scp "$TEMP_DIR/camera-webapp.tar.gz" "$DEPLOY_USER@$DEPLOY_HOST:/tmp/"
    
    # Execute remote deployment
    ssh "$DEPLOY_USER@$DEPLOY_HOST" << EOF
        set -e
        
        # Create deployment directory
        sudo mkdir -p $DEPLOY_PATH
        sudo chown $DEPLOY_USER:$DEPLOY_USER $DEPLOY_PATH
        
        # Stop existing service
        sudo systemctl stop $SERVICE_NAME || true
        
        # Backup current deployment
        if [ -d "$DEPLOY_PATH/backend" ]; then
            sudo mv $DEPLOY_PATH $DEPLOY_PATH.backup.\$(date +%Y%m%d_%H%M%S)
            sudo mkdir -p $DEPLOY_PATH
            sudo chown $DEPLOY_USER:$DEPLOY_USER $DEPLOY_PATH
        fi
        
        # Extract new deployment
        cd $DEPLOY_PATH
        tar -xzf /tmp/camera-webapp.tar.gz
        rm /tmp/camera-webapp.tar.gz
        
        # Set up Python environment
        python3 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip
        pip install -r requirements.txt
        
        # Copy configuration
        if [ ! -f ".env" ]; then
            cp .env.example .env
            echo "Please configure .env file"
        fi
        
        # Create directories
        mkdir -p captures previews logs
        
        # Set permissions
        chmod +x scripts/*.sh
        
        # Create systemd service
        sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOL
[Unit]
Description=Camera Web App
After=network.target

[Service]
Type=simple
User=$DEPLOY_USER
WorkingDirectory=$DEPLOY_PATH
Environment=PATH=$DEPLOY_PATH/venv/bin
EnvironmentFile=$DEPLOY_PATH/.env
ExecStart=$DEPLOY_PATH/venv/bin/uvicorn backend.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOL
        
        # Reload and start service
        sudo systemctl daemon-reload
        sudo systemctl enable $SERVICE_NAME
        sudo systemctl start $SERVICE_NAME
        
        echo "Remote deployment completed!"
        echo "Service status:"
        sudo systemctl status $SERVICE_NAME --no-pager
EOF
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
    log_success "Remote deployment completed!"
    log_info "Access the app at: http://$DEPLOY_HOST:8000"
}

# Main deployment logic
case "${1:-local}" in
    "local")
        deploy_local
        ;;
    "remote")
        if [ -z "$DEPLOY_HOST" ] || [ -z "$DEPLOY_USER" ]; then
            log_error "DEPLOY_HOST and DEPLOY_USER must be set for remote deployment"
            log_info "Usage: DEPLOY_HOST=server.com DEPLOY_USER=user ./scripts/deploy.sh remote"
            exit 1
        fi
        deploy_remote
        ;;
    *)
        log_error "Unknown deployment type: $1"
        log_info "Usage: ./scripts/deploy.sh [local|remote]"
        exit 1
        ;;
esac

---

#!/bin/bash