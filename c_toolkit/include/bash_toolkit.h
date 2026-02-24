#ifndef BASH_TOOLKIT_H
#define BASH_TOOLKIT_H

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Configuration and Utility Functions
 */

/**
 * Run a bash script.
 *
 * @param script_path Relative path to the script (e.g., "iot/mqtt_helper.sh").
 * @param args Array of string arguments.
 * @param dry_run If 1, print the command instead of executing.
 * @return Exit code of the script, or -1 on error.
 */
int run_script(const char *script_path, char *const args[], int dry_run);

/*
 * IoT Module
 */
int mqtt_client(const char *topic, const char *mode, const char *broker, int port, const char *message, int qos, int retain, const char *username, const char *password, const char *client_id, const char *output_file, int dry_run);
int device_discovery(int scan_time, const char *services[], int num_services, int all_services, int continuous, const char *output_file, int dry_run);
int firmware_check(const char *device_type, const char *current_version, const char *update_url, const char *output_file, int dry_run);
int gpio_control(int pin, const char *action, const char *value, const char *mode, int dry_run);
int serial_monitor(const char *port, int baudrate, const char *output_file, int no_timestamps, int dry_run);
int traffic_monitor(const char *interface, const char *filter, int packet_count, int duration, const char *output_file, int dry_run);

/*
 * Cybersecurity Module
 */
int port_scan(const char *host, const char *ports, const char *type, int timeout, int threads, const char *output_file, int verbose, int dry_run);
int subnet_scan(const char *subnet, int timeout, int threads, int resolve, int quick_port_scan, const char *ports, const char *output_file, int dry_run);
int ssl_check(const char *domain, int port, int warning_days, int check_chain, int check_protocols, int check_ciphers, const char *output_file, int dry_run);
int log_analyze(const char *log_file, const char *log_type, int tail_lines, int watch_mode, int show_all, const char *output_file, int dry_run);
int password_check(const char *password, const char *file_input, int min_length, int show_password, int dry_run);
int hash_generate(const char *file, const char *mode, const char *type, const char *expected_hash, int recursive, const char *output_file, int dry_run);
int vuln_scan(const char *target, const char *scan_type, const char *output_file, int use_nmap, int use_nikto, int use_testssl, int use_all, int dry_run);
int integrity_check(const char *directory, const char *mode, const char *baseline_file, const char *hash_type, const char *backup_dir, int dry_run);

/*
 * Automation Module
 */
int health_monitor(int interval, int cpu_threshold, int mem_threshold, int disk_threshold, int continuous, const char *output_file, int dry_run);
int auto_backup(const char *source, const char *backup_dir, int retention_days, const char *exclude_patterns[], int num_excludes, int no_compression, const char *remote_host, int dry_run);
int service_watchdog(const char *services[], int num_services, int interval, int max_restarts, const char *email, int run_once, int dry_run);
int deploy_helper(const char *project_dir, const char *deploy_type, const char *branch, int run_tests, int no_backup, const char *restart_services[], int num_restart_services, int dry_run);
int batch_processor(const char *operation, const char *directory, const char *pattern, const char *new_extension, const char *prefix, const char *suffix, const char *find_text, const char *replace_text, const char *compress_type, int dry_run_script, int dry_run);
int api_test(const char *url, const char *method, const char *headers[], int num_headers, const char *data, int expected_status, int timeout, const char *test_file, const char *output_file, int verbose, int no_follow_redirects, int dry_run);

#ifdef __cplusplus
}
#endif

#endif /* BASH_TOOLKIT_H */
