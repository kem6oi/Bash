#!/bin/bash
################################################################################
# SSL/TLS Certificate Checker
# Analyzes SSL certificates for security issues and expiration
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

DOMAIN=""
PORT=443
CHECK_CHAIN=1
CHECK_PROTOCOLS=1
CHECK_CIPHERS=0
OUTPUT_FILE=""
DAYS_WARNING=30

################################################################################
# Functions
################################################################################

# Display usage information
usage() {
    print_banner "SSL/TLS Certificate Checker"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -d DOMAIN       Target domain [required]
    -p PORT         Target port [default: 443]
    -w DAYS         Warning threshold for expiration (days) [default: 30]
    -c              Check certificate chain
    -P              Check SSL/TLS protocols
    -C              Check supported ciphers (slow)
    -o FILE         Output results to file
    --help          Show this help message

Examples:
    $0 -d example.com
    $0 -d example.com -p 8443 -c -P
    $0 -d example.com -w 60 -o ssl_report.txt
EOF
)"
    exit 0
}

# Check if OpenSSL is available
check_openssl() {
    require_command openssl
}

# Get certificate info
get_cert_info() {
    local domain="$1"
    local port="$2"

    echo | openssl s_client -servername "$domain" -connect "$domain:$port" 2>/dev/null | \
        openssl x509 -noout -text 2>/dev/null
}

# Get certificate in PEM format
get_cert_pem() {
    local domain="$1"
    local port="$2"

    echo | openssl s_client -servername "$domain" -connect "$domain:$port" 2>/dev/null | \
        openssl x509 2>/dev/null
}

# Extract certificate field
get_cert_field() {
    local cert_info="$1"
    local field="$2"

    echo "$cert_info" | grep "$field" | head -1 | sed "s/.*$field: //" | sed 's/^ *//'
}

# Check certificate expiration
check_expiration() {
    local domain="$1"
    local port="$2"

    log_subheader "Certificate Expiration"

    local cert=$(get_cert_pem "$domain" "$port")
    if [[ -z "$cert" ]]; then
        log_error "Failed to retrieve certificate"
        return 1
    fi

    local not_before=$(echo "$cert" | openssl x509 -noout -startdate 2>/dev/null | cut -d= -f2)
    local not_after=$(echo "$cert" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    log_info "Valid From: $not_before"
    log_info "Valid Until: $not_after"

    # Calculate days until expiration
    local end_epoch=$(date -d "$not_after" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$not_after" +%s 2>/dev/null)
    local now_epoch=$(date +%s)
    local days_left=$(( (end_epoch - now_epoch) / 86400 ))

    if ((days_left < 0)); then
        log_error "Certificate EXPIRED $((days_left * -1)) days ago!"
    elif ((days_left < DAYS_WARNING)); then
        log_warning "Certificate expires in $days_left days!"
    else
        log_success "Certificate expires in $days_left days"
    fi

    [[ -n "$OUTPUT_FILE" ]] && {
        echo "Valid From: $not_before" >> "$OUTPUT_FILE"
        echo "Valid Until: $not_after" >> "$OUTPUT_FILE"
        echo "Days Until Expiration: $days_left" >> "$OUTPUT_FILE"
        echo >> "$OUTPUT_FILE"
    }
}

# Check certificate subject
check_subject() {
    local domain="$1"
    local port="$2"

    log_subheader "Certificate Subject Information"

    local cert_info=$(get_cert_info "$domain" "$port")
    if [[ -z "$cert_info" ]]; then
        log_error "Failed to retrieve certificate"
        return 1
    fi

    local subject=$(echo "$cert_info" | grep "Subject:" | sed 's/.*Subject: //')
    local issuer=$(echo "$cert_info" | grep "Issuer:" | sed 's/.*Issuer: //')
    local cn=$(echo "$subject" | grep -oP 'CN\s*=\s*\K[^,]+' || echo "$subject")

    log_info "Common Name (CN): $cn"
    log_info "Subject: $subject"
    log_info "Issuer: $issuer"

    # Check if CN matches domain
    if [[ "$cn" == "$domain" ]] || [[ "$cn" == "*."* && "$domain" == *"${cn#\*.}" ]]; then
        log_success "Common Name matches domain"
    else
        log_warning "Common Name ($cn) does not match domain ($domain)"
    fi

    [[ -n "$OUTPUT_FILE" ]] && {
        echo "Common Name: $cn" >> "$OUTPUT_FILE"
        echo "Subject: $subject" >> "$OUTPUT_FILE"
        echo "Issuer: $issuer" >> "$OUTPUT_FILE"
        echo >> "$OUTPUT_FILE"
    }
}

# Check Subject Alternative Names (SAN)
check_san() {
    local domain="$1"
    local port="$2"

    log_subheader "Subject Alternative Names (SAN)"

    local cert=$(get_cert_pem "$domain" "$port")
    local san=$(echo "$cert" | openssl x509 -noout -text 2>/dev/null | grep -A1 "Subject Alternative Name" | tail -1 | sed 's/DNS://g' | tr ',' '\n' | sed 's/^ *//')

    if [[ -n "$san" ]]; then
        log_info "SAN entries found:"
        echo "$san" | while read -r entry; do
            [[ -n "$entry" ]] && echo "  - $entry"
        done
        log_success "SAN present"
    else
        log_warning "No Subject Alternative Names found"
    fi

    [[ -n "$OUTPUT_FILE" ]] && {
        echo "Subject Alternative Names:" >> "$OUTPUT_FILE"
        echo "$san" >> "$OUTPUT_FILE"
        echo >> "$OUTPUT_FILE"
    }
}

# Check certificate chain
check_chain() {
    local domain="$1"
    local port="$2"

    log_subheader "Certificate Chain Validation"

    local chain_output=$(echo | openssl s_client -servername "$domain" -connect "$domain:$port" -showcerts 2>&1)

    # Check verification result
    if echo "$chain_output" | grep -q "Verify return code: 0 (ok)"; then
        log_success "Certificate chain is valid"
    else
        local error=$(echo "$chain_output" | grep "Verify return code:" | sed 's/.*Verify return code: //')
        log_error "Certificate chain validation failed: $error"
    fi

    # Count certificates in chain
    local cert_count=$(echo "$chain_output" | grep -c "BEGIN CERTIFICATE")
    log_info "Certificates in chain: $cert_count"

    [[ -n "$OUTPUT_FILE" ]] && {
        echo "Certificate Chain: $cert_count certificates" >> "$OUTPUT_FILE"
        echo >> "$OUTPUT_FILE"
    }
}

# Check SSL/TLS protocols
check_protocols() {
    local domain="$1"
    local port="$2"

    log_subheader "SSL/TLS Protocol Support"

    local protocols=("ssl3" "tls1" "tls1_1" "tls1_2" "tls1_3")
    local protocol_names=("SSLv3" "TLS 1.0" "TLS 1.1" "TLS 1.2" "TLS 1.3")

    for i in "${!protocols[@]}"; do
        local proto="${protocols[$i]}"
        local name="${protocol_names[$i]}"

        if echo | timeout 3 openssl s_client -"$proto" -connect "$domain:$port" >/dev/null 2>&1; then
            if [[ "$proto" == "ssl3" || "$proto" == "tls1" || "$proto" == "tls1_1" ]]; then
                log_warning "$name: ENABLED (insecure, should be disabled)"
            else
                log_success "$name: ENABLED"
            fi
            [[ -n "$OUTPUT_FILE" ]] && echo "$name: ENABLED" >> "$OUTPUT_FILE"
        else
            if [[ "$proto" == "tls1_2" || "$proto" == "tls1_3" ]]; then
                log_info "$name: DISABLED"
            else
                log_success "$name: DISABLED (good)"
            fi
            [[ -n "$OUTPUT_FILE" ]] && echo "$name: DISABLED" >> "$OUTPUT_FILE"
        fi
    done

    [[ -n "$OUTPUT_FILE" ]] && echo >> "$OUTPUT_FILE"
}

# Check cipher suites
check_ciphers() {
    local domain="$1"
    local port="$2"

    log_subheader "Checking Cipher Suites (this may take a while...)"

    local ciphers=$(openssl ciphers -v 'ALL:eNULL' | awk '{print $1}')
    local supported=()
    local weak=()

    while IFS= read -r cipher; do
        if echo | timeout 2 openssl s_client -cipher "$cipher" -connect "$domain:$port" >/dev/null 2>&1; then
            supported+=("$cipher")

            # Check for weak ciphers
            if [[ "$cipher" =~ (NULL|EXPORT|DES|MD5|RC4|anon) ]]; then
                weak+=("$cipher")
            fi
        fi
    done <<< "$ciphers"

    log_info "Supported ciphers: ${#supported[@]}"
    if [ ${#weak[@]} -gt 0 ]; then
        log_warning "Weak ciphers found: ${#weak[@]}"
        for cipher in "${weak[@]}"; do
            echo "  - $cipher"
        done
    else
        log_success "No weak ciphers detected"
    fi

    [[ -n "$OUTPUT_FILE" ]] && {
        echo "Total Supported Ciphers: ${#supported[@]}" >> "$OUTPUT_FILE"
        echo "Weak Ciphers: ${#weak[@]}" >> "$OUTPUT_FILE"
        echo >> "$OUTPUT_FILE"
    }
}

# Main check function
perform_check() {
    local domain="$1"
    local port="$2"

    log_header "SSL/TLS Certificate Check"
    log_info "Target: $domain:$port"
    log_info "Date: $(timestamp)"
    echo

    # Prepare output file
    if [[ -n "$OUTPUT_FILE" ]]; then
        cat > "$OUTPUT_FILE" << EOF
SSL/TLS Certificate Check Report
Target: $domain:$port
Date: $(timestamp)
================================================================================

EOF
    fi

    # Test connection first
    log_info "Testing connection to $domain:$port..."
    if ! timeout 5 bash -c "echo > /dev/tcp/$domain/$port" 2>/dev/null; then
        die "Cannot connect to $domain:$port"
    fi
    log_success "Connection successful"
    echo

    # Run checks
    check_expiration "$domain" "$port"
    echo

    check_subject "$domain" "$port"
    echo

    check_san "$domain" "$port"
    echo

    if ((CHECK_CHAIN)); then
        check_chain "$domain" "$port"
        echo
    fi

    if ((CHECK_PROTOCOLS)); then
        check_protocols "$domain" "$port"
        echo
    fi

    if ((CHECK_CIPHERS)); then
        check_ciphers "$domain" "$port"
        echo
    fi

    # Summary
    log_header "Check Complete"

    if [[ -n "$OUTPUT_FILE" ]]; then
        cat >> "$OUTPUT_FILE" << EOF
================================================================================
Check completed: $(timestamp)
EOF
        log_success "Report saved to: $OUTPUT_FILE"
    fi
}

################################################################################
# Main Script
################################################################################

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d)
                DOMAIN="$2"
                shift 2
                ;;
            -p)
                PORT="$2"
                shift 2
                ;;
            -w)
                DAYS_WARNING="$2"
                shift 2
                ;;
            -c)
                CHECK_CHAIN=1
                shift
                ;;
            -P)
                CHECK_PROTOCOLS=1
                shift
                ;;
            -C)
                CHECK_CIPHERS=1
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
    require_arg "$DOMAIN" "domain (-d)"

    if ! is_valid_domain "$DOMAIN" && ! is_valid_ip "$DOMAIN"; then
        die "Invalid domain: $DOMAIN"
    fi

    if ! is_valid_port "$PORT"; then
        die "Invalid port: $PORT"
    fi

    if ! is_number "$DAYS_WARNING" || ((DAYS_WARNING < 1)); then
        die "Invalid warning days: $DAYS_WARNING (must be >= 1)"
    fi

    # Check dependencies
    check_openssl

    # Perform check
    perform_check "$DOMAIN" "$PORT"
}

# Run main function
main "$@"
