from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import StreamingResponse
from typing import Dict, Any, List
import io
import logging

from camera.controller import CameraController
from camera.exceptions import CameraException, CameraNotConnectedException
from models.camera import CameraStatus, CameraSettings, CaptureResult, PreviewResult
from models.responses import APIResponse
from models.requests import CaptureRequest, SettingsUpdateRequest

logger = logging.getLogger(__name__)
router = APIRouter()

# Singleton camera controller
camera_controller = CameraController()


def get_camera_controller() -> CameraController:
    return camera_controller


@router.get("/status", response_model=CameraStatus)
async def get_camera_status(
    camera: CameraController = Depends(get_camera_controller),
) -> CameraStatus:
    """Get current camera connection status"""
    return camera.get_status()


@router.post("/connect", response_model=APIResponse)
async def connect_camera(
    camera: CameraController = Depends(get_camera_controller),
) -> APIResponse:
    """Connect to camera"""
    try:
        success = camera.connect()
        if success:
            return APIResponse(success=True, message="Camera connected successfully")
        else:
            return APIResponse(success=False, message="Failed to connect to camera")
    except Exception as e:
        logger.error(f"Connection error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/disconnect", response_model=APIResponse)
async def disconnect_camera(
    camera: CameraController = Depends(get_camera_controller),
) -> APIResponse:
    """Disconnect camera"""
    try:
        success = camera.disconnect()
        return APIResponse(
            success=success,
            message="Camera disconnected" if success else "Failed to disconnect",
        )
    except Exception as e:
        logger.error(f"Disconnect error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/settings", response_model=CameraSettings)
async def get_camera_settings(
    camera: CameraController = Depends(get_camera_controller),
) -> CameraSettings:
    """Get current camera settings"""
    try:
        return camera.get_settings()
    except CameraNotConnectedException:
        raise HTTPException(status_code=400, detail="Camera not connected")
    except CameraException as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/settings", response_model=APIResponse)
async def update_camera_settings(
    settings_update: SettingsUpdateRequest,
    camera: CameraController = Depends(get_camera_controller),
) -> APIResponse:
    """Update camera settings"""
    try:
        # Convert request to CameraSettings model
        settings = CameraSettings(
            iso=settings_update.iso,
            aperture=settings_update.aperture,
            shutter_speed=settings_update.shutter_speed,
            white_balance=settings_update.white_balance,
            exposure_mode=settings_update.exposure_mode,
        )

        success = camera.update_settings(settings)
        if success:
            return APIResponse(
                success=True,
                message="Settings updated successfully",
                data=camera.get_settings().dict(),
            )
        else:
            return APIResponse(success=False, message="Failed to update settings")

    except CameraNotConnectedException:
        raise HTTPException(status_code=400, detail="Camera not connected")
    except CameraException as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/settings/available")
async def get_available_settings(
    camera: CameraController = Depends(get_camera_controller),
) -> Dict[str, List[str]]:
    """Get available options for camera settings"""
    try:
        return camera.get_available_settings()
    except CameraNotConnectedException:
        raise HTTPException(status_code=400, detail="Camera not connected")
    except CameraException as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/capture", response_model=CaptureResult)
async def capture_image(
    request: CaptureRequest = None,
    camera: CameraController = Depends(get_camera_controller),
) -> CaptureResult:
    """Capture a photo"""
    try:
        filename = request.filename if request else None

        # Apply any settings changes before capture
        if request and request.settings:
            settings = CameraSettings(**request.settings)
            camera.update_settings(settings)

        result = camera.capture_image(filename)
        return result
    except CameraNotConnectedException:
        raise HTTPException(status_code=400, detail="Camera not connected")
    except CameraException as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/preview/live")
async def get_live_preview(
    camera: CameraController = Depends(get_camera_controller),
):
    """Get live preview stream"""
    try:
        preview_data = camera.get_preview()
        return StreamingResponse(
            io.BytesIO(preview_data),
            media_type="image/jpeg",
            headers={"Cache-Control": "no-cache"},
        )
    except CameraNotConnectedException:
        raise HTTPException(status_code=400, detail="Camera not connected")
    except CameraException as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/preview/snapshot", response_model=PreviewResult)
async def take_preview_snapshot(
    camera: CameraController = Depends(get_camera_controller),
) -> PreviewResult:
    """Take a preview snapshot"""
    try:
        preview_data = camera.get_preview()
        # Save preview to preview directory with timestamp
        import time

        filename = f"preview_{int(time.time())}.jpg"
        preview_path = f"../frontend/previews/{filename}"

        with open(preview_path, "wb") as f:
            f.write(preview_data)

        return PreviewResult(
            success=True,
            url=f"/static/previews/{filename}",
            message="Preview snapshot taken",
        )
    except CameraNotConnectedException:
        raise HTTPException(status_code=400, detail="Camera not connected")
    except CameraException as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/focus/auto", response_model=APIResponse)
async def trigger_autofocus(
    camera: CameraController = Depends(get_camera_controller),
) -> APIResponse:
    """Trigger autofocus"""
    try:
        success = camera.auto_focus()
        return APIResponse(
            success=success,
            message="Autofocus completed" if success else "Autofocus not available",
        )
    except CameraNotConnectedException:
        raise HTTPException(status_code=400, detail="Camera not connected")
    except Exception as e:
        logger.error(f"Autofocus error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/config/tree")
async def get_config_tree(
    camera: CameraController = Depends(get_camera_controller),
) -> Dict[str, Any]:
    """Get full camera configuration tree (for debugging/advanced use)"""
    try:
        return camera.get_config_tree()
    except CameraNotConnectedException:
        raise HTTPException(status_code=400, detail="Camera not connected")
    except CameraException as e:
        raise HTTPException(status_code=500, detail=str(e))
