#!/bin/bash
################################################################################
# Network Traffic Monitor
# Capture and analyze IoT device network traffic
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

INTERFACE="eth0"
FILTER=""
OUTPUT_FILE=""
PACKET_COUNT=100
DURATION=0

usage() {
    print_banner "Network Traffic Monitor"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -i INTERFACE    Network interface [default: eth0]
    -f FILTER       tcpdump filter expression
    -c COUNT        Packet count limit [default: 100]
    -t SECONDS      Capture duration in seconds
    -o FILE         Output pcap file
    --help          Show this help message

Examples:
    $0 -i wlan0 -f "port 1883"
    $0 -c 500 -o capture.pcap
    $0 -i eth0 -f "host 192.168.1.100" -t 60
EOF
)"
    exit 0
}

check_permissions() {
    if ! is_root; then
        die "This script requires root privileges. Try: sudo $0 $*"
    fi
}

monitor_traffic() {
    log_header "Network Traffic Monitor"
    log_info "Interface: $INTERFACE"
    [[ -n "$FILTER" ]] && log_info "Filter: $FILTER"
    [[ -n "$OUTPUT_FILE" ]] && log_info "Output: $OUTPUT_FILE"
    echo

    require_command tcpdump

    local tcpdump_opts="-i $INTERFACE"
    [[ -n "$FILTER" ]] && tcpdump_opts="$tcpdump_opts $FILTER"

    if [[ -n "$OUTPUT_FILE" ]]; then
        tcpdump_opts="$tcpdump_opts -w $OUTPUT_FILE"
    else
        tcpdump_opts="$tcpdump_opts -n"
    fi

    if ((PACKET_COUNT > 0)); then
        tcpdump_opts="$tcpdump_opts -c $PACKET_COUNT"
    fi

    if ((DURATION > 0)); then
        tcpdump_opts="$tcpdump_opts -G $DURATION -W 1"
    fi

    log_info "Capturing packets..."
    eval "tcpdump $tcpdump_opts"

    [[ -n "$OUTPUT_FILE" ]] && log_success "Capture saved to: $OUTPUT_FILE"
}

main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i) INTERFACE="$2"; shift 2 ;;
            -f) FILTER="$2"; shift 2 ;;
            -c) PACKET_COUNT="$2"; shift 2 ;;
            -t) DURATION="$2"; shift 2 ;;
            -o) OUTPUT_FILE="$2"; shift 2 ;;
            --help) usage ;;
            *) log_error "Unknown option: $1"; usage ;;
        esac
    done

    check_permissions
    monitor_traffic
}

main "$@"
