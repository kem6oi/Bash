# Bash Toolkit SDK

A Python SDK for the Bash Security & IoT Toolkit.

## Installation

```bash
pip install .
```

## Usage

### IoT

```python
from bash_toolkit.iot import mqtt_client, device_discovery

# Subscribe to MQTT topic
mqtt_client(topic="sensors/#", broker="mqtt.example.com")

# Discover IoT devices
device_discovery(scan_time=10, all_services=True)
```

### Cybersecurity

```python
from bash_toolkit.cybersecurity import port_scan, hash_generate

# Scan ports
port_scan(host="192.168.1.1", ports="1-1000")

# Generate hash
hash_generate(file="important.doc", type="sha256")
```

### Automation

```python
from bash_toolkit.automation import health_monitor, auto_backup

# Check system health
health_monitor()

# Backup directory
auto_backup(source="/var/www/html", backup_dir="/backups")
```

## Testing

You can use `dry_run=True` to print the command that would be executed without actually running it.

```python
port_scan(host="localhost", dry_run=True)
```
