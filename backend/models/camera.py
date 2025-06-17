from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class CameraStatus(BaseModel):
    connected: bool
    model: Optional[str] = None
    battery: Optional[int] = None
    storage_available: Optional[int] = None


class CameraSettings(BaseModel):
    iso: Optional[int] = None
    aperture: Optional[str] = None
    shutter_speed: Optional[str] = None
    white_balance: Optional[str] = None
    exposure_mode: Optional[str] = None
    focus_mode: Optional[str] = None


class CaptureResult(BaseModel):
    success: bool
    filename: Optional[str] = None
    url: Optional[str] = None
    message: Optional[str] = None
    timestamp: datetime


class PreviewResult(BaseModel):
    success: bool
    url: Optional[str] = None
    message: Optional[str] = None


class FocusResult(BaseModel):
    success: bool
    message: Optional[str] = None
    position: Optional[int] = None
