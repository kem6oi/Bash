from .utils import run_script

def port_scan(host, ports="1-1000", type="tcp", timeout=1, threads=50, output_file=None, verbose=False, dry_run=False):
    """
    Wrapper for cybersecurity/port_scanner.sh
    """
    args = ["-h", host, "-p", ports, "-t", type, "-T", timeout, "-j", threads]

    if output_file:
        args.extend(["-o", output_file])

    if verbose:
        args.append("-v")

    return run_script("cybersecurity/port_scanner.sh", args, dry_run=dry_run)

def subnet_scan(subnet, timeout=1, threads=50, resolve=False, quick_port_scan=False, ports=None, output_file=None, dry_run=False):
    """
    Wrapper for cybersecurity/subnet_scanner.sh
    """
    args = ["-s", subnet, "-t", timeout, "-j", threads]

    if resolve:
        args.append("-r")

    if quick_port_scan:
        args.append("-p")

    if ports:
        args.extend(["-P", ports])

    if output_file:
        args.extend(["-o", output_file])

    return run_script("cybersecurity/subnet_scanner.sh", args, dry_run=dry_run)

def ssl_check(domain, port=443, warning_days=30, check_chain=False, check_protocols=False, check_ciphers=False, output_file=None, dry_run=False):
    """
    Wrapper for cybersecurity/ssl_checker.sh
    """
    args = ["-d", domain, "-p", port, "-w", warning_days]

    if check_chain:
        args.append("-c")

    if check_protocols:
        args.append("-P")

    if check_ciphers:
        args.append("-C")

    if output_file:
        args.extend(["-o", output_file])

    return run_script("cybersecurity/ssl_checker.sh", args, dry_run=dry_run)

def log_analyze(log_file=None, log_type="syslog", tail_lines=1000, watch_mode=False, show_all=False, output_file=None, dry_run=False):
    """
    Wrapper for cybersecurity/log_analyzer.sh
    """
    args = ["-t", log_type, "-n", tail_lines]

    if log_file:
        args.extend(["-f", log_file])

    if watch_mode:
        args.append("-w")

    if show_all:
        args.append("-a")

    if output_file:
        args.extend(["-o", output_file])

    return run_script("cybersecurity/log_analyzer.sh", args, stream=watch_mode, dry_run=dry_run)

def password_check(password=None, file_input=None, min_length=12, show_password=False, dry_run=False):
    """
    Wrapper for cybersecurity/password_checker.sh
    """
    args = ["-l", min_length]

    if password:
        args.extend(["-p", password])

    if file_input:
        args.extend(["-f", file_input])

    if show_password:
        args.append("-s")

    return run_script("cybersecurity/password_checker.sh", args, dry_run=dry_run)

def hash_generate(file, mode="generate", type="sha256", expected_hash=None, recursive=False, output_file=None, dry_run=False):
    """
    Wrapper for cybersecurity/hash_tool.sh
    """
    args = ["-m", mode, "-f", file, "-t", type]

    if expected_hash:
        args.extend(["-e", expected_hash])

    if recursive:
        args.append("-r")

    if output_file:
        args.extend(["-o", output_file])

    return run_script("cybersecurity/hash_tool.sh", args, dry_run=dry_run)

def vuln_scan(target, scan_type="quick", output_file=None, use_nmap=False, use_nikto=False, use_testssl=False, use_all=False, dry_run=False):
    """
    Wrapper for cybersecurity/vuln_scanner.sh
    """
    args = ["-t", target, "-s", scan_type]

    if output_file:
        args.extend(["-o", output_file])

    if use_nmap:
        args.append("--nmap")

    if use_nikto:
        args.append("--nikto")

    if use_testssl:
        args.append("--testssl")

    if use_all:
        args.append("--all")

    return run_script("cybersecurity/vuln_scanner.sh", args, dry_run=dry_run)

def integrity_check(directory, mode="baseline", baseline_file=None, hash_type="sha256", backup_dir=None, dry_run=False):
    """
    Wrapper for cybersecurity/integrity_checker.sh
    """
    args = ["-d", directory, "-m", mode, "-t", hash_type]

    if baseline_file:
        args.extend(["-b", baseline_file])

    if backup_dir:
        args.extend(["-o", backup_dir])

    return run_script("cybersecurity/integrity_checker.sh", args, dry_run=dry_run)
