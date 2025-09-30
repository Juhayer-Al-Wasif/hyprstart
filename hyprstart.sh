#!/bin/bash

# hyprstart.sh - Hyprland Autostart Manager
# Hyprland Purple theme with typewriter ASCII art header

set -e

# Hyprland Purple Colors
PURPLE='\033[0;35m'
PURPLE_DARK='\033[38;5;99m'
PURPLE_MEDIUM='\033[38;5;105m'
PURPLE_LIGHT='\033[38;5;141m'
PURPLE_BRIGHT='\033[38;5;147m'
PURPLE_PALE='\033[38;5;183m'
PINK='\033[38;5;213m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$HOME/.local/bin"
HYPRLAND_SETUP_SCRIPT="$SCRIPT_DIR/hyprland-autostart-setup.sh"
HYPRLAND_VERIFY_SCRIPT="$SCRIPT_DIR/hyprland-verify-setup.sh"
SERVICE_FILE="$HOME/.config/systemd/user/hyprland.service"

# Animation functions
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${PURPLE_LIGHT}[%c]${NC}  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Hyprland purple theme ASCII art
typewriter_ascii() {
    local ascii_lines=(
        "██╗  ██╗██╗   ██╗██████╗ ██████╗ ███████╗████████╗ █████╗ ██████╗ ████████╗"
        "██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝"
        "███████║ ╚████╔╝ ██████╔╝██████╔╝███████╗   ██║   ███████║██████╔╝   ██║   "
        "██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗╚════██║   ██║   ██╔══██║██╔══██╗   ██║   "
        "██║  ██║   ██║   ██║     ██║  ██║███████║   ██║   ██║  ██║██║  ██║   ██║   "
        "╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   "
    )
    
    local purples=("$PURPLE_DARK" "$PURPLE" "$PURPLE_MEDIUM" "$PURPLE_LIGHT" "$PURPLE_BRIGHT" "$PURPLE_PALE")
    
    clear
    for line_idx in "${!ascii_lines[@]}"; do
        line="${ascii_lines[$line_idx]}"
        color="${purples[$line_idx % ${#purples[@]}]}"
        for ((i=0; i<${#line}; i++)); do
            printf "${color}%s${NC}" "${line:$i:1}"
            sleep 0.001
        done
        printf "\n"
    done
    echo ""
    echo -e "${PURPLE}====================================================================${NC}"
    echo -e "${PINK}                     Simple Autostart Manager${NC}"
    echo -e "${PURPLE}====================================================================${NC}"
    echo ""
}

# Print header
print_header() {
    typewriter_ascii
}

print_section() {
    echo ""
    echo -e "${PURPLE_LIGHT}=== $1 ===${NC}"
    echo ""
}

print_info() { 
    echo -e "${PURPLE_LIGHT}[INFO]${NC} $1"
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
    echo -e "${PURPLE_MEDIUM}[ACTION]${NC} $1"
}

# Check if running on Arch Linux
check_arch_linux() {
    if [ ! -f /etc/arch-release ] && ! grep -q "Arch Linux" /etc/os-release 2>/dev/null; then
        print_error "This script is designed for Arch Linux only."
        exit 1
    fi
}

# Check if Hyprland is installed (silent version)
check_hyprland_installed() {
    if ! command -v Hyprland &> /dev/null && ! command -v hyprland &> /dev/null; then
        print_error "Hyprland is not installed!"
        echo ""
        echo -e "${YELLOW}Installation options:${NC}"
        echo -e "  ${GREEN}›${NC} ${PURPLE_LIGHT}sudo pacman -S hyprland${NC}"
        echo -e "  ${GREEN}›${NC} ${PURPLE_LIGHT}yay -S hyprland-git${NC}"
        echo ""
        print_info "After installing Hyprland, run this script again."
        exit 1
    fi
}

# Install scripts automatically
install_scripts() {
    if [ -f "$HYPRLAND_SETUP_SCRIPT" ] && [ -f "$HYPRLAND_VERIFY_SCRIPT" ]; then
        return 0
    fi
    
    print_action "Installing necessary scripts..."
    mkdir -p "$SCRIPT_DIR"
    
    # Show spinner while creating scripts
    (
        # Create setup script with Hyprland purple colors
        cat > "$HYPRLAND_SETUP_SCRIPT" << 'EOF'
#!/bin/bash
# Hyprland autostart setup script

set -e

# Hyprland Purple Colors
PURPLE='\033[0;35m'
PURPLE_LIGHT='\033[38;5;141m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${PURPLE}[INFO]${NC} $1"; }
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
    echo -e "${PURPLE}==========================================${NC}"
    echo -e "${PURPLE}        Hyprland Autostart Setup${NC}"
    echo -e "${PURPLE}==========================================${NC}"
    echo ""
    
    HYPRLAND_EXEC=$(check_hyprland)
    setup_service "$HYPRLAND_EXEC"
    enable_service
    
    echo ""
    echo -e "${PURPLE}==========================================${NC}"
    print_success "Setup completed successfully!"
    echo ""
    echo "Hyprland will start automatically on login."
}

main "$@"
EOF

        # Create verify script with Hyprland purple colors
        cat > "$HYPRLAND_VERIFY_SCRIPT" << 'EOF'
#!/bin/bash
# Hyprland setup verification script

set -e

# Hyprland Purple Colors
PURPLE='\033[0;35m'
PURPLE_LIGHT='\033[38;5;141m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

SERVICE_FILE="$HOME/.config/systemd/user/hyprland.service"

echo -e "${PURPLE}==========================================${NC}"
echo -e "${PURPLE}    Hyprland Autostart Verification${NC}"
echo -e "${PURPLE}==========================================${NC}"
echo ""

# Check service file
echo -e "${PURPLE_LIGHT}Service File Check:${NC}"
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
            echo -e "${PURPLE_LIGHT}Expected: $EXPECTED_EXEC${NC}"
        fi
    fi
else
    print_error "Service file not found: $SERVICE_FILE"
fi

# Check service status
echo ""
echo -e "${PURPLE_LIGHT}Service Status:${NC}"
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
echo -e "${PURPLE}==========================================${NC}"
if [ -f "$SERVICE_FILE" ] && systemctl --user is-enabled hyprland.service 2>/dev/null; then
    print_success "Hyprland autostart is properly configured!"
    echo "Hyprland will start automatically on login."
    exit 0
else
    print_error "Hyprland autostart is not properly configured."
    echo "Run the setup script to configure autostart."
    exit 1
fi
EOF

        chmod +x "$HYPRLAND_SETUP_SCRIPT" "$HYPRLAND_VERIFY_SCRIPT"
    ) &
    spinner $!
    print_success "Scripts installed to: ${PURPLE_LIGHT}$SCRIPT_DIR${NC}"
}

# Check if setup is needed
is_setup_needed() {
    if [ ! -f "$SERVICE_FILE" ] || ! systemctl --user is-enabled hyprland.service 2>/dev/null; then
        return 0  # Setup needed
    else
        return 1  # Setup not needed
    fi
}

# Check if setup exists
is_setup_exists() {
    if [ -f "$SERVICE_FILE" ] || systemctl --user is-enabled hyprland.service 2>/dev/null; then
        return 0  # Setup exists
    else
        return 1  # Setup doesn't exist
    fi
}

# Main setup function - verifies and sets up if needed
main_setup() {
    print_section "Hyprland Autostart Setup"
    
    # Auto-install scripts if missing
    install_scripts
    
    # Run verification first
    print_action "Verifying current setup..."
    if [ -f "$HYPRLAND_VERIFY_SCRIPT" ]; then
        "$HYPRLAND_VERIFY_SCRIPT"
        VERIFY_EXIT_CODE=$?
    else
        print_warning "Verify script not found, using basic verification..."
        VERIFY_EXIT_CODE=1
    fi
    
    echo ""
    
    # If verification passed (everything is already set up)
    if [ $VERIFY_EXIT_CODE -eq 0 ]; then
        print_success "Hyprland autostart is already properly configured!"
        echo ""
        read -p "$(echo -e "${PURPLE_LIGHT}Exit script? ${GREEN}(Y/n)${NC}: ")" choice
        if [[ $choice =~ ^[Nn]$ ]]; then
            print_info "Returning to menu..."
            return
        else
            print_success "Have a good day! 🚀"
            exit 0
        fi
    fi
    
    # If verification failed (setup is needed)
    print_warning "Hyprland autostart is not properly configured."
    read -p "$(echo -e "${YELLOW}Would you like to set it up now? ${GREEN}(Y/n)${NC}: ")" choice
    if [[ $choice =~ ^[Nn]$ ]]; then
        print_info "Setup cancelled."
        return
    fi
    
    print_action "Configuring Hyprland autostart..."
    if [ -f "$HYPRLAND_SETUP_SCRIPT" ]; then
        "$HYPRLAND_SETUP_SCRIPT"
    else
        print_error "Setup script not found!"
        return 1
    fi
}

# Undo setup function
undo_setup() {
    print_section "Undo Hyprland Autostart Setup"
    
    if ! is_setup_exists; then
        print_warning "No Hyprland autostart setup found to undo."
        return
    fi
    
    print_action "Checking current setup..."
    echo ""
    
    if systemctl --user is-active hyprland.service 2>/dev/null; then
        print_action "Stopping Hyprland service..."
        systemctl --user stop hyprland.service 2>/dev/null && print_success "Service stopped" || print_warning "Could not stop service"
    fi
    
    if systemctl --user is-enabled hyprland.service 2>/dev/null; then
        print_action "Disabling Hyprland service..."
        systemctl --user disable hyprland.service 2>/dev/null && print_success "Service disabled" || print_warning "Could not disable service"
    fi
    
    print_action "Reloading systemd..."
    systemctl --user daemon-reload 2>/dev/null && print_success "Systemd reloaded" || print_warning "Could not reload systemd"
    
    if [ -f "$SERVICE_FILE" ]; then
        print_action "Removing service file..."
        rm "$SERVICE_FILE" && print_success "Service file removed: ${PURPLE_LIGHT}$SERVICE_FILE${NC}" || print_error "Could not remove service file"
    fi
    
    echo ""
    print_success "Hyprland autostart setup has been completely removed!"
    echo ""
    print_info "Note: Hyprland will no longer start automatically on login."
}

# Show menu
show_menu() {
    echo ""
    echo -e "${WHITE}Please choose an option:${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}) ${PURPLE_LIGHT}Setup Hyprland Autostart${NC} - ${WHITE}Verifies and configures automatically${NC}"
    echo -e "  ${GREEN}2${NC}) ${YELLOW}Undo Setup${NC} - ${WHITE}Remove autostart configuration${NC}"
    echo -e "  ${GREEN}3${NC}) ${PINK}Exit${NC} - ${WHITE}Close the application${NC}"
    echo ""
}

# Main application logic
main() {
    print_header
    check_arch_linux
    check_hyprland_installed
    
    # Auto-install scripts on first run
    install_scripts
    
    # If no arguments, show interactive menu
    if [ $# -eq 0 ]; then
        while true; do
            show_menu
            read -p "$(echo -e "${PURPLE}Enter your choice ${GREEN}(1-3) [1]${NC}: ")" choice
            choice=${choice:-1}  # Default to 1 if empty
            
            case $choice in
                1)
                    main_setup
                    echo ""
                    ;;
                2)
                    undo_setup
                    echo ""
                    ;;
                3)
                    echo ""
                    print_success "Thank you for using ${PURPLE_LIGHT}HyprStart${NC}! 🌟"
                    print_success "Have a good day! 🚀"
                    exit 0
                    ;;
                *)
                    print_error "Invalid choice. Please enter 1-3."
                    echo ""
                    ;;
            esac
        done
    else
        # Handle command line arguments
        case $1 in
            "setup"|"auto")
                main_setup
                ;;
            "undo"|"remove")
                undo_setup
                ;;
            *)
                print_error "Unknown command: $1"
                echo -e "${WHITE}Available commands: ${PURPLE_LIGHT}setup${NC}, ${YELLOW}undo${NC}"
                exit 1
                ;;
        esac
    fi
}

# Run the application
main "$@"
