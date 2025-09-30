
A minimal shell script to start up Hyprland as a systemd user service.

## Features

- Creates systemd user service for Hyprland
- Idempotent - safe to run multiple times
- Undo functionality to cleanly remove the service
- Automatic verification of existing setup

## Usage
```bash
# Installation
chmod +x setup_hyprland.sh
./setup_hyprland.sh

# Removal
./setup_hyprland.sh --undo
