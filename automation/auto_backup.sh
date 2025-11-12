#!/bin/bash
################################################################################
# Automated Backup Script
# Creates scheduled backups with rotation
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

SOURCE_DIR=""
BACKUP_DIR="$PROJECT_ROOT/backups"
RETENTION_DAYS=7
COMPRESS=1
EXCLUDE_PATTERNS=()
REMOTE_BACKUP=0
REMOTE_HOST=""

################################################################################
# Functions
################################################################################

usage() {
    print_banner "Automated Backup Script"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -s SOURCE       Source directory to backup [required]
    -b BACKUP_DIR   Backup destination directory [default: ./backups]
    -r DAYS         Retention period in days [default: 7]
    -e PATTERN      Exclude pattern (can be used multiple times)
    -n              No compression (backup as-is)
    -R HOST         Remote backup via rsync (user@host:/path)
    --help          Show this help message

Examples:
    $0 -s /var/www/html -b /backups
    $0 -s /home/user/data -r 14 -e "*.tmp" -e "*.log"
    $0 -s /important/files -R user@backup-server:/backups
EOF
)"
    exit 0
}

# Create backup name
generate_backup_name() {
    local source="$1"
    local basename=$(basename "$source")
    echo "${basename}_$(date +%Y%m%d_%H%M%S)"
}

# Perform local backup
backup_local() {
    local source="$1"
    local dest="$2"
    local name=$(generate_backup_name "$source")

    log_header "Creating Local Backup"
    log_info "Source: $source"
    log_info "Destination: $dest"
    log_info "Name: $name"
    echo

    ensure_dir "$dest"

    if ((COMPRESS)); then
        # Create compressed archive
        local backup_file="$dest/${name}.tar.gz"
        log_info "Creating compressed backup..."

        local exclude_opts=""
        for pattern in "${EXCLUDE_PATTERNS[@]}"; do
            exclude_opts="$exclude_opts --exclude=$pattern"
        done

        tar -czf "$backup_file" $exclude_opts -C "$(dirname "$source")" "$(basename "$source")" 2>&1 | \
            grep -v "Removing leading" || true

        if [[ -f "$backup_file" ]]; then
            local size=$(du -h "$backup_file" | awk '{print $1}')
            log_success "Backup created: $backup_file"
            log_info "Size: $size"

            # Generate checksum
            local hash=$(sha256sum "$backup_file" | awk '{print $1}')
            echo "$hash  $backup_file" > "${backup_file}.sha256"
            log_success "Checksum saved: ${backup_file}.sha256"
        else
            die "Backup failed"
        fi
    else
        # Copy directory as-is
        local backup_dir="$dest/$name"
        log_info "Copying directory..."

        rsync -av --delete "$source/" "$backup_dir/" 2>&1

        if [[ -d "$backup_dir" ]]; then
            local size=$(du -sh "$backup_dir" | awk '{print $1}')
            log_success "Backup created: $backup_dir"
            log_info "Size: $size"
        else
            die "Backup failed"
        fi
    fi
}

# Perform remote backup
backup_remote() {
    local source="$1"
    local remote="$2"

    log_header "Creating Remote Backup"
    log_info "Source: $source"
    log_info "Remote: $remote"
    echo

    require_command rsync

    log_info "Syncing to remote server..."

    local exclude_opts=""
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        exclude_opts="$exclude_opts --exclude=$pattern"
    done

    rsync -avz --delete $exclude_opts "$source/" "$remote/" 2>&1

    if [ $? -eq 0 ]; then
        log_success "Remote backup completed"
    else
        die "Remote backup failed"
    fi
}

# Clean old backups
cleanup_old_backups() {
    local dest="$1"
    local days="$2"

    log_header "Cleaning Old Backups"
    log_info "Retention: $days days"

    local count=$(find "$dest" -name "*.tar.gz" -mtime +$days 2>/dev/null | wc -l)

    if ((count > 0)); then
        log_info "Found $count old backup(s) to remove"
        find "$dest" -name "*.tar.gz" -mtime +$days -exec rm -f {} \; 2>/dev/null
        find "$dest" -name "*.sha256" -mtime +$days -exec rm -f {} \; 2>/dev/null
        log_success "Old backups removed"
    else
        log_info "No old backups to remove"
    fi
}

# List backups
list_backups() {
    local dest="$1"

    log_header "Available Backups"

    if [[ ! -d "$dest" ]]; then
        log_warning "Backup directory not found: $dest"
        return
    fi

    local backups=$(find "$dest" -name "*.tar.gz" -o -type d -mindepth 1 -maxdepth 1 | sort -r)

    if [[ -z "$backups" ]]; then
        log_info "No backups found"
    else
        echo "$backups" | while read -r backup; do
            local size=$(du -sh "$backup" 2>/dev/null | awk '{print $1}')
            local date=$(stat -c %y "$backup" 2>/dev/null | cut -d' ' -f1,2 | cut -d':' -f1-2)
            log_info "[$date] $backup ($size)"
        done
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
                SOURCE_DIR="$2"
                shift 2
                ;;
            -b)
                BACKUP_DIR="$2"
                shift 2
                ;;
            -r)
                RETENTION_DAYS="$2"
                shift 2
                ;;
            -e)
                EXCLUDE_PATTERNS+=("$2")
                shift 2
                ;;
            -n)
                COMPRESS=0
                shift
                ;;
            -R)
                REMOTE_BACKUP=1
                REMOTE_HOST="$2"
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
    require_arg "$SOURCE_DIR" "source directory (-s)"

    if [[ ! -d "$SOURCE_DIR" ]]; then
        die "Source directory not found: $SOURCE_DIR"
    fi

    if ! is_number "$RETENTION_DAYS" || ((RETENTION_DAYS < 1)); then
        die "Invalid retention days: $RETENTION_DAYS"
    fi

    # Perform backup
    if ((REMOTE_BACKUP)); then
        require_arg "$REMOTE_HOST" "remote host (-R)"
        backup_remote "$SOURCE_DIR" "$REMOTE_HOST"
    else
        backup_local "$SOURCE_DIR" "$BACKUP_DIR"

        # Clean old backups
        echo
        cleanup_old_backups "$BACKUP_DIR" "$RETENTION_DAYS"

        # List backups
        echo
        list_backups "$BACKUP_DIR"
    fi
}

main "$@"
