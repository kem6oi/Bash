#!/bin/bash
################################################################################
# Batch File Processor
# Performs bulk operations on files (rename, convert, compress, etc.)
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

OPERATION="list"
TARGET_DIR="."
PATTERN="*"
NEW_EXTENSION=""
PREFIX=""
SUFFIX=""
FIND_TEXT=""
REPLACE_TEXT=""
COMPRESS_TYPE="gz"
DRY_RUN=0

################################################################################
# Functions
################################################################################

usage() {
    print_banner "Batch File Processor"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -o OPERATION    Operation: list, rename, compress, decompress, convert, replace
    -d DIRECTORY    Target directory [default: current]
    -p PATTERN      File pattern (glob) [default: *]
    -e EXTENSION    New file extension (for convert)
    -P PREFIX       Add prefix to filenames (for rename)
    -S SUFFIX       Add suffix to filenames (for rename)
    -f FIND         Find text in files (for replace)
    -r REPLACE      Replace text in files (for replace)
    -c TYPE         Compression type: gz, bz2, xz [default: gz]
    -n              Dry run (show what would be done)
    --help          Show this help message

Operations:
    list            List files matching pattern
    rename          Rename files with prefix/suffix
    compress        Compress files
    decompress      Decompress files
    convert         Convert file extensions
    replace         Find and replace text in files

Examples:
    $0 -o list -d /path/to/files -p "*.txt"
    $0 -o rename -p "*.jpg" -P "photo_" -S "_2024"
    $0 -o compress -p "*.log" -c gz
    $0 -o replace -p "*.conf" -f "old_value" -r "new_value" -n
EOF
)"
    exit 0
}

# List files
op_list() {
    local dir="$1"
    local pattern="$2"

    log_header "Listing Files"
    log_info "Directory: $dir"
    log_info "Pattern: $pattern"
    echo

    local count=0
    while IFS= read -r -d '' file; do
        ((count++))
        local size=$(du -h "$file" | awk '{print $1}')
        local modified=$(stat -c %y "$file" | cut -d' ' -f1)
        log_info "[$count] $file ($size, modified: $modified)"
    done < <(find "$dir" -maxdepth 1 -name "$pattern" -type f -print0)

    echo
    log_success "Total files found: $count"
}

# Rename files
op_rename() {
    local dir="$1"
    local pattern="$2"

    log_header "Renaming Files"
    log_info "Directory: $dir"
    log_info "Pattern: $pattern"
    [[ -n "$PREFIX" ]] && log_info "Prefix: $PREFIX"
    [[ -n "$SUFFIX" ]] && log_info "Suffix: $SUFFIX"
    ((DRY_RUN)) && log_warning "DRY RUN MODE - No actual changes"
    echo

    local count=0
    while IFS= read -r -d '' file; do
        local basename=$(basename "$file")
        local dirname=$(dirname "$file")
        local filename="${basename%.*}"
        local extension="${basename##*.}"

        # Handle files without extension
        if [[ "$filename" == "$extension" ]]; then
            extension=""
        fi

        local new_name="${PREFIX}${filename}${SUFFIX}"
        [[ -n "$extension" ]] && new_name="${new_name}.${extension}"

        local new_path="$dirname/$new_name"

        if [[ "$file" != "$new_path" ]]; then
            ((count++))
            log_info "[$count] $basename -> $new_name"

            if ! ((DRY_RUN)); then
                mv "$file" "$new_path" && log_success "Renamed successfully"
            fi
        fi
    done < <(find "$dir" -maxdepth 1 -name "$pattern" -type f -print0)

    echo
    log_success "Total files renamed: $count"
}

# Compress files
op_compress() {
    local dir="$1"
    local pattern="$2"

    log_header "Compressing Files"
    log_info "Directory: $dir"
    log_info "Pattern: $pattern"
    log_info "Compression: $COMPRESS_TYPE"
    ((DRY_RUN)) && log_warning "DRY RUN MODE"
    echo

    local count=0
    while IFS= read -r -d '' file; do
        ((count++))
        local basename=$(basename "$file")
        local original_size=$(du -h "$file" | awk '{print $1}')

        log_info "[$count] Compressing: $basename (original: $original_size)"

        if ! ((DRY_RUN)); then
            case "$COMPRESS_TYPE" in
                gz)
                    gzip -k "$file" && log_success "Created: ${basename}.gz"
                    ;;
                bz2)
                    bzip2 -k "$file" && log_success "Created: ${basename}.bz2"
                    ;;
                xz)
                    xz -k "$file" && log_success "Created: ${basename}.xz"
                    ;;
            esac
        fi
    done < <(find "$dir" -maxdepth 1 -name "$pattern" -type f -print0)

    echo
    log_success "Total files compressed: $count"
}

# Decompress files
op_decompress() {
    local dir="$1"
    local pattern="$2"

    log_header "Decompressing Files"
    log_info "Directory: $dir"
    log_info "Pattern: $pattern"
    ((DRY_RUN)) && log_warning "DRY RUN MODE"
    echo

    local count=0
    while IFS= read -r -d '' file; do
        ((count++))
        local basename=$(basename "$file")

        log_info "[$count] Decompressing: $basename"

        if ! ((DRY_RUN)); then
            case "$file" in
                *.gz)
                    gunzip "$file" && log_success "Decompressed"
                    ;;
                *.bz2)
                    bunzip2 "$file" && log_success "Decompressed"
                    ;;
                *.xz)
                    unxz "$file" && log_success "Decompressed"
                    ;;
                *.zip)
                    unzip -q "$file" -d "$dir" && log_success "Decompressed"
                    ;;
                *)
                    log_warning "Unknown compression format"
                    ;;
            esac
        fi
    done < <(find "$dir" -maxdepth 1 -name "$pattern" -type f -print0)

    echo
    log_success "Total files decompressed: $count"
}

# Convert file extensions
op_convert() {
    local dir="$1"
    local pattern="$2"

    require_arg "$NEW_EXTENSION" "new extension (-e)"

    log_header "Converting File Extensions"
    log_info "Directory: $dir"
    log_info "Pattern: $pattern"
    log_info "New Extension: $NEW_EXTENSION"
    ((DRY_RUN)) && log_warning "DRY RUN MODE"
    echo

    local count=0
    while IFS= read -r -d '' file; do
        local basename=$(basename "$file")
        local dirname=$(dirname "$file")
        local filename="${basename%.*}"

        local new_name="${filename}.${NEW_EXTENSION}"
        local new_path="$dirname/$new_name"

        ((count++))
        log_info "[$count] $basename -> $new_name"

        if ! ((DRY_RUN)); then
            mv "$file" "$new_path" && log_success "Converted"
        fi
    done < <(find "$dir" -maxdepth 1 -name "$pattern" -type f -print0)

    echo
    log_success "Total files converted: $count"
}

# Find and replace text
op_replace() {
    local dir="$1"
    local pattern="$2"

    require_arg "$FIND_TEXT" "find text (-f)"
    require_arg "$REPLACE_TEXT" "replace text (-r)"

    log_header "Find and Replace Text"
    log_info "Directory: $dir"
    log_info "Pattern: $pattern"
    log_info "Find: $FIND_TEXT"
    log_info "Replace: $REPLACE_TEXT"
    ((DRY_RUN)) && log_warning "DRY RUN MODE"
    echo

    local count=0
    while IFS= read -r -d '' file; do
        local basename=$(basename "$file")

        # Check if file contains the search text
        if grep -q "$FIND_TEXT" "$file" 2>/dev/null; then
            ((count++))
            local matches=$(grep -c "$FIND_TEXT" "$file")
            log_info "[$count] $basename - $matches match(es)"

            if ! ((DRY_RUN)); then
                sed -i "s/$FIND_TEXT/$REPLACE_TEXT/g" "$file" && log_success "Replaced"
            fi
        fi
    done < <(find "$dir" -maxdepth 1 -name "$pattern" -type f -print0)

    echo
    log_success "Total files processed: $count"
}

################################################################################
# Main Script
################################################################################

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o)
                OPERATION="$2"
                shift 2
                ;;
            -d)
                TARGET_DIR="$2"
                shift 2
                ;;
            -p)
                PATTERN="$2"
                shift 2
                ;;
            -e)
                NEW_EXTENSION="$2"
                shift 2
                ;;
            -P)
                PREFIX="$2"
                shift 2
                ;;
            -S)
                SUFFIX="$2"
                shift 2
                ;;
            -f)
                FIND_TEXT="$2"
                shift 2
                ;;
            -r)
                REPLACE_TEXT="$2"
                shift 2
                ;;
            -c)
                COMPRESS_TYPE="$2"
                shift 2
                ;;
            -n)
                DRY_RUN=1
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
    if [[ ! -d "$TARGET_DIR" ]]; then
        die "Directory not found: $TARGET_DIR"
    fi

    if [[ ! "$OPERATION" =~ ^(list|rename|compress|decompress|convert|replace)$ ]]; then
        die "Invalid operation: $OPERATION"
    fi

    if [[ ! "$COMPRESS_TYPE" =~ ^(gz|bz2|xz)$ ]]; then
        die "Invalid compression type: $COMPRESS_TYPE"
    fi

    # Execute operation
    case "$OPERATION" in
        list)
            op_list "$TARGET_DIR" "$PATTERN"
            ;;
        rename)
            op_rename "$TARGET_DIR" "$PATTERN"
            ;;
        compress)
            op_compress "$TARGET_DIR" "$PATTERN"
            ;;
        decompress)
            op_decompress "$TARGET_DIR" "$PATTERN"
            ;;
        convert)
            op_convert "$TARGET_DIR" "$PATTERN"
            ;;
        replace)
            op_replace "$TARGET_DIR" "$PATTERN"
            ;;
    esac
}

main "$@"
