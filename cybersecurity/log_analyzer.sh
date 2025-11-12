#!/bin/bash
################################################################################
# Log Analyzer
# Parses system logs for suspicious activities and security events
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

LOG_FILE=""
LOG_TYPE="syslog"
TAIL_LINES=1000
WATCH_MODE=0
OUTPUT_FILE=""
SHOW_ALL=0

################################################################################
# Patterns for detection
################################################################################

# Suspicious patterns
declare -A PATTERNS=(
    ["Failed Login"]="Failed password|authentication failure|Invalid user"
    ["SSH Brute Force"]="Failed password for.*from.*port"
    ["Root Access"]="session opened for user root|sudo.*root"
    ["Port Scan"]="refused connect from|Connection attempt"
    ["System Error"]="kernel.*error|segfault|panic"
    ["Unauthorized Access"]="Permission denied|Operation not permitted"
    ["Service Failure"]="failed|error|warning.*service"
)

################################################################################
# Functions
################################################################################

usage() {
    print_banner "Security Log Analyzer"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -f FILE         Log file to analyze [default: /var/log/syslog or /var/log/messages]
    -t TYPE         Log type: syslog, auth, apache, nginx [default: syslog]
    -n LINES        Number of lines to analyze from end [default: 1000]
    -w              Watch mode (continuously monitor)
    -a              Show all entries (not just suspicious ones)
    -o FILE         Output results to file
    --help          Show this help message

Examples:
    $0 -f /var/log/auth.log -n 5000
    $0 -t auth -w
    $0 -f /var/log/nginx/access.log -t nginx -o analysis.txt
EOF
)"
    exit 0
}

# Auto-detect log file based on type
detect_log_file() {
    local type="$1"

    case "$type" in
        syslog)
            if [[ -f /var/log/syslog ]]; then
                echo "/var/log/syslog"
            elif [[ -f /var/log/messages ]]; then
                echo "/var/log/messages"
            else
                die "Cannot find syslog or messages log file"
            fi
            ;;
        auth)
            if [[ -f /var/log/auth.log ]]; then
                echo "/var/log/auth.log"
            elif [[ -f /var/log/secure ]]; then
                echo "/var/log/secure"
            else
                die "Cannot find auth log file"
            fi
            ;;
        apache)
            if [[ -f /var/log/apache2/error.log ]]; then
                echo "/var/log/apache2/error.log"
            elif [[ -f /var/log/httpd/error_log ]]; then
                echo "/var/log/httpd/error_log"
            else
                die "Cannot find Apache error log"
            fi
            ;;
        nginx)
            if [[ -f /var/log/nginx/error.log ]]; then
                echo "/var/log/nginx/error.log"
            else
                die "Cannot find Nginx error log"
            fi
            ;;
        *)
            die "Unknown log type: $type"
            ;;
    esac
}

# Analyze log content
analyze_logs() {
    local logfile="$1"
    local lines="$2"

    log_header "Analyzing Log File"
    log_info "File: $logfile"
    log_info "Lines to analyze: $lines"
    log_info "Analysis started: $(timestamp)"
    echo

    # Read log file
    local log_content
    if [[ "$lines" == "all" ]]; then
        log_content=$(cat "$logfile" 2>/dev/null)
    else
        log_content=$(tail -n "$lines" "$logfile" 2>/dev/null)
    fi

    if [[ -z "$log_content" ]]; then
        die "Unable to read log file or file is empty"
    fi

    local total_lines=$(echo "$log_content" | wc -l)
    log_info "Total lines read: $total_lines"
    echo

    # Analyze patterns
    for pattern_name in "${!PATTERNS[@]}"; do
        log_subheader "$pattern_name"

        local pattern="${PATTERNS[$pattern_name]}"
        local matches=$(echo "$log_content" | grep -E "$pattern" | wc -l)

        if ((matches > 0)); then
            log_warning "Found $matches occurrence(s)"

            # Show sample matches
            echo "$log_content" | grep -E "$pattern" | tail -5 | while read -r line; do
                echo "  $line"
            done

            [[ -n "$OUTPUT_FILE" ]] && {
                echo "[$pattern_name] $matches occurrence(s)" >> "$OUTPUT_FILE"
                echo "$log_content" | grep -E "$pattern" | tail -10 >> "$OUTPUT_FILE"
                echo >> "$OUTPUT_FILE"
            }
        else
            log_success "No matches found"
        fi
        echo
    done

    # IP address analysis
    analyze_ip_addresses "$log_content"

    # Summary
    log_header "Analysis Summary"
    log_info "Total lines analyzed: $total_lines"
    log_info "Completed: $(timestamp)"

    [[ -n "$OUTPUT_FILE" ]] && {
        echo "Analysis completed: $(timestamp)" >> "$OUTPUT_FILE"
        log_success "Results saved to: $OUTPUT_FILE"
    }
}

# Analyze IP addresses in logs
analyze_ip_addresses() {
    local content="$1"

    log_subheader "Top Source IP Addresses"

    local ips=$(echo "$content" | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | sort | uniq -c | sort -rn | head -10)

    if [[ -n "$ips" ]]; then
        echo "$ips" | while read -r count ip; do
            log_info "$ip - $count occurrences"
        done

        [[ -n "$OUTPUT_FILE" ]] && {
            echo "Top IP Addresses:" >> "$OUTPUT_FILE"
            echo "$ips" >> "$OUTPUT_FILE"
            echo >> "$OUTPUT_FILE"
        }
    else
        log_info "No IP addresses found"
    fi
    echo
}

# Watch mode - continuous monitoring
watch_logs() {
    local logfile="$1"

    log_header "Watch Mode - Monitoring $logfile"
    log_info "Press Ctrl+C to stop"
    echo

    tail -f "$logfile" | while read -r line; do
        local suspicious=0

        for pattern_name in "${!PATTERNS[@]}"; do
            local pattern="${PATTERNS[$pattern_name]}"

            if echo "$line" | grep -qE "$pattern"; then
                log_warning "[$pattern_name] $line"
                suspicious=1
                break
            fi
        done

        if ((SHOW_ALL)) && ((suspicious == 0)); then
            log_info "$line"
        fi
    done
}

################################################################################
# Main Script
################################################################################

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f)
                LOG_FILE="$2"
                shift 2
                ;;
            -t)
                LOG_TYPE="$2"
                shift 2
                ;;
            -n)
                TAIL_LINES="$2"
                shift 2
                ;;
            -w)
                WATCH_MODE=1
                shift
                ;;
            -a)
                SHOW_ALL=1
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

    # Auto-detect log file if not specified
    if [[ -z "$LOG_FILE" ]]; then
        LOG_FILE=$(detect_log_file "$LOG_TYPE")
    fi

    # Check if log file exists and is readable
    check_file "$LOG_FILE"

    # Validate tail lines
    if [[ "$TAIL_LINES" != "all" ]] && ! is_number "$TAIL_LINES"; then
        die "Invalid line count: $TAIL_LINES"
    fi

    # Prepare output file
    if [[ -n "$OUTPUT_FILE" ]]; then
        cat > "$OUTPUT_FILE" << EOF
Security Log Analysis Report
Log File: $LOG_FILE
Analysis Date: $(timestamp)
================================================================================

EOF
    fi

    # Run analysis or watch mode
    if ((WATCH_MODE)); then
        watch_logs "$LOG_FILE"
    else
        analyze_logs "$LOG_FILE" "$TAIL_LINES"
    fi
}

main "$@"
