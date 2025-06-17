from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from datetime import datetime
import logging
import os
from pathlib import Path

from api.camera import router as camera_router
from api.system import router as system_router
from api.files import router as files_router
from config.settings import settings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Camera Web App",
    description="Telescope Camera Control Interface",
    version="1.0.0",
)

# Add gzip compression for better performance
app.add_middleware(GZipMiddleware, minimum_size=1000)

# CORS middleware (only needed if serving from different ports)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Define paths
FRONTEND_DIR = Path(__file__).parent.parent / "frontend"
STATIC_DIR = FRONTEND_DIR


# Custom StaticFiles with better headers
class OptimizedStaticFiles(StaticFiles):
    def __init__(self, *, directory: str, **kwargs):
        super().__init__(directory=directory, **kwargs)

    def file_response(
        self, full_path: str, stat_result: os.stat_result, scope, status_code: int = 200
    ):
        response = super().file_response(full_path, stat_result, scope, status_code)

        # Add caching headers for static assets
        if full_path.endswith((".css", ".js", ".png", ".jpg", ".ico")):
            response.headers["Cache-Control"] = "public, max-age=31536000"  # 1 year
        elif full_path.endswith(".html"):
            response.headers["Cache-Control"] = "no-cache"

        # Add security headers
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"

        return response


# Mount static files with optimization
app.mount("/static", OptimizedStaticFiles(directory=str(STATIC_DIR)), name="static")

# Include API routers
app.include_router(camera_router, prefix="/api/camera", tags=["camera"])
app.include_router(system_router, prefix="/api/system", tags=["system"])
app.include_router(files_router, prefix="/api/files", tags=["files"])


# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow(), "version": "1.0.0"}


# Serve the main application
@app.get("/", response_class=HTMLResponse)
async def read_index():
    index_path = FRONTEND_DIR / "index.html"
    if index_path.exists():
        return FileResponse(
            str(index_path),
            headers={"Cache-Control": "no-cache", "X-Content-Type-Options": "nosniff"},
        )
    else:
        return HTMLResponse(
            content="""
            <html>
                <head><title>Camera App - Setup Required</title></head>
                <body>
                    <h1>Camera Web App</h1>
                    <p>Frontend files not found. Please ensure frontend/index.html exists.</p>
                    <p>Current directory: {}</p>
                </body>
            </html>
            """.format(
                os.getcwd()
            ),
            status_code=404,
        )


# Catch-all route for SPA routing (if needed later)
@app.get("/{path:path}")
async def catch_all(path: str):
    # For SPA routing, serve index.html for non-API routes
    if not path.startswith(("api/", "static/", "health")):
        return await read_index()
    return {"error": "Not found"}, 404


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host=settings.HOST,
        port=settings.PORT,
        log_level="info",
        reload=settings.DEBUG,
    )
