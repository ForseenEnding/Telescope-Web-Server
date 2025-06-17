import uvicorn
from pathlib import Path
import subprocess
import threading
import time
import os


def watch_frontend():
    """Watch frontend files and rebuild on changes"""
    frontend_dir = Path(__file__).parent.parent / "frontend"

    # Simple file watcher (you could use watchdog for more advanced watching)
    last_modified = {}

    while True:
        try:
            for file_path in frontend_dir.rglob("*.ts"):
                current_mtime = file_path.stat().st_mtime
                if (
                    str(file_path) not in last_modified
                    or last_modified[str(file_path)] < current_mtime
                ):
                    last_modified[str(file_path)] = current_mtime
                    print(f"Frontend file changed: {file_path.name}")
                    # Trigger TypeScript compilation
                    subprocess.run(["npm", "run", "build"], cwd=file_path.parent.parent)
                    break
        except Exception as e:
            print(f"Error watching files: {e}")

        time.sleep(1)


def run_dev_server():
    """Run development server with frontend watching"""
    # Start frontend file watcher in background
    watcher_thread = threading.Thread(target=watch_frontend, daemon=True)
    watcher_thread.start()

    # Run the main server
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        reload_dirs=["./"],
        log_level="info",
    )


if __name__ == "__main__":
    run_dev_server()
