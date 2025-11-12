#!/bin/bash
################################################################################
# MQTT Client Helper
# Publish/subscribe to MQTT topics for IoT applications
################################################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

################################################################################
# Configuration
################################################################################

MODE="subscribe"
BROKER="localhost"
PORT=1883
TOPIC=""
MESSAGE=""
QOS=0
RETAIN=0
USERNAME=""
PASSWORD=""
CLIENT_ID="bash_mqtt_$$"
OUTPUT_FILE=""

################################################################################
# Functions
################################################################################

usage() {
    print_banner "MQTT Client Helper"
    print_usage "$(cat << EOF
    $0 [OPTIONS]

Options:
    -m MODE         Mode: subscribe, publish [default: subscribe]
    -b BROKER       MQTT broker address [default: localhost]
    -p PORT         MQTT broker port [default: 1883]
    -t TOPIC        MQTT topic [required]
    -M MESSAGE      Message to publish (publish mode)
    -q QOS          Quality of Service: 0, 1, 2 [default: 0]
    -r              Retain message (publish mode)
    -u USERNAME     MQTT username
    -P PASSWORD     MQTT password
    -c CLIENT_ID    Client ID [default: bash_mqtt_PID]
    -o FILE         Output messages to file (subscribe mode)
    --help          Show this help message

Examples:
    $0 -m subscribe -b mqtt.example.com -t "sensors/#"
    $0 -m publish -t "home/temperature" -M "22.5"
    $0 -m subscribe -t "alerts/+" -u admin -P secret -o alerts.log
EOF
)"
    exit 0
}

# Check for mosquitto clients
check_mosquitto() {
    if [[ "$MODE" == "subscribe" ]]; then
        require_command mosquitto_sub "mosquitto-clients"
    else
        require_command mosquitto_pub "mosquitto-clients"
    fi
}

# Subscribe to topic
mqtt_subscribe() {
    log_header "MQTT Subscribe"
    log_info "Broker: $BROKER:$PORT"
    log_info "Topic: $TOPIC"
    log_info "Client ID: $CLIENT_ID"
    log_info "QoS: $QOS"
    [[ -n "$OUTPUT_FILE" ]] && log_info "Output: $OUTPUT_FILE"
    echo

    # Build command
    local cmd="mosquitto_sub -h $BROKER -p $PORT -t '$TOPIC' -q $QOS -i $CLIENT_ID"

    [[ -n "$USERNAME" ]] && cmd="$cmd -u '$USERNAME'"
    [[ -n "$PASSWORD" ]] && cmd="$cmd -P '$PASSWORD'"

    # Add verbose flag for better output
    cmd="$cmd -v"

    log_info "Listening for messages... (Press Ctrl+C to stop)"
    echo

    # Subscribe and process messages
    eval "$cmd" | while read -r line; do
        local timestamp=$(timestamp)
        log_success "[$timestamp] $line"

        [[ -n "$OUTPUT_FILE" ]] && echo "[$timestamp] $line" >> "$OUTPUT_FILE"
    done
}

# Publish message
mqtt_publish() {
    log_header "MQTT Publish"
    log_info "Broker: $BROKER:$PORT"
    log_info "Topic: $TOPIC"
    log_info "Message: $MESSAGE"
    log_info "QoS: $QOS"
    ((RETAIN)) && log_info "Retain: YES"
    echo

    # Build command
    local cmd="mosquitto_pub -h $BROKER -p $PORT -t '$TOPIC' -m '$MESSAGE' -q $QOS -i $CLIENT_ID"

    [[ -n "$USERNAME" ]] && cmd="$cmd -u '$USERNAME'"
    [[ -n "$PASSWORD" ]] && cmd="$cmd -P '$PASSWORD'"
    ((RETAIN)) && cmd="$cmd -r"

    # Publish message
    log_info "Publishing message..."

    if eval "$cmd"; then
        log_success "Message published successfully"
    else
        die "Failed to publish message"
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
            -b)
                BROKER="$2"
                shift 2
                ;;
            -p)
                PORT="$2"
                shift 2
                ;;
            -t)
                TOPIC="$2"
                shift 2
                ;;
            -M)
                MESSAGE="$2"
                shift 2
                ;;
            -q)
                QOS="$2"
                shift 2
                ;;
            -r)
                RETAIN=1
                shift
                ;;
            -u)
                USERNAME="$2"
                shift 2
                ;;
            -P)
                PASSWORD="$2"
                shift 2
                ;;
            -c)
                CLIENT_ID="$2"
                shift 2
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
    require_arg "$TOPIC" "topic (-t)"

    if [[ ! "$MODE" =~ ^(subscribe|publish)$ ]]; then
        die "Invalid mode: $MODE (must be: subscribe or publish)"
    fi

    if ! is_valid_port "$PORT"; then
        die "Invalid port: $PORT"
    fi

    if ! is_number "$QOS" || ((QOS < 0 || QOS > 2)); then
        die "Invalid QoS: $QOS (must be 0, 1, or 2)"
    fi

    if [[ "$MODE" == "publish" ]]; then
        require_arg "$MESSAGE" "message (-M)"
    fi

    # Check dependencies
    check_mosquitto

    # Initialize output file
    if [[ -n "$OUTPUT_FILE" ]]; then
        ensure_dir "$(dirname "$OUTPUT_FILE")"
        echo "MQTT Subscribe Log - Started: $(timestamp)" > "$OUTPUT_FILE"
    fi

    # Execute mode
    case "$MODE" in
        subscribe)
            mqtt_subscribe
            ;;
        publish)
            mqtt_publish
            ;;
    esac
}

main "$@"
