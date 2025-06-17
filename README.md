# Camera Web App

A web-based telescope camera control interface built with FastAPI and TypeScript, featuring advanced camera configuration management through gphoto2.

## ✨ Features

- **🔴 Live Preview**: Real-time camera preview with smooth updates optimized for telescope use
- **⚙️ Dynamic Camera Control**: Automatic detection and control of camera-specific settings (ISO, aperture, shutter speed, etc.)
- **📸 Image Capture**: High-quality image capture with customizable settings
- **📁 File Management**: View, download, and manage captured images with thumbnail gallery
- **📱 Responsive Design**: Works seamlessly on desktop and mobile devices
- **🌙 Dark Theme**: Night vision-friendly interface with red accent lighting
- **🔄 Auto-Discovery**: Automatically detects available camera settings and options
- **🛡️ Robust Error Handling**: Graceful handling of camera disconnections and USB timeouts

## 🏗️ Architecture

### Backend (Python/FastAPI)
- **FastAPI** for high-performance API with automatic documentation
- **gphoto2** integration with advanced configuration management
- **Pydantic** models for type safety and validation
- **Dependency injection** for clean service architecture

### Frontend (TypeScript/HTML/CSS)
- **Pure TypeScript** with ES modules for type safety
- **Modular architecture** with separate components for camera control, preview, and file management
- **CSS custom properties** for consistent theming
- **Responsive grid layout** optimized for telescope workflows

## 📁 Project Structure

```
camera-webapp/
├── backend/                    # Python FastAPI backend
│   ├── main.py                # Main application entry point
│   ├── api/                   # API route handlers
│   │   ├── camera.py          # Camera control endpoints
│   │   ├── system.py          # System monitoring endpoints
│   │   └── files.py           # File management endpoints
│   ├── camera/                # Camera control logic
│   │   ├── controller.py      # Enhanced camera controller
│   │   ├── camera_config.py   # Advanced gphoto2 config manager
│   │   └── exceptions.py      # Camera-specific exceptions
│   ├── services/              # Business logic services
│   │   ├── camera_service.py  # Camera connection management
│   │   └── file_service.py    # File operations service
│   ├── models/                # Pydantic data models
│   │   ├── camera.py          # Camera operation models
│   │   ├── responses.py       # API response models
│   │   └── requests.py        # API request models
│   └── config/                # Configuration management
│       └── settings.py        # Environment-based settings
├── frontend/                  # TypeScript/HTML frontend
│   ├── index.html             # Main application shell
│   ├── scripts/               # TypeScript modules
│   │   ├── main.ts            # Application entry point
│   │   ├── CameraControl.ts   # Camera control component
│   │   ├── LivePreview.ts     # Live preview component
│   │   └── FileManager.ts     # File management component
│   └── styles/                # CSS stylesheets
│       ├── variables.css      # CSS custom properties
│       ├── main.css           # Main application styles
│       └── camera.css         # Camera-specific styles
├── captures/                  # Captured images directory
├── previews/                  # Preview snapshots directory
├── requirements.txt           # Python dependencies
├── package.json              # Node.js dependencies (TypeScript)
├── tsconfig.json             # TypeScript configuration
├── .env.example              # Environment variables template
└── README.md                 # This file
```

## 🚀 Quick Start

```bash
# 1. Clone and setup (one command!)
git clone <your-repo> camera-webapp
cd camera-webapp
chmod +x scripts/*.sh
./scripts/quick-start.sh

# 2. Daily operations
./scripts/start.sh          # Start app
./scripts/stop.sh           # Stop app
./scripts/logs.sh -f        # View live logs
./scripts/health-check.sh   # Check system health

# 3. Development
./scripts/dev.sh            # Start with auto-reload

# 4. Maintenance
./scripts/update.sh         # Update and restart
./scripts/backup.sh         # Backup your images

**Access the application:**
    - Open your browser to: **http://localhost:8000**
    - Connect your camera via USB
    - Click "Connect Camera" to start controlling your camera

## 🔧 Development Setup

### Backend Development
```bash
# Start backend with auto-reload
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# View API documentation
# http://localhost:8000/docs (Swagger UI)
# http://localhost:8000/redoc (ReDoc)
```

### Frontend Development
```bash
# Watch TypeScript files for changes
npm run watch

# Manual compilation
npm run build

# Linting
npm run lint
```

### Development Workflow
1. **Backend changes**: Automatically reload with `--reload` flag
2. **Frontend changes**: Run `npm run watch` for auto-compilation
3. **Refresh browser** to see frontend changes

## 📋 API Endpoints

### Camera Control (`/api/camera`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/status` | Get camera connection status and info |
| POST | `/connect` | Connect to camera |
| POST | `/disconnect` | Disconnect camera |
| GET | `/settings` | Get current camera settings |
| PUT | `/settings` | Update camera settings |
| GET | `/settings/available` | Get available setting options |
| POST | `/capture` | Capture an image |
| GET | `/preview/live` | Get live preview stream |
| POST | `/preview/snapshot` | Take preview snapshot |
| POST | `/focus/auto` | Trigger autofocus |
| GET | `/config/tree` | Get full camera config (debug) |

### File Management (`/api/files`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/captures` | List captured photos |
| GET | `/captures/{filename}` | Download specific photo |
| DELETE | `/captures/{filename}` | Delete photo |
| POST | `/captures/download-all` | Download all as ZIP |
| DELETE | `/captures/clear` | Delete all captures |

### System Info (`/api/system`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/info` | System resource information |
| GET | `/cameras` | List available cameras |
| POST | `/restart` | Restart camera service |
| GET | `/logs` | Get recent log entries |

## 📷 Camera Compatibility

This application works with cameras supported by **gphoto2**, including:

### Tested Cameras
- **Canon**: EOS series DSLR cameras
- **Nikon**: D-series DSLR cameras  
- **Sony**: Alpha series cameras

### Check Compatibility
```bash
# List connected cameras
gphoto2 --auto-detect

# Test camera connection
gphoto2 --summary

# View supported cameras
gphoto2 --list-cameras
```

**Full compatibility list**: http://gphoto.org/proj/libgphoto2/support.php

## ⚙️ Configuration

### Environment Variables (`.env`)
```bash
# Camera Settings
CAMERA_TIMEOUT=30              # Camera operation timeout (seconds)
CAPTURE_PATH=./captures        # Directory for captured images
PREVIEW_PATH=./previews        # Directory for preview snapshots

# Server Settings
HOST=0.0.0.0                  # Server bind address
PORT=8000                     # Server port
DEBUG=false                   # Enable debug mode

# USB Settings (optional - for specific camera targeting)
USB_VENDOR_ID=                # Camera vendor ID
USB_PRODUCT_ID=               # Camera product ID

# Security (production)
SECRET_KEY=your-secret-key    # JWT secret (if implementing auth)
ALLOWED_HOSTS=localhost,127.0.0.1  # Allowed hosts (production)
```

### Camera Settings
The application automatically detects and provides controls for:
- **ISO** values supported by your camera
- **Aperture** settings (f-stops)
- **Shutter speed** options
- **White balance** presets
- **Exposure modes** (Manual, Aperture Priority, etc.)
- **Focus modes** (Single, Continuous, Manual)

## 🚀 Deployment

### Development
```bash
# Single command startup
cd backend && uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Production
```bash
# 1. Build frontend
npm run build

# 2. Set production environment
export DEBUG=false
export HOST=0.0.0.0
export PORT=8000

# 3. Start server
cd backend
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 1

# 4. Optional: Use process manager
# pip install gunicorn
# gunicorn -w 1 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:8000
```

### Docker Deployment (Optional)
```dockerfile
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgphoto2-dev \
    gphoto2 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application
COPY backend/ ./backend/
COPY frontend/ ./frontend/

# Expose port
EXPOSE 8000

# Start application
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## 🔧 Troubleshooting

### Camera Connection Issues

**Camera not detected:**
```bash
# Check if gphoto2 can see the camera
gphoto2 --auto-detect

# Check USB connection
lsusb | grep -i camera

# Restart camera service
sudo systemctl restart gphoto2
```

**Permission denied:**
```bash
# Add user to camera group
sudo usermod -a -G plugdev $USER

# Reload groups (or logout/login)
newgrp plugdev

# Check camera permissions
ls -la /dev/bus/usb/
```

**Camera busy/locked:**
```bash
# Kill any processes using the camera
sudo pkill gphoto2
sudo pkill gvfs

# Restart gvfs (if using GNOME)
sudo systemctl restart gvfs-gphoto2-volume-monitor
```

### Application Issues

**Frontend not loading:**
- Ensure `frontend/index.html` exists
- Check TypeScript compilation: `npm run build`
- Verify server is running on correct port

**API errors:**
- Check backend logs for detailed error messages
- Verify camera is connected and accessible
- Check `.env` configuration

**Performance issues:**
- Reduce live preview refresh rate
- Check available system resources
- Ensure camera supports preview mode

### Network Issues

**Cannot access from other devices:**
```bash
# Check firewall settings
sudo ufw allow 8000

# Bind to all interfaces
uvicorn main:app --host 0.0.0.0 --port 8000

# Check network connectivity
curl http://your-ip:8000/health
```

## 🧪 Testing

### Backend Tests
```bash
# Install test dependencies
pip install pytest pytest-asyncio

# Run tests
pytest backend/tests/

# Run with coverage
pytest --cov=backend backend/tests/
```

### Frontend Tests
```bash
# Linting
npm run lint

# Type checking
npx tsc --noEmit
```

### Manual Testing Checklist
- [ ] Camera connection/disconnection
- [ ] Live preview functionality
- [ ] Image capture with various settings
- [ ] File download and management
- [ ] Settings persistence across sessions
- [ ] Mobile responsiveness

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit changes**: `git commit -m 'Add amazing feature'`
4. **Push to branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Development Guidelines
- Follow **PEP 8** for Python code
- Use **TypeScript strict mode** for frontend
- Add **type annotations** for all functions
- Include **error handling** for camera operations
- Write **descriptive commit messages**
- Update **documentation** for new features

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **gphoto2** project for excellent camera support
- **FastAPI** for the modern Python web framework
- **Astronomy community** for inspiration and requirements

## 📞 Support

- **Issues**: Create an issue on GitHub
- **Discussions**: Use GitHub Discussions for questions
- **Camera Compatibility**: Check gphoto2 documentation

---

**Built with ❤️ for the astronomy and photography community**