from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any
import psutil
import logging
from datetime import datetime

from models.responses import APIResponse, SystemInfo

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/info", response_model=SystemInfo)
async def get_system_info() -> SystemInfo:
    """Get system resource information"""
    try:
        # Get system metrics
        cpu_usage = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage("/")

        # Get uptime
        boot_time = datetime.fromtimestamp(psutil.boot_time())
        uptime = str(datetime.now() - boot_time)

        return SystemInfo(
            cpu_usage=cpu_usage,
            memory_usage=memory.percent,
            disk_usage=disk.percent,
            uptime=uptime,
            camera_service_status="running",  # TODO: Implement actual service check
        )
    except Exception as e:
        logger.error(f"Error getting system info: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/cameras")
async def list_available_cameras() -> List[Dict[str, Any]]:
    """List all available cameras"""
    try:
        import gphoto2 as gp

        cameras = []
        context = gp.Context()

        # Get list of cameras
        camera_list = gp.check_result(gp.gp_camera_autodetect(context))

        for index, (name, addr) in enumerate(camera_list):
            cameras.append(
                {
                    "id": str(index),
                    "name": name,
                    "address": addr,
                    "connected": False,  # TODO: Check actual connection status
                }
            )

        return cameras
    except Exception as e:
        logger.error(f"Error listing cameras: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/restart", response_model=APIResponse)
async def restart_camera_service() -> APIResponse:
    """Restart camera service"""
    try:
        # TODO: Implement actual service restart logic
        logger.info("Camera service restart requested")
        return APIResponse(success=True, message="Camera service restart initiated")
    except Exception as e:
        logger.error(f"Error restarting service: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/logs")
async def get_recent_logs(lines: int = 50) -> Dict[str, List[str]]:
    """Get recent log entries"""
    try:
        # TODO: Implement log reading from actual log files
        logs = [
            f"[{datetime.now().isoformat()}] INFO: Camera service started",
            f"[{datetime.now().isoformat()}] INFO: System monitoring active",
        ]
        return {"logs": logs[-lines:]}
    except Exception as e:
        logger.error(f"Error reading logs: {e}")
        raise HTTPException(status_code=500, detail=str(e))
