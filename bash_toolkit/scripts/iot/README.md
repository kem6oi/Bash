# IoT Tools

Tools for managing and monitoring IoT devices and networks.

## Tools

### 1. MQTT Helper (`mqtt_helper.sh`)
MQTT client for pub/sub operations.
```bash
./mqtt_helper.sh -m subscribe -t "sensors/#"
./mqtt_helper.sh -m publish -t "home/temp" -M "22.5"
```

### 2. Device Discovery (`device_discovery.sh`)
Discovers IoT devices on network.
```bash
./device_discovery.sh -t 10
./device_discovery.sh -a -o devices.txt
```

### 3. Serial Monitor (`serial_monitor.sh`)
Monitors serial port data.
```bash
./serial_monitor.sh -p /dev/ttyUSB0 -b 115200
./serial_monitor.sh -p /dev/ttyACM0 -o serial.log
```

### 4. Traffic Monitor (`traffic_monitor.sh`)
Captures network traffic.
```bash
sudo ./traffic_monitor.sh -i wlan0 -f "port 1883"
sudo ./traffic_monitor.sh -c 500 -o capture.pcap
```

### 5. Firmware Checker (`firmware_checker.sh`)
Checks for firmware updates.
```bash
./firmware_checker.sh -d "ESP32" -v "1.0.0"
./firmware_checker.sh -d "Arduino" -v "2.3.1" -u "https://api.example.com/firmware"
```

### 6. GPIO Controller (`gpio_controller.sh`)
Controls Raspberry Pi GPIO pins.
```bash
sudo ./gpio_controller.sh -p 17 -a read
sudo ./gpio_controller.sh -p 27 -a write -v 1
sudo ./gpio_controller.sh -p 22 -a toggle
```

## Requirements
- MQTT: mosquitto-clients
- mDNS: avahi-utils (Linux) or Bonjour (macOS)
- Serial: screen or minicom
- Traffic: tcpdump (requires root)
- GPIO: Raspberry Pi with GPIO support

## Common Use Cases
- Monitor sensor data via MQTT
- Discover and manage IoT devices
- Debug serial communications
- Analyze IoT network traffic
- Control hardware via GPIO
