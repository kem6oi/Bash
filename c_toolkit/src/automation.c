#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../include/bash_toolkit.h"

int health_monitor(int interval, int cpu_threshold, int mem_threshold, int disk_threshold, int continuous, const char *output_file, int dry_run) {
    char *args[20];
    int i = 0;

    char int_str[16]; snprintf(int_str, sizeof(int_str), "%d", interval);
    args[i++] = "-i"; args[i++] = int_str;

    char cpu_str[16]; snprintf(cpu_str, sizeof(cpu_str), "%d", cpu_threshold);
    args[i++] = "-c"; args[i++] = cpu_str;

    char mem_str[16]; snprintf(mem_str, sizeof(mem_str), "%d", mem_threshold);
    args[i++] = "-m"; args[i++] = mem_str;

    char disk_str[16]; snprintf(disk_str, sizeof(disk_str), "%d", disk_threshold);
    args[i++] = "-d"; args[i++] = disk_str;

    if (continuous) args[i++] = "-C";
    if (output_file) { args[i++] = "-o"; args[i++] = (char *)output_file; }

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/automation/health_monitor.sh", args, dry_run);
}

int auto_backup(const char *source, const char *backup_dir, int retention_days, const char *exclude_patterns[], int num_excludes, int no_compression, const char *remote_host, int dry_run) {
    char *args[64];
    int i = 0;

    args[i++] = "-s"; args[i++] = (char *)source;
    args[i++] = "-b"; args[i++] = (char *)backup_dir;

    char ret_str[16]; snprintf(ret_str, sizeof(ret_str), "%d", retention_days);
    args[i++] = "-r"; args[i++] = ret_str;

    if (exclude_patterns) {
        for (int j = 0; j < num_excludes; j++) {
            if (i < 60) {
                args[i++] = "-e"; args[i++] = (char *)exclude_patterns[j];
            }
        }
    }

    if (no_compression) args[i++] = "-n";
    if (remote_host) { args[i++] = "-R"; args[i++] = (char *)remote_host; }

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/automation/auto_backup.sh", args, dry_run);
}

int service_watchdog(const char *services[], int num_services, int interval, int max_restarts, const char *email, int run_once, int dry_run) {
    char *args[64];
    int i = 0;

    if (services) {
        for (int j = 0; j < num_services; j++) {
            if (i < 50) {
                args[i++] = "-s"; args[i++] = (char *)services[j];
            }
        }
    }

    char int_str[16]; snprintf(int_str, sizeof(int_str), "%d", interval);
    args[i++] = "-i"; args[i++] = int_str;

    char max_str[16]; snprintf(max_str, sizeof(max_str), "%d", max_restarts);
    args[i++] = "-m"; args[i++] = max_str;

    if (email) { args[i++] = "-e"; args[i++] = (char *)email; }
    if (run_once) args[i++] = "-1";

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/automation/service_watchdog.sh", args, dry_run);
}

int deploy_helper(const char *project_dir, const char *deploy_type, const char *branch, int run_tests, int no_backup, const char *restart_services[], int num_restart_services, int dry_run) {
    char *args[64];
    int i = 0;

    args[i++] = "-p"; args[i++] = (char *)project_dir;
    args[i++] = "-t"; args[i++] = (char *)deploy_type;
    args[i++] = "-b"; args[i++] = (char *)branch;

    if (run_tests) args[i++] = "-T";
    if (no_backup) args[i++] = "-n";

    if (restart_services) {
        for (int j = 0; j < num_restart_services; j++) {
            if (i < 60) {
                args[i++] = "-r"; args[i++] = (char *)restart_services[j];
            }
        }
    }

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/automation/deploy_helper.sh", args, dry_run);
}

int batch_processor(const char *operation, const char *directory, const char *pattern, const char *new_extension, const char *prefix, const char *suffix, const char *find_text, const char *replace_text, const char *compress_type, int dry_run_script, int dry_run) {
    char *args[32];
    int i = 0;

    args[i++] = "-o"; args[i++] = (char *)operation;
    args[i++] = "-d"; args[i++] = (char *)directory;
    args[i++] = "-p"; args[i++] = (char *)pattern;
    args[i++] = "-c"; args[i++] = (char *)compress_type;

    if (new_extension) { args[i++] = "-e"; args[i++] = (char *)new_extension; }
    if (prefix) { args[i++] = "-P"; args[i++] = (char *)prefix; }
    if (suffix) { args[i++] = "-S"; args[i++] = (char *)suffix; }
    if (find_text) { args[i++] = "-f"; args[i++] = (char *)find_text; }
    if (replace_text) { args[i++] = "-r"; args[i++] = (char *)replace_text; }
    if (dry_run_script) args[i++] = "-n";

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/automation/batch_processor.sh", args, dry_run);
}

int api_test(const char *url, const char *method, const char *headers[], int num_headers, const char *data, int expected_status, int timeout, const char *test_file, const char *output_file, int verbose, int no_follow_redirects, int dry_run) {
    char *args[64];
    int i = 0;

    if (test_file) {
        args[i++] = "-f"; args[i++] = (char *)test_file;
    } else {
        if (!url) return -1;
        args[i++] = "-u"; args[i++] = (char *)url;
        args[i++] = "-m"; args[i++] = (char *)method;

        char status_str[16]; snprintf(status_str, sizeof(status_str), "%d", expected_status);
        args[i++] = "-s"; args[i++] = status_str;

        char timeout_str[16]; snprintf(timeout_str, sizeof(timeout_str), "%d", timeout);
        args[i++] = "-t"; args[i++] = timeout_str;

        if (headers) {
            for (int j = 0; j < num_headers; j++) {
                if (i < 50) {
                    args[i++] = "-H"; args[i++] = (char *)headers[j];
                }
            }
        }

        if (data) { args[i++] = "-d"; args[i++] = (char *)data; }
    }

    if (output_file) { args[i++] = "-o"; args[i++] = (char *)output_file; }
    if (verbose) args[i++] = "-v";
    if (no_follow_redirects) args[i++] = "-n";

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/automation/api_tester.sh", args, dry_run);
}
