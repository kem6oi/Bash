#!/bin/bash
################################################################################
# Report Generator
# Generate formatted reports from scan/test results
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

INPUT_FILE=""
OUTPUT_FILE=""
FORMAT="text"
TITLE="Report"

usage() {
    print_banner "Report Generator"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -i FILE         Input file
    -o FILE         Output report file [required]
    -f FORMAT       Format: text, html, md [default: text]
    -t TITLE        Report title [default: Report]
    --help          Show this help message

Examples:
    $0 -i scan_results.txt -o report.txt -f text
    $0 -i data.txt -o report.html -f html -t "Security Audit"
EOF
)"
    exit 0
}

generate_text_report() {
    local input="$1"
    local output="$2"

    cat > "$output" << EOF
================================================================================
$TITLE
================================================================================
Generated: $(timestamp)
================================================================================

EOF

    [[ -f "$input" ]] && cat "$input" >> "$output"

    cat >> "$output" << EOF

================================================================================
End of Report
================================================================================
EOF

    log_success "Text report generated: $output"
}

generate_html_report() {
    local input="$1"
    local output="$2"

    cat > "$output" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>$TITLE</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        pre { background: #f4f4f4; padding: 15px; border-radius: 5px; }
        .meta { color: #666; }
    </style>
</head>
<body>
    <h1>$TITLE</h1>
    <p class="meta">Generated: $(timestamp)</p>
    <hr>
    <pre>
EOF

    [[ -f "$input" ]] && cat "$input" >> "$output"

    cat >> "$output" << EOF
    </pre>
</body>
</html>
EOF

    log_success "HTML report generated: $output"
}

main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i) INPUT_FILE="$2"; shift 2 ;;
            -o) OUTPUT_FILE="$2"; shift 2 ;;
            -f) FORMAT="$2"; shift 2 ;;
            -t) TITLE="$2"; shift 2 ;;
            --help) usage ;;
            *) log_error "Unknown option: $1"; usage ;;
        esac
    done

    require_arg "$OUTPUT_FILE" "output file (-o)"

    log_header "Report Generator"
    log_info "Format: $FORMAT"
    log_info "Title: $TITLE"
    echo

    case "$FORMAT" in
        text) generate_text_report "$INPUT_FILE" "$OUTPUT_FILE" ;;
        html) generate_html_report "$INPUT_FILE" "$OUTPUT_FILE" ;;
        md) generate_text_report "$INPUT_FILE" "$OUTPUT_FILE" ;;
        *) die "Invalid format: $FORMAT" ;;
    esac
}

main "$@"
