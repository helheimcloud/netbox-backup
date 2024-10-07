#!/bin/bash -l

FILES_BACKUP_CONFIG="${FILES_BACKUP_CONFIG:-/opt/netbox/netbox/configuration}"
FILES_BACKUP_MEDIA="${FILES_BACKUP_MEDIA:-/opt/netbox/netbox/media}"
FILES_BACKUP_REPORTS="${FILES_BACKUP_REPORTS:-/opt/netbox/netbox/reports}"
FILES_BACKUP_SCRIPTS="${FILES_BACKUP_SCRIPTS:-/opt/netbox/netbox/scripts}"

source /usr/local/bin/retry_operation.sh

trap 'handle_error $? $LINENO' ERR

usage() {
    echo "Usage: $0 {config|media|reports|scripts|all} [period] [shared_backup_folder]"
    echo "period: manual, daily, weekly, monthly, yearly (used for backup/cleanup periods)"
    exit 1
}

handle_error() {
    local exit_code=$1
    local line_number=$2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - Error on line $line_number: Command exited with status $exit_code" | tee -a /var/log/cron.log
    exit 1
}

validate_backup() {
    local backup_file=$1
    if gzip -t "$backup_file"; then
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Backup file is valid: $backup_file" | tee -a /var/log/cron.log
    else
        echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - Backup file is corrupted: $backup_file" | tee -a /var/log/cron.log
        exit 1
    fi
}

backup_files() {
    local file_type=$1
    local src_path=$2
    local backup_period=$3
    local shared_backup_folder=$4
    
    local backup_folder="${shared_backup_folder:-$MOUNT_DIR/$backup_period/${BACKUP_PREFIX}_${timestamp}_${file_type}}"  
    mkdir -p "$backup_folder" 

    local timestamp=$(date +%Y%m%d_%H%M)
    mkdir -p "$shared_backup_folder"

    if [ ! -d "$src_path" ] || [ -z "$(ls -A "$src_path")" ]; then
        echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - Source path for ${file_type} is either missing or empty: $src_path" | tee -a /var/log/cron.log
        return 1
    fi

    local backup_file="${BACKUP_PREFIX}_${timestamp}_${file_type}.tar.gz"
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Starting ${file_type} backup." | tee -a /var/log/cron.log

    if tar -cpzf "$BACKUP_TEMPDIR/$backup_file" -C "$(dirname "$src_path")" "$(basename "$src_path")"; then
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - ${file_type} backup completed successfully: $BACKUP_TEMPDIR/$backup_file" | tee -a /var/log/cron.log
        validate_backup "$BACKUP_TEMPDIR/$backup_file"

        retry_operation 3 5 rsync -avh --progress "$BACKUP_TEMPDIR/$backup_file" "$backup_folder/"
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - ${file_type} backup copied to SMB in $backup_folder." | tee -a /var/log/cron.log
    else
        echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - ${file_type} backup failed." | tee -a /var/log/cron.log
        exit 1
    fi
}

# Determine if this is a manual backup or a cron job
backup_period=${2:-manual}
shared_backup_folder=$3

# Run tasks based on the argument
case "$1" in
    config)
        backup_files "configuration" "$FILES_BACKUP_CONFIG" "$backup_period" "$shared_backup_folder"
        ;;
    media)
        backup_files "media" "$FILES_BACKUP_MEDIA" "$backup_period" "$shared_backup_folder"
        ;;
    reports)
        backup_files "reports" "$FILES_BACKUP_REPORTS" "$backup_period" "$shared_backup_folder"
        ;;
    scripts)
        backup_files "scripts" "$FILES_BACKUP_SCRIPTS" "$backup_period" "$shared_backup_folder"
        ;;
    all)
        backup_files "configuration" "$FILES_BACKUP_CONFIG" "$backup_period" "$shared_backup_folder"
        backup_files "media" "$FILES_BACKUP_MEDIA" "$backup_period" "$shared_backup_folder"
        backup_files "reports" "$FILES_BACKUP_REPORTS" "$backup_period" "$shared_backup_folder"
        backup_files "scripts" "$FILES_BACKUP_SCRIPTS" "$backup_period" "$shared_backup_folder"
        ;;
    *)
        usage
        ;;
esac