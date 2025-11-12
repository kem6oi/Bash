#!/bin/bash
################################################################################
# IoT Device Discovery
# Discovers IoT devices on local network using mDNS/Bonjour
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

SCAN_TIME=5
SERVICE_TYPES=("_http._tcp" "_mqtt._tcp" "_homekit._tcp" "_ipp._tcp")
OUTPUT_FILE=""
CONTINUOUS=0

################################################################################
# Functions
################################################################################

usage() {
    print_banner "IoT Device Discovery"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -t TIME         Scan duration in seconds [default: 5]
    -s SERVICE      Service type to scan (can be multiple)
    -a              Scan all common IoT services
    -c              Continuous discovery mode
    -o FILE         Output results to file
    --help          Show this help message

Common Services:
    _http._tcp      HTTP services
    _mqtt._tcp      MQTT brokers
    _homekit._tcp   HomeKit devices
    _ipp._tcp       Network printers

Examples:
    $0 -t 10
    $0 -s _mqtt._tcp -s _http._tcp
    $0 -a -o devices.txt
EOF
)"
    exit 0
}

# Discover devices using avahi
discover_avahi() {
    local service="$1"
    local time="$2"

    log_info "Scanning for $service..."

    timeout "$time" avahi-browse -ptr "$service" 2>/dev/null | grep "^=" | while read -r line; do
        local hostname=$(echo "$line" | awk '{print $4}')
        local ip=$(echo "$line" | awk '{print $8}')
        local port=$(echo "$line" | awk '{print $9}')

        if [[ -n "$hostname" ]]; then
            log_success "Found: $hostname ($ip:$port) - Service: $service"
            [[ -n "$OUTPUT_FILE" ]] && echo "[$service] $hostname - $ip:$port" >> "$OUTPUT_FILE"
        fi
    done
}

# Discover devices using dns-sd (macOS)
discover_dns_sd() {
    local service="$1"
    local time="$2"

    log_info "Scanning for $service..."

    timeout "$time" dns-sd -B "$service" 2>/dev/null | tail -n +4 | while read -r line; do
        local instance=$(echo "$line" | awk -F'  +' '{print $7}')

        if [[ -n "$instance" ]]; then
            log_success "Found: $instance - Service: $service"
            [[ -n "$OUTPUT_FILE" ]] && echo "[$service] $instance" >> "$OUTPUT_FILE"
        fi
    done
}

# Basic network scan fallback
discover_basic() {
    log_subheader "Basic Network Scan"

    local local_ip=$(get_local_ip)
    local network="${local_ip%.*}.0/24"

    log_info "Scanning network: $network"
    log_info "Looking for common IoT ports..."
    echo

    local common_ports=(80 443 1883 8080 8883 8123 5000)
    local found=0

    for ((i=1; i<255; i++)); do
        local ip="${local_ip%.*}.$i"

        for port in "${common_ports[@]}"; do
            if timeout 1 bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null; then
                log_success "Device found: $ip:$port"
                [[ -n "$OUTPUT_FILE" ]] && echo "$ip:$port" >> "$OUTPUT_FILE"
                ((found++))
            fi
        done &

        # Limit concurrent connections
        while [ $(jobs -r | wc -l) -ge 50 ]; do
            sleep 0.1
        done
    done

    wait

    echo
    log_info "Basic scan found $found active port(s)"
}

# Perform discovery
perform_discovery() {
    log_header "IoT Device Discovery"
    log_info "Scan Duration: ${SCAN_TIME}s"
    log_info "Services: ${SERVICE_TYPES[*]}"
    echo

    local start_time=$(epoch_time)

    # Prepare output file
    if [[ -n "$OUTPUT_FILE" ]]; then
        cat > "$OUTPUT_FILE" << EOF
IoT Device Discovery Results
Started: $(timestamp)
================================================================================

EOF
    fi

    # Check for mDNS tools
    if command_exists avahi-browse; then
        log_success "Using avahi-browse for discovery"
        echo

        for service in "${SERVICE_TYPES[@]}"; do
            discover_avahi "$service" "$SCAN_TIME"
        done
    elif command_exists dns-sd; then
        log_success "Using dns-sd for discovery"
        echo

        for service in "${SERVICE_TYPES[@]}"; do
            discover_dns_sd "$service" "$SCAN_TIME"
        done
    else
        log_warning "No mDNS tool found (avahi-browse or dns-sd)"
        log_info "Falling back to basic network scan..."
        echo

        discover_basic
    fi

    local end_time=$(epoch_time)
    local duration=$(calc_duration "$start_time" "$end_time")

    echo
    log_header "Discovery Complete"
    log_info "Duration: $duration"

    [[ -n "$OUTPUT_FILE" ]] && {
        echo "Completed: $(timestamp)" >> "$OUTPUT_FILE"
        log_success "Results saved to: $OUTPUT_FILE"
    }
}

################################################################################
# Main Script
################################################################################

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t)
                SCAN_TIME="$2"
                shift 2
                ;;
            -s)
                SERVICE_TYPES=("$2")
                shift 2
                ;;
            -a)
                SERVICE_TYPES=("_http._tcp" "_https._tcp" "_mqtt._tcp" "_mqtts._tcp" "_homekit._tcp" "_hap._tcp" "_ipp._tcp" "_printer._tcp" "_ssh._tcp")
                shift
                ;;
            -c)
                CONTINUOUS=1
                shift
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
    if ! is_number "$SCAN_TIME" || ((SCAN_TIME < 1)); then
        die "Invalid scan time: $SCAN_TIME"
    fi

    # Run discovery
    if ((CONTINUOUS)); then
        log_info "Continuous discovery mode enabled"
        log_info "Press Ctrl+C to stop"
        echo

        while true; do
            perform_discovery
            echo
            log_info "Waiting 30s before next scan..."
            sleep 30
        done
    else
        perform_discovery
    fi
}

main "$@"
