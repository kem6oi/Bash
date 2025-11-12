#!/bin/bash
################################################################################
# Backup & Integrity Checker
# Monitor file changes and create secure backups
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

MODE="baseline"
TARGET_DIR=""
BASELINE_FILE="$PROJECT_ROOT/reports/integrity_baseline.txt"
BACKUP_DIR="$PROJECT_ROOT/backups"
HASH_TYPE="sha256"

################################################################################
# Functions
################################################################################

usage() {
    print_banner "File Integrity & Backup Tool"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -m MODE         Mode: baseline, check, backup [default: baseline]
    -d DIRECTORY    Directory to monitor/backup [required]
    -b FILE         Baseline file [default: ./reports/integrity_baseline.txt]
    -t TYPE         Hash type: md5, sha256, sha512 [default: sha256]
    -o DIR          Backup output directory [default: ./backups]
    --help          Show this help message

Modes:
    baseline        Create initial baseline of file hashes
    check           Compare current state against baseline
    backup          Create compressed backup of directory

Examples:
    $0 -m baseline -d /etc/config
    $0 -m check -d /etc/config
    $0 -m backup -d /var/www/html -o /backups
EOF
)"
    exit 0
}

# Generate hash for file
generate_hash() {
    local file="$1"

    case "$HASH_TYPE" in
        md5) md5sum "$file" 2>/dev/null | awk '{print $1}' ;;
        sha256) sha256sum "$file" 2>/dev/null | awk '{print $1}' ;;
        sha512) sha512sum "$file" 2>/dev/null | awk '{print $1}' ;;
        *) die "Unsupported hash type: $HASH_TYPE" ;;
    esac
}

# Create baseline
mode_baseline() {
    local dir="$1"

    log_header "Creating Integrity Baseline"
    log_info "Directory: $dir"
    log_info "Hash Type: ${HASH_TYPE^^}"
    log_info "Baseline File: $BASELINE_FILE"
    echo

    ensure_dir "$(dirname "$BASELINE_FILE")"

    # Create baseline file
    cat > "$BASELINE_FILE" << EOF
# File Integrity Baseline
# Directory: $dir
# Created: $(timestamp)
# Hash Type: ${HASH_TYPE^^}
# Format: <hash> <file_path>

EOF

    local count=0
    while IFS= read -r -d '' file; do
        local hash=$(generate_hash "$file")
        echo "$hash  $file" >> "$BASELINE_FILE"
        ((count++))
        show_progress "$count" "$count" "Processing files"
    done < <(find "$dir" -type f -print0)

    echo
    log_success "Baseline created with $count files"
    log_success "Baseline saved to: $BASELINE_FILE"
}

# Check integrity
mode_check() {
    local dir="$1"

    log_header "Checking File Integrity"
    log_info "Directory: $dir"
    log_info "Baseline: $BASELINE_FILE"
    echo

    check_file "$BASELINE_FILE"

    # Read baseline into associative array
    declare -A baseline_hashes
    while IFS= read -r line; do
        [[ "$line" =~ ^# ]] && continue  # Skip comments
        [[ -z "$line" ]] && continue

        local hash=$(echo "$line" | awk '{print $1}')
        local filepath=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
        baseline_hashes["$filepath"]="$hash"
    done < "$BASELINE_FILE"

    local total=${#baseline_hashes[@]}
    local modified=0
    local missing=0
    local new=0
    local current=0

    log_subheader "Checking Existing Files"

    # Check files in baseline
    for filepath in "${!baseline_hashes[@]}"; do
        ((current++))
        show_progress "$current" "$total" "Verifying files"

        if [[ ! -f "$filepath" ]]; then
            log_error "MISSING: $filepath"
            ((missing++))
        else
            local current_hash=$(generate_hash "$filepath")
            local baseline_hash="${baseline_hashes[$filepath]}"

            if [[ "$current_hash" != "$baseline_hash" ]]; then
                log_warning "MODIFIED: $filepath"
                ((modified++))
            fi
        fi
    done

    echo
    log_subheader "Checking for New Files"

    # Check for new files not in baseline
    while IFS= read -r -d '' file; do
        if [[ ! -v baseline_hashes["$file"] ]]; then
            log_info "NEW: $file"
            ((new++))
        fi
    done < <(find "$dir" -type f -print0)

    # Summary
    echo
    log_header "Integrity Check Summary"
    log_info "Total files in baseline: $total"
    log_success "Unchanged: $((total - modified - missing))"
    ((modified > 0)) && log_warning "Modified: $modified"
    ((missing > 0)) && log_error "Missing: $missing"
    ((new > 0)) && log_info "New files: $new"

    if ((modified == 0 && missing == 0 && new == 0)); then
        log_success "No changes detected - integrity intact"
    else
        log_warning "Changes detected - review required"
    fi
}

# Create backup
mode_backup() {
    local dir="$1"

    log_header "Creating Backup"
    log_info "Source: $dir"
    log_info "Backup Directory: $BACKUP_DIR"
    echo

    check_file "$dir"
    ensure_dir "$BACKUP_DIR"

    # Generate backup filename
    local dir_name=$(basename "$dir")
    local backup_file="$BACKUP_DIR/${dir_name}_$(date +%Y%m%d_%H%M%S).tar.gz"

    # Create backup
    log_info "Creating compressed archive..."
    tar -czf "$backup_file" -C "$(dirname "$dir")" "$(basename "$dir")" 2>&1 | \
        grep -v "Removing leading" || true

    if [[ -f "$backup_file" ]]; then
        local size=$(du -h "$backup_file" | awk '{print $1}')
        log_success "Backup created: $backup_file"
        log_info "Size: $size"

        # Generate hash for backup
        log_info "Generating verification hash..."
        local hash=$(generate_hash "$backup_file")
        echo "$hash  $backup_file" > "${backup_file}.${HASH_TYPE}"
        log_success "Hash saved: ${backup_file}.${HASH_TYPE}"
    else
        die "Backup failed"
    fi
}

################################################################################
# Main Script
################################################################################

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m)
                MODE="$2"
                shift 2
                ;;
            -d)
                TARGET_DIR="$2"
                shift 2
                ;;
            -b)
                BASELINE_FILE="$2"
                shift 2
                ;;
            -t)
                HASH_TYPE="$2"
                shift 2
                ;;
            -o)
                BACKUP_DIR="$2"
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
    require_arg "$TARGET_DIR" "target directory (-d)"

    if [[ ! -d "$TARGET_DIR" ]]; then
        die "Directory not found: $TARGET_DIR"
    fi

    if [[ ! "$MODE" =~ ^(baseline|check|backup)$ ]]; then
        die "Invalid mode: $MODE (must be: baseline, check, or backup)"
    fi

    if [[ ! "$HASH_TYPE" =~ ^(md5|sha256|sha512)$ ]]; then
        die "Invalid hash type: $HASH_TYPE"
    fi

    # Check required commands
    case "$HASH_TYPE" in
        md5) require_command md5sum ;;
        sha256) require_command sha256sum ;;
        sha512) require_command sha512sum ;;
    esac

    [[ "$MODE" == "backup" ]] && require_command tar

    # Execute mode
    case "$MODE" in
        baseline)
            mode_baseline "$TARGET_DIR"
            ;;
        check)
            mode_check "$TARGET_DIR"
            ;;
        backup)
            mode_backup "$TARGET_DIR"
            ;;
    esac
}

main "$@"
