#!/bin/bash
################################################################################
# System Health Monitor
# Monitors CPU, memory, disk usage and sends alerts
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

INTERVAL=5
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=80
CONTINUOUS=0
OUTPUT_FILE=""

################################################################################
# Functions
################################################################################

usage() {
    print_banner "System Health Monitor"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -i INTERVAL     Check interval in seconds [default: 5]
    -c THRESHOLD    CPU threshold percentage [default: 80]
    -m THRESHOLD    Memory threshold percentage [default: 80]
    -d THRESHOLD    Disk threshold percentage [default: 80]
    -C              Continuous monitoring mode
    -o FILE         Output log to file
    --help          Show this help message

Examples:
    $0 -i 10 -c 90 -m 85
    $0 -C -o health_monitor.log
    $0 -i 5 -c 80 -m 80 -d 90 -C
EOF
)"
    exit 0
}

# Get CPU usage
get_cpu_usage() {
    # Use top or mpstat for CPU usage
    if command_exists mpstat; then
        mpstat 1 1 | awk '/Average:/ {print 100 - $NF}'
    elif command_exists top; then
        top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'
    else
        # Fallback: parse /proc/stat
        awk '/^cpu / {usage=($2+$4)*100/($2+$4+$5)} END {print usage}' /proc/stat 2>/dev/null || echo "0"
    fi
}

# Get memory usage
get_memory_usage() {
    free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}'
}

# Get disk usage
get_disk_usage() {
    df -h / | awk 'NR==2 {print $5}' | sed 's/%//'
}

# Get system load
get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | sed 's/,//g' | awk '{print $1}'
}

# Get top processes by CPU
get_top_cpu_processes() {
    ps aux --sort=-%cpu | head -6 | tail -5
}

# Get top processes by Memory
get_top_mem_processes() {
    ps aux --sort=-%mem | head -6 | tail -5
}

# Check system health
check_health() {
    local timestamp=$(timestamp)
    local cpu=$(get_cpu_usage)
    local mem=$(get_memory_usage)
    local disk=$(get_disk_usage)
    local load=$(get_load_average)

    # Round for comparison
    local cpu_int=${cpu%.*}
    local mem_int=${mem%.*}
    local disk_int=$disk

    # Display header
    log_header "System Health Check - $timestamp"

    # CPU Check
    log_subheader "CPU Usage: ${cpu}%"
    if ((cpu_int >= CPU_THRESHOLD)); then
        log_error "CPU usage is HIGH (threshold: ${CPU_THRESHOLD}%)"
        echo "Top CPU processes:"
        get_top_cpu_processes
    else
        log_success "CPU usage is normal"
    fi
    echo

    # Memory Check
    log_subheader "Memory Usage: ${mem}%"
    if ((mem_int >= MEM_THRESHOLD)); then
        log_error "Memory usage is HIGH (threshold: ${MEM_THRESHOLD}%)"
        echo "Top Memory processes:"
        get_top_mem_processes
    else
        log_success "Memory usage is normal"
    fi
    echo

    # Disk Check
    log_subheader "Disk Usage: ${disk}%"
    if ((disk_int >= DISK_THRESHOLD)); then
        log_error "Disk usage is HIGH (threshold: ${DISK_THRESHOLD}%)"
        echo "Disk usage by partition:"
        df -h | grep -v tmpfs | grep -v "/dev/loop"
    else
        log_success "Disk usage is normal"
    fi
    echo

    # Load Average
    log_subheader "Load Average: $load"
    local num_cores=$(nproc 2>/dev/null || echo "1")
    log_info "Number of CPU cores: $num_cores"
    echo

    # Log to file
    if [[ -n "$OUTPUT_FILE" ]]; then
        cat >> "$OUTPUT_FILE" << EOF
[$timestamp] CPU: ${cpu}% | MEM: ${mem}% | DISK: ${disk}% | LOAD: $load
EOF
    fi

    # Overall status
    if ((cpu_int >= CPU_THRESHOLD || mem_int >= MEM_THRESHOLD || disk_int >= DISK_THRESHOLD)); then
        log_warning "System health: ATTENTION REQUIRED"
        return 1
    else
        log_success "System health: ALL CLEAR"
        return 0
    fi
}

# Continuous monitoring
monitor_continuous() {
    log_header "Starting Continuous Monitoring"
    log_info "Interval: ${INTERVAL}s"
    log_info "Thresholds - CPU: ${CPU_THRESHOLD}% | MEM: ${MEM_THRESHOLD}% | DISK: ${DISK_THRESHOLD}%"
    log_info "Press Ctrl+C to stop"
    echo

    while true; do
        check_health
        echo
        log_info "Next check in ${INTERVAL}s..."
        echo "----------------------------------------"
        sleep "$INTERVAL"
    done
}

################################################################################
# Main Script
################################################################################

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i)
                INTERVAL="$2"
                shift 2
                ;;
            -c)
                CPU_THRESHOLD="$2"
                shift 2
                ;;
            -m)
                MEM_THRESHOLD="$2"
                shift 2
                ;;
            -d)
                DISK_THRESHOLD="$2"
                shift 2
                ;;
            -C)
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
    if ! is_number "$INTERVAL" || ((INTERVAL < 1)); then
        die "Invalid interval: $INTERVAL"
    fi

    if ! is_number "$CPU_THRESHOLD" || ((CPU_THRESHOLD < 1 || CPU_THRESHOLD > 100)); then
        die "Invalid CPU threshold: $CPU_THRESHOLD"
    fi

    if ! is_number "$MEM_THRESHOLD" || ((MEM_THRESHOLD < 1 || MEM_THRESHOLD > 100)); then
        die "Invalid memory threshold: $MEM_THRESHOLD"
    fi

    if ! is_number "$DISK_THRESHOLD" || ((DISK_THRESHOLD < 1 || DISK_THRESHOLD > 100)); then
        die "Invalid disk threshold: $DISK_THRESHOLD"
    fi

    # Initialize log file
    if [[ -n "$OUTPUT_FILE" ]]; then
        ensure_dir "$(dirname "$OUTPUT_FILE")"
        log_info "Logging to: $OUTPUT_FILE"
    fi

    # Run monitoring
    if ((CONTINUOUS)); then
        monitor_continuous
    else
        check_health
    fi
}

main "$@"
