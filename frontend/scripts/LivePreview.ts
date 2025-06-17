export class LivePreview {
    private baseUrl = '/api/camera/preview';
    private previewElement: HTMLImageElement | null = null;
    private isRunning = false;
    private updateInterval: number | null = null;

    async initialize(): Promise<void> {
        this.previewElement = document.getElementById('live-preview') as HTMLImageElement;
        this.setupEventHandlers();
    }

    start(): void {
        if (this.isRunning || !this.previewElement) return;
        
        this.isRunning = true;
        this.updatePreview();
        
        // Update preview every 100ms for smooth live view
        this.updateInterval = window.setInterval(() => {
            this.updatePreview();
        }, 100);
    }

    stop(): void {
        this.isRunning = false;
        
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
            this.updateInterval = null;
        }
        
        if (this.previewElement) {
            this.previewElement.src = '';
        }
    }

    private async updatePreview(): Promise<void> {
        if (!this.isRunning || !this.previewElement) return;
        
        try {
            const timestamp = Date.now();
            const response = await fetch(`${this.baseUrl}/live?t=${timestamp}`);
            
            if (response.ok) {
                const blob = await response.blob();
                const imageUrl = URL.createObjectURL(blob);
                
                // Clean up previous URL
                if (this.previewElement.src.startsWith('blob:')) {
                    URL.revokeObjectURL(this.previewElement.src);
                }
                
                this.previewElement.src = imageUrl;
            }
        } catch (error) {
            console.error('Failed to update preview:', error);
        }
    }

    private setupEventHandlers(): void {
        // Snapshot button
        const snapshotBtn = document.getElementById('snapshot-btn');
        snapshotBtn?.addEventListener('click', async () => {
            await this.takeSnapshot();
        });

        // Auto focus button
        const focusBtn = document.getElementById('focus-btn');
        focusBtn?.addEventListener('click', async () => {
            await this.autoFocus();
        });
    }

    private async takeSnapshot(): Promise<void> {
        try {
            const response = await fetch(`${this.baseUrl}/snapshot`, {
                method: 'POST'
            });
            const result = await response.json();
            
            if (result.success) {
                // Show snapshot notification or update UI
                console.log('Snapshot taken:', result.url);
            }
        } catch (error) {
            console.error('Failed to take snapshot:', error);
        }
    }

    private async autoFocus(): Promise<void> {
        try {
            const response = await fetch('/api/camera/focus/auto', {
                method: 'POST'
            });
            const result = await response.json();
            
            if (result.success) {
                console.log('Auto focus completed');
            }
        } catch (error) {
            console.error('Auto focus failed:', error);
        }
    }
}
