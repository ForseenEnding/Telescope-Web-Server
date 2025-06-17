from pathlib import Path
from typing import Optional, Dict, Any
import shutil
import logging
from datetime import datetime

from config.settings import settings
from models.responses import FileInfo

logger = logging.getLogger(__name__)


class FileService:
    """Service to manage captured files and directories"""

    def __init__(self):
        self.capture_path = Path(settings.CAPTURE_PATH)
        self.preview_path = Path(settings.PREVIEW_PATH)

        # Ensure directories exist
        self.capture_path.mkdir(exist_ok=True)
        self.preview_path.mkdir(exist_ok=True)

    def get_storage_info(self) -> Dict[str, Any]:
        """Get storage information"""
        try:
            usage = shutil.disk_usage(self.capture_path)
            return {
                "total": usage.total,
                "used": usage.used,
                "free": usage.free,
                "percent_used": (usage.used / usage.total) * 100,
            }
        except Exception as e:
            logger.error(f"Error getting storage info: {e}")
            return {}

    def cleanup_old_files(self, days_old: int = 30) -> int:
        """Clean up files older than specified days"""
        try:
            cutoff_time = datetime.now().timestamp() - (days_old * 24 * 60 * 60)
            deleted_count = 0

            for file_path in self.capture_path.glob("*"):
                if file_path.is_file() and file_path.stat().st_mtime < cutoff_time:
                    file_path.unlink()
                    deleted_count += 1

            logger.info(f"Cleaned up {deleted_count} old files")
            return deleted_count

        except Exception as e:
            logger.error(f"Error cleaning up old files: {e}")
            return 0

    def get_file_info(self, filename: str) -> Optional[FileInfo]:
        """Get information about a specific file"""
        try:
            file_path = self.capture_path / filename
            if not file_path.exists():
                return None

            stat = file_path.stat()
            return FileInfo(
                filename=filename,
                size=stat.st_size,
                date=datetime.fromtimestamp(stat.st_mtime),
                url=f"/api/files/captures/{filename}",
            )
        except Exception as e:
            logger.error(f"Error getting file info for {filename}: {e}")
            return None


# Singleton instance
file_service = FileService()
