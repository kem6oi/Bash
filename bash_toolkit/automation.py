from .utils import run_script

def health_monitor(interval=5, cpu_threshold=80, mem_threshold=80, disk_threshold=80, continuous=False, output_file=None, dry_run=False):
    """
    Wrapper for bash_toolkit/scripts/automation/health_monitor.sh
    """
    args = ["-i", interval, "-c", cpu_threshold, "-m", mem_threshold, "-d", disk_threshold]

    if continuous:
        args.append("-C")

    if output_file:
        args.extend(["-o", output_file])

    return run_script("bash_toolkit/scripts/automation/health_monitor.sh", args, stream=continuous, dry_run=dry_run)

def auto_backup(source, backup_dir="./backups", retention_days=7, exclude_patterns=None, no_compression=False, remote_host=None, dry_run=False):
    """
    Wrapper for bash_toolkit/scripts/automation/auto_backup.sh
    """
    args = ["-s", source, "-b", backup_dir, "-r", retention_days]

    if exclude_patterns:
        for pattern in exclude_patterns:
            args.extend(["-e", pattern])

    if no_compression:
        args.append("-n")

    if remote_host:
        args.extend(["-R", remote_host])

    return run_script("bash_toolkit/scripts/automation/auto_backup.sh", args, dry_run=dry_run)

def service_watchdog(services, interval=30, max_restarts=3, email=None, run_once=False, dry_run=False):
    """
    Wrapper for bash_toolkit/scripts/automation/service_watchdog.sh
    """
    args = ["-i", interval, "-m", max_restarts]

    if isinstance(services, list):
        for service in services:
            args.extend(["-s", service])
    else:
        args.extend(["-s", services])

    if email:
        args.extend(["-e", email])

    if run_once:
        args.append("-1")

    stream = not run_once
    return run_script("bash_toolkit/scripts/automation/service_watchdog.sh", args, stream=stream, dry_run=dry_run)

def deploy_helper(project_dir, deploy_type="web", branch="main", run_tests=False, no_backup=False, restart_services=None, dry_run=False):
    """
    Wrapper for bash_toolkit/scripts/automation/deploy_helper.sh
    """
    args = ["-p", project_dir, "-t", deploy_type, "-b", branch]

    if run_tests:
        args.append("-T")

    if no_backup:
        args.append("-n")

    if restart_services:
        if isinstance(restart_services, list):
            for service in restart_services:
                args.extend(["-r", service])
        else:
            args.extend(["-r", restart_services])

    return run_script("bash_toolkit/scripts/automation/deploy_helper.sh", args, dry_run=dry_run)

def batch_processor(operation="list", directory=".", pattern="*", new_extension=None, prefix=None, suffix=None, find_text=None, replace_text=None, compress_type="gz", dry_run_script=False, dry_run=False):
    """
    Wrapper for bash_toolkit/scripts/automation/batch_processor.sh
    """
    args = ["-o", operation, "-d", directory, "-p", pattern, "-c", compress_type]

    if new_extension:
        args.extend(["-e", new_extension])

    if prefix:
        args.extend(["-P", prefix])

    if suffix:
        args.extend(["-S", suffix])

    if find_text:
        args.extend(["-f", find_text])

    if replace_text:
        args.extend(["-r", replace_text])

    if dry_run_script:
        args.append("-n")

    return run_script("bash_toolkit/scripts/automation/batch_processor.sh", args, dry_run=dry_run)

def api_test(url=None, method="GET", headers=None, data=None, expected_status=200, timeout=30, test_file=None, output_file=None, verbose=False, no_follow_redirects=False, dry_run=False):
    """
    Wrapper for bash_toolkit/scripts/automation/api_tester.sh
    """
    args = []

    if test_file:
        args.extend(["-f", test_file])
    else:
        if url is None:
             raise ValueError("URL is required unless test_file is provided")
        args.extend(["-u", url, "-m", method, "-s", expected_status, "-t", timeout])

        if headers:
            for header in headers:
                args.extend(["-H", header])

        if data:
            args.extend(["-d", data])

    if output_file:
        args.extend(["-o", output_file])

    if verbose:
        args.append("-v")

    if no_follow_redirects:
        args.append("-n")

    return run_script("bash_toolkit/scripts/automation/api_tester.sh", args, dry_run=dry_run)
