interface CameraStatus {
    connected: boolean;
    model?: string;
    battery?: number;
}

interface CameraSettings {
    iso?: number;
    aperture?: string;
    shutter_speed?: string;
}

export class CameraControl {
    private baseUrl = '/api/camera';
    private eventHandlers: Map<string, Function[]> = new Map();
    private status: CameraStatus = { connected: false };
    
    constructor() {
        this.setupEventHandlers();
    }

    async initialize(): Promise<void> {
        await this.updateStatus();
        this.setupUI();
    }

    on(event: string, handler: Function): void {
        if (!this.eventHandlers.has(event)) {
            this.eventHandlers.set(event, []);
        }
        this.eventHandlers.get(event)?.push(handler);
    }

    private emit(event: string, data?: any): void {
        const handlers = this.eventHandlers.get(event);
        if (handlers) {
            handlers.forEach(handler => handler(data));
        }
    }

    async updateStatus(): Promise<void> {
        try {
            const response = await fetch(`${this.baseUrl}/status`);
            this.status = await response.json();
            
            this.updateStatusDisplay();
        } catch (error) {
            console.error('Failed to update camera status:', error);
        }
    }

    async connect(): Promise<boolean> {
        try {
            const response = await fetch(`${this.baseUrl}/connect`, {
                method: 'POST'
            });
            const result = await response.json();
            
            if (result.success) {
                await this.updateStatus();
                this.emit('connected');
                return true;
            } else {
                this.emit('error', result.message);
                return false;
            }
        } catch (error) {
            this.emit('error', 'Failed to connect to camera');
            return false;
        }
    }

    async disconnect(): Promise<boolean> {
        try {
            const response = await fetch(`${this.baseUrl}/disconnect`, {
                method: 'POST'
            });
            const result = await response.json();
            
            if (result.success) {
                this.status.connected = false;
                this.emit('disconnected');
                return true;
            }
            return false;
        } catch (error) {
            this.emit('error', 'Failed to disconnect camera');
            return false;
        }
    }

    async capture(filename?: string): Promise<boolean> {
        if (!this.status.connected) {
            this.emit('error', 'Camera not connected');
            return false;
        }

        try {
            const url = filename ? 
                `${this.baseUrl}/capture?filename=${encodeURIComponent(filename)}` :
                `${this.baseUrl}/capture`;
                
            const response = await fetch(url, { method: 'POST' });
            const result = await response.json();
            
            if (result.success) {
                this.emit('captured', result.filename);
                return true;
            } else {
                this.emit('error', result.message || 'Capture failed');
                return false;
            }
        } catch (error) {
            this.emit('error', 'Failed to capture image');
            return false;
        }
    }

    private setupEventHandlers(): void {
        // Connect button
        const connectBtn = document.getElementById('connect-btn');
        connectBtn?.addEventListener('click', async () => {
            if (this.status.connected) {
                await this.disconnect();
            } else {
                await this.connect();
            }
        });

        // Capture button
        const captureBtn = document.getElementById('capture-btn');
        captureBtn?.addEventListener('click', async () => {
            const btn = captureBtn as HTMLButtonElement;
            btn.disabled = true;
            btn.textContent = 'Capturing...';
            
            await this.capture();
            
            btn.disabled = false;
            btn.textContent = 'Capture';
        });
    }

    private setupUI(): void {
        this.updateStatusDisplay();
    }

    private updateStatusDisplay(): void {
        // Update connection status
        const statusEl = document.getElementById('connection-status');
        if (statusEl) {
            statusEl.textContent = this.status.connected ? 'Connected' : 'Disconnected';
            statusEl.className = this.status.connected ? 'status-connected' : 'status-disconnected';
        }

        // Update battery level
        const batteryEl = document.getElementById('battery-level');
        if (batteryEl) {
            batteryEl.textContent = this.status.battery ? `${this.status.battery}%` : '--';
        }

        // Update connect button
        const connectBtn = document.getElementById('connect-btn') as HTMLButtonElement;
        if (connectBtn) {
            connectBtn.textContent = this.status.connected ? 'Disconnect' : 'Connect Camera';
        }

        // Update capture button
        const captureBtn = document.getElementById('capture-btn') as HTMLButtonElement;
        if (captureBtn) {
            captureBtn.disabled = !this.status.connected;
        }
    }
}
