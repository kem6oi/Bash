#!/bin/bash
################################################################################
# Hash Generator/Checker
# Generate and verify file hashes for integrity checking
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

MODE="generate"
FILE_PATH=""
HASH_TYPE="sha256"
EXPECTED_HASH=""
OUTPUT_FILE=""
RECURSIVE=0

################################################################################
# Functions
################################################################################

usage() {
    print_banner "Hash Generator/Checker"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -m MODE         Mode: generate, verify [default: generate]
    -f FILE         File or directory to hash
    -t TYPE         Hash type: md5, sha1, sha256, sha512 [default: sha256]
    -e HASH         Expected hash (for verify mode)
    -r              Recursive (for directories)
    -o FILE         Output results to file
    --help          Show this help message

Examples:
    $0 -f /path/to/file -t sha256
    $0 -m verify -f /path/to/file -e abc123def...
    $0 -f /path/to/dir -r -o hashes.txt
EOF
)"
    exit 0
}

# Generate hash for single file
generate_hash() {
    local file="$1"
    local type="$2"

    case "$type" in
        md5)
            md5sum "$file" 2>/dev/null | awk '{print $1}'
            ;;
        sha1)
            sha1sum "$file" 2>/dev/null | awk '{print $1}'
            ;;
        sha256)
            sha256sum "$file" 2>/dev/null | awk '{print $1}'
            ;;
        sha512)
            sha512sum "$file" 2>/dev/null | awk '{print $1}'
            ;;
        *)
            die "Unsupported hash type: $type"
            ;;
    esac
}

# Generate hashes for file(s)
mode_generate() {
    local path="$1"

    if [[ -f "$path" ]]; then
        # Single file
        log_header "Generating Hash"
        log_info "File: $path"
        log_info "Type: ${HASH_TYPE^^}"

        local hash=$(generate_hash "$path" "$HASH_TYPE")
        log_success "Hash: $hash"

        [[ -n "$OUTPUT_FILE" ]] && echo "$hash  $path" >> "$OUTPUT_FILE"

    elif [[ -d "$path" ]]; then
        # Directory
        if ! ((RECURSIVE)); then
            die "Path is a directory. Use -r for recursive hashing"
        fi

        log_header "Generating Hashes (Recursive)"
        log_info "Directory: $path"
        log_info "Type: ${HASH_TYPE^^}"
        echo

        local count=0
        while IFS= read -r -d '' file; do
            local hash=$(generate_hash "$file" "$HASH_TYPE")
            log_success "$hash  $file"
            [[ -n "$OUTPUT_FILE" ]] && echo "$hash  $file" >> "$OUTPUT_FILE"
            ((count++))
        done < <(find "$path" -type f -print0)

        echo
        log_info "Total files hashed: $count"
    else
        die "Invalid path: $path"
    fi

    [[ -n "$OUTPUT_FILE" ]] && log_success "Hashes saved to: $OUTPUT_FILE"
}

# Verify hash against expected value
mode_verify() {
    local file="$1"
    local expected="$2"

    check_file "$file"
    require_arg "$expected" "expected hash (-e)"

    log_header "Verifying Hash"
    log_info "File: $file"
    log_info "Type: ${HASH_TYPE^^}"
    log_info "Expected: $expected"

    local actual=$(generate_hash "$file" "$HASH_TYPE")
    log_info "Actual:   $actual"
    echo

    if [[ "$actual" == "$expected" ]]; then
        log_success "Hash verification PASSED - File is authentic"
        return 0
    else
        log_error "Hash verification FAILED - File may be corrupted or tampered"
        return 1
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
            -f)
                FILE_PATH="$2"
                shift 2
                ;;
            -t)
                HASH_TYPE="$2"
                shift 2
                ;;
            -e)
                EXPECTED_HASH="$2"
                shift 2
                ;;
            -r)
                RECURSIVE=1
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
    require_arg "$FILE_PATH" "file path (-f)"

    if [[ ! "$MODE" =~ ^(generate|verify)$ ]]; then
        die "Invalid mode: $MODE (must be: generate or verify)"
    fi

    if [[ ! "$HASH_TYPE" =~ ^(md5|sha1|sha256|sha512)$ ]]; then
        die "Invalid hash type: $HASH_TYPE"
    fi

    # Check for required commands
    case "$HASH_TYPE" in
        md5) require_command md5sum ;;
        sha1) require_command sha1sum ;;
        sha256) require_command sha256sum ;;
        sha512) require_command sha512sum ;;
    esac

    # Execute mode
    case "$MODE" in
        generate)
            mode_generate "$FILE_PATH"
            ;;
        verify)
            mode_verify "$FILE_PATH" "$EXPECTED_HASH"
            ;;
    esac
}

main "$@"
