from pydantic import BaseModel
from typing import Optional, Any
from datetime import datetime


class APIResponse(BaseModel):
    success: bool
    message: Optional[str] = None
    data: Optional[Any] = None


class FileInfo(BaseModel):
    filename: str
    size: int
    date: datetime
    url: str
    thumbnail_url: Optional[str] = None


class SystemInfo(BaseModel):
    cpu_usage: float
    memory_usage: float
    disk_usage: float
    uptime: str
    camera_service_status: str


class CameraInfo(BaseModel):
    id: str
    name: str
    address: str
    connected: bool


class StorageInfo(BaseModel):
    total: int
    used: int
    free: int
    percent_used: float


class LogEntry(BaseModel):
    timestamp: datetime
    level: str
    message: str
    module: Optional[str] = None
