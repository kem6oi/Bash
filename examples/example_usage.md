# Example Usage Guide

## Cybersecurity Workflows

### Basic Network Assessment
```bash
# 1. Discover active hosts
./cybersecurity/subnet_scanner.sh -s 192.168.1.0/24 -o hosts.txt

# 2. Scan common ports on discovered host
./cybersecurity/port_scanner.sh -h 192.168.1.100 -p 1-1000 -o ports.txt

# 3. Check SSL certificate
./cybersecurity/ssl_checker.sh -d 192.168.1.100 -c -P
```

### Security Monitoring
```bash
# Monitor auth logs in real-time
./cybersecurity/log_analyzer.sh -t auth -w

# Check file integrity
./cybersecurity/integrity_checker.sh -m baseline -d /etc/config
./cybersecurity/integrity_checker.sh -m check -d /etc/config
```

## Automation Workflows

### Server Health Monitoring
```bash
# One-time check
./automation/health_monitor.sh -c 80 -m 80 -d 90

# Continuous monitoring
./automation/health_monitor.sh -C -i 60 -o /var/log/health.log
```

### Backup Strategy
```bash
# Daily website backup
./automation/auto_backup.sh -s /var/www/html -b /backups -r 7

# Database backup
./automation/auto_backup.sh -s /var/lib/mysql -b /backups -r 14 -e "*.log"
```

### Service Management
```bash
# Monitor critical services
./automation/service_watchdog.sh -s nginx -s mysql -s redis -i 30
```

## IoT Workflows

### Smart Home Monitoring
```bash
# Subscribe to all sensors
./iot/mqtt_helper.sh -m subscribe -t "home/sensors/#" -o sensors.log

# Publish command
./iot/mqtt_helper.sh -m publish -t "home/lights/living" -M "ON"
```

### Device Discovery and Analysis
```bash
# Find all IoT devices
./iot/device_discovery.sh -a -o devices.txt

# Monitor specific device traffic
sudo ./iot/traffic_monitor.sh -i eth0 -f "host 192.168.1.50" -o device.pcap
```

### Raspberry Pi Projects
```bash
# Read sensor on GPIO 17
sudo ./iot/gpio_controller.sh -p 17 -a read

# Control LED on GPIO 27
sudo ./iot/gpio_controller.sh -p 27 -a write -v 1
```

## Combined Workflows

### Complete Security Audit
```bash
#!/bin/bash
TARGET="192.168.1.100"

echo "Starting security audit of $TARGET"

# Port scan
./cybersecurity/port_scanner.sh -h $TARGET -p 1-65535 -o audit_ports.txt

# Vulnerability scan
./cybersecurity/vuln_scanner.sh -t $TARGET -s full -o audit_vuln.txt

# SSL check
./cybersecurity/ssl_checker.sh -d $TARGET -c -P -o audit_ssl.txt

# Generate report
./utils/report_generator.sh -i audit_ports.txt -o final_report.html -f html -t "Security Audit: $TARGET"

echo "Audit complete. See final_report.html"
```

### Automated Deployment Pipeline
```bash
#!/bin/bash
PROJECT="/var/www/myapp"

# Backup before deployment
./automation/auto_backup.sh -s $PROJECT -b /backups

# Deploy
./automation/deploy_helper.sh -p $PROJECT -b main -T -r nginx

# Monitor after deployment
./automation/health_monitor.sh -i 5 -c 90 -m 85
```

### IoT System Setup
```bash
#!/bin/bash

# Discover devices
./iot/device_discovery.sh -t 30 -o devices.txt

# Setup MQTT monitoring
./iot/mqtt_helper.sh -m subscribe -t "sensors/#" -o mqtt.log &

# Monitor serial device
./iot/serial_monitor.sh -p /dev/ttyUSB0 -b 115200 -o serial.log &

echo "IoT monitoring started"
```

## API Testing Examples

### REST API Test Suite
```bash
# Single endpoint test
./automation/api_tester.sh -u https://api.example.com/health -s 200

# POST with data
./automation/api_tester.sh \
  -u https://api.example.com/users \
  -m POST \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@example.com"}' \
  -s 201

# Authenticated request
./automation/api_tester.sh \
  -u https://api.example.com/private \
  -H "Authorization: Bearer TOKEN" \
  -s 200
```

## Batch Processing Examples

### File Management
```bash
# Rename photos
./automation/batch_processor.sh -o rename -p "*.jpg" -P "vacation_2024_"

# Compress logs
./automation/batch_processor.sh -o compress -p "*.log" -c gz

# Convert file extensions
./automation/batch_processor.sh -o convert -p "*.txt" -e md
```

## Pro Tips

1. **Chain commands**: Use output files from one tool as input to another
2. **Schedule with cron**: Automate regular tasks
3. **Log everything**: Use -o flags to keep records
4. **Test first**: Use -n (dry run) flags when available
5. **Read help**: Every tool has --help with examples
