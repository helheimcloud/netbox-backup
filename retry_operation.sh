#!/bin/bash -l

retry_operation() {
    local max_attempts=$1
    local delay=$2
    shift 2  # Shift arguments so that the command follows the first two arguments

    local attempt=1
    until "$@" || [ $attempt -eq $max_attempts ]; do
        echo "[WARN] Command failed. Retrying in $delay seconds... (Attempt $attempt/$max_attempts)" | tee -a /var/log/cron.log
        sleep $delay
        attempt=$((attempt + 1))
    done

    if [ $attempt -eq $max_attempts ]; then
        echo "[ERROR] Command failed after $max_attempts attempts." | tee -a /var/log/cron.log
        exit 1
    fi
}
