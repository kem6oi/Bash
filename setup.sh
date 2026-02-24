#!/bin/bash
################################################################################
# Environment Setup Script
# Checks and installs required dependencies
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/bash_toolkit/scripts/lib/common.sh"

################################################################################
# Dependency Lists
################################################################################

# Core dependencies (required for basic functionality)
CORE_DEPS=(
    "bash"
    "grep"
    "sed"
    "awk"
    "find"
    "cat"
    "tar"
)

# Optional dependencies (enhance functionality)
OPTIONAL_DEPS=(
    "nmap:Network scanning tools"
    "openssl:SSL/TLS certificate checking"
    "curl:HTTP requests and API testing"
    "jq:JSON parsing"
    "netcat:Network utilities (nc)"
    "tcpdump:Traffic monitoring"
    "mosquitto_pub:MQTT client tools"
    "avahi-browse:mDNS device discovery"
)

################################################################################
# Functions
################################################################################

check_core_dependencies() {
    log_header "Checking Core Dependencies"

    local missing=()
    for dep in "${CORE_DEPS[@]}"; do
        if command_exists "$dep"; then
            log_success "$dep - installed"
        else
            log_error "$dep - MISSING"
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo
        die "Missing core dependencies: ${missing[*]}"
    fi

    echo
}

check_optional_dependencies() {
    log_header "Checking Optional Dependencies"

    local installed=0
    local missing=0

    for entry in "${OPTIONAL_DEPS[@]}"; do
        local cmd="${entry%%:*}"
        local desc="${entry#*:}"

        if command_exists "$cmd" || command_exists "${cmd}_pub" || command_exists "${cmd}_sub"; then
            log_success "$cmd - installed ($desc)"
            ((installed++))
        else
            log_warning "$cmd - not installed ($desc)"
            ((missing++))
        fi
    done

    echo
    log_info "Optional dependencies: $installed installed, $missing missing"
    echo
}

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

show_installation_instructions() {
    local os=$(detect_os)

    log_header "Installation Instructions"

    case "$os" in
        ubuntu|debian)
            log_info "For Ubuntu/Debian systems, run:"
            echo "sudo apt-get update"
            echo "sudo apt-get install -y nmap openssl curl jq netcat tcpdump mosquitto-clients avahi-utils"
            ;;
        fedora|rhel|centos)
            log_info "For Fedora/RHEL/CentOS systems, run:"
            echo "sudo dnf install -y nmap openssl curl jq nc tcpdump mosquitto avahi-tools"
            ;;
        arch)
            log_info "For Arch Linux systems, run:"
            echo "sudo pacman -S nmap openssl curl jq openbsd-netcat tcpdump mosquitto avahi"
            ;;
        macos)
            log_info "For macOS systems with Homebrew, run:"
            echo "brew install nmap openssl curl jq netcat tcpdump mosquitto"
            ;;
        *)
            log_warning "Unknown OS. Please install dependencies manually."
            ;;
    esac

    echo
}

make_scripts_executable() {
    log_header "Making Scripts Executable"

    find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} \;

    log_success "All scripts are now executable"
    echo
}

create_directories() {
    log_header "Creating Required Directories"

    ensure_dir "$SCRIPT_DIR/logs"
    ensure_dir "$SCRIPT_DIR/reports"
    ensure_dir "$SCRIPT_DIR/backups"

    log_success "Directories created"
    echo
}

show_summary() {
    log_header "Setup Complete"

    cat << EOF
The Bash Security & IoT Toolkit is ready to use!

Quick Start:
  1. Launch the interactive menu:
     ./menu.sh

  2. Or run tools directly:
     ./cybersecurity/port_scanner.sh -h 192.168.1.1
     ./automation/health_monitor.sh -C
     ./iot/mqtt_helper.sh -t "sensors/#"

  3. View tool help:
     ./<category>/<tool>.sh --help

Documentation:
  - Read README.md for detailed information
  - Check examples/ directory for usage examples

For issues or suggestions:
  - Open an issue on GitHub
  - Check the documentation

Happy hacking! (Ethically, of course)
EOF
}

################################################################################
# Main Script
################################################################################

main() {
    print_banner "Bash Security & IoT Toolkit - Setup"

    log_info "Detected OS: $(detect_os)"
    echo

    # Run setup steps
    check_core_dependencies
    check_optional_dependencies
    create_directories
    make_scripts_executable

    # Show installation help if dependencies are missing
    if ! command_exists nmap || ! command_exists curl; then
        show_installation_instructions
    fi

    # Summary
    show_summary
}

main "$@"
