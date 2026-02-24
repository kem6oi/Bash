#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#include <sys/wait.h>
#include "../include/bash_toolkit.h"

#define MAX_CMD_LEN 4096

/**
 * Helper to find the absolute path of a script.
 */
static int resolve_script_path(const char *script_rel_path, char *out_path, size_t size) {
    const char *root = getenv("BASH_TOOLKIT_ROOT");

    if (root) {
        snprintf(out_path, size, "%s/%s", root, script_rel_path);
        if (access(out_path, F_OK) == 0) {
            return 0;
        }
    }

    // Check relative to CWD
    snprintf(out_path, size, "./%s", script_rel_path);
    if (access(out_path, F_OK) == 0) {
        return 0;
    }

    // Check relative to parent directory (dev environment)
    snprintf(out_path, size, "../%s", script_rel_path);
    if (access(out_path, F_OK) == 0) {
        return 0;
    }

    return -1;
}

int run_script(const char *script_rel_path, char *const args[], int dry_run) {
    char script_path[PATH_MAX];

    // Resolve script path
    if (resolve_script_path(script_rel_path, script_path, sizeof(script_path)) != 0) {
        if (dry_run) {
            snprintf(script_path, sizeof(script_path), "%s", script_rel_path);
        } else {
            fprintf(stderr, "Error: Script not found: %s\n", script_rel_path);
            return -1;
        }
    }

    // Count arguments
    int argc = 0;
    if (args) {
        while (args[argc] != NULL) argc++;
    }

    // Create argv array: script path + args + NULL
    // +2 for script name (argv[0]) and NULL terminator
    char **argv = malloc((argc + 2) * sizeof(char *));
    if (!argv) {
        perror("malloc");
        return -1;
    }

    argv[0] = script_path;
    if (args) {
        for (int i = 0; i < argc; i++) {
            argv[i + 1] = args[i];
        }
    }
    argv[argc + 1] = NULL;

    if (dry_run) {
        printf("Dry run: ");
        for (int i = 0; argv[i] != NULL; i++) {
            printf("%s ", argv[i]);
        }
        printf("\n");
        free(argv);
        return 0;
    }

    pid_t pid = fork();
    if (pid == -1) {
        perror("fork");
        free(argv);
        return -1;
    } else if (pid == 0) {
        // Child process
        execv(script_path, argv);
        perror("execv");
        free(argv); // Although memory is copied, good practice
        exit(127);
    } else {
        // Parent process
        int status;
        waitpid(pid, &status, 0);
        free(argv);

        if (WIFEXITED(status)) {
            return WEXITSTATUS(status);
        } else {
            return -1;
        }
    }
}
