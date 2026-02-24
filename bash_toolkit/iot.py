from .utils import run_script

def mqtt_client(topic, mode="subscribe", broker="localhost", port=1883, message=None, qos=0, retain=False, username=None, password=None, client_id=None, output_file=None, dry_run=False):
    """
    Wrapper for iot/mqtt_helper.sh
    """
    args = ["-t", topic, "-m", mode, "-b", broker, "-p", port, "-q", qos]

    if mode == "publish":
        if message is None:
            raise ValueError("Message is required for publish mode")
        args.extend(["-M", message])
        if retain:
            args.append("-r")

    if username:
        args.extend(["-u", username])
    if password:
        args.extend(["-P", password])
    if client_id:
        args.extend(["-c", client_id])
    if output_file:
        args.extend(["-o", output_file])

    stream = (mode == "subscribe")
    return run_script("iot/mqtt_helper.sh", args, stream=stream, dry_run=dry_run)

def device_discovery(scan_time=5, services=None, all_services=False, continuous=False, output_file=None, dry_run=False):
    """
    Wrapper for iot/device_discovery.sh
    """
    args = ["-t", scan_time]

    if services:
        for service in services:
            args.extend(["-s", service])

    if all_services:
        args.append("-a")

    if continuous:
        args.append("-c")

    if output_file:
        args.extend(["-o", output_file])

    return run_script("iot/device_discovery.sh", args, stream=continuous, dry_run=dry_run)

def firmware_check(device_type, current_version, update_url=None, output_file=None, dry_run=False):
    """
    Wrapper for iot/firmware_checker.sh
    """
    args = ["-d", device_type, "-v", current_version]

    if update_url:
        args.extend(["-u", update_url])

    if output_file:
        args.extend(["-o", output_file])

    return run_script("iot/firmware_checker.sh", args, dry_run=dry_run)

def gpio_control(pin, action="read", value=None, mode="out", dry_run=False):
    """
    Wrapper for iot/gpio_controller.sh
    """
    args = ["-p", pin, "-a", action, "-m", mode]

    if action == "write":
        if value is None:
             raise ValueError("Value is required for write action")
        args.extend(["-v", value])

    return run_script("iot/gpio_controller.sh", args, dry_run=dry_run)

def serial_monitor(port="/dev/ttyUSB0", baudrate=9600, output_file=None, no_timestamps=False, dry_run=False):
    """
    Wrapper for iot/serial_monitor.sh
    """
    args = ["-p", port, "-b", baudrate]

    if output_file:
        args.extend(["-o", output_file])

    if no_timestamps:
        args.append("-n")

    return run_script("iot/serial_monitor.sh", args, stream=True, dry_run=dry_run)

def traffic_monitor(interface="eth0", filter_exp=None, packet_count=100, duration=0, output_file=None, dry_run=False):
    """
    Wrapper for iot/traffic_monitor.sh
    """
    args = ["-i", interface, "-c", packet_count]

    if filter_exp:
        args.extend(["-f", filter_exp])

    if duration > 0:
        args.extend(["-t", duration])

    if output_file:
        args.extend(["-o", output_file])

    return run_script("iot/traffic_monitor.sh", args, stream=True, dry_run=dry_run)
