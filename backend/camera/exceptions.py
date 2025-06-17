class CameraException(Exception):
    """Base exception for camera operations"""

    pass


class CameraNotConnectedException(CameraException):
    """Raised when camera operation is attempted without connection"""

    pass


class CameraTimeoutException(CameraException):
    """Raised when camera operation times out"""

    pass


class CameraSettingsException(CameraException):
    """Raised when camera settings operation fails"""

    pass


class CaptureException(CameraException):
    """Raised when photo capture fails"""

    pass
