from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import FileResponse
from typing import List, Optional
from pathlib import Path
import zipfile
import tempfile
from datetime import datetime
import logging

from models.responses import APIResponse, FileInfo
from config.settings import settings

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/captures", response_model=List[FileInfo])
async def list_captures(
    limit: Optional[int] = Query(None, description="Limit number of files returned"),
    offset: Optional[int] = Query(0, description="Offset for pagination"),
) -> List[FileInfo]:
    """List all captured photos"""
    try:
        capture_path = Path(settings.CAPTURE_PATH)
        if not capture_path.exists():
            return []

        files = []
        for file_path in capture_path.glob("*.jpg"):
            if file_path.is_file():
                stat = file_path.stat()
                files.append(
                    FileInfo(
                        filename=file_path.name,
                        size=stat.st_size,
                        date=datetime.fromtimestamp(stat.st_mtime),
                        url=f"/api/files/captures/{file_path.name}",
                        thumbnail_url=f"/api/files/captures/{file_path.name}?thumbnail=true",
                    )
                )

        # Sort by date (newest first)
        files.sort(key=lambda x: x.date, reverse=True)

        # Apply pagination
        if limit:
            files = files[offset : offset + limit]

        return files
    except Exception as e:
        logger.error(f"Error listing captures: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/captures/{filename}")
async def get_capture(
    filename: str,
    thumbnail: bool = Query(False, description="Return thumbnail version"),
):
    """Download a specific captured photo"""
    try:
        file_path = Path(settings.CAPTURE_PATH) / filename

        # Security check - ensure file is in capture directory
        if not file_path.resolve().is_relative_to(
            Path(settings.CAPTURE_PATH).resolve()
        ):
            raise HTTPException(status_code=400, detail="Invalid file path")

        if not file_path.exists():
            raise HTTPException(status_code=404, detail="File not found")

        # TODO: Implement thumbnail generation if requested
        if thumbnail:
            # For now, return the original file
            # In production, you'd want to generate/cache thumbnails
            pass

        return FileResponse(
            path=str(file_path), filename=filename, media_type="image/jpeg"
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error serving file {filename}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/captures/{filename}", response_model=APIResponse)
async def delete_capture(filename: str) -> APIResponse:
    """Delete a specific captured photo"""
    try:
        file_path = Path(settings.CAPTURE_PATH) / filename

        # Security check
        if not file_path.resolve().is_relative_to(
            Path(settings.CAPTURE_PATH).resolve()
        ):
            raise HTTPException(status_code=400, detail="Invalid file path")

        if not file_path.exists():
            raise HTTPException(status_code=404, detail="File not found")

        file_path.unlink()
        logger.info(f"Deleted file: {filename}")

        return APIResponse(
            success=True, message=f"File {filename} deleted successfully"
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting file {filename}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/captures/download-all")
async def download_all_captures():
    """Download all captures as a ZIP file"""
    try:
        capture_path = Path(settings.CAPTURE_PATH)
        if not capture_path.exists():
            raise HTTPException(status_code=404, detail="No captures directory found")

        # Get all image files
        image_files = list(capture_path.glob("*.jpg"))
        if not image_files:
            raise HTTPException(status_code=404, detail="No images found")

        # Create temporary ZIP file
        temp_zip = tempfile.NamedTemporaryFile(delete=False, suffix=".zip")

        try:
            with zipfile.ZipFile(temp_zip.name, "w", zipfile.ZIP_DEFLATED) as zip_file:
                for image_file in image_files:
                    zip_file.write(image_file, image_file.name)

            # Return the ZIP file
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            zip_filename = f"captures_{timestamp}.zip"

            return FileResponse(
                path=temp_zip.name, filename=zip_filename, media_type="application/zip"
            )
        finally:
            # Clean up temp file after response
            # Note: FastAPI will handle this automatically
            pass

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating ZIP archive: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/captures/clear", response_model=APIResponse)
async def clear_all_captures() -> APIResponse:
    """Delete all captured photos"""
    try:
        capture_path = Path(settings.CAPTURE_PATH)
        if not capture_path.exists():
            return APIResponse(
                success=True, message="No captures to clear", data={"count": 0}
            )

        # Delete all image files
        deleted_count = 0
        for file_path in capture_path.glob("*.jpg"):
            if file_path.is_file():
                file_path.unlink()
                deleted_count += 1

        logger.info(f"Cleared {deleted_count} capture files")

        return APIResponse(
            success=True,
            message=f"Cleared {deleted_count} files",
            data={"count": deleted_count},
        )
    except Exception as e:
        logger.error(f"Error clearing captures: {e}")
        raise HTTPException(status_code=500, detail=str(e))
