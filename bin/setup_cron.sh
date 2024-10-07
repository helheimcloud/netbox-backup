#!/bin/bash -l

ANNOUNCE_OFFSET_MINUTES=${ANNOUNCE_OFFSET_MINUTES:-10}

CRON_FILE="/etc/cron.d/netbox-backup-cron" 

# Clear the cron file
> "$CRON_FILE"

add_cron_job() {
    local cron_schedule=$1
    local backup_command=$2
    # Redirect output to both cron.log and Docker logs (stdout)
    echo "$cron_schedule $backup_command >> /var/log/cron.log 2>&1 | tee /proc/1/fd/1" >> "$CRON_FILE"
}

# Function to add announcement jobs based on ANNOUNCE_OFFSET_MINUTES
add_announcement_job() {
    local cron_schedule=$1
    local backup_type=$2
    local job_period=$3  

    # Parse minutes and hours from the cron schedule
    local minute=$(echo "$cron_schedule" | awk '{print $1}')
    local hour=$(echo "$cron_schedule" | awk '{print $2}')

    # Check if minute is a numeric value or not
    if [[ "$minute" =~ ^[0-9]+$ ]]; then
        # Adjust minutes and hours based on the offset if its a number
        minute=$((minute - ANNOUNCE_OFFSET_MINUTES))
        if [ "$minute" -lt 0 ]; then
            minute=$((60 + minute))
            hour=$((hour - 1))
        fi
    fi

    # Construct the announcement cron schedule
    local announcement_cron="$minute $hour * * *"

    # Translate cron schedule to human readable time
    local human_readable_time
    if [[ "$minute" =~ ^[0-9]+$ ]]; then
        human_readable_time=$(printf "%02d:%02d" "$hour" "$minute")
    else
        # If its not a number, just use the original value
        human_readable_time="*/$minute"
    fi

    # Add the announcement cron job
    add_cron_job "$announcement_cron" "echo \"[INFO] \$(date '+%Y-%m-%d %H:%M:%S') - Upcoming $backup_type backup job at $human_readable_time for $job_period.\" 2>&1 | tee -a /var/log/cron.log > /proc/1/fd/1"
}


# Add backup and announcement jobs
if [ "$DO_SQL_BACKUP" = "true" ]; then
    add_cron_job "$BACKUP_DATABASE_DAILY_CRON" "/usr/local/bin/netbox-backup.sh backup_database daily"
    add_announcement_job "$BACKUP_DATABASE_DAILY_CRON" "database" "daily"

    add_cron_job "$BACKUP_DATABASE_WEEKLY_CRON" "/usr/local/bin/netbox-backup.sh backup_database weekly"
    add_announcement_job "$BACKUP_DATABASE_WEEKLY_CRON" "database" "weekly"

    add_cron_job "$BACKUP_DATABASE_MONTHLY_CRON" "/usr/local/bin/netbox-backup.sh backup_database monthly"
    add_announcement_job "$BACKUP_DATABASE_MONTHLY_CRON" "database" "monthly"

    add_cron_job "$BACKUP_DATABASE_YEARLY_CRON" "/usr/local/bin/netbox-backup.sh backup_database yearly"
    add_announcement_job "$BACKUP_DATABASE_YEARLY_CRON" "database" "yearly"
fi

# Config backups
if [ "$DO_CONFIG_BACKUP" = "true" ]; then
    add_cron_job "$BACKUP_CONFIG_DAILY_CRON" "/usr/local/bin/netbox-backup.sh backup_files config daily"
    add_announcement_job "$BACKUP_CONFIG_DAILY_CRON" "config" "daily"

    add_cron_job "$BACKUP_CONFIG_WEEKLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files config weekly"
    add_announcement_job "$BACKUP_CONFIG_WEEKLY_CRON" "config" "weekly"

    add_cron_job "$BACKUP_CONFIG_MONTHLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files config monthly"
    add_announcement_job "$BACKUP_CONFIG_MONTHLY_CRON" "config" "monthly"

    add_cron_job "$BACKUP_CONFIG_YEARLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files config yearly"
    add_announcement_job "$BACKUP_CONFIG_YEARLY_CRON" "config" "yearly"
fi

# Media backups
if [ "$DO_MEDIA_BACKUP" = "true" ]; then
    add_cron_job "$BACKUP_MEDIA_DAILY_CRON" "/usr/local/bin/netbox-backup.sh backup_files media daily"
    add_announcement_job "$BACKUP_MEDIA_DAILY_CRON" "media" "daily"

    add_cron_job "$BACKUP_MEDIA_WEEKLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files media weekly"
    add_announcement_job "$BACKUP_MEDIA_WEEKLY_CRON" "media" "weekly"

    add_cron_job "$BACKUP_MEDIA_MONTHLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files media monthly"
    add_announcement_job "$BACKUP_MEDIA_MONTHLY_CRON" "media" "monthly"

    add_cron_job "$BACKUP_MEDIA_YEARLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files media yearly"
    add_announcement_job "$BACKUP_MEDIA_YEARLY_CRON" "media" "yearly"
fi

# Reports backups
if [ "$DO_REPORTS_BACKUP" = "true" ]; then
    add_cron_job "$BACKUP_REPORTS_DAILY_CRON" "/usr/local/bin/netbox-backup.sh backup_files reports daily"
    add_announcement_job "$BACKUP_REPORTS_DAILY_CRON" "reports" "daily"

    add_cron_job "$BACKUP_REPORTS_WEEKLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files reports weekly"
    add_announcement_job "$BACKUP_REPORTS_WEEKLY_CRON" "reports" "weekly"

    add_cron_job "$BACKUP_REPORTS_MONTHLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files reports monthly"
    add_announcement_job "$BACKUP_REPORTS_MONTHLY_CRON" "reports" "monthly"

    add_cron_job "$BACKUP_REPORTS_YEARLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files reports yearly"
    add_announcement_job "$BACKUP_REPORTS_YEARLY_CRON" "reports" "yearly"
fi

# Scripts backups
if [ "$DO_SCRIPTS_BACKUP" = "true" ]; then
    add_cron_job "$BACKUP_SCRIPTS_DAILY_CRON" "/usr/local/bin/netbox-backup.sh backup_files scripts daily"
    add_announcement_job "$BACKUP_SCRIPTS_DAILY_CRON" "scripts" "daily"

    add_cron_job "$BACKUP_SCRIPTS_WEEKLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files scripts weekly"
    add_announcement_job "$BACKUP_SCRIPTS_WEEKLY_CRON" "scripts" "weekly"

    add_cron_job "$BACKUP_SCRIPTS_MONTHLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files scripts monthly"
    add_announcement_job "$BACKUP_SCRIPTS_MONTHLY_CRON" "scripts" "monthly"

    add_cron_job "$BACKUP_SCRIPTS_YEARLY_CRON" "/usr/local/bin/netbox-backup.sh backup_files scripts yearly"
    add_announcement_job "$BACKUP_SCRIPTS_YEARLY_CRON" "scripts" "yearly"
fi

# Add the "all" backup schedule
if [ "$DO_ALL_BACKUP" = "true" ]; then
    add_cron_job "$BACKUP_ALL_DAILY_CRON" "/usr/local/bin/netbox-backup.sh all daily"
    add_announcement_job "$BACKUP_ALL_DAILY_CRON" "all" "daily"

    add_cron_job "$BACKUP_ALL_WEEKLY_CRON" "/usr/local/bin/netbox-backup.sh all weekly"
    add_announcement_job "$BACKUP_ALL_WEEKLY_CRON" "all" "weekly"

    add_cron_job "$BACKUP_ALL_MONTHLY_CRON" "/usr/local/bin/netbox-backup.sh all monthly"
    add_announcement_job "$BACKUP_ALL_MONTHLY_CRON" "all" "monthly"

    add_cron_job "$BACKUP_ALL_YEARLY_CRON" "/usr/local/bin/netbox-backup.sh all yearly"
    add_announcement_job "$BACKUP_ALL_YEARLY_CRON" "all" "yearly"
fi

# Apply correct permissions for the cron file
chmod 0644 "$CRON_FILE"

# Load the cron jobs into the crontab
crontab "$CRON_FILE"
