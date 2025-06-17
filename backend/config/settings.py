from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # Camera settings
    CAMERA_TIMEOUT: int = 30
    CAPTURE_PATH: str = "./captures"
    PREVIEW_PATH: str = "./previews"

    # Server settings
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    DEBUG: bool = False

    # USB settings
    USB_VENDOR_ID: Optional[str] = None
    USB_PRODUCT_ID: Optional[str] = None

    class Config:
        env_file = ".env"


settings = Settings()
