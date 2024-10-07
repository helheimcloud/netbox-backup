#!/bin/bash -l

trap 'handle_error $? $LINENO' ERR

usage() {
    echo "Usage: $0 {backup_database|backup_config|backup_media|backup_reports|backup_scripts|all} [period]"
    echo "period: manual, daily, weekly, monthly, yearly (used for backup/cleanup periods)"
    exit 1
}

handle_error() {
    local exit_code=$1
    local line_number=$2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - Error on line $line_number: Command exited with status $exit_code" | tee -a /var/log/cron.log
    exit 1
}

# Set default period to manual if not provided
period=${2:-manual}
timestamp=$(date +%Y%m%d_%H%M)
shared_backup_folder="$MOUNT_DIR/$period/${BACKUP_PREFIX}_${timestamp}_all"

create_backup_folder() {
    local backup_type=$1
    if [ "$backup_type" = "all" ]; then
        echo "$shared_backup_folder"
    else
        echo "$MOUNT_DIR/$period/${BACKUP_PREFIX}_${timestamp}_${backup_type}"
    fi
}

# Run tasks based on the argument
case "$1" in
    backup_database)
        backup_folder=$(create_backup_folder "database")
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Starting database backup." | tee -a /var/log/cron.log
        /usr/local/bin/backup_database.sh "$period" "$backup_folder"
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Database backup completed." | tee -a /var/log/cron.log
        ;;
    
    backup_config)
        backup_folder=$(create_backup_folder "config")
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Starting config file backup for period: $period." | tee -a /var/log/cron.log
        /usr/local/bin/backup_files.sh config "$period" "$backup_folder"
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Config file backup completed for period: $period." | tee -a /var/log/cron.log
        ;;
    
    backup_media)
        backup_folder=$(create_backup_folder "media")
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Starting media file backup for period: $period." | tee -a /var/log/cron.log
        /usr/local/bin/backup_files.sh media "$period" "$backup_folder"
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Media file backup completed for period: $period." | tee -a /var/log/cron.log
        ;;
    
    backup_reports)
        backup_folder=$(create_backup_folder "reports")
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Starting reports file backup for period: $period." | tee -a /var/log/cron.log
        /usr/local/bin/backup_files.sh reports "$period" "$backup_folder"
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Reports file backup completed for period: $period." | tee -a /var/log/cron.log
        ;;
    
    backup_scripts)
        backup_folder=$(create_backup_folder "scripts")
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Starting scripts file backup for period: $period." | tee -a /var/log/cron.log
        /usr/local/bin/backup_files.sh scripts "$period" "$backup_folder"
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Scripts file backup completed for period: $period." | tee -a /var/log/cron.log
        ;;

    all)
        if [ -z "$period" ]; then
            echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - Backup period not specified. Exiting." | tee -a /var/log/cron.log
            usage
        fi
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Starting all backups for period: $period." | tee -a /var/log/cron.log
        /usr/local/bin/backup_database.sh "$period" "$shared_backup_folder"
        /usr/local/bin/backup_files.sh all "$period" "$shared_backup_folder"
        
        if [ "$period" != "manual" ]; then
            /usr/local/bin/cleanup_old_backups.sh "$period"
        else
            echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Skipping cleanup for manual backups." | tee -a /var/log/cron.log
        fi
        
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - All backups and cleanup completed for period: $period." | tee -a /var/log/cron.log
        ;;
    
    *)
        usage
        ;;
esac