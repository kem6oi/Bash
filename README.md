# Bash Security & IoT Toolkit

A comprehensive collection of Bash scripts for cybersecurity, automation, and IoT management. This toolkit provides penetration testers, system administrators, and IoT developers with practical command-line tools for daily tasks.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Tools Overview](#tools-overview)
- [Installation](#installation)
- [Usage](#usage)
- [Requirements](#requirements)
- [Contributing](#contributing)
- [License](#license)

## Features

- **23 specialized tools** covering cybersecurity, automation, and IoT
- **Common library** with shared utilities for consistent behavior
- **Interactive menu system** for easy tool access
- **Comprehensive logging** and report generation
- **Cross-platform support** (Linux, macOS, BSD)
- **Educational resource** with well-commented code

## Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd Bash

# Run setup script to install dependencies
./setup.sh

# Launch interactive menu
./menu.sh
```

## Directory Structure

```
Bash/
├── cybersecurity/       # Security and penetration testing tools
├── automation/          # System automation scripts
├── iot/                # IoT device management tools
├── utils/              # Utility scripts
├── lib/                # Shared libraries
├── examples/           # Usage examples
├── logs/               # Tool output logs (gitignored)
├── reports/            # Generated reports (gitignored)
├── menu.sh             # Interactive menu launcher
└── setup.sh            # Environment setup script
```

## Tools Overview

### Cybersecurity Tools

| Tool | Description | Use Case |
|------|-------------|----------|
| **port_scanner.sh** | TCP/UDP port scanner | Network reconnaissance, security audits |
| **subnet_scanner.sh** | Network host discovery | Find active hosts on subnet |
| **ssl_checker.sh** | SSL/TLS certificate analyzer | Validate certificate security |
| **log_analyzer.sh** | Security log parser | Detect suspicious activities |
| **password_checker.sh** | Password strength evaluator | Test password complexity |
| **hash_tool.sh** | File hash generator/verifier | Integrity verification |
| **vuln_scanner.sh** | Vulnerability scan wrapper | Automate security scans |
| **integrity_checker.sh** | File integrity monitor | Detect unauthorized changes |

### Automation Tools

| Tool | Description | Use Case |
|------|-------------|----------|
| **health_monitor.sh** | System resource monitor | CPU, memory, disk alerts |
| **auto_backup.sh** | Scheduled backup script | Automated data protection |
| **service_watchdog.sh** | Service monitor/restarter | Ensure service uptime |
| **deploy_helper.sh** | Deployment automation | Simplify CI/CD processes |
| **batch_processor.sh** | Bulk file operations | Batch rename, convert, compress |
| **api_tester.sh** | REST API testing tool | Automated endpoint testing |

### IoT Tools

| Tool | Description | Use Case |
|------|-------------|----------|
| **mqtt_helper.sh** | MQTT client wrapper | Publish/subscribe to topics |
| **device_discovery.sh** | Network device scanner | Find IoT devices (mDNS) |
| **serial_monitor.sh** | Serial port logger | Monitor device output |
| **traffic_monitor.sh** | Network traffic analyzer | Analyze IoT communications |
| **firmware_checker.sh** | Firmware update tool | Check for device updates |
| **gpio_controller.sh** | GPIO control (RPi) | Control Raspberry Pi pins |

### Utilities

| Tool | Description | Use Case |
|------|-------------|----------|
| **report_generator.sh** | Report formatter | Create formatted output |

## Installation

### Prerequisites

- Bash 4.0 or higher
- Standard Unix utilities (grep, sed, awk, nc, etc.)
- Optional: nmap, openssl, mosquitto-clients, tcpdump

### Setup

```bash
# Make all scripts executable
chmod +x setup.sh menu.sh
chmod +x cybersecurity/*.sh automation/*.sh iot/*.sh utils/*.sh

# Run setup to check and install dependencies
./setup.sh
```

## Usage

### Interactive Menu

Launch the interactive menu to access all tools:

```bash
./menu.sh
```

### Direct Execution

Run any tool directly with appropriate flags:

```bash
# Scan ports on a host
./cybersecurity/port_scanner.sh -h 192.168.1.1 -p 1-1000

# Monitor system health
./automation/health_monitor.sh -i 5 -c 80

# Check SSL certificate
./cybersecurity/ssl_checker.sh -d example.com
```

### Using the Common Library

All tools use the shared library at `lib/common.sh`:

```bash
#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"

log_info "Starting script"
log_success "Operation completed"
log_error "Something went wrong"
```

## Requirements

### Core Requirements
- Linux, macOS, or BSD-based system
- Bash 4.0+
- Standard GNU utilities

### Optional Dependencies
- **nmap**: Network scanning (port_scanner, subnet_scanner)
- **openssl**: SSL/TLS checking (ssl_checker)
- **mosquitto-clients**: MQTT operations (mqtt_helper)
- **tcpdump**: Traffic monitoring (traffic_monitor)
- **jq**: JSON parsing (api_tester)
- **curl**: HTTP requests (api_tester, firmware_checker)

## Examples

See the `examples/` directory for detailed usage examples of each tool.

## Security Notice

**Educational and Authorized Use Only**

These tools are intended for:
- Authorized security testing and penetration testing
- System administration on your own networks
- Educational purposes in controlled environments
- CTF competitions and security research

**Always obtain proper authorization before scanning or testing systems you do not own.**

Unauthorized access to computer systems is illegal. Users are responsible for complying with all applicable laws and regulations.

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add your improvements
4. Submit a pull request

## License

See LICENSE file for details.

## Author

Created for cybersecurity and IoT education and automation.

## Support

For issues, questions, or suggestions, please open an issue in the repository.

---

**Happy Hacking!** (Ethically, of course)
