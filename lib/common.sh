#!/bin/bash
################################################################################
# Common Library for Bash Security & IoT Toolkit
# Provides shared functions and utilities for all scripts
################################################################################

# Color codes for output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_MAGENTA='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_WHITE='\033[1;37m'
readonly COLOR_RESET='\033[0m'
readonly COLOR_BOLD='\033[1m'

# Symbols
readonly SYMBOL_SUCCESS="✓"
readonly SYMBOL_ERROR="✗"
readonly SYMBOL_WARNING="⚠"
readonly SYMBOL_INFO="ℹ"
readonly SYMBOL_ARROW="→"

# Script metadata
SCRIPT_NAME="$(basename "$0" .sh)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
REPORT_DIR="$PROJECT_ROOT/reports"

################################################################################
# Logging Functions
################################################################################

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
}

# Log message to file
log_to_file() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE" 2>/dev/null
}

# Print info message
log_info() {
    local message="$1"
    echo -e "${COLOR_BLUE}${SYMBOL_INFO}${COLOR_RESET} $message"
    log_to_file "INFO: $message"
}

# Print success message
log_success() {
    local message="$1"
    echo -e "${COLOR_GREEN}${SYMBOL_SUCCESS}${COLOR_RESET} $message"
    log_to_file "SUCCESS: $message"
}

# Print warning message
log_warning() {
    local message="$1"
    echo -e "${COLOR_YELLOW}${SYMBOL_WARNING}${COLOR_RESET} $message"
    log_to_file "WARNING: $message"
}

# Print error message
log_error() {
    local message="$1"
    echo -e "${COLOR_RED}${SYMBOL_ERROR}${COLOR_RESET} $message" >&2
    log_to_file "ERROR: $message"
}

# Print section header
log_header() {
    local message="$1"
    echo -e "\n${COLOR_CYAN}${COLOR_BOLD}=== $message ===${COLOR_RESET}\n"
    log_to_file "HEADER: $message"
}

# Print sub-header
log_subheader() {
    local message="$1"
    echo -e "${COLOR_MAGENTA}${SYMBOL_ARROW} $message${COLOR_RESET}"
    log_to_file "SUBHEADER: $message"
}

################################################################################
# Error Handling
################################################################################

# Exit with error message
die() {
    local message="$1"
    local code="${2:-1}"
    log_error "$message"
    exit "$code"
}

# Check if command succeeded
check_status() {
    local status=$?
    local message="$1"
    if [ $status -ne 0 ]; then
        die "$message" $status
    fi
}

################################################################################
# Input Validation
################################################################################

# Check if value is empty
is_empty() {
    [[ -z "$1" ]]
}

# Check if value is a number
is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

# Check if value is a valid IP address
is_valid_ip() {
    local ip=$1
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'

    if [[ $ip =~ $regex ]]; then
        local IFS='.'
        read -ra octets <<< "$ip"
        for octet in "${octets[@]}"; do
            if ((octet > 255)); then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Check if value is a valid domain
is_valid_domain() {
    local domain=$1
    [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]
}

# Check if value is a valid port
is_valid_port() {
    local port=$1
    is_number "$port" && ((port >= 1 && port <= 65535))
}

# Validate required argument
require_arg() {
    local arg="$1"
    local name="$2"
    if is_empty "$arg"; then
        die "Missing required argument: $name"
    fi
}

################################################################################
# System Checks
################################################################################

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Require root privileges
require_root() {
    if ! is_root; then
        die "This script must be run as root. Try: sudo $0 $*"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Require command to exist
require_command() {
    local cmd="$1"
    local package="${2:-$1}"
    if ! command_exists "$cmd"; then
        die "Required command not found: $cmd. Please install: $package"
    fi
}

# Check multiple commands
check_dependencies() {
    local missing=()
    for cmd in "$@"; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        return 1
    fi
    return 0
}

################################################################################
# File Operations
################################################################################

# Create directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || die "Failed to create directory: $dir"
    fi
}

# Check if file exists and is readable
check_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        die "File not found: $file"
    fi
    if [[ ! -r "$file" ]]; then
        die "File not readable: $file"
    fi
}

# Backup file
backup_file() {
    local file="$1"
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    if [[ -f "$file" ]]; then
        cp "$file" "$backup" || die "Failed to backup file: $file"
        log_success "Backed up: $file -> $backup"
    fi
}

################################################################################
# Report Generation
################################################################################

# Initialize report file
init_report() {
    local report_name="${1:-report}"
    ensure_dir "$REPORT_DIR"
    REPORT_FILE="$REPORT_DIR/${report_name}_$(date +%Y%m%d_%H%M%S).txt"

    cat > "$REPORT_FILE" << EOF
================================================================================
$(echo "$report_name" | tr '[:lower:]' '[:upper:]') REPORT
================================================================================
Generated: $(date '+%Y-%m-%d %H:%M:%S')
Script: $SCRIPT_NAME
================================================================================

EOF
    log_info "Report initialized: $REPORT_FILE"
}

# Add to report
report_add() {
    local message="$1"
    echo "$message" >> "$REPORT_FILE"
}

# Finalize report
report_finalize() {
    cat >> "$REPORT_FILE" << EOF

================================================================================
Report completed: $(date '+%Y-%m-%d %H:%M:%S')
================================================================================
EOF
    log_success "Report saved: $REPORT_FILE"
}

################################################################################
# Display Functions
################################################################################

# Print banner
print_banner() {
    local title="$1"
    local width=80

    echo -e "${COLOR_CYAN}"
    echo "================================================================================"
    printf "%-${width}s\n" " $title"
    echo "================================================================================"
    echo -e "${COLOR_RESET}"
}

# Print usage message
print_usage() {
    local usage_text="$1"
    echo -e "${COLOR_WHITE}Usage:${COLOR_RESET}"
    echo -e "$usage_text"
    echo
}

# Prompt user for confirmation
confirm() {
    local message="$1"
    local response

    echo -ne "${COLOR_YELLOW}${message} (y/n): ${COLOR_RESET}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

# Show progress
show_progress() {
    local current=$1
    local total=$2
    local message="${3:-Processing}"
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))

    printf "\r${COLOR_CYAN}%s: [" "$message"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "] %3d%% (%d/%d)${COLOR_RESET}" "$percent" "$current" "$total"

    if [ "$current" -eq "$total" ]; then
        echo
    fi
}

################################################################################
# Network Utilities
################################################################################

# Check if host is reachable
is_host_reachable() {
    local host="$1"
    local timeout="${2:-2}"
    ping -c 1 -W "$timeout" "$host" >/dev/null 2>&1
}

# Get local IP address
get_local_ip() {
    ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || \
    hostname -I 2>/dev/null | awk '{print $1}' || \
    echo "127.0.0.1"
}

# Parse CIDR notation
parse_cidr() {
    local cidr="$1"
    local ip="${cidr%/*}"
    local mask="${cidr#*/}"
    echo "$ip $mask"
}

################################################################################
# Time Utilities
################################################################################

# Get timestamp
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Get epoch time
epoch_time() {
    date +%s
}

# Calculate duration
calc_duration() {
    local start=$1
    local end=$2
    local duration=$((end - start))

    if ((duration < 60)); then
        echo "${duration}s"
    elif ((duration < 3600)); then
        echo "$((duration / 60))m $((duration % 60))s"
    else
        echo "$((duration / 3600))h $(((duration % 3600) / 60))m"
    fi
}

################################################################################
# Cleanup Handler
################################################################################

# Cleanup function (to be called on exit)
cleanup() {
    log_info "Cleaning up..."
}

# Register cleanup handler
trap cleanup EXIT

################################################################################
# Initialization
################################################################################

# Initialize logging on library load
init_logging

# Export functions for use in other scripts
export -f log_info log_success log_warning log_error log_header log_subheader
export -f die check_status is_empty is_number is_valid_ip is_valid_domain is_valid_port
export -f require_arg is_root require_root command_exists require_command check_dependencies
export -f ensure_dir check_file backup_file init_report report_add report_finalize
export -f print_banner print_usage confirm show_progress is_host_reachable get_local_ip
export -f timestamp epoch_time calc_duration
