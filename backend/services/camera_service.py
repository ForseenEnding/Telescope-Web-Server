from typing import Optional
import logging
import threading
import time

from camera.controller import CameraController
from models.camera import CameraStatus

logger = logging.getLogger(__name__)


class CameraService:
    """Service to manage camera connections and operations"""

    def __init__(self):
        self.camera_controller = CameraController()
        self._status_monitor_thread: Optional[threading.Thread] = None
        self._monitoring = False
        self._last_status: Optional[CameraStatus] = None

    def start_monitoring(self):
        """Start background monitoring of camera status"""
        if self._monitoring:
            return

        self._monitoring = True
        self._status_monitor_thread = threading.Thread(
            target=self._monitor_camera_status, daemon=True
        )
        self._status_monitor_thread.start()
        logger.info("Camera monitoring started")

    def stop_monitoring(self):
        """Stop background monitoring"""
        self._monitoring = False
        if self._status_monitor_thread:
            self._status_monitor_thread.join(timeout=5)
        logger.info("Camera monitoring stopped")

    def _monitor_camera_status(self):
        """Background thread to monitor camera status"""
        while self._monitoring:
            try:
                current_status = self.camera_controller.get_status()

                # Check for status changes
                if (
                    self._last_status
                    and current_status.connected != self._last_status.connected
                ):
                    if current_status.connected:
                        logger.info("Camera connected")
                    else:
                        logger.warning("Camera disconnected")

                self._last_status = current_status

            except Exception as e:
                logger.error(f"Error monitoring camera status: {e}")

            time.sleep(5)  # Check every 5 seconds

    def get_controller(self) -> CameraController:
        """Get the camera controller instance"""
        return self.camera_controller

    def get_current_status(self) -> Optional[CameraStatus]:
        """Get the last known camera status"""
        return self._last_status


# Singleton instance
camera_service = CameraService()
