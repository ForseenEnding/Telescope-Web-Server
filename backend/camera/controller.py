import gphoto2 as gp
import logging
from typing import Optional, Dict, Any, List
from pathlib import Path
import time

from .camera_config import CameraConfigManager
from .exceptions import (
    CameraNotConnectedException,
    CameraSettingsException,
    CaptureException,
)
from models.camera import CameraStatus, CameraSettings, CaptureResult
from config.settings import settings

logger = logging.getLogger(__name__)


class CameraController:
    """Camera controller using the CameraConfigManager"""

    def __init__(self):
        self.camera: Optional[gp.Camera] = None
        self.context = gp.Context()
        self.config_manager: Optional[CameraConfigManager] = None
        self._connected = False

        # Ensure capture directories exist
        Path(settings.CAPTURE_PATH).mkdir(exist_ok=True)
        Path(settings.PREVIEW_PATH).mkdir(exist_ok=True)

    def connect(self) -> bool:
        """Connect to camera and initialize config manager"""
        try:
            self.camera = gp.Camera()
            self.camera.init(self.context)

            # Initialize configuration manager
            self.config_manager = CameraConfigManager(self.camera)

            self._connected = True
            logger.info("Camera connected successfully with enhanced configuration")
            return True
        except gp.GPhoto2Error as e:
            logger.error(f"Failed to connect camera: {e}")
            self._connected = False
            return False

    def disconnect(self) -> bool:
        """Disconnect camera"""
        try:
            if self.camera:
                self.camera.exit(self.context)
                self.camera = None
                self.config_manager = None
            self._connected = False
            logger.info("Camera disconnected")
            return True
        except gp.GPhoto2Error as e:
            logger.error(f"Error disconnecting camera: {e}")
            return False

    def get_status(self) -> CameraStatus:
        """Get camera status with enhanced information"""
        if not self._connected or not self.camera or not self.config_manager:
            return CameraStatus(connected=False)

        try:
            # Get camera model
            summary = self.camera.get_summary(self.context)
            model = str(summary).split("\n")[0] if summary else "Unknown"

            # Try to get battery level
            battery = None
            battery_entry = self.config_manager.get_by_name("batterylevel")
            if battery_entry and battery_entry.value:
                try:
                    battery = int(battery_entry.value.replace("%", ""))
                except (ValueError, AttributeError):
                    pass

            # Try to get storage info
            storage_available = None
            # This varies by camera model - some have 'availableshots' or similar

            return CameraStatus(
                connected=True,
                model=model,
                battery=battery,
                storage_available=storage_available,
            )
        except gp.GPhoto2Error as e:
            logger.error(f"Error getting camera status: {e}")
            return CameraStatus(connected=False)

    def get_settings(self) -> CameraSettings:
        """Get current camera settings using config manager"""
        if not self._connected or not self.config_manager:
            raise CameraNotConnectedException("Camera not connected")

        try:
            # Refresh configuration from camera
            self.config_manager.refresh()

            # Extract common settings
            iso_entry = self.config_manager.get_by_name("iso")
            aperture_entry = self.config_manager.get_by_name("aperture")
            shutter_entry = self.config_manager.get_by_name("shutterspeed")
            wb_entry = self.config_manager.get_by_name("whitebalance")
            exposure_entry = self.config_manager.get_by_name("autoexposuremode")
            focus_entry = self.config_manager.get_by_name("autofocusmode")

            return CameraSettings(
                iso=int(iso_entry.value) if iso_entry and iso_entry.value else None,
                aperture=(
                    str(aperture_entry.value)
                    if aperture_entry and aperture_entry.value
                    else None
                ),
                shutter_speed=(
                    str(shutter_entry.value)
                    if shutter_entry and shutter_entry.value
                    else None
                ),
                white_balance=(
                    str(wb_entry.value) if wb_entry and wb_entry.value else None
                ),
                exposure_mode=(
                    str(exposure_entry.value)
                    if exposure_entry and exposure_entry.value
                    else None
                ),
                focus_mode=(
                    str(focus_entry.value)
                    if focus_entry and focus_entry.value
                    else None
                ),
            )
        except gp.GPhoto2Error as e:
            logger.error(f"Error getting camera settings: {e}")
            raise CameraSettingsException(f"Failed to get settings: {e}")

    def update_settings(self, settings: CameraSettings) -> bool:
        """Update camera settings using config manager"""
        if not self._connected or not self.config_manager:
            raise CameraNotConnectedException("Camera not connected")

        try:
            changes_made = False

            # Update ISO
            if settings.iso is not None:
                iso_entry = self.config_manager.get_by_name("iso")
                if iso_entry and not iso_entry.read_only:
                    iso_entry.set_value(str(settings.iso))
                    changes_made = True

            # Update aperture
            if settings.aperture is not None:
                aperture_entry = self.config_manager.get_by_name("aperture")
                if aperture_entry and not aperture_entry.read_only:
                    aperture_entry.set_value(settings.aperture)
                    changes_made = True

            # Update shutter speed
            if settings.shutter_speed is not None:
                shutter_entry = self.config_manager.get_by_name("shutterspeed")
                if shutter_entry and not shutter_entry.read_only:
                    shutter_entry.set_value(settings.shutter_speed)
                    changes_made = True

            # Update white balance
            if settings.white_balance is not None:
                wb_entry = self.config_manager.get_by_name("whitebalance")
                if wb_entry and not wb_entry.read_only:
                    wb_entry.set_value(settings.white_balance)
                    changes_made = True

            # Update exposure mode
            if settings.exposure_mode is not None:
                exposure_entry = self.config_manager.get_by_name("autoexposuremode")
                if exposure_entry and not exposure_entry.read_only:
                    exposure_entry.set_value(settings.exposure_mode)
                    changes_made = True

            # Update focus mode
            if settings.focus_mode is not None:
                focus_entry = self.config_manager.get_by_name("autofocusmode")
                if focus_entry and not focus_entry.read_only:
                    focus_entry.set_value(settings.focus_mode)
                    changes_made = True

            # Apply changes to camera
            if changes_made:
                self.config_manager.apply_changes()
                logger.info("Camera settings updated successfully")

            return True

        except (gp.GPhoto2Error, ValueError) as e:
            logger.error(f"Error updating camera settings: {e}")
            raise CameraSettingsException(f"Failed to update settings: {e}")

    def get_available_settings(self) -> Dict[str, List[str]]:
        """Get available options for each camera setting"""
        if not self._connected or not self.config_manager:
            raise CameraNotConnectedException("Camera not connected")

        try:
            available_settings = {}

            # Common setting names to check
            setting_names = [
                "iso",
                "aperture",
                "shutterspeed",
                "whitebalance",
                "autoexposuremode",
                "autofocusmode",
            ]

            for setting_name in setting_names:
                entry = self.config_manager.get_by_name(setting_name)
                if entry and entry.choices:
                    available_settings[setting_name] = entry.choices

            return available_settings

        except gp.GPhoto2Error as e:
            logger.error(f"Error getting available settings: {e}")
            raise CameraSettingsException(f"Failed to get available settings: {e}")

    def capture_image(self, filename: Optional[str] = None) -> CaptureResult:
        """Capture an image"""
        if not self._connected or not self.camera:
            raise CameraNotConnectedException("Camera not connected")

        try:
            # Capture image
            file_path = self.camera.capture(gp.GP_CAPTURE_IMAGE, self.context)

            # Generate filename if not provided
            if not filename:
                timestamp = int(time.time())
                filename = f"capture_{timestamp}.jpg"

            # Download image from camera
            target_path = Path(settings.CAPTURE_PATH) / filename
            camera_file = self.camera.file_get(
                file_path.folder, file_path.name, gp.GP_FILE_TYPE_NORMAL, self.context
            )
            camera_file.save(str(target_path))

            # Clean up camera memory
            self.camera.file_delete(file_path.folder, file_path.name, self.context)

            logger.info(f"Image captured: {filename}")
            return CaptureResult(
                success=True,
                filename=filename,
                url=f"/api/files/captures/{filename}",
                timestamp=time.time(),
            )

        except gp.GPhoto2Error as e:
            logger.error(f"Capture failed: {e}")
            raise CaptureException(f"Capture failed: {e}")

    def get_preview(self) -> bytes:
        """Get live preview image"""
        if not self._connected or not self.camera:
            raise CameraNotConnectedException("Camera not connected")

        try:
            camera_file = self.camera.capture_preview(self.context)
            file_data = camera_file.get_data_and_size()
            return file_data
        except gp.GPhoto2Error as e:
            logger.error(f"Preview failed: {e}")
            raise CaptureException(f"Preview failed: {e}")

    def auto_focus(self) -> bool:
        """Trigger autofocus"""
        if not self._connected or not self.config_manager:
            raise CameraNotConnectedException("Camera not connected")

        try:
            # Look for autofocus trigger
            af_entry = self.config_manager.get_by_name("autofocusdrive")
            if af_entry and not af_entry.read_only:
                af_entry.set_value("1")  # Trigger autofocus
                self.config_manager.apply_changes()
                logger.info("Autofocus triggered")
                return True
            else:
                logger.warning("Autofocus not available or not writable")
                return False

        except (gp.GPhoto2Error, ValueError) as e:
            logger.error(f"Autofocus failed: {e}")
            return False

    def get_config_tree(self) -> Dict[str, Any]:
        """Get the full configuration tree for debugging/advanced use"""
        if not self._connected or not self.config_manager:
            raise CameraNotConnectedException("Camera not connected")

        def entry_to_dict(entry):
            return {
                "id": entry.id,
                "name": entry.name,
                "type": entry.type.name,
                "label": entry.label,
                "value": entry.value,
                "choices": entry.choices,
                "read_only": entry.read_only,
                "children": [entry_to_dict(child) for child in entry.get_children()],
            }

        try:
            root_entries = self.config_manager.filter_by(lambda e: e.parent_id == -1)
            return {"entries": [entry_to_dict(entry) for entry in root_entries]}
        except Exception as e:
            logger.error(f"Error getting config tree: {e}")
            raise
