#!/bin/bash
################################################################################
# Vulnerability Scanner Wrapper
# Automates common vulnerability scanning tasks using various tools
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

TARGET=""
SCAN_TYPE="quick"
OUTPUT_FILE=""
USE_NMAP=0
USE_NIKTO=0
USE_TESTSSL=0

################################################################################
# Functions
################################################################################

usage() {
    print_banner "Vulnerability Scanner Wrapper"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -t TARGET       Target host or network
    -s TYPE         Scan type: quick, full, web [default: quick]
    -o FILE         Output results to file
    --nmap          Use nmap for network scanning
    --nikto         Use nikto for web scanning
    --testssl       Use testssl.sh for SSL/TLS scanning
    --all           Use all available tools
    --help          Show this help message

Examples:
    $0 -t 192.168.1.1 -s quick
    $0 -t example.com -s web --nikto --testssl
    $0 -t 10.0.0.0/24 --nmap --all -o scan_results.txt

Note: This is a wrapper script. Install nmap, nikto, testssl.sh for full functionality.
EOF
)"
    exit 0
}

# Check available tools
check_tools() {
    log_header "Checking Available Tools"

    local tools_found=0

    if command_exists nmap; then
        log_success "nmap: available"
        USE_NMAP=1
        ((tools_found++))
    else
        log_warning "nmap: not installed"
    fi

    if command_exists nikto; then
        log_success "nikto: available"
        USE_NIKTO=1
        ((tools_found++))
    else
        log_warning "nikto: not installed"
    fi

    if command_exists testssl.sh || command_exists testssl; then
        log_success "testssl: available"
        USE_TESTSSL=1
        ((tools_found++))
    else
        log_warning "testssl: not installed"
    fi

    echo
    if ((tools_found == 0)); then
        die "No scanning tools available. Please install: nmap, nikto, or testssl.sh"
    fi

    log_info "Found $tools_found scanning tool(s)"
    echo
}

# Nmap scan
scan_nmap() {
    local target="$1"
    local type="$2"

    log_subheader "Nmap Vulnerability Scan"

    if ! command_exists nmap; then
        log_warning "Nmap not installed, skipping..."
        return
    fi

    local nmap_opts=""
    case "$type" in
        quick)
            nmap_opts="-sV -sC --top-ports 100"
            ;;
        full)
            nmap_opts="-sV -sC -p- -A"
            ;;
        *)
            nmap_opts="-sV -sC"
            ;;
    esac

    log_info "Running: nmap $nmap_opts $target"
    local output=$(nmap $nmap_opts "$target" 2>&1)

    echo "$output"

    [[ -n "$OUTPUT_FILE" ]] && {
        echo "=== Nmap Scan ===" >> "$OUTPUT_FILE"
        echo "$output" >> "$OUTPUT_FILE"
        echo >> "$OUTPUT_FILE"
    }

    # Check for vulnerabilities in output
    if echo "$output" | grep -qi "vulnerable"; then
        log_warning "Potential vulnerabilities detected by nmap"
    fi
    echo
}

# Nikto web scan
scan_nikto() {
    local target="$1"

    log_subheader "Nikto Web Vulnerability Scan"

    if ! command_exists nikto; then
        log_warning "Nikto not installed, skipping..."
        return
    fi

    # Determine if target has protocol
    if [[ ! "$target" =~ ^https?:// ]]; then
        target="http://$target"
    fi

    log_info "Running: nikto -h $target"
    local output=$(nikto -h "$target" 2>&1)

    echo "$output"

    [[ -n "$OUTPUT_FILE" ]] && {
        echo "=== Nikto Scan ===" >> "$OUTPUT_FILE"
        echo "$output" >> "$OUTPUT_FILE"
        echo >> "$OUTPUT_FILE"
    }

    echo
}

# TestSSL scan
scan_testssl() {
    local target="$1"

    log_subheader "TestSSL Security Scan"

    local testssl_cmd=""
    if command_exists testssl.sh; then
        testssl_cmd="testssl.sh"
    elif command_exists testssl; then
        testssl_cmd="testssl"
    else
        log_warning "TestSSL not installed, skipping..."
        return
    fi

    log_info "Running: $testssl_cmd $target"
    local output=$($testssl_cmd "$target" 2>&1)

    echo "$output"

    [[ -n "$OUTPUT_FILE" ]] && {
        echo "=== TestSSL Scan ===" >> "$OUTPUT_FILE"
        echo "$output" >> "$OUTPUT_FILE"
        echo >> "$OUTPUT_FILE"
    }

    echo
}

# Perform basic manual checks
basic_checks() {
    local target="$1"

    log_subheader "Basic Security Checks"

    # Test connectivity
    log_info "Testing connectivity..."
    if is_host_reachable "$target"; then
        log_success "Target is reachable"
    else
        log_warning "Target is not responding to ping"
    fi

    # Check common ports
    log_info "Checking common ports..."
    local common_ports=(21 22 23 25 80 443 3306 3389 8080 8443)
    for port in "${common_ports[@]}"; do
        if timeout 2 bash -c "echo >/dev/tcp/$target/$port" 2>/dev/null; then
            log_warning "Port $port is open"
        fi
    done

    echo
}

# Main scanning function
perform_scan() {
    local target="$1"
    local type="$2"

    log_header "Starting Vulnerability Scan"
    log_info "Target: $target"
    log_info "Scan Type: $type"
    log_info "Started: $(timestamp)"
    echo

    local start_time=$(epoch_time)

    # Prepare output file
    if [[ -n "$OUTPUT_FILE" ]]; then
        cat > "$OUTPUT_FILE" << EOF
Vulnerability Scan Report
Target: $target
Scan Type: $type
Started: $(timestamp)
================================================================================

EOF
    fi

    # Run basic checks first
    basic_checks "$target"

    # Run tools based on scan type and availability
    case "$type" in
        quick)
            ((USE_NMAP)) && scan_nmap "$target" "quick"
            ;;
        full)
            ((USE_NMAP)) && scan_nmap "$target" "full"
            ((USE_TESTSSL)) && scan_testssl "$target"
            ;;
        web)
            ((USE_NIKTO)) && scan_nikto "$target"
            ((USE_TESTSSL)) && scan_testssl "$target"
            ;;
    esac

    local end_time=$(epoch_time)
    local duration=$(calc_duration "$start_time" "$end_time")

    # Summary
    log_header "Scan Complete"
    log_info "Duration: $duration"

    [[ -n "$OUTPUT_FILE" ]] && {
        cat >> "$OUTPUT_FILE" << EOF
================================================================================
Scan completed: $(timestamp)
Duration: $duration
EOF
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
                TARGET="$2"
                shift 2
                ;;
            -s)
                SCAN_TYPE="$2"
                shift 2
                ;;
            -o)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --nmap)
                USE_NMAP=1
                shift
                ;;
            --nikto)
                USE_NIKTO=1
                shift
                ;;
            --testssl)
                USE_TESTSSL=1
                shift
                ;;
            --all)
                USE_NMAP=1
                USE_NIKTO=1
                USE_TESTSSL=1
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
    require_arg "$TARGET" "target (-t)"

    if [[ ! "$SCAN_TYPE" =~ ^(quick|full|web)$ ]]; then
        die "Invalid scan type: $SCAN_TYPE (must be: quick, full, or web)"
    fi

    # Check available tools
    check_tools

    # Perform scan
    perform_scan "$TARGET" "$SCAN_TYPE"
}

main "$@"
