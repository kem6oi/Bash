#!/bin/bash
################################################################################
# Port Scanner
# Scans TCP/UDP ports on target host for security audits
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

TARGET_HOST=""
PORT_RANGE="1-1000"
SCAN_TYPE="tcp"
TIMEOUT=1
THREADS=50
OUTPUT_FILE=""
VERBOSE=0

################################################################################
# Functions
################################################################################

# Display usage information
usage() {
    print_banner "Port Scanner"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -h HOST         Target host (IP or domain) [required]
    -p PORTS        Port range (e.g., 1-1000, 80,443,8080) [default: 1-1000]
    -t TYPE         Scan type: tcp, udp, both [default: tcp]
    -T TIMEOUT      Connection timeout in seconds [default: 1]
    -j THREADS      Number of parallel threads [default: 50]
    -o FILE         Output results to file
    -v              Verbose output
    --help          Show this help message

Examples:
    $0 -h 192.168.1.1 -p 1-1000
    $0 -h example.com -p 80,443,8080 -t tcp
    $0 -h 10.0.0.1 -p 1-65535 -t both -o scan_results.txt
EOF
)"
    exit 0
}

# Parse port range or list
parse_ports() {
    local port_spec="$1"
    local ports=()

    # Check if it's a range (e.g., 1-1000)
    if [[ $port_spec =~ ^([0-9]+)-([0-9]+)$ ]]; then
        local start="${BASH_REMATCH[1]}"
        local end="${BASH_REMATCH[2]}"

        if ((start > end)); then
            die "Invalid port range: start ($start) > end ($end)"
        fi

        for ((port=start; port<=end; port++)); do
            ports+=("$port")
        done
    # Check if it's a comma-separated list (e.g., 80,443,8080)
    elif [[ $port_spec =~ ^[0-9]+(,[0-9]+)*$ ]]; then
        IFS=',' read -ra ports <<< "$port_spec"
    else
        die "Invalid port specification: $port_spec"
    fi

    # Validate all ports
    for port in "${ports[@]}"; do
        if ! is_valid_port "$port"; then
            die "Invalid port: $port"
        fi
    done

    echo "${ports[@]}"
}

# Scan single TCP port
scan_tcp_port() {
    local host="$1"
    local port="$2"

    # Use timeout and /dev/tcp for connection test
    if timeout "$TIMEOUT" bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Scan single UDP port (requires root)
scan_udp_port() {
    local host="$1"
    local port="$2"

    # UDP scan is less reliable - send empty packet and check for ICMP response
    if command_exists nc; then
        if timeout "$TIMEOUT" nc -u -z -w "$TIMEOUT" "$host" "$port" 2>/dev/null; then
            return 0
        fi
    else
        log_warning "netcat (nc) not found - UDP scanning unavailable"
        return 1
    fi
    return 1
}

# Get service name for port
get_service_name() {
    local port="$1"
    local protocol="${2:-tcp}"

    getent services "$port/$protocol" 2>/dev/null | awk '{print $1}' || echo "unknown"
}

# Scan port and report results
scan_port() {
    local host="$1"
    local port="$2"
    local type="$3"

    if [[ "$type" == "tcp" ]]; then
        if scan_tcp_port "$host" "$port"; then
            local service=$(get_service_name "$port" "tcp")
            local result="[TCP] Port $port is OPEN - Service: $service"
            log_success "$result"
            [[ -n "$OUTPUT_FILE" ]] && echo "$result" >> "$OUTPUT_FILE"
            return 0
        fi
    elif [[ "$type" == "udp" ]]; then
        if scan_udp_port "$host" "$port"; then
            local service=$(get_service_name "$port" "udp")
            local result="[UDP] Port $port is OPEN - Service: $service"
            log_success "$result"
            [[ -n "$OUTPUT_FILE" ]] && echo "$result" >> "$OUTPUT_FILE"
            return 0
        fi
    fi

    if ((VERBOSE)); then
        log_info "[${type^^}] Port $port is closed"
    fi
    return 1
}

# Main scanning function
perform_scan() {
    local host="$1"
    shift
    local ports=("$@")
    local total_ports=${#ports[@]}
    local open_ports=0
    local current=0

    log_header "Starting Port Scan"
    log_info "Target: $host"
    log_info "Ports: ${#ports[@]} ports"
    log_info "Type: ${SCAN_TYPE^^}"
    log_info "Timeout: ${TIMEOUT}s"
    echo

    local start_time=$(epoch_time)

    # Prepare output file
    if [[ -n "$OUTPUT_FILE" ]]; then
        cat > "$OUTPUT_FILE" << EOF
Port Scan Results
Target: $host
Scan Type: ${SCAN_TYPE^^}
Started: $(timestamp)
================================================================================

EOF
    fi

    # Scan ports with thread control
    for port in "${ports[@]}"; do
        ((current++))

        # Show progress
        if ! ((VERBOSE)); then
            show_progress "$current" "$total_ports" "Scanning"
        fi

        # Scan based on type
        if [[ "$SCAN_TYPE" == "both" ]]; then
            if scan_port "$host" "$port" "tcp" || scan_port "$host" "$port" "udp"; then
                ((open_ports++))
            fi
        else
            if scan_port "$host" "$port" "$SCAN_TYPE"; then
                ((open_ports++))
            fi
        fi

        # Simple thread control - wait if too many background jobs
        while [ "$(jobs -r | wc -l)" -ge "$THREADS" ]; do
            sleep 0.1
        done
    done

    # Wait for remaining background jobs
    wait

    local end_time=$(epoch_time)
    local duration=$(calc_duration "$start_time" "$end_time")

    # Summary
    echo
    log_header "Scan Complete"
    log_info "Total ports scanned: $total_ports"
    log_success "Open ports found: $open_ports"
    log_info "Duration: $duration"

    if [[ -n "$OUTPUT_FILE" ]]; then
        cat >> "$OUTPUT_FILE" << EOF

================================================================================
Total ports scanned: $total_ports
Open ports found: $open_ports
Completed: $(timestamp)
Duration: $duration
EOF
        log_success "Results saved to: $OUTPUT_FILE"
    fi
}

################################################################################
# Main Script
################################################################################

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h)
                TARGET_HOST="$2"
                shift 2
                ;;
            -p)
                PORT_RANGE="$2"
                shift 2
                ;;
            -t)
                SCAN_TYPE="$2"
                shift 2
                ;;
            -T)
                TIMEOUT="$2"
                shift 2
                ;;
            -j)
                THREADS="$2"
                shift 2
                ;;
            -o)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -v)
                VERBOSE=1
                shift
                ;;
            --help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Validate arguments
    require_arg "$TARGET_HOST" "target host (-h)"

    if ! is_valid_ip "$TARGET_HOST" && ! is_valid_domain "$TARGET_HOST"; then
        die "Invalid target: $TARGET_HOST (must be valid IP or domain)"
    fi

    if [[ ! "$SCAN_TYPE" =~ ^(tcp|udp|both)$ ]]; then
        die "Invalid scan type: $SCAN_TYPE (must be: tcp, udp, or both)"
    fi

    if ! is_number "$TIMEOUT" || ((TIMEOUT < 1)); then
        die "Invalid timeout: $TIMEOUT (must be >= 1)"
    fi

    if ! is_number "$THREADS" || ((THREADS < 1)); then
        die "Invalid thread count: $THREADS (must be >= 1)"
    fi

    # Check if host is reachable
    log_info "Checking if target is reachable..."
    if ! is_host_reachable "$TARGET_HOST"; then
        log_warning "Target $TARGET_HOST is not responding to ping (may be firewalled)"
        if ! confirm "Continue anyway?"; then
            exit 0
        fi
    fi

    # Parse ports
    local ports=($(parse_ports "$PORT_RANGE"))

    # Perform scan
    perform_scan "$TARGET_HOST" "${ports[@]}"
}

# Run main function
main "$@"
