#!/bin/bash -l

source /usr/local/bin/retry_operation.sh

trap 'handle_error $? $LINENO' ERR

handle_error() {
    local exit_code=$1
    local line_number=$2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - Error on line $line_number: Command exited with status $exit_code" | tee -a /var/log/cron.log
    exit 1
}

backup_database() {
    local backup_period=$1
    local shared_backup_folder=$2
    local backup_folder="${shared_backup_folder:-$MOUNT_DIR/$backup_period/${BACKUP_PREFIX}_${timestamp}_${file_type}}"  
    mkdir -p "$backup_folder" 
    
    local timestamp=$(date +%Y%m%d_%H%M)
    local backup_file="${BACKUP_PREFIX}_${timestamp}_netbox_db.sql.gz"
    
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Starting database backup." | tee -a /var/log/cron.log
    mkdir -p "$shared_backup_folder"

    if PGPASSWORD="$POSTGRES_PASSWORD" pg_dump -Fc \
        --username "$POSTGRES_USER" \
        --host "$POSTGRES_HOST" \
        --port "$POSTGRES_PORT" \
        --dbname "$POSTGRES_DB" | gzip > "$BACKUP_TEMPDIR/$backup_file"; then
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Database backup completed successfully: $BACKUP_TEMPDIR/$backup_file" | tee -a /var/log/cron.log
        validate_backup "$BACKUP_TEMPDIR/$backup_file"
        
        retry_operation 3 5 rsync -avh --progress "$BACKUP_TEMPDIR/$backup_file" "$backup_folder/"
        echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - Database backup copied to SMB in $backup_folder." | tee -a /var/log/cron.log
    else
        echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - Database backup failed." | tee -a /var/log/cron.log
        exit 1
    fi
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

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - Backup period or shared folder not specified."
    echo "Usage: $0 {manual|daily|weekly|monthly} shared_backup_folder"
    exit 1
fi

# Call the backup function with the backup period and shared folder
backup_database "$1" "$2"