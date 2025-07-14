// My App - Main Application JavaScript

let platformElement;

// Initialize Neutralino
function onWindowReady() {
    Neutralino.init();
    
    // Platform detection (but don't display it prominently)
    detectPlatform();
    
    // Set up window controls
    setupWindowControls();
    
    console.log('Application initialized successfully');
}

async function detectPlatform() {
    try {
        const osInfo = await Neutralino.os.getInfo();
        console.log(`Platform: ${osInfo.name} ${osInfo.version}`);
    } catch (error) {
        console.log('Platform detection failed:', error);
    }
}

function setupWindowControls() {
    // Remove minimize and maximize buttons if they exist
    try {
        Neutralino.window.setTitle("Application - Application Description");
    } catch (error) {
        console.log('Window setup failed:', error);
    }
}

// Neutralino event handlers
Neutralino.events.on("windowClose", async () => {
    // Only exit if the window is actually being closed, not minimized
    try {
        const isVisible = await Neutralino.window.isVisible();
        const isMinimized = await Neutralino.window.isMinimized();
        
        // If window is hidden but not minimized, it might be a real close event
        if (!isVisible && !isMinimized) {
            Neutralino.app.exit();
        }
    } catch (error) {
        // If we can't check window state, assume it's a real close
        console.log('Window state check failed, exiting:', error);
        Neutralino.app.exit();
    }
});

Neutralino.events.on("ready", onWindowReady);

// Add window focus event handling to prevent disappearing issues
async function handleWindowFocus() {
    try {
        // Ensure window is visible and focused
        await Neutralino.window.show();
        await Neutralino.window.focus();
    } catch (error) {
        console.log('Focus handling failed:', error);
    }
}

// Handle window minimize/restore events more gracefully
document.addEventListener('visibilitychange', async () => {
    if (document.visibilityState === 'visible') {
        // Window became visible again (e.g., after alt-tab)
        try {
            await Neutralino.window.show();
            await Neutralino.window.focus();
        } catch (error) {
            console.log('Visibility change handling failed:', error);
        }
    }
});

// Quick utility functions for the app
function showNotification(message, type = 'info') {
    // Simple notification system
    console.log(`${type.toUpperCase()}: ${message}`);
    
    // Could be enhanced with proper notifications later
    if (typeof Neutralino !== 'undefined' && Neutralino.os && Neutralino.os.showNotification) {
        Neutralino.os.showNotification('My App', message);
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    console.log('My App DOM ready');
}); 
