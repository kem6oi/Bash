#!/bin/bash
################################################################################
# Network Subnet Scanner
# Discovers active hosts on a network subnet using ping sweeps
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

SUBNET=""
TIMEOUT=1
THREADS=50
OUTPUT_FILE=""
RESOLVE_NAMES=0
PORT_SCAN=0
COMMON_PORTS="22,80,443,3389,8080"

################################################################################
# Functions
################################################################################

# Display usage information
usage() {
    print_banner "Network Subnet Scanner"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -s SUBNET       Target subnet in CIDR notation (e.g., 192.168.1.0/24) [required]
    -t TIMEOUT      Ping timeout in seconds [default: 1]
    -j THREADS      Number of parallel threads [default: 50]
    -r              Resolve hostnames for discovered hosts
    -p              Perform quick port scan on discovered hosts
    -P PORTS        Ports to scan (comma-separated) [default: 22,80,443,3389,8080]
    -o FILE         Output results to file
    --help          Show this help message

Examples:
    $0 -s 192.168.1.0/24
    $0 -s 10.0.0.0/24 -r -o hosts.txt
    $0 -s 172.16.0.0/24 -p -P 22,80,443
EOF
)"
    exit 0
}

# Convert CIDR to IP range
cidr_to_range() {
    local cidr="$1"
    local ip="${cidr%/*}"
    local prefix="${cidr#*/}"

    # Validate CIDR
    if ! is_valid_ip "$ip"; then
        die "Invalid IP in CIDR notation: $ip"
    fi

    if ! is_number "$prefix" || ((prefix < 0 || prefix > 32)); then
        die "Invalid CIDR prefix: $prefix (must be 0-32)"
    fi

    # Calculate network range
    IFS='.' read -ra octets <<< "$ip"
    local ip_int=$((octets[0] * 256**3 + octets[1] * 256**2 + octets[2] * 256 + octets[3]))

    local mask=$(((2**32 - 1) << (32 - prefix)))
    local network=$((ip_int & mask))
    local broadcast=$((network | ~mask & (2**32 - 1)))

    # Generate IP list
    local ips=()
    for ((i=network+1; i<broadcast; i++)); do
        local a=$((i >> 24 & 255))
        local b=$((i >> 16 & 255))
        local c=$((i >> 8 & 255))
        local d=$((i & 255))
        ips+=("$a.$b.$c.$d")
    done

    echo "${ips[@]}"
}

# Ping single host
ping_host() {
    local host="$1"
    ping -c 1 -W "$TIMEOUT" "$host" >/dev/null 2>&1
}

# Resolve hostname
resolve_hostname() {
    local ip="$1"
    local hostname=$(host "$ip" 2>/dev/null | grep "pointer" | awk '{print $NF}' | sed 's/\.$//')

    if [[ -z "$hostname" ]]; then
        hostname=$(getent hosts "$ip" 2>/dev/null | awk '{print $2}')
    fi

    if [[ -z "$hostname" ]]; then
        echo "N/A"
    else
        echo "$hostname"
    fi
}

# Quick port check
check_port() {
    local host="$1"
    local port="$2"
    timeout 1 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null
}

# Scan common ports on host
scan_host_ports() {
    local host="$1"
    local ports="$2"
    local open_ports=()

    IFS=',' read -ra port_array <<< "$ports"
    for port in "${port_array[@]}"; do
        if check_port "$host" "$port"; then
            open_ports+=("$port")
        fi
    done

    if [ ${#open_ports[@]} -gt 0 ]; then
        echo "${open_ports[*]}"
    else
        echo "none"
    fi
}

# Get MAC address (requires root on local network)
get_mac_address() {
    local ip="$1"
    arp -n "$ip" 2>/dev/null | grep -v "incomplete" | awk '{print $3}' | grep -E '^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$' || echo "N/A"
}

# Scan single host and report
scan_host() {
    local ip="$1"

    if ping_host "$ip"; then
        local result="[ACTIVE] $ip"

        # Resolve hostname
        if ((RESOLVE_NAMES)); then
            local hostname=$(resolve_hostname "$ip")
            result="$result - Hostname: $hostname"
        fi

        # Check ports
        if ((PORT_SCAN)); then
            local open_ports=$(scan_host_ports "$ip" "$COMMON_PORTS")
            result="$result - Open Ports: $open_ports"
        fi

        # Get MAC address
        local mac=$(get_mac_address "$ip")
        if [[ "$mac" != "N/A" ]]; then
            result="$result - MAC: $mac"
        fi

        log_success "$result"
        [[ -n "$OUTPUT_FILE" ]] && echo "$result" >> "$OUTPUT_FILE"
        return 0
    fi
    return 1
}

# Main scanning function
perform_scan() {
    shift
    local ips=("$@")
    local total_ips=${#ips[@]}
    local active_hosts=0
    local current=0

    log_header "Starting Network Scan"
    log_info "Subnet: $SUBNET"
    log_info "Total IPs to scan: $total_ips"
    log_info "Timeout: ${TIMEOUT}s"
    ((RESOLVE_NAMES)) && log_info "Hostname resolution: enabled"
    ((PORT_SCAN)) && log_info "Port scanning: enabled (ports: $COMMON_PORTS)"
    echo

    local start_time=$(epoch_time)

    # Prepare output file
    if [[ -n "$OUTPUT_FILE" ]]; then
        cat > "$OUTPUT_FILE" << EOF
Network Subnet Scan Results
Subnet: $SUBNET
Started: $(timestamp)
================================================================================

EOF
    fi

    # Scan hosts
    for ip in "${ips[@]}"; do
        ((current++))
        show_progress "$current" "$total_ips" "Scanning hosts"

        # Scan in background for speed
        {
            if scan_host "$ip"; then
                ((active_hosts++))
            fi
        } &

        # Thread control
        while [ "$(jobs -r | wc -l)" -ge "$THREADS" ]; do
            sleep 0.1
        done
    done

    # Wait for all scans to complete
    wait

    local end_time=$(epoch_time)
    local duration=$(calc_duration "$start_time" "$end_time")

    # Summary
    echo
    log_header "Scan Complete"
    log_info "Total IPs scanned: $total_ips"
    log_success "Active hosts found: $active_hosts"
    log_info "Duration: $duration"

    if [[ -n "$OUTPUT_FILE" ]]; then
        cat >> "$OUTPUT_FILE" << EOF

================================================================================
Total IPs scanned: $total_ips
Active hosts found: $active_hosts
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
            -s)
                SUBNET="$2"
                shift 2
                ;;
            -t)
                TIMEOUT="$2"
                shift 2
                ;;
            -j)
                THREADS="$2"
                shift 2
                ;;
            -r)
                RESOLVE_NAMES=1
                shift
                ;;
            -p)
                PORT_SCAN=1
                shift
                ;;
            -P)
                COMMON_PORTS="$2"
                shift 2
                ;;
            -o)
                OUTPUT_FILE="$2"
                shift 2
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
    require_arg "$SUBNET" "subnet (-s)"

    if ! is_number "$TIMEOUT" || ((TIMEOUT < 1)); then
        die "Invalid timeout: $TIMEOUT (must be >= 1)"
    fi

    if ! is_number "$THREADS" || ((THREADS < 1)); then
        die "Invalid thread count: $THREADS (must be >= 1)"
    fi

    # Check for required commands
    require_command ping
    ((RESOLVE_NAMES)) && require_command host "dnsutils or bind-utils"

    # Generate IP list from CIDR
    log_info "Parsing subnet range..."
    local ips=($(cidr_to_range "$SUBNET"))

    if [ ${#ips[@]} -eq 0 ]; then
        die "No valid IPs in range"
    fi

    # Perform scan
    perform_scan "${ips[@]}"
}

# Run main function
main "$@"
