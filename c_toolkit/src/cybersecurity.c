#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../include/bash_toolkit.h"

int port_scan(const char *host, const char *ports, const char *type, int timeout, int threads, const char *output_file, int verbose, int dry_run) {
    char *args[20];
    int i = 0;

    args[i++] = "-h"; args[i++] = (char *)host;
    args[i++] = "-p"; args[i++] = (char *)ports;
    args[i++] = "-t"; args[i++] = (char *)type;

    char timeout_str[16]; snprintf(timeout_str, sizeof(timeout_str), "%d", timeout);
    args[i++] = "-T"; args[i++] = timeout_str;

    char threads_str[16]; snprintf(threads_str, sizeof(threads_str), "%d", threads);
    args[i++] = "-j"; args[i++] = threads_str;

    if (output_file) { args[i++] = "-o"; args[i++] = (char *)output_file; }
    if (verbose) args[i++] = "-v";

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/cybersecurity/port_scanner.sh", args, dry_run);
}

int subnet_scan(const char *subnet, int timeout, int threads, int resolve, int quick_port_scan, const char *ports, const char *output_file, int dry_run) {
    char *args[20];
    int i = 0;

    args[i++] = "-s"; args[i++] = (char *)subnet;

    char timeout_str[16]; snprintf(timeout_str, sizeof(timeout_str), "%d", timeout);
    args[i++] = "-t"; args[i++] = timeout_str;

    char threads_str[16]; snprintf(threads_str, sizeof(threads_str), "%d", threads);
    args[i++] = "-j"; args[i++] = threads_str;

    if (resolve) args[i++] = "-r";
    if (quick_port_scan) args[i++] = "-p";
    if (ports) { args[i++] = "-P"; args[i++] = (char *)ports; }
    if (output_file) { args[i++] = "-o"; args[i++] = (char *)output_file; }

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/cybersecurity/subnet_scanner.sh", args, dry_run);
}

int ssl_check(const char *domain, int port, int warning_days, int check_chain, int check_protocols, int check_ciphers, const char *output_file, int dry_run) {
    char *args[20];
    int i = 0;

    args[i++] = "-d"; args[i++] = (char *)domain;

    char port_str[16]; snprintf(port_str, sizeof(port_str), "%d", port);
    args[i++] = "-p"; args[i++] = port_str;

    char days_str[16]; snprintf(days_str, sizeof(days_str), "%d", warning_days);
    args[i++] = "-w"; args[i++] = days_str;

    if (check_chain) args[i++] = "-c";
    if (check_protocols) args[i++] = "-P";
    if (check_ciphers) args[i++] = "-C";
    if (output_file) { args[i++] = "-o"; args[i++] = (char *)output_file; }

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/cybersecurity/ssl_checker.sh", args, dry_run);
}

int log_analyze(const char *log_file, const char *log_type, int tail_lines, int watch_mode, int show_all, const char *output_file, int dry_run) {
    char *args[20];
    int i = 0;

    args[i++] = "-t"; args[i++] = (char *)log_type;

    char lines_str[16]; snprintf(lines_str, sizeof(lines_str), "%d", tail_lines);
    args[i++] = "-n"; args[i++] = lines_str;

    if (log_file) { args[i++] = "-f"; args[i++] = (char *)log_file; }
    if (watch_mode) args[i++] = "-w";
    if (show_all) args[i++] = "-a";
    if (output_file) { args[i++] = "-o"; args[i++] = (char *)output_file; }

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/cybersecurity/log_analyzer.sh", args, dry_run);
}

int password_check(const char *password, const char *file_input, int min_length, int show_password, int dry_run) {
    char *args[16];
    int i = 0;

    char len_str[16]; snprintf(len_str, sizeof(len_str), "%d", min_length);
    args[i++] = "-l"; args[i++] = len_str;

    if (password) { args[i++] = "-p"; args[i++] = (char *)password; }
    if (file_input) { args[i++] = "-f"; args[i++] = (char *)file_input; }
    if (show_password) args[i++] = "-s";

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/cybersecurity/password_checker.sh", args, dry_run);
}

int hash_generate(const char *file, const char *mode, const char *type, const char *expected_hash, int recursive, const char *output_file, int dry_run) {
    char *args[20];
    int i = 0;

    args[i++] = "-m"; args[i++] = (char *)mode;
    args[i++] = "-f"; args[i++] = (char *)file;
    args[i++] = "-t"; args[i++] = (char *)type;

    if (expected_hash) { args[i++] = "-e"; args[i++] = (char *)expected_hash; }
    if (recursive) args[i++] = "-r";
    if (output_file) { args[i++] = "-o"; args[i++] = (char *)output_file; }

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/cybersecurity/hash_tool.sh", args, dry_run);
}

int vuln_scan(const char *target, const char *scan_type, const char *output_file, int use_nmap, int use_nikto, int use_testssl, int use_all, int dry_run) {
    char *args[20];
    int i = 0;

    args[i++] = "-t"; args[i++] = (char *)target;
    args[i++] = "-s"; args[i++] = (char *)scan_type;

    if (output_file) { args[i++] = "-o"; args[i++] = (char *)output_file; }
    if (use_nmap) args[i++] = "--nmap";
    if (use_nikto) args[i++] = "--nikto";
    if (use_testssl) args[i++] = "--testssl";
    if (use_all) args[i++] = "--all";

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/cybersecurity/vuln_scanner.sh", args, dry_run);
}

int integrity_check(const char *directory, const char *mode, const char *baseline_file, const char *hash_type, const char *backup_dir, int dry_run) {
    char *args[20];
    int i = 0;

    args[i++] = "-d"; args[i++] = (char *)directory;
    args[i++] = "-m"; args[i++] = (char *)mode;
    args[i++] = "-t"; args[i++] = (char *)hash_type;

    if (baseline_file) { args[i++] = "-b"; args[i++] = (char *)baseline_file; }
    if (backup_dir) { args[i++] = "-o"; args[i++] = (char *)backup_dir; }

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/cybersecurity/integrity_checker.sh", args, dry_run);
}
