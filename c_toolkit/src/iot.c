#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../include/bash_toolkit.h"

int mqtt_client(const char *topic, const char *mode, const char *broker, int port, const char *message, int qos, int retain, const char *username, const char *password, const char *client_id, const char *output_file, int dry_run) {
    char *args[32];
    int i = 0;

    args[i++] = "-t"; args[i++] = (char *)topic;
    args[i++] = "-m"; args[i++] = (char *)mode;
    args[i++] = "-b"; args[i++] = (char *)broker;

    char port_str[16]; snprintf(port_str, sizeof(port_str), "%d", port);
    args[i++] = "-p"; args[i++] = port_str;

    char qos_str[4]; snprintf(qos_str, sizeof(qos_str), "%d", qos);
    args[i++] = "-q"; args[i++] = qos_str;

    if (strcmp(mode, "publish") == 0) {
        if (!message) return -1;
        args[i++] = "-M"; args[i++] = (char *)message;
        if (retain) args[i++] = "-r";
    }

    if (username) { args[i++] = "-u"; args[i++] = (char *)username; }
    if (password) { args[i++] = "-P"; args[i++] = (char *)password; }
    if (client_id) { args[i++] = "-c"; args[i++] = (char *)client_id; }
    if (output_file) { args[i++] = "-o"; args[i++] = (char *)output_file; }

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/iot/mqtt_helper.sh", args, dry_run);
}

int device_discovery(int scan_time, const char *services[], int num_services, int all_services, int continuous, const char *output_file, int dry_run) {
    char *args[64];
    int i = 0;

    char time_str[16]; snprintf(time_str, sizeof(time_str), "%d", scan_time);
    args[i++] = "-t"; args[i++] = time_str;

    if (services) {
        for (int j = 0; j < num_services; j++) {
            if (i < 60) {
                args[i++] = "-s"; args[i++] = (char *)services[j];
            }
        }
    }

    if (all_services) args[i++] = "-a";
    if (continuous) args[i++] = "-c";
    if (output_file) { args[i++] = "-o"; args[i++] = (char *)output_file; }

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/iot/device_discovery.sh", args, dry_run);
}

int firmware_check(const char *device_type, const char *current_version, const char *update_url, const char *output_file, int dry_run) {
    char *args[16];
    int i = 0;

    args[i++] = "-d"; args[i++] = (char *)device_type;
    args[i++] = "-v"; args[i++] = (char *)current_version;

    if (update_url) { args[i++] = "-u"; args[i++] = (char *)update_url; }
    if (output_file) { args[i++] = "-o"; args[i++] = (char *)output_file; }

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/iot/firmware_checker.sh", args, dry_run);
}

int gpio_control(int pin, const char *action, const char *value, const char *mode, int dry_run) {
    char *args[16];
    int i = 0;

    char pin_str[16]; snprintf(pin_str, sizeof(pin_str), "%d", pin);
    args[i++] = "-p"; args[i++] = pin_str;

    args[i++] = "-a"; args[i++] = (char *)action;
    args[i++] = "-m"; args[i++] = (char *)mode;

    if (strcmp(action, "write") == 0) {
        if (!value) return -1;
        args[i++] = "-v"; args[i++] = (char *)value;
    }

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/iot/gpio_controller.sh", args, dry_run);
}

int serial_monitor(const char *port, int baudrate, const char *output_file, int no_timestamps, int dry_run) {
    char *args[16];
    int i = 0;

    args[i++] = "-p"; args[i++] = (char *)port;

    char baud_str[16]; snprintf(baud_str, sizeof(baud_str), "%d", baudrate);
    args[i++] = "-b"; args[i++] = baud_str;

    if (output_file) { args[i++] = "-o"; args[i++] = (char *)output_file; }
    if (no_timestamps) args[i++] = "-n";

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/iot/serial_monitor.sh", args, dry_run);
}

int traffic_monitor(const char *interface, const char *filter, int packet_count, int duration, const char *output_file, int dry_run) {
    char *args[16];
    int i = 0;

    args[i++] = "-i"; args[i++] = (char *)interface;

    char count_str[16]; snprintf(count_str, sizeof(count_str), "%d", packet_count);
    args[i++] = "-c"; args[i++] = count_str;

    if (filter) { args[i++] = "-f"; args[i++] = (char *)filter; }

    if (duration > 0) {
        char dur_str[16]; snprintf(dur_str, sizeof(dur_str), "%d", duration);
        args[i++] = "-t"; args[i++] = dur_str;
    }

    if (output_file) { args[i++] = "-o"; args[i++] = (char *)output_file; }

    args[i] = NULL;
    return run_script("bash_toolkit/scripts/iot/traffic_monitor.sh", args, dry_run);
}
