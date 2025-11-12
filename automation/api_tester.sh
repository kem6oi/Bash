#!/bin/bash
################################################################################
# API Testing Tool
# Automated REST API endpoint testing
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

URL=""
METHOD="GET"
HEADERS=()
DATA=""
EXPECTED_STATUS=200
OUTPUT_FILE=""
VERBOSE=0
FOLLOW_REDIRECTS=1
TIMEOUT=30
TEST_FILE=""

################################################################################
# Functions
################################################################################

usage() {
    print_banner "API Testing Tool"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -u URL          API endpoint URL [required]
    -m METHOD       HTTP method: GET, POST, PUT, DELETE, PATCH [default: GET]
    -H HEADER       Add header (can be used multiple times)
    -d DATA         Request body data (JSON or form data)
    -s STATUS       Expected HTTP status code [default: 200]
    -t TIMEOUT      Request timeout in seconds [default: 30]
    -f FILE         Test suite file (JSON format)
    -o FILE         Output results to file
    -v              Verbose output
    -n              No follow redirects
    --help          Show this help message

Examples:
    $0 -u https://api.example.com/users
    $0 -u https://api.example.com/users -m POST -d '{"name":"John"}' -H "Content-Type: application/json"
    $0 -u https://api.example.com/status -s 200 -o results.txt
    $0 -f test_suite.json
EOF
)"
    exit 0
}

# Make HTTP request
make_request() {
    local url="$1"
    local method="$2"
    local data="$3"

    local curl_opts="-X $method"
    curl_opts="$curl_opts -w '\n%{http_code}|%{time_total}'"
    curl_opts="$curl_opts --max-time $TIMEOUT"
    curl_opts="$curl_opts -s"

    # Add headers
    for header in "${HEADERS[@]}"; do
        curl_opts="$curl_opts -H '$header'"
    done

    # Add data for POST/PUT/PATCH
    if [[ -n "$data" ]]; then
        curl_opts="$curl_opts -d '$data'"
    fi

    # Follow redirects
    ((FOLLOW_REDIRECTS)) && curl_opts="$curl_opts -L"

    # Execute request
    eval "curl $curl_opts '$url'"
}

# Test single endpoint
test_endpoint() {
    local url="$1"
    local method="$2"
    local data="$3"
    local expected_status="$4"

    log_header "Testing API Endpoint"
    log_info "URL: $url"
    log_info "Method: $method"
    [[ -n "$data" ]] && log_info "Data: $data"
    log_info "Expected Status: $expected_status"
    echo

    local start_time=$(epoch_time)

    # Make request
    log_info "Sending request..."
    local response=$(make_request "$url" "$method" "$data")

    # Parse response
    local body=$(echo "$response" | head -n -1)
    local footer=$(echo "$response" | tail -n 1)
    local status_code=$(echo "$footer" | cut -d'|' -f1)
    local time_total=$(echo "$footer" | cut -d'|' -f2)

    local end_time=$(epoch_time)

    # Display results
    echo
    log_subheader "Response"

    # Status code check
    if [[ "$status_code" == "$expected_status" ]]; then
        log_success "Status Code: $status_code (Expected: $expected_status)"
    else
        log_error "Status Code: $status_code (Expected: $expected_status)"
    fi

    # Response time
    log_info "Response Time: ${time_total}s"

    # Response body
    if ((VERBOSE)) || [[ -n "$OUTPUT_FILE" ]]; then
        echo
        log_subheader "Response Body"
        echo "$body" | head -20

        if [[ $(echo "$body" | wc -l) -gt 20 ]]; then
            log_info "... (truncated, see output file for full response)"
        fi
    fi

    # Try to parse JSON
    if command_exists jq && echo "$body" | jq . >/dev/null 2>&1; then
        log_success "Valid JSON response"
    fi

    # Save to output file
    if [[ -n "$OUTPUT_FILE" ]]; then
        cat >> "$OUTPUT_FILE" << EOF
========================================
URL: $url
Method: $method
Status: $status_code
Time: ${time_total}s
Response:
$body
========================================

EOF
    fi

    # Return success/failure
    if [[ "$status_code" == "$expected_status" ]]; then
        return 0
    else
        return 1
    fi
}

# Run test suite from file
run_test_suite() {
    local file="$1"

    check_file "$file"
    require_command jq

    log_header "Running Test Suite"
    log_info "File: $file"
    echo

    local total=0
    local passed=0
    local failed=0

    # Read test cases from JSON file
    while read -r test_case; do
        ((total++))

        local url=$(echo "$test_case" | jq -r '.url')
        local method=$(echo "$test_case" | jq -r '.method // "GET"')
        local data=$(echo "$test_case" | jq -r '.data // ""')
        local expected=$(echo "$test_case" | jq -r '.expected_status // 200')
        local name=$(echo "$test_case" | jq -r '.name // "Test '$total'"')

        log_subheader "Test Case: $name"

        if test_endpoint "$url" "$method" "$data" "$expected"; then
            ((passed++))
            log_success "PASSED"
        else
            ((failed++))
            log_error "FAILED"
        fi

        echo
        sleep 1  # Avoid rate limiting
    done < <(jq -c '.tests[]' "$file")

    # Summary
    log_header "Test Suite Summary"
    log_info "Total Tests: $total"
    log_success "Passed: $passed"
    ((failed > 0)) && log_error "Failed: $failed"
}

################################################################################
# Main Script
################################################################################

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u)
                URL="$2"
                shift 2
                ;;
            -m)
                METHOD="$2"
                shift 2
                ;;
            -H)
                HEADERS+=("$2")
                shift 2
                ;;
            -d)
                DATA="$2"
                shift 2
                ;;
            -s)
                EXPECTED_STATUS="$2"
                shift 2
                ;;
            -t)
                TIMEOUT="$2"
                shift 2
                ;;
            -f)
                TEST_FILE="$2"
                shift 2
                ;;
            -o)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -v)
                VERBOSE=1
                shift
                ;;
            -n)
                FOLLOW_REDIRECTS=0
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

    # Check for curl
    require_command curl

    # Prepare output file
    if [[ -n "$OUTPUT_FILE" ]]; then
        cat > "$OUTPUT_FILE" << EOF
API Test Results
Started: $(timestamp)
========================================

EOF
    fi

    # Run tests
    if [[ -n "$TEST_FILE" ]]; then
        run_test_suite "$TEST_FILE"
    else
        require_arg "$URL" "URL (-u)"

        if [[ ! "$METHOD" =~ ^(GET|POST|PUT|DELETE|PATCH)$ ]]; then
            die "Invalid HTTP method: $METHOD"
        fi

        if ! is_number "$EXPECTED_STATUS"; then
            die "Invalid expected status: $EXPECTED_STATUS"
        fi

        if ! is_number "$TIMEOUT" || ((TIMEOUT < 1)); then
            die "Invalid timeout: $TIMEOUT"
        fi

        test_endpoint "$URL" "$METHOD" "$DATA" "$EXPECTED_STATUS"
    fi

    # Finalize output file
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "Completed: $(timestamp)" >> "$OUTPUT_FILE"
        log_success "Results saved to: $OUTPUT_FILE"
    fi
}

main "$@"
