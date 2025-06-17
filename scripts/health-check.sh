#!/bin/bash
# scripts/health-check.sh - System health check

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

check_service_status() {
    echo "Camera Web App Health Check"
    echo "==========================="
    echo
    
    # Check if application is running
    if [ -f "camera-webapp.pid" ]; then
        PID=$(cat camera-webapp.pid)
        if ps -p "$PID" > /dev/null 2>&1; then
            log_success "Application is running (PID: $PID)"
            
            # Check if responding to HTTP requests
            if curl -s http://localhost:8000/health > /dev/null 2>&1; then
                log_success "HTTP health check passed"
            else
                log_error "HTTP health check failed"
                return 1
            fi
        else
            log_error "PID file exists but process not running"
            return 1
        fi
    else
        log_error "Application not running (no PID file)"
        return 1
    fi
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Python environment
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
        log_success "Virtual environment OK"
        
        # Check Python packages
        if python3 -c "import fastapi, gphoto2, uvicorn" 2>/dev/null; then
            log_success "Python dependencies OK"
        else
            log_error "Python dependencies missing"
            return 1
        fi
    else
        log_error "Virtual environment not found"
        return 1
    fi
    
    # Frontend build
    if [ -f "frontend/scripts/main.js" ]; then
        log_success "Frontend build OK"
    else
        log_error "Frontend build missing"
        return 1
    fi
}

check_camera() {
    log_info "Checking camera connectivity..."
    
    # Check gphoto2 installation
    if command -v gphoto2 &> /dev/null; then
        log_success "gphoto2 installed"
        
        # Check for connected cameras
        CAMERAS=$(gphoto2 --auto-detect | grep -c "usb:" || echo "0")
        if [ "$CAMERAS" -gt 0 ]; then
            log_success "$CAMERAS camera(s) detected"
            
            # Test camera communication
            if gphoto2 --summary > /dev/null 2>&1; then
                log_success "Camera communication OK"
            else
                log_warning "Camera detected but communication failed"
                log_info "Camera may be busy or require different settings"
            fi
        else
            log_warning "No cameras detected"
            log_info "Connect a camera via USB and ensure it's in PTP mode"
        fi
    else
        log_error "gphoto2 not installed"
        return 1
    fi
}

check_permissions() {
    log_info "Checking permissions..."
    
    # Check camera group membership
    if groups | grep -q plugdev; then
        log_success "User in plugdev group"
    else
        log_warning "User not in plugdev group"
        log_info "Run: sudo usermod -a -G plugdev $USER"
    fi
    
    # Check directory permissions
    for dir in captures previews logs; do
        if [ -d "$dir" ] && [ -w "$dir" ]; then
            log_success "$dir directory writable"
        else
            log_error "$dir directory not writable"
            mkdir -p "$dir" 2>/dev/null || log_error "Cannot create $dir"
        fi
    done
}

check_system_resources() {
    log_info "Checking system resources..."
    
    # Check disk space
    DISK_USAGE=$(df . | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -lt 90 ]; then
        log_success "Disk space OK ($DISK_USAGE% used)"
    else
        log_warning "Disk space low ($DISK_USAGE% used)"
    fi
    
    # Check memory
    if command -v free &> /dev/null; then
        MEM_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
        if [ "$MEM_USAGE" -lt 90 ]; then
            log_success "Memory usage OK ($MEM_USAGE% used)"
        else
            log_warning "Memory usage high ($MEM_USAGE% used)"
        fi
    fi
    
    # Check CPU load
    if command -v uptime &> /dev/null; then
        LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
        log_info "CPU load average: $LOAD"
    fi
}

check_network() {
    log_info "Checking network connectivity..."
    
    # Check if port is accessible
    if netstat -tln 2>/dev/null | grep -q ":8000 "; then
        log_success "Port 8000 is listening"
        
        # Test local HTTP access
        if curl -s http://localhost:8000/health > /dev/null 2>&1; then
            log_success "Local HTTP access OK"
        else
            log_error "Local HTTP access failed"
        fi
    else
        log_error "Port 8000 not listening"
        return 1
    fi
}

check_logs() {
    log_info "Checking logs for errors..."
    
    LOG_FILE="logs/camera-webapp.log"
    if [ -f "$LOG_FILE" ]; then
        ERROR_COUNT=$(grep -c "ERROR" "$LOG_FILE" 2>/dev/null || echo "0")
        WARNING_COUNT=$(grep -c "WARNING" "$LOG_FILE" 2>/dev/null || echo "0")
        
        if [ "$ERROR_COUNT" -eq 0 ]; then
            log_success "No errors in logs"
        else
            log_warning "$ERROR_COUNT errors found in logs"
            log_info "Recent errors:"
            grep "ERROR" "$LOG_FILE" | tail -3
        fi
        
        if [ "$WARNING_COUNT" -gt 0 ]; then
            log_info "$WARNING_COUNT warnings in logs"
        fi
    else
        log_warning "Log file not found"
    fi
}

generate_report() {
    echo
    echo "Health Check Summary"
    echo "==================="
    echo "Date: $(date)"
    echo "Host: $(hostname)"
    echo "User: $USER"
    echo "Directory: $(pwd)"
    echo
    
    # System info
    echo "System Information:"
    echo "- OS: $(uname -s -r)"
    echo "- Python: $(python3 --version 2>&1 || echo 'Not found')"
    echo "- Node.js: $(node --version 2>&1 || echo 'Not found')"
    echo "- gphoto2: $(gphoto2 --version 2>&1 | head -1 || echo 'Not found')"
    echo
    
    # Disk usage for important directories
    echo "Storage Usage:"
    du -sh captures previews logs 2>/dev/null || echo "Directories not found"
    echo
}

run_all_checks() {
    local failed_checks=0
    
    check_service_status || ((failed_checks++))
    echo
    
    check_dependencies || ((failed_checks++))
    echo
    
    check_camera || ((failed_checks++))
    echo
    
    check_permissions || ((failed_checks++))
    echo
    
    check_system_resources || ((failed_checks++))
    echo
    
    check_network || ((failed_checks++))
    echo
    
    check_logs || ((failed_checks++))
    echo
    
    generate_report
    
    if [ $failed_checks -eq 0 ]; then
        log_success "All health checks passed!"
        return 0
    else
        log_error "$failed_checks health check(s) failed"
        return 1
    fi
}

# Parse command line arguments
case "${1:-all}" in
    "service"|"status")
        check_service_status
        ;;
    "deps"|"dependencies")
        check_dependencies
        ;;
    "camera")
        check_camera
        ;;
    "permissions")
        check_permissions
        ;;
    "resources"|"system")
        check_system_resources
        ;;
    "network")
        check_network
        ;;
    "logs")
        check_logs
        ;;
    "all")
        run_all_checks
        ;;
    *)
        echo "Usage: $0 [all|service|deps|camera|permissions|resources|network|logs]"
        echo
        echo "Health check options:"
        echo "  all          - Run all checks (default)"
        echo "  service      - Check if application is running"
        echo "  deps         - Check dependencies"
        echo "  camera       - Check camera connectivity"
        echo "  permissions  - Check file and camera permissions"
        echo "  resources    - Check system resources"
        echo "  network      - Check network connectivity"
        echo "  logs         - Check logs for errors"
        exit 1
        ;;
esac

---
