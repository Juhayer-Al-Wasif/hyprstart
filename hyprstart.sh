#!/bin/bash

set -e

CONFIG_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$CONFIG_DIR/hyprland.service"
SERVICE_CONTENT="[Unit]
Description=Hyprland Wayland Compositor
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/Hyprland
Restart=on-failure
Environment=XDG_SESSION_TYPE=wayland

[Install]
WantedBy=default.target"

undo() {
    echo "Removing Hyprland service..."
    systemctl --user disable hyprland.service 2>/dev/null || true
    rm -f "$SERVICE_FILE"
    rmdir "$CONFIG_DIR" 2>/dev/null || true
    echo "Undo complete!"
    exit 0
}

[[ "$1" == "--undo" ]] && undo

echo "Setting up Hyprland systemd user service..."

mkdir -p "$CONFIG_DIR"
echo "$SERVICE_CONTENT" > "$SERVICE_FILE"

if systemctl --user is-enabled hyprland.service 2>/dev/null | grep -q "enabled"; then
    echo "Service already enabled"
else
    systemctl --user enable hyprland.service
    echo "Service enabled"
fi

echo "Setup complete! Use '$0 --undo' to remove."
