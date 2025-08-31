#!/bin/bash

# Wallpaper rotation control script
# Usage: ./wallpaper_control.sh [start|stop|status|restart|change]

SERVICE_NAME="wallpaper-rotate.service"
SCRIPT_DIR="$HOME/.config/hypr/scripts"

# Function to show usage
show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start     - Start wallpaper rotation service"
    echo "  stop      - Stop wallpaper rotation service"
    echo "  restart   - Restart wallpaper rotation service"
    echo "  status    - Show service status"
    echo "  change    - Change wallpaper immediately"
    echo "  enable    - Enable service to start on boot"
    echo "  disable   - Disable service from starting on boot"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start      # Start rotation"
    echo "  $0 stop       # Stop rotation"
    echo "  $0 change     # Change wallpaper now"
    echo "  $0 status     # Check if running"
}

# Function to check if service exists
check_service() {
    if ! systemctl --user list-unit-files | grep -q "$SERVICE_NAME"; then
        echo "Error: Service $SERVICE_NAME not found!"
        echo "Make sure the service file is properly installed."
        exit 1
    fi
}

# Function to start service
start_service() {
    echo "Starting wallpaper rotation service..."
    systemctl --user start "$SERVICE_NAME"
    if [ $? -eq 0 ]; then
        echo "✅ Service started successfully!"
        echo "Wallpapers will change every 30 minutes."
    else
        echo "❌ Failed to start service!"
        exit 1
    fi
}

# Function to stop service
stop_service() {
    echo "Stopping wallpaper rotation service..."
    systemctl --user stop "$SERVICE_NAME"
    if [ $? -eq 0 ]; then
        echo "✅ Service stopped successfully!"
    else
        echo "❌ Failed to stop service!"
        exit 1
    fi
}

# Function to restart service
restart_service() {
    echo "Restarting wallpaper rotation service..."
    systemctl --user restart "$SERVICE_NAME"
    if [ $? -eq 0 ]; then
        echo "✅ Service restarted successfully!"
    else
        echo "❌ Failed to restart service!"
        exit 1
    fi
}

# Function to show status
show_status() {
    echo "Wallpaper Rotation Service Status:"
    echo "=================================="
    systemctl --user status "$SERVICE_NAME" --no-pager -l
}

# Function to change wallpaper immediately
change_wallpaper() {
    echo "Changing wallpaper immediately..."
    if [ -f "$SCRIPT_DIR/wallpaper_cron.sh" ]; then
        "$SCRIPT_DIR/wallpaper_cron.sh"
        echo "✅ Wallpaper changed!"
    else
        echo "❌ Wallpaper script not found!"
        exit 1
    fi
}

# Function to enable service
enable_service() {
    echo "Enabling wallpaper rotation service..."
    systemctl --user enable "$SERVICE_NAME"
    if [ $? -eq 0 ]; then
        echo "✅ Service enabled! It will start automatically on boot."
    else
        echo "❌ Failed to enable service!"
        exit 1
    fi
}

# Function to disable service
disable_service() {
    echo "Disabling wallpaper rotation service..."
    systemctl --user disable "$SERVICE_NAME"
    if [ $? -eq 0 ]; then
        echo "✅ Service disabled! It will not start automatically on boot."
    else
        echo "❌ Failed to disable service!"
        exit 1
    fi
}

# Main execution
case "${1:-help}" in
    "start")
        check_service
        start_service
        ;;
    "stop")
        check_service
        stop_service
        ;;
    "restart")
        check_service
        restart_service
        ;;
    "status")
        check_service
        show_status
        ;;
    "change")
        change_wallpaper
        ;;
    "enable")
        check_service
        enable_service
        ;;
    "disable")
        check_service
        disable_service
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        echo "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac
