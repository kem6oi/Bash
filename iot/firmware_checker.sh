#!/bin/bash
################################################################################
# Firmware Update Checker
# Check for firmware updates for IoT devices
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

DEVICE_TYPE=""
CURRENT_VERSION=""
UPDATE_URL=""
OUTPUT_FILE=""

usage() {
    print_banner "Firmware Update Checker"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -d DEVICE       Device type/model
    -v VERSION      Current firmware version
    -u URL          Update check URL
    -o FILE         Output results to file
    --help          Show this help message

Examples:
    $0 -d "ESP32" -v "1.0.0" -u "https://api.example.com/firmware/latest"
    $0 -d "Arduino" -v "2.3.1"
EOF
)"
    exit 0
}

check_updates() {
    log_header "Firmware Update Check"
    log_info "Device: $DEVICE_TYPE"
    log_info "Current Version: $CURRENT_VERSION"
    [[ -n "$UPDATE_URL" ]] && log_info "Update URL: $UPDATE_URL"
    echo

    if [[ -n "$UPDATE_URL" ]]; then
        require_command curl

        log_info "Checking for updates..."
        local response=$(curl -s "$UPDATE_URL")

        if command_exists jq && echo "$response" | jq . >/dev/null 2>&1; then
            local latest=$(echo "$response" | jq -r '.version // .latest_version // .tag_name' 2>/dev/null)

            if [[ -n "$latest" && "$latest" != "null" ]]; then
                log_info "Latest Version: $latest"

                if [[ "$latest" != "$CURRENT_VERSION" ]]; then
                    log_warning "Update available: $CURRENT_VERSION -> $latest"
                else
                    log_success "Firmware is up to date"
                fi
            else
                log_warning "Could not parse version from response"
            fi
        else
            echo "$response"
        fi
    else
        log_info "No update URL provided. Manual check required."
    fi

    [[ -n "$OUTPUT_FILE" ]] && {
        echo "Device: $DEVICE_TYPE" > "$OUTPUT_FILE"
        echo "Current: $CURRENT_VERSION" >> "$OUTPUT_FILE"
        echo "Checked: $(timestamp)" >> "$OUTPUT_FILE"
    }
}

main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d) DEVICE_TYPE="$2"; shift 2 ;;
            -v) CURRENT_VERSION="$2"; shift 2 ;;
            -u) UPDATE_URL="$2"; shift 2 ;;
            -o) OUTPUT_FILE="$2"; shift 2 ;;
            --help) usage ;;
            *) log_error "Unknown option: $1"; usage ;;
        esac
    done

    require_arg "$DEVICE_TYPE" "device type (-d)"
    require_arg "$CURRENT_VERSION" "current version (-v)"

    check_updates
}

main "$@"
