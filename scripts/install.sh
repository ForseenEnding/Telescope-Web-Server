#!/bin/bash
# scripts/install.sh - Complete installation script

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/ForseenEnding/Telescope-Web-Server.git"  # Update this
APP_DIR="Telescope Web Server"
PYTHON_MIN_VERSION="3.8"
NODE_MIN_VERSION="16"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed or not in PATH"
        return 1
    fi
    return 0
}

check_python_version() {
    if check_command python3; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        log_info "Found Python $PYTHON_VERSION"
        
        # Simple version comparison
        if python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)"; then
            return 0
        else
            log_error "Python 3.8+ required, found $PYTHON_VERSION"
            return 1
        fi
    fi
    return 1
}

check_node_version() {
    if check_command node; then
        NODE_VERSION=$(node --version | sed 's/v//')
        log_info "Found Node.js $NODE_VERSION"
        
        # Simple version check for Node 16+
        MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'.' -f1)
        if [ "$MAJOR_VERSION" -ge "16" ]; then
            return 0
        else
            log_error "Node.js 16+ required, found $NODE_VERSION"
            return 1
        fi
    fi
    return 1
}

install_system_dependencies() {
    log_info "Installing system dependencies..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Ubuntu/Debian
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y \
                python3 \
                python3-pip \
                python3-venv \
                libgphoto2-dev \
                gphoto2 \
                nodejs \
                npm \
                git \
                curl
        # CentOS/RHEL/Fedora
        elif command -v yum &> /dev/null; then
            sudo yum install -y \
                python3 \
                python3-pip \
                libgphoto2-devel \
                gphoto2 \
                nodejs \
                npm \
                git \
                curl
        else
            log_warning "Unknown Linux distribution. Please install dependencies manually."
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install python3 libgphoto2 gphoto2 node git
        else
            log_error "Homebrew not found. Please install Homebrew first: https://brew.sh/"
            exit 1
        fi
    else
        log_warning "Unsupported OS: $OSTYPE"
        log_info "Please install dependencies manually:"
        log_info "- Python 3.8+"
        log_info "- Node.js 16+"
        log_info "- libgphoto2 and gphoto2"
        log_info "- git"
    fi
}

clone_repository() {
    log_info "Cloning repository..."
    
    if [ -d "$APP_DIR" ]; then
        log_warning "Directory $APP_DIR already exists"
        read -p "Remove existing directory and re-clone? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$APP_DIR"
        else
            log_info "Using existing directory"
            cd "$APP_DIR"
            git pull origin main || log_warning "Failed to update repository"
            return 0
        fi
    fi
    
    git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
}

setup_python_environment() {
    log_info "Setting up Python virtual environment..."
    
    # Create virtual environment
    python3 -m venv venv
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install Python dependencies
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
        log_success "Python dependencies installed"
    else
        log_error "requirements.txt not found"
        exit 1
    fi
}

setup_node_environment() {
    log_info "Setting up Node.js environment..."
    
    # Install Node.js dependencies
    if [ -f "package.json" ]; then
        npm install
        log_success "Node.js dependencies installed"
    else
        log_error "package.json not found"
        exit 1
    fi
}

build_frontend() {
    log_info "Building frontend..."
    npm run build
    log_success "Frontend built successfully"
}

setup_configuration() {
    log_info "Setting up configuration..."
    
    if [ ! -f ".env" ] && [ -f ".env.example" ]; then
        cp .env.example .env
        log_success "Created .env file from template"
        log_info "Please edit .env file to configure your settings"
    fi
    
    # Create necessary directories
    mkdir -p captures previews logs
    log_success "Created necessary directories"
}

setup_permissions() {
    log_info "Setting up camera permissions..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Add user to plugdev group for camera access
        if getent group plugdev > /dev/null 2>&1; then
            sudo usermod -a -G plugdev "$USER"
            log_success "Added $USER to plugdev group"
            log_warning "You may need to logout and login again for group changes to take effect"
        fi
        
        # Create udev rules for camera access (optional)
        if [ ! -f "/etc/udev/rules.d/90-libgphoto2.rules" ]; then
            log_info "Creating udev rules for camera access..."
            # This would typically be handled by the libgphoto2 package
            sudo /usr/lib/libgphoto2/print-camera-list udev-rules version 201 group plugdev mode 664 > /tmp/90-libgphoto2.rules
            sudo mv /tmp/90-libgphoto2.rules /etc/udev/rules.d/
            sudo udevadm control --reload-rules
            log_success "Camera udev rules created"
        fi
    fi
}

test_installation() {
    log_info "Testing installation..."
    
    # Test Python imports
    if ! python3 -c "import fastapi, gphoto2" 2>/dev/null; then
        log_error "Python dependencies test failed"
        return 1
    fi
    
    # Test gphoto2 installation
    if ! gphoto2 --version > /dev/null 2>&1; then
        log_error "gphoto2 test failed"
        return 1
    fi
    
    # Test frontend build
    if [ ! -f "frontend/scripts/main.js" ]; then
        log_error "Frontend build test failed - main.js not found"
        return 1
    fi
    
    log_success "Installation tests passed"
    return 0
}

print_next_steps() {
    log_success "Installation completed successfully!"
    echo
    log_info "Next steps:"
    echo "1. Connect your camera via USB"
    echo "2. Edit .env file if needed: nano .env"
    echo "3. Start the application: ./scripts/start.sh"
    echo "4. Open browser to: http://localhost:8000"
    echo
    log_info "Useful commands:"
    echo "- Start app: ./scripts/start.sh"
    echo "- Stop app: ./scripts/stop.sh"
    echo "- Update app: ./scripts/update.sh"
    echo "- View logs: ./scripts/logs.sh"
    echo
    if [[ "$OSTYPE" == "linux-gnu"* ]] && groups | grep -q plugdev; then
        log_warning "Camera permissions: You may need to logout/login for camera access"
    fi
}

# Main installation process
main() {
    log_info "Starting Camera Web App installation..."
    echo
    
    # Check prerequisites
    log_info "Checking system requirements..."
    
    if ! check_python_version; then
        log_info "Installing system dependencies to get Python 3.8+..."
        install_system_dependencies
        if ! check_python_version; then
            log_error "Failed to install Python 3.8+. Please install manually."
            exit 1
        fi
    fi
    
    if ! check_node_version; then
        log_info "Installing system dependencies to get Node.js 16+..."
        install_system_dependencies
        if ! check_node_version; then
            log_error "Failed to install Node.js 16+. Please install manually."
            exit 1
        fi
    fi
    
    if ! check_command git; then
        install_system_dependencies
    fi
    
    # Install system dependencies if needed
    if ! check_command gphoto2; then
        log_info "Installing gphoto2 and related dependencies..."
        install_system_dependencies
    fi
    
    # Clone and setup
    clone_repository
    setup_python_environment
    setup_node_environment
    build_frontend
    setup_configuration
    setup_permissions
    
    # Test installation
    if test_installation; then
        print_next_steps
    else
        log_error "Installation tests failed. Please check the logs above."
        exit 1
    fi
}

# Run main function
main "$@"

---
