#!/bin/bash
################################################################################
# Password Strength Checker
# Evaluates password complexity and strength
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

PASSWORD=""
MIN_LENGTH=12
BATCH_MODE=0
FILE_INPUT=""
SHOW_PASSWORD=0

################################################################################
# Functions
################################################################################

usage() {
    print_banner "Password Strength Checker"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -p PASSWORD     Password to check (will prompt if not provided)
    -f FILE         Check passwords from file (one per line)
    -l LENGTH       Minimum password length [default: 12]
    -s              Show password in output (use with caution)
    --help          Show this help message

Examples:
    $0
    $0 -p "MyP@ssw0rd123"
    $0 -f passwords.txt -l 16
EOF
)"
    exit 0
}

# Calculate password entropy
calculate_entropy() {
    local password="$1"
    local length=${#password}
    local charset_size=0

    # Determine character set size
    [[ "$password" =~ [a-z] ]] && ((charset_size += 26))
    [[ "$password" =~ [A-Z] ]] && ((charset_size += 26))
    [[ "$password" =~ [0-9] ]] && ((charset_size += 10))
    [[ "$password" =~ [^a-zA-Z0-9] ]] && ((charset_size += 32))

    # Calculate entropy: log2(charset_size^length)
    if ((charset_size > 0)); then
        local entropy=$(awk -v c="$charset_size" -v l="$length" 'BEGIN {print l * log(c) / log(2)}')
        printf "%.2f" "$entropy"
    else
        echo "0"
    fi
}

# Check password against common patterns
check_common_patterns() {
    local password="$1"
    local issues=()

    # Sequential characters
    if [[ "$password" =~ (abc|bcd|cde|123|234|345|456|567|678|789) ]]; then
        issues+=("Contains sequential characters")
    fi

    # Repeated characters
    if [[ "$password" =~ (.)\1{2,} ]]; then
        issues+=("Contains repeated characters")
    fi

    # Common patterns
    if [[ "$password" =~ ^[0-9]+$ ]]; then
        issues+=("Only contains numbers")
    fi

    if [[ "$password" =~ ^[a-zA-Z]+$ ]]; then
        issues+=("Only contains letters")
    fi

    # Common words (basic check)
    local lower_pass=$(echo "$password" | tr '[:upper:]' '[:lower:]')
    if [[ "$lower_pass" =~ (password|admin|login|welcome|letmein|qwerty|monkey|dragon) ]]; then
        issues+=("Contains common password words")
    fi

    # Keyboard patterns
    if [[ "$lower_pass" =~ (qwerty|asdfgh|zxcvbn|!@#\$%^) ]]; then
        issues+=("Contains keyboard pattern")
    fi

    # Return issues
    if [ ${#issues[@]} -gt 0 ]; then
        printf '%s\n' "${issues[@]}"
        return 1
    fi
    return 0
}

# Check password strength
check_password_strength() {
    local password="$1"
    local show_pass="$2"

    local length=${#password}
    local score=0
    local max_score=100
    local issues=()

    # Display password being checked (masked by default)
    if ((show_pass)); then
        log_info "Checking password: $password"
    else
        local masked=$(echo "$password" | sed 's/./*/g')
        log_info "Checking password: $masked"
    fi
    echo

    # Length check
    log_subheader "Length Check"
    if ((length >= MIN_LENGTH)); then
        log_success "Length: $length characters (minimum: $MIN_LENGTH)"
        ((score += 20))
    elif ((length >= 8)); then
        log_warning "Length: $length characters (recommended: $MIN_LENGTH+)"
        ((score += 10))
        issues+=("Password too short")
    else
        log_error "Length: $length characters (too short!)"
        issues+=("Password critically short")
    fi
    echo

    # Character variety check
    log_subheader "Character Variety"
    local has_lowercase=0 has_uppercase=0 has_numbers=0 has_special=0

    if [[ "$password" =~ [a-z] ]]; then
        has_lowercase=1
        log_success "Contains lowercase letters"
        ((score += 15))
    else
        log_warning "Missing lowercase letters"
        issues+=("No lowercase letters")
    fi

    if [[ "$password" =~ [A-Z] ]]; then
        has_uppercase=1
        log_success "Contains uppercase letters"
        ((score += 15))
    else
        log_warning "Missing uppercase letters"
        issues+=("No uppercase letters")
    fi

    if [[ "$password" =~ [0-9] ]]; then
        has_numbers=1
        log_success "Contains numbers"
        ((score += 15))
    else
        log_warning "Missing numbers"
        issues+=("No numbers")
    fi

    if [[ "$password" =~ [^a-zA-Z0-9] ]]; then
        has_special=1
        log_success "Contains special characters"
        ((score += 20))
    else
        log_warning "Missing special characters"
        issues+=("No special characters")
    fi
    echo

    # Pattern check
    log_subheader "Pattern Analysis"
    local pattern_issues=$(check_common_patterns "$password")
    if [ $? -eq 0 ]; then
        log_success "No common patterns detected"
        ((score += 15))
    else
        log_error "Common patterns detected:"
        echo "$pattern_issues" | while read -r issue; do
            echo "  - $issue"
        done
        issues+=("Contains weak patterns")
    fi
    echo

    # Entropy calculation
    log_subheader "Entropy Analysis"
    local entropy=$(calculate_entropy "$password")
    log_info "Password entropy: $entropy bits"

    if (( $(echo "$entropy >= 80" | bc -l) )); then
        log_success "Very strong entropy (80+ bits)"
    elif (( $(echo "$entropy >= 60" | bc -l) )); then
        log_success "Strong entropy (60+ bits)"
    elif (( $(echo "$entropy >= 40" | bc -l) )); then
        log_warning "Moderate entropy (40-60 bits)"
    else
        log_error "Weak entropy (< 40 bits)"
    fi
    echo

    # Calculate final rating
    log_header "Password Strength Assessment"
    log_info "Score: $score / $max_score"

    if ((score >= 85)); then
        log_success "Rating: VERY STRONG"
    elif ((score >= 70)); then
        log_success "Rating: STRONG"
    elif ((score >= 50)); then
        log_warning "Rating: MODERATE"
    elif ((score >= 30)); then
        log_error "Rating: WEAK"
    else
        log_error "Rating: VERY WEAK"
    fi

    if [ ${#issues[@]} -gt 0 ]; then
        echo
        log_warning "Issues found:"
        for issue in "${issues[@]}"; do
            echo "  - $issue"
        done
    fi

    echo
    log_info "Recommendations:"
    echo "  - Use at least $MIN_LENGTH characters"
    echo "  - Mix uppercase, lowercase, numbers, and special characters"
    echo "  - Avoid common words, patterns, and sequential characters"
    echo "  - Consider using a passphrase or password manager"
}

# Process passwords from file
process_file() {
    local file="$1"

    log_header "Batch Password Analysis"
    log_info "File: $file"

    local total=0
    local weak=0
    local moderate=0
    local strong=0

    while IFS= read -r password; do
        [[ -z "$password" ]] && continue
        ((total++))

        local length=${#password}
        local score=0

        # Quick scoring for batch mode
        ((length >= MIN_LENGTH)) && ((score += 20)) || ((score += 10))
        [[ "$password" =~ [a-z] ]] && ((score += 15))
        [[ "$password" =~ [A-Z] ]] && ((score += 15))
        [[ "$password" =~ [0-9] ]] && ((score += 15))
        [[ "$password" =~ [^a-zA-Z0-9] ]] && ((score += 20))

        local pattern_check=$(check_common_patterns "$password")
        [ $? -eq 0 ] && ((score += 15))

        # Categorize
        local masked=$(echo "$password" | sed 's/./*/g')
        if ((score >= 70)); then
            ((strong++))
            log_success "[$masked] Strong (score: $score)"
        elif ((score >= 50)); then
            ((moderate++))
            log_warning "[$masked] Moderate (score: $score)"
        else
            ((weak++))
            log_error "[$masked] Weak (score: $score)"
        fi
    done < "$file"

    echo
    log_header "Batch Analysis Summary"
    log_info "Total passwords: $total"
    log_success "Strong: $strong"
    log_warning "Moderate: $moderate"
    log_error "Weak: $weak"
}

################################################################################
# Main Script
################################################################################

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p)
                PASSWORD="$2"
                shift 2
                ;;
            -f)
                FILE_INPUT="$2"
                BATCH_MODE=1
                shift 2
                ;;
            -l)
                MIN_LENGTH="$2"
                shift 2
                ;;
            -s)
                SHOW_PASSWORD=1
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

    # Validate minimum length
    if ! is_number "$MIN_LENGTH" || ((MIN_LENGTH < 1)); then
        die "Invalid minimum length: $MIN_LENGTH"
    fi

    # Batch mode
    if ((BATCH_MODE)); then
        check_file "$FILE_INPUT"
        process_file "$FILE_INPUT"
        exit 0
    fi

    # Single password mode
    if [[ -z "$PASSWORD" ]]; then
        # Prompt for password
        echo -n "Enter password to check: "
        read -s PASSWORD
        echo
    fi

    if [[ -z "$PASSWORD" ]]; then
        die "No password provided"
    fi

    check_password_strength "$PASSWORD" "$SHOW_PASSWORD"
}

main "$@"
