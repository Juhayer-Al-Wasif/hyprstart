#!/bin/bash

# hyprland-autostart-manager.sh
# Terminal app for managing Hyprland autostart setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$HOME/.local/bin"
HYPRLAND_SETUP_SCRIPT="$SCRIPT_DIR/hyprland-autostart-setup.sh"
HYPRLAND_VERIFY_SCRIPT="$SCRIPT_DIR/hyprland-verify-setup.sh"
SERVICE_FILE="$HOME/.config/systemd/user/hyprland.service"

# Print colored output
print_header() {
    echo -e "${PURPLE}==========================================${NC}"
    echo -e "${PURPLE}    Hyprland Autostart Manager${NC}"
    echo -e "${PURPLE}==========================================${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_action() {
    echo -e "${CYAN}[ACTION]${NC} $1"
}

# Check if running on Arch Linux
check_arch_linux() {
    if [ ! -f /etc/arch-release ] && ! grep -q "Arch Linux" /etc/os-release 2>/dev/null; then
        print_error "This script is designed for Arch Linux only."
        exit 1
    fi
    print_success "Running on Arch Linux"
}

# Install the necessary scripts
install_scripts() {
    print_action "Installing Hyprland autostart scripts..."
    
    # Create script directory if it doesn't exist
    mkdir -p "$SCRIPT_DIR"
    
    # Create the setup script
    cat > "$HYPRLAND_SETUP_SCRIPT" << 'EOF'
#!/bin/bash
# hyprland-autostart-setup.sh
# Setup script for Hyprland systemd autostart

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Check if Hyprland is installed
check_hyprland() {
    if ! command -v Hyprland &> /dev/null && ! command -v hyprland &> /dev/null; then
        print_warning "Hyprland not found in PATH."
        echo "Install with: sudo pacman -S hyprland"
        exit 1
    fi
    
    HYPRLAND_EXEC=$(command -v Hyprland || command -v hyprland)
    print_success "Found Hyprland at: $HYPRLAND_EXEC"
    echo "$HYPRLAND_EXEC"
}

# Create or update service file
setup_service() {
    local hyprland_exec="$1"
    local service_file="$HOME/.config/systemd/user/hyprland.service"
    
    print_status "Setting up systemd service..."
    
    mkdir -p ~/.config/systemd/user
    
    cat > "$service_file" << EOSERVICE
[Unit]
Description=Hyprland Wayland Compositor
After=graphical-session.target

[Service]
Type=simple
ExecStart=$hyprland_exec
Restart=on-failure
RestartSec=3
Environment=XDG_SESSION_TYPE=wayland
Environment=QT_QPA_PLATFORM=wayland
Environment=MOZ_ENABLE_WAYLAND=1

[Install]
WantedBy=graphical-session.target
EOSERVICE

    print_success "Service file created: $service_file"
}

# Enable the service
enable_service() {
    print_status "Enabling Hyprland service..."
    
    if systemctl --user daemon-reload && systemctl --user enable hyprland.service; then
        print_success "Hyprland service enabled"
    else
        print_warning "Could not enable service via systemctl --user"
        print_status "The service file is ready and will be enabled on next login"
    fi
}

main() {
    echo "=========================================="
    echo "  Hyprland Autostart Setup"
    echo "=========================================="
    
    HYPRLAND_EXEC=$(check_hyprland)
    setup_service "$HYPRLAND_EXEC"
    enable_service
    
    echo ""
    echo "=========================================="
    print_success "Setup completed successfully!"
    echo ""
    echo "Hyprland will start automatically on login."
}

main "$@"
EOF

    # Create the verify script
    cat > "$HYPRLAND_VERIFY_SCRIPT" << 'EOF'
#!/bin/bash
# hyprland-verify-setup.sh
# Verification script for Hyprland autostart setup

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅${NC} $1"; }
print_error() { echo -e "${RED}❌${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠️${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ️${NC} $1"; }

SERVICE_FILE="$HOME/.config/systemd/user/hyprland.service"

echo "=========================================="
echo "    Hyprland Autostart Verification"
echo "=========================================="
echo ""

# Check if Hyprland is installed
if command -v Hyprland &> /dev/null || command -v hyprland &> /dev/null; then
    HYPRLAND_EXEC=$(command -v Hyprland || command -v hyprland)
    print_success "Hyprland installed: $HYPRLAND_EXEC"
else
    print_error "Hyprland not found in PATH"
fi

# Check service file
echo ""
echo "Service File Check:"
if [ -f "$SERVICE_FILE" ]; then
    print_success "Service file exists: $SERVICE_FILE"
    
    # Check if executable in service file is correct
    if command -v Hyprland &> /dev/null; then
        EXPECTED_EXEC=$(command -v Hyprland)
        CURRENT_EXEC=$(grep -oP '^ExecStart=\K.*' "$SERVICE_FILE" 2>/dev/null || echo "")
        if [ "$CURRENT_EXEC" == "$EXPECTED_EXEC" ]; then
            print_success "Service file points to correct Hyprland executable"
        else
            print_warning "Service file points to: $CURRENT_EXEC"
            print_info "Expected: $EXPECTED_EXEC"
        fi
    fi
else
    print_error "Service file not found: $SERVICE_FILE"
fi

# Check service status
echo ""
echo "Service Status:"
if systemctl --user is-enabled hyprland.service 2>/dev/null; then
    print_success "Service is enabled"
else
    print_error "Service is not enabled"
fi

if systemctl --user is-active hyprland.service 2>/dev/null; then
    print_success "Service is running"
else
    print_warning "Service is not running (normal if not logged in graphically)"
fi

# Overall status
echo ""
echo "=========================================="
if [ -f "$SERVICE_FILE" ] && systemctl --user is-enabled hyprland.service 2>/dev/null; then
    print_success "Hyprland autostart is properly configured!"
    echo "Hyprland will start automatically on login."
else
    print_error "Hyprland autostart is not properly configured."
    echo "Run the setup script to configure autostart."
fi
echo "=========================================="
EOF

    # Make scripts executable
    chmod +x "$HYPRLAND_SETUP_SCRIPT"
    chmod +x "$HYPRLAND_VERIFY_SCRIPT"
    
    print_success "Scripts installed to: $SCRIPT_DIR"
}

# Verify current setup
verify_setup() {
    print_action "Verifying current Hyprland autostart setup..."
    
    # Run the verify script if it exists, otherwise do basic checks
    if [ -f "$HYPRLAND_VERIFY_SCRIPT" ]; then
        "$HYPRLAND_VERIFY_SCRIPT"
    else
        print_warning "Verify script not found. Performing basic checks..."
        
        # Basic checks
        if command -v Hyprland &> /dev/null || command -v hyprland &> /dev/null; then
            print_success "Hyprland is installed"
        else
            print_error "Hyprland is not installed"
        fi
        
        if [ -f "$SERVICE_FILE" ]; then
            print_success "Service file exists"
        else
            print_error "Service file not found"
        fi
        
        if systemctl --user is-enabled hyprland.service 2>/dev/null; then
            print_success "Service is enabled"
        else
            print_error "Service is not enabled"
        fi
    fi
}

# Run setup
run_setup() {
    print_action "Running Hyprland autostart setup..."
    
    if [ -f "$HYPRLAND_SETUP_SCRIPT" ]; then
        "$HYPRLAND_SETUP_SCRIPT"
    else
        print_error "Setup script not found. Please install scripts first."
        exit 1
    fi
}

# Show menu
show_menu() {
    echo ""
    print_header
    echo "Please choose an option:"
    echo ""
    echo -e "${GREEN}1${NC}) Verify current setup"
    echo -e "${GREEN}2${NC}) Install/Update scripts only"
    echo -e "${GREEN}3${NC}) Verify and setup if needed (auto)"
    echo -e "${GREEN}4${NC}) Run setup only"
    echo -e "${GREEN}5${NC}) Check Hyprland installation"
    echo -e "${GREEN}6${NC}) Exit"
    echo ""
}

# Check if setup is needed
is_setup_needed() {
    if [ ! -f "$SERVICE_FILE" ] || ! systemctl --user is-enabled hyprland.service 2>/dev/null; then
        return 0  # Setup needed
    else
        return 1  # Setup not needed
    fi
}

# Check Hyprland installation
check_hyprland_install() {
    print_action "Checking Hyprland installation..."
    
    if command -v Hyprland &> /dev/null || command -v hyprland &> /dev/null; then
        HYPRLAND_EXEC=$(command -v Hyprland || command -v hyprland)
        print_success "Hyprland is installed: $HYPRLAND_EXEC"
        
        # Check version if possible
        if $HYPRLAND_EXEC --version &>/dev/null; then
            VERSION=$($HYPRLAND_EXEC --version 2>/dev/null | head -n1 || echo "Unknown version")
            print_info "Version: $VERSION"
        fi
    else
        print_error "Hyprland is not installed"
        echo ""
        print_info "To install Hyprland, run:"
        echo "  sudo pacman -S hyprland"
        echo ""
        print_info "Or for the git version:"
        echo "  yay -S hyprland-git"
    fi
}

# Main application logic
main() {
    check_arch_linux
    
    # If no arguments, show interactive menu
    if [ $# -eq 0 ]; then
        while true; do
            show_menu
            read -p "Enter your choice (1-6): " choice
            
            case $choice in
                1)
                    verify_setup
                    ;;
                2)
                    install_scripts
                    ;;
                3)
                    install_scripts
                    verify_setup
                    if is_setup_needed; then
                        echo ""
                        read -p "Setup is needed. Run setup now? (y/N): " run_setup_choice
                        if [[ $run_setup_choice =~ ^[Yy]$ ]]; then
                            run_setup
                        fi
                    else
                        print_success "Setup is already complete!"
                    fi
                    ;;
                4)
                    run_setup
                    ;;
                5)
                    check_hyprland_install
                    ;;
                6)
                    print_info "Have a good day!"
                    exit 0
                    ;;
                *)
                    print_error "Invalid choice. Please enter 1-6."
                    ;;
            esac
            
            echo ""
            read -p "Press Enter to continue..."
        done
    else
        # Handle command line arguments
        case $1 in
            "verify")
                verify_setup
                ;;
            "install-scripts")
                install_scripts
                ;;
            "setup")
                run_setup
                ;;
            "auto")
                install_scripts
                if is_setup_needed; then
                    print_action "Auto-detected setup needed. Running setup..."
                    run_setup
                else
                    print_success "Setup is already complete!"
                fi
                ;;
            "check-hyprland")
                check_hyprland_install
                ;;
            *)
                print_error "Unknown command: $1"
                echo "Available commands: verify, install-scripts, setup, auto, check-hyprland"
                exit 1
                ;;
        esac
    fi
}

# Run the application
main "$@"
