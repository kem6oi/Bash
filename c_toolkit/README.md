# C Toolkit SDK

A C SDK for the Bash Security & IoT Toolkit.

## Building

```bash
make
```

This will produce:
- `lib/libbash_toolkit.a`: Static library
- `lib/libbash_toolkit.so`: Shared library

## Usage

Include the header `include/bash_toolkit.h` and link against the library.

### IoT

```c
#include "bash_toolkit.h"

// Subscribe to MQTT topic
mqtt_client("sensors/#", "subscribe", "mqtt.example.com", 1883, NULL, 0, 0, NULL, NULL, NULL, NULL, 0);

// Discover IoT devices
device_discovery(10, NULL, 0, 1, 0, NULL, 0);
```

### Cybersecurity

```c
#include "bash_toolkit.h"

// Scan ports
port_scan("192.168.1.1", "1-1000", "tcp", 1, 50, NULL, 0, 0);

// Generate hash
hash_generate("important.doc", "generate", "sha256", NULL, 0, NULL, 0);
```

### Automation

```c
#include "bash_toolkit.h"

// Check system health
health_monitor(5, 80, 80, 80, 0, NULL, 0);

// Backup directory
auto_backup("/var/www/html", "/backups", 7, NULL, 0, 0, NULL, 0);
```

## Environment

The SDK looks for scripts relative to the current working directory, or you can set the `BASH_TOOLKIT_ROOT` environment variable to the root of the repository.

```bash
export BASH_TOOLKIT_ROOT=/path/to/bash-toolkit
./my_app
```
