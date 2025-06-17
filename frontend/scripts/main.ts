import { CameraControl } from './CameraControl.js';
import { LivePreview } from './LivePreview.js';
import { FileManager } from './FileManager.js';

class App {
    private cameraControl: CameraControl;
    private livePreview: LivePreview;
    private fileManager: FileManager;

    constructor() {
        this.cameraControl = new CameraControl();
        this.livePreview = new LivePreview();
        this.fileManager = new FileManager();
        
        this.init();
    }

    private async init(): Promise<void> {
        try {
            await this.cameraControl.initialize();
            await this.livePreview.initialize();
            await this.fileManager.initialize();
            
            this.setupEventListeners();
            this.updateUI();
        } catch (error) {
            console.error('Failed to initialize app:', error);
        }
    }

    private setupEventListeners(): void {
        // Camera control events
        this.cameraControl.on('connected', () => {
            this.livePreview.start();
            this.updateConnectionStatus(true);
        });
        
        this.cameraControl.on('disconnected', () => {
            this.livePreview.stop();
            this.updateConnectionStatus(false);
        });
        
        this.cameraControl.on('captured', (filename: string) => {
            this.fileManager.refresh();
            this.showNotification(`Image captured: ${filename}`, 'success');
        });
        
        this.cameraControl.on('error', (error: string) => {
            this.showNotification(error, 'error');
        });
    }

    private updateConnectionStatus(connected: boolean): void {
        const statusElement = document.getElementById('connection-status');
        if (statusElement) {
            statusElement.textContent = connected ? 'Connected' : 'Disconnected';
            statusElement.className = connected ? 'status-connected' : 'status-disconnected';
        }
    }

    private updateUI(): void {
        // Update status periodically
        setInterval(async () => {
            await this.cameraControl.updateStatus();
        }, 5000);
    }

    private showNotification(message: string, type: 'success' | 'error' | 'info'): void {
        // Simple notification system
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.remove();
        }, 5000);
    }
}

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    new App();
});
