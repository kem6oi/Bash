#!/bin/bash
################################################################################
# Service Watchdog
# Monitors and automatically restarts failed services
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

SERVICES=()
INTERVAL=30
MAX_RESTARTS=3
NOTIFICATION_EMAIL=""
CONTINUOUS=1

################################################################################
# Functions
################################################################################

usage() {
    print_banner "Service Watchdog"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -s SERVICE      Service name to monitor (can be used multiple times)
    -i INTERVAL     Check interval in seconds [default: 30]
    -m MAX          Maximum restart attempts [default: 3]
    -e EMAIL        Email for notifications (requires mail command)
    -1              Run once (not continuous)
    --help          Show this help message

Examples:
    $0 -s nginx -s mysql -i 60
    $0 -s apache2 -m 5 -e admin@example.com
    $0 -s sshd -s docker -1
EOF
)"
    exit 0
}

# Check if service is running
is_service_running() {
    local service="$1"

    if command_exists systemctl; then
        systemctl is-active --quiet "$service"
    elif command_exists service; then
        service "$service" status >/dev/null 2>&1
    else
        # Fallback: check with ps
        pgrep -x "$service" >/dev/null
    fi
}

# Restart service
restart_service() {
    local service="$1"

    log_warning "Attempting to restart $service..."

    if command_exists systemctl; then
        systemctl restart "$service" 2>&1
    elif command_exists service; then
        service "$service" restart 2>&1
    else
        log_error "No service manager found"
        return 1
    fi

    sleep 5

    if is_service_running "$service"; then
        log_success "$service restarted successfully"
        return 0
    else
        log_error "$service restart failed"
        return 1
    fi
}

# Send notification
send_notification() {
    local service="$1"
    local status="$2"
    local message="$3"

    if [[ -n "$NOTIFICATION_EMAIL" ]] && command_exists mail; then
        echo "$message" | mail -s "Service Watchdog Alert: $service - $status" "$NOTIFICATION_EMAIL"
        log_info "Notification sent to $NOTIFICATION_EMAIL"
    fi
}

# Monitor single service
monitor_service() {
    local service="$1"
    local restart_count="${SERVICE_RESTARTS[$service]:-0}"

    if is_service_running "$service"; then
        log_success "[$service] Running"
        # Reset restart counter on successful run
        SERVICE_RESTARTS[$service]=0
        return 0
    else
        log_error "[$service] NOT RUNNING"

        if ((restart_count < MAX_RESTARTS)); then
            ((restart_count++))
            SERVICE_RESTARTS[$service]=$restart_count

            log_warning "[$service] Restart attempt $restart_count/$MAX_RESTARTS"

            if restart_service "$service"; then
                send_notification "$service" "RESTARTED" "Service $service was down and has been restarted (attempt $restart_count/$MAX_RESTARTS)"
            else
                send_notification "$service" "RESTART FAILED" "Service $service is down and restart attempt failed ($restart_count/$MAX_RESTARTS)"
            fi
        else
            log_error "[$service] Maximum restart attempts reached ($MAX_RESTARTS)"
            send_notification "$service" "CRITICAL" "Service $service has failed $MAX_RESTARTS restart attempts. Manual intervention required."
        fi
        return 1
    fi
}

# Main monitoring loop
monitor_services() {
    log_header "Service Watchdog Started"
    log_info "Monitoring: ${SERVICES[*]}"
    log_info "Check Interval: ${INTERVAL}s"
    log_info "Max Restarts: $MAX_RESTARTS"
    [[ -n "$NOTIFICATION_EMAIL" ]] && log_info "Notifications: $NOTIFICATION_EMAIL"
    echo

    # Initialize restart counters
    declare -gA SERVICE_RESTARTS
    for service in "${SERVICES[@]}"; do
        SERVICE_RESTARTS[$service]=0
    done

    local iteration=1
    while true; do
        log_subheader "Check #$iteration - $(timestamp)"

        for service in "${SERVICES[@]}"; do
            monitor_service "$service"
        done

        ((CONTINUOUS)) || break

        echo
        log_info "Next check in ${INTERVAL}s..."
        echo "----------------------------------------"
        sleep "$INTERVAL"
        ((iteration++))
    done
}

################################################################################
# Main Script
################################################################################

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s)
                SERVICES+=("$2")
                shift 2
                ;;
            -i)
                INTERVAL="$2"
                shift 2
                ;;
            -m)
                MAX_RESTARTS="$2"
                shift 2
                ;;
            -e)
                NOTIFICATION_EMAIL="$2"
                shift 2
                ;;
            -1)
                CONTINUOUS=0
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
    if [ ${#SERVICES[@]} -eq 0 ]; then
        die "No services specified. Use -s SERVICE"
    fi

    if ! is_number "$INTERVAL" || ((INTERVAL < 1)); then
        die "Invalid interval: $INTERVAL"
    fi

    if ! is_number "$MAX_RESTARTS" || ((MAX_RESTARTS < 1)); then
        die "Invalid max restarts: $MAX_RESTARTS"
    fi

    # Check for service manager
    if ! command_exists systemctl && ! command_exists service; then
        log_warning "No standard service manager found. Using fallback methods."
    fi

    # Run monitoring
    monitor_services
}

main "$@"
