#!/bin/bash

trap 'handle_error $? $LINENO' ERR

handle_error() {
    local exit_code=$1
    local line_number=$2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - Error on line $line_number: Command exited with status $exit_code" | tee -a /var/log/cron.log
    exit 1
}

cleanup_old_backups() {
    local period=$1
    local backup_type=$2
    local max_backups=$3

    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Cleaning up old ${backup_type} backups for ${period}. Retaining last ${max_backups} backups."

    # Find and delete old backups, keeping only the last $max_backups
    local BACKUP_TEMPDIR="$MOUNT_DIR/$period"
    local dirs=($(find "$BACKUP_TEMPDIR" -maxdepth 1 -type d -name "${BACKUP_PREFIX}_*_${backup_type}_*" -printf '%T@ %p\n' | sort -n | awk '{print $2}'))

    if [ ${#dirs[@]} -gt $max_backups ]; then
        for ((i=0; i<${#dirs[@]} - $max_backups; i++)); do
            rm -rf "${dirs[$i]}"
            echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Deleted old backup: ${dirs[$i]}" | tee -a /var/log/cron.log
        done
    else
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - No backups to delete. Total backups are within the retention limit."
    fi
}

# Cleanup process for different backup periods
run_cleanup_for_period() {
    local period=$1
    local retention_var="RETAIN_${period^^}"
    local max_backups=${!retention_var}

    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Running cleanup for ${period} backups. Retaining the last ${max_backups} backups."

    # Run cleanup for each type of backup
    cleanup_old_backups "$period" "netbox_db" "$max_backups"
    cleanup_old_backups "$period" "configuration" "$max_backups"
    cleanup_old_backups "$period" "media" "$max_backups"
    cleanup_old_backups "$period" "reports" "$max_backups"
    cleanup_old_backups "$period" "scripts" "$max_backups"
}

# Function to clean up all backup periods
run_cleanup_for_all() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Running cleanup for all backup periods."

    run_cleanup_for_period "daily"
    run_cleanup_for_period "weekly"
    run_cleanup_for_period "monthly"
    run_cleanup_for_period "yearly"
}

# Check which period to clean up based on the argument
if [ -z "$1" ]; then
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - Backup period not specified."
    echo "Usage: $0 {daily|weekly|monthly|yearly|all}"
    exit 1
fi

case "$1" in
    daily)
        run_cleanup_for_period "daily"
        ;;
    weekly)
        run_cleanup_for_period "weekly"
        ;;
    monthly)
        run_cleanup_for_period "monthly"
        ;;
    yearly)
        run_cleanup_for_period "yearly"
        ;;
    all)
        run_cleanup_for_all
        ;;
    *)
        echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - Invalid backup period specified: $1"
        echo "Usage: $0 {daily|weekly|monthly|yearly|all}"
        exit 1
        ;;
esac
