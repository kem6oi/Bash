#!/bin/bash
################################################################################
# Interactive Menu System
# Main launcher for all tools
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/bash_toolkit/scripts/lib/common.sh"

################################################################################
# Menu Functions
################################################################################

show_main_menu() {
    clear
    print_banner "Bash Security & IoT Toolkit"

    echo "1. Cybersecurity Tools"
    echo "2. Automation Tools"
    echo "3. IoT Tools"
    echo "4. Utilities"
    echo "5. About"
    echo "0. Exit"
    echo
    echo -n "Select category: "
}

show_cybersecurity_menu() {
    clear
    log_header "Cybersecurity Tools"

    echo "1. Port Scanner"
    echo "2. Network Subnet Scanner"
    echo "3. SSL/TLS Certificate Checker"
    echo "4. Log Analyzer"
    echo "5. Password Strength Checker"
    echo "6. Hash Generator/Checker"
    echo "7. Vulnerability Scanner"
    echo "8. Integrity Checker"
    echo "0. Back to Main Menu"
    echo
    echo -n "Select tool: "
}

show_automation_menu() {
    clear
    log_header "Automation Tools"

    echo "1. System Health Monitor"
    echo "2. Automated Backup"
    echo "3. Service Watchdog"
    echo "4. Deployment Helper"
    echo "5. Batch File Processor"
    echo "6. API Tester"
    echo "0. Back to Main Menu"
    echo
    echo -n "Select tool: "
}

show_iot_menu() {
    clear
    log_header "IoT Tools"

    echo "1. MQTT Client Helper"
    echo "2. Device Discovery"
    echo "3. Serial Monitor"
    echo "4. Traffic Monitor"
    echo "5. Firmware Checker"
    echo "6. GPIO Controller (Raspberry Pi)"
    echo "0. Back to Main Menu"
    echo
    echo -n "Select tool: "
}

show_about() {
    clear
    print_banner "About This Toolkit"

    cat << EOF
Bash Security & IoT Toolkit
Version: 1.0.0

A comprehensive collection of 23 specialized Bash scripts for:
  - Cybersecurity and penetration testing
  - System automation
  - IoT device management

Created for educational and authorized testing purposes.

Repository: https://github.com/yourusername/bash-toolkit
Documentation: See README.md

Press Enter to continue...
EOF
    read
}

run_tool() {
    local tool="$1"
    shift

    echo
    log_info "Launching: $tool"
    echo

    if [[ -x "$tool" ]]; then
        "$tool" "$@"
    else
        log_error "Tool not found or not executable: $tool"
    fi

    echo
    echo "Press Enter to continue..."
    read
}

################################################################################
# Main Menu Logic
################################################################################

while true; do
    show_main_menu
    read -r choice

    case $choice in
        1)
            while true; do
                show_cybersecurity_menu
                read -r subchoice

                case $subchoice in
                    1) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/cybersecurity/port_scanner.sh" --help ;;
                    2) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/cybersecurity/subnet_scanner.sh" --help ;;
                    3) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/cybersecurity/ssl_checker.sh" --help ;;
                    4) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/cybersecurity/log_analyzer.sh" --help ;;
                    5) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/cybersecurity/password_checker.sh" --help ;;
                    6) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/cybersecurity/hash_tool.sh" --help ;;
                    7) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/cybersecurity/vuln_scanner.sh" --help ;;
                    8) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/cybersecurity/integrity_checker.sh" --help ;;
                    0) break ;;
                    *) log_error "Invalid choice" ; sleep 1 ;;
                esac
            done
            ;;
        2)
            while true; do
                show_automation_menu
                read -r subchoice

                case $subchoice in
                    1) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/automation/health_monitor.sh" --help ;;
                    2) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/automation/auto_backup.sh" --help ;;
                    3) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/automation/service_watchdog.sh" --help ;;
                    4) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/automation/deploy_helper.sh" --help ;;
                    5) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/automation/batch_processor.sh" --help ;;
                    6) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/automation/api_tester.sh" --help ;;
                    0) break ;;
                    *) log_error "Invalid choice" ; sleep 1 ;;
                esac
            done
            ;;
        3)
            while true; do
                show_iot_menu
                read -r subchoice

                case $subchoice in
                    1) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/iot/mqtt_helper.sh" --help ;;
                    2) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/iot/device_discovery.sh" --help ;;
                    3) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/iot/serial_monitor.sh" --help ;;
                    4) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/iot/traffic_monitor.sh" --help ;;
                    5) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/iot/firmware_checker.sh" --help ;;
                    6) run_tool "$SCRIPT_DIR/bash_toolkit/scripts/iot/gpio_controller.sh" --help ;;
                    0) break ;;
                    *) log_error "Invalid choice" ; sleep 1 ;;
                esac
            done
            ;;
        4)
            run_tool "$SCRIPT_DIR/bash_toolkit/scripts/utils/report_generator.sh" --help
            ;;
        5)
            show_about
            ;;
        0)
            log_info "Goodbye!"
            exit 0
            ;;
        *)
            log_error "Invalid choice"
            sleep 1
            ;;
    esac
done
