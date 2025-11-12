#!/bin/bash
################################################################################
# GPIO Controller for Raspberry Pi
# Control GPIO pins on Raspberry Pi
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

PIN=""
ACTION="read"
VALUE=""
MODE="out"

usage() {
    print_banner "GPIO Controller (Raspberry Pi)"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -p PIN          GPIO pin number (BCM) [required]
    -a ACTION       Action: read, write, toggle [default: read]
    -v VALUE        Value: 0 (low), 1 (high) [for write action]
    -m MODE         Pin mode: in, out [default: out]
    --help          Show this help message

Examples:
    $0 -p 17 -a read
    $0 -p 27 -a write -v 1
    $0 -p 22 -a toggle
EOF
)"
    exit 0
}

check_raspberry_pi() {
    if [[ ! -f /proc/device-tree/model ]] || ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
        log_warning "This doesn't appear to be a Raspberry Pi"
    fi
}

setup_gpio() {
    local pin="$1"
    local mode="$2"

    if [[ ! -d "/sys/class/gpio/gpio$pin" ]]; then
        echo "$pin" > /sys/class/gpio/export 2>/dev/null || true
        sleep 0.1
    fi

    echo "$mode" > "/sys/class/gpio/gpio$pin/direction" 2>/dev/null
}

gpio_read() {
    local pin="$1"

    setup_gpio "$pin" "in"

    local value=$(cat "/sys/class/gpio/gpio$pin/value" 2>/dev/null)
    log_info "GPIO $pin state: $value"
}

gpio_write() {
    local pin="$1"
    local value="$2"

    setup_gpio "$pin" "out"

    echo "$value" > "/sys/class/gpio/gpio$pin/value" 2>/dev/null
    log_success "GPIO $pin set to: $value"
}

gpio_toggle() {
    local pin="$1"

    setup_gpio "$pin" "out"

    local current=$(cat "/sys/class/gpio/gpio$pin/value" 2>/dev/null)
    local new_value=$((1 - current))

    echo "$new_value" > "/sys/class/gpio/gpio$pin/value" 2>/dev/null
    log_success "GPIO $pin toggled: $current -> $new_value"
}

main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p) PIN="$2"; shift 2 ;;
            -a) ACTION="$2"; shift 2 ;;
            -v) VALUE="$2"; shift 2 ;;
            -m) MODE="$2"; shift 2 ;;
            --help) usage ;;
            *) log_error "Unknown option: $1"; usage ;;
        esac
    done

    require_arg "$PIN" "GPIO pin (-p)"
    check_raspberry_pi

    if ! is_root; then
        die "This script requires root privileges. Try: sudo $0 -p $PIN -a $ACTION"
    fi

    log_header "GPIO Controller"
    log_info "Pin: GPIO $PIN"
    log_info "Action: $ACTION"
    echo

    case "$ACTION" in
        read) gpio_read "$PIN" ;;
        write)
            require_arg "$VALUE" "value (-v)"
            gpio_write "$PIN" "$VALUE"
            ;;
        toggle) gpio_toggle "$PIN" ;;
        *) die "Invalid action: $ACTION" ;;
    esac
}

main "$@"
