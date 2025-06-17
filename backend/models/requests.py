from pydantic import BaseModel
from typing import Optional, Dict, Any


class CaptureRequest(BaseModel):
    filename: Optional[str] = None
    settings: Optional[Dict[str, Any]] = None


class SettingsUpdateRequest(BaseModel):
    iso: Optional[int] = None
    aperture: Optional[str] = None
    shutter_speed: Optional[str] = None
    white_balance: Optional[str] = None
    exposure_mode: Optional[str] = None


class FocusRequest(BaseModel):
    direction: Optional[str] = None  # "near", "far"
    steps: Optional[int] = None
