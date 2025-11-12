#!/bin/bash
################################################################################
# Serial Monitor
# Monitor and log serial port data from IoT devices
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

PORT="/dev/ttyUSB0"
BAUDRATE=9600
OUTPUT_FILE=""
TIMESTAMP=1

usage() {
    print_banner "Serial Port Monitor"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -p PORT         Serial port [default: /dev/ttyUSB0]
    -b BAUDRATE     Baud rate [default: 9600]
    -o FILE         Output log file
    -n              No timestamps
    --help          Show this help message

Examples:
    $0 -p /dev/ttyACM0 -b 115200
    $0 -p /dev/ttyUSB0 -o serial.log
EOF
)"
    exit 0
}

monitor_serial() {
    log_header "Serial Port Monitor"
    log_info "Port: $PORT"
    log_info "Baudrate: $BAUDRATE"
    [[ -n "$OUTPUT_FILE" ]] && log_info "Output: $OUTPUT_FILE"
    echo
    log_info "Listening... (Press Ctrl+C to stop)"
    echo

    if command_exists screen; then
        screen "$PORT" "$BAUDRATE"
    elif command_exists minicom; then
        minicom -D "$PORT" -b "$BAUDRATE"
    else
        # Fallback: use stty and cat
        stty -F "$PORT" "$BAUDRATE" raw -echo
        cat "$PORT" | while read -r line; do
            if ((TIMESTAMP)); then
                echo "[$(timestamp)] $line" | tee -a "$OUTPUT_FILE"
            else
                echo "$line" | tee -a "$OUTPUT_FILE"
            fi
        done
    fi
}

main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p) PORT="$2"; shift 2 ;;
            -b) BAUDRATE="$2"; shift 2 ;;
            -o) OUTPUT_FILE="$2"; shift 2 ;;
            -n) TIMESTAMP=0; shift ;;
            --help) usage ;;
            *) log_error "Unknown option: $1"; usage ;;
        esac
    done

    if [[ ! -e "$PORT" ]]; then
        die "Serial port not found: $PORT"
    fi

    monitor_serial
}

main "$@"
