interface FileInfo {
    filename: string;
    size: number;
    date: string;
    url: string;
    thumbnail_url?: string;
}

export class FileManager {
    private baseUrl = '/api/files';
    private files: FileInfo[] = [];
    private galleryElement: HTMLElement | null = null;

    async initialize(): Promise<void> {
        this.galleryElement = document.getElementById('image-gallery');
        this.setupEventHandlers();
        await this.refresh();
    }

    async refresh(): Promise<void> {
        try {
            const response = await fetch(`${this.baseUrl}/captures`);
            this.files = await response.json();
            this.updateGallery();
        } catch (error) {
            console.error('Failed to refresh file list:', error);
        }
    }

    private updateGallery(): void {
        if (!this.galleryElement) return;

        this.galleryElement.innerHTML = '';

        this.files.forEach(file => {
            const fileElement = this.createFileElement(file);
            this.galleryElement?.appendChild(fileElement);
        });
    }

    private createFileElement(file: FileInfo): HTMLElement {
        const element = document.createElement('div');
        element.className = 'file-item';
        
        const sizeStr = this.formatFileSize(file.size);
        const dateStr = new Date(file.date).toLocaleString();
        
        element.innerHTML = `
            <div class="file-thumbnail">
                <img src="${file.thumbnail_url || file.url}" alt="${file.filename}" 
                     onclick="window.open('${file.url}', '_blank')" />
            </div>
            <div class="file-info">
                <div class="file-name">${file.filename}</div>
                <div class="file-details">${sizeStr} • ${dateStr}</div>
            </div>
            <div class="file-actions">
                <button onclick="window.open('${file.url}', '_blank')" class="btn-download">
                    Download
                </button>
                <button onclick="FileManager.deleteFile('${file.filename}')" class="btn-delete">
                    Delete
                </button>
            </div>
        `;

        return element;
    }

    private formatFileSize(bytes: number): string {
        if (bytes === 0) return '0 B';
        
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    static async deleteFile(filename: string): Promise<void> {
        if (!confirm(`Delete ${filename}?`)) return;
        
        try {
            const response = await fetch(`/api/files/captures/${filename}`, {
                method: 'DELETE'
            });
            const result = await response.json();
            
            if (result.success) {
                // Refresh the gallery
                const app = (window as any).app;
                if (app && app.fileManager) {
                    await app.fileManager.refresh();
                }
            } else {
                alert('Failed to delete file: ' + result.message);
            }
        } catch (error) {
            alert('Failed to delete file');
            console.error('Delete error:', error);
        }
    }

    private setupEventHandlers(): void {
        // Download all button
        const downloadAllBtn = document.getElementById('download-all-btn');
        downloadAllBtn?.addEventListener('click', async () => {
            window.open(`${this.baseUrl}/captures/download-all`, '_blank');
        });

        // Clear all button
        const clearAllBtn = document.getElementById('clear-all-btn');
        clearAllBtn?.addEventListener('click', async () => {
            if (!confirm('Delete all captured images? This cannot be undone.')) return;
            
            try {
                const response = await fetch(`${this.baseUrl}/captures/clear`, {
                    method: 'DELETE'
                });
                const result = await response.json();
                
                if (result.success) {
                    await this.refresh();
                    alert(`Deleted ${result.data.count} files`);
                } else {
                    alert('Failed to clear files: ' + result.message);
                }
            } catch (error) {
                alert('Failed to clear files');
                console.error('Clear error:', error);
            }
        });
    }
}