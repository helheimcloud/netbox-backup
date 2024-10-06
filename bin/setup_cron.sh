#!/bin/bash

ANNOUNCE_OFFSET_MINUTES=${ANNOUNCE_OFFSET_MINUTES:-10}

CRON_FILE="/etc/cron.d/netbox-backup-cron" 

# Clear the cron file
> "$CRON_FILE"

add_cron_job() {
    local cron_schedule=$1
    local backup_command=$2
    echo "$cron_schedule $backup_command" >> "$CRON_FILE"
}

# Function to add announcement jobs based on ANNOUNCE_OFFSET_MINUTES
add_announcement_job() {
    local cron_schedule=$1
    local backup_type=$2
    local job_period=$3  

    # Parse minutes and hours from the cron schedule
    local minute=$(echo "$cron_schedule" | awk '{print $1}')
    local hour=$(echo "$cron_schedule" | awk '{print $2}')

    # Adjust minutes and hours based on the offset
    minute=$((minute - ANNOUNCE_OFFSET_MINUTES))
    if [ "$minute" -lt 0 ]; then
        minute=$((60 + minute))
        hour=$((hour - 1))
    fi

    # Construct the announcement cron schedule
    local announcement_cron="$minute $hour * * *"

    # Translate cron schedule to human-readable time
    local human_readable_time=$(printf "%02d:%02d" "$hour" "$minute")

    # Add the announcement cron job
    add_cron_job "$announcement_cron" "echo \"[INFO] \$(date '+%Y-%m-%d %H:%M:%S') - Upcoming $backup_type backup job at $human_readable_time for $job_period.\" | tee -a /var/log/cron.log"
}

# Add backup and announcement jobs
if [ "$DO_SQL_BACKUP" = "true" ]; then
    add_cron_job "$BACKUP_DATABASE_DAILY_CRON" "/usr/local/bin/netbox-backup.sh backup_database daily | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_DATABASE_DAILY_CRON" "database" "daily"

    add_cron_job "$BACKUP_DATABASE_WEEKLY_CRON" "/usr/local/bin/netbox-backup.sh backup_database weekly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_DATABASE_WEEKLY_CRON" "database" "weekly"

    add_cron_job "$BACKUP_DATABASE_MONTHLY_CRON" "/usr/local/bin/netbox-backup.sh backup_database monthly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_DATABASE_MONTHLY_CRON" "database" "monthly"

    add_cron_job "$BACKUP_DATABASE_YEARLY_CRON" "/usr/local/bin/netbox-backup.sh backup_database yearly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_DATABASE_YEARLY_CRON" "database" "yearly"
fi

# Config backups
if [ "$DO_CONFIG_BACKUP" = "true" ]; then
    add_cron_job "$BACKUP_CONFIG_DAILY_CRON" "/usr/local/bin/netbox-backup.sh backup_files config daily | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_CONFIG_DAILY_CRON" "config" "daily"

    add_cron_job "$BACKUP_CONFIG_WEEKLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files config weekly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_CONFIG_WEEKLY_CRON" "config" "weekly"

    add_cron_job "$BACKUP_CONFIG_MONTHLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files config monthly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_CONFIG_MONTHLY_CRON" "config" "monthly"

    add_cron_job "$BACKUP_CONFIG_YEARLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files config yearly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_CONFIG_YEARLY_CRON" "config" "yearly"
fi

# Media backups
if [ "$DO_MEDIA_BACKUP" = "true" ]; then
    add_cron_job "$BACKUP_MEDIA_DAILY_CRON" "/usr/local/bin/netbox-backup.sh backup_files media daily | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_MEDIA_DAILY_CRON" "media" "daily"

    add_cron_job "$BACKUP_MEDIA_WEEKLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files media weekly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_MEDIA_WEEKLY_CRON" "media" "weekly"

    add_cron_job "$BACKUP_MEDIA_MONTHLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files media monthly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_MEDIA_MONTHLY_CRON" "media" "monthly"

    add_cron_job "$BACKUP_MEDIA_YEARLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files media yearly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_MEDIA_YEARLY_CRON" "media" "yearly"
fi

# Reports backups
if [ "$DO_REPORTS_BACKUP" = "true" ]; then
    add_cron_job "$BACKUP_REPORTS_DAILY_CRON" "/usr/local/bin/netbox-backup.sh backup_files reports daily | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_REPORTS_DAILY_CRON" "reports" "daily"

    add_cron_job "$BACKUP_REPORTS_WEEKLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files reports weekly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_REPORTS_WEEKLY_CRON" "reports" "weekly"

    add_cron_job "$BACKUP_REPORTS_MONTHLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files reports monthly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_REPORTS_MONTHLY_CRON" "reports" "monthly"

    add_cron_job "$BACKUP_REPORTS_YEARLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files reports yearly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_REPORTS_YEARLY_CRON" "reports" "yearly"
fi

# Scripts backups
if [ "$DO_SCRIPTS_BACKUP" = "true" ]; then
    add_cron_job "$BACKUP_SCRIPTS_DAILY_CRON" "/usr/local/bin/netbox-backup.sh backup_files scripts daily | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_SCRIPTS_DAILY_CRON" "scripts" "daily"

    add_cron_job "$BACKUP_SCRIPTS_WEEKLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files scripts weekly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_SCRIPTS_WEEKLY_CRON" "scripts" "weekly"

    add_cron_job "$BACKUP_SCRIPTS_MONTHLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files scripts monthly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_SCRIPTS_MONTHLY_CRON" "scripts" "monthly"

    add_cron_job "$BACKUP_SCRIPTS_YEARLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files scripts yearly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_SCRIPTS_YEARLY_CRON" "scripts" "yearly"
fi

# Add the "all" backup schedule
if [ "$DO_ALL_BACKUP" = "true" ]; then
    add_cron_job "$BACKUP_ALL_DAILY_CRON" "/usr/local/bin/netbox-backup.sh all daily | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_ALL_DAILY_CRON" "all" "daily"

    add_cron_job "$BACKUP_ALL_WEEKLY_CRON" "/usr/local/bin/netbox-backup.sh all weekly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_ALL_WEEKLY_CRON" "all" "weekly"

    add_cron_job "$BACKUP_ALL_MONTHLY_CRON" "/usr/local/bin/netbox-backup.sh all monthly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_ALL_MONTHLY_CRON" "all" "monthly"

    add_cron_job "$BACKUP_ALL_YEARLY_CRON" "/usr/local/bin/netbox-backup.sh all yearly | tee -a /var/log/cron.log"
    add_announcement_job "$BACKUP_ALL_YEARLY_CRON" "all" "yearly"
fi

# Apply correct permissions for the cron file
chmod 0644 "$CRON_FILE"

# Load the cron jobs into the crontab
crontab "$CRON_FILE"