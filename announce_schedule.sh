#!/bin/bash -l

CRON_FILE="/etc/cron.d/netbox-backup-cron" 

# Function to zero-pad minutes and hours for better formatting
zero_pad() {
    local value="$1"
    
    # added handle for special cases in cron expressions
    if [[ "$value" == "*" ]] || [[ "$value" == */* ]]; then
        echo "$value"
    else
        printf "%02d" "$value"
    fi
}


# Function to log the cron schedule grouped by period
log_cron_schedule() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - The following NetBox backup and cleanup cron jobs are scheduled:" | tee -a /var/log/cron.log

    if [ -f "$CRON_FILE" ]; then
        # Create a temporary file to capture the jobs
        tmp_jobs_file=$(mktemp)

        # Read the cron file and parse the schedule
        grep -E "netbox-backup.sh|cleanup" "$CRON_FILE" | while read -r line; do
            # Extract the cron time part and the job type
            cron_time=$(echo "$line" | awk '{print $1, $2, $3, $4, $5}')
            
            if echo "$line" | grep -q "backup_files"; then
                # Extract backup subtype for backup_files
                subtype=$(echo "$line" | grep -oE "(config|media|reports|scripts)" || echo "Unknown")
                job_type="backup_files ($subtype)"
            elif echo "$line" | grep -q "cleanup"; then
                job_type="cleanup"
            else
                job_type=$(echo "$line" | grep -oE "(backup_database|all)" || echo "Unknown")
            fi

            # Translate the cron time to a readable format
            readable_time=$(translate_cron_time "$cron_time")
            
            # Group the jobs based on period in the command
            if echo "$line" | grep -q "daily"; then
                echo "daily|    • $job_type scheduled at $readable_time" >> "$tmp_jobs_file"
            elif echo "$line" | grep -q "weekly"; then
                echo "weekly|    • $job_type scheduled at $readable_time" >> "$tmp_jobs_file"
            elif echo "$line" | grep -q "monthly"; then
                echo "monthly|    • $job_type scheduled at $readable_time" >> "$tmp_jobs_file"
            elif echo "$line" | grep -q "yearly"; then
                echo "yearly|    • $job_type scheduled at $readable_time" >> "$tmp_jobs_file"
            elif echo "$line" | grep -q "cleanup"; then
                echo "cleanup|    • $job_type scheduled at $readable_time" >> "$tmp_jobs_file"    
            fi
        done

        # Print grouped jobs by period
        if grep -q "daily" "$tmp_jobs_file"; then
            echo -e "\n[INFO] === DAILY BACKUPS ===" | tee -a /var/log/cron.log
            grep "daily" "$tmp_jobs_file" | cut -d'|' -f2 | tee -a /var/log/cron.log
        fi

        if grep -q "weekly" "$tmp_jobs_file"; then
            echo -e "\n[INFO] === WEEKLY BACKUPS ===" | tee -a /var/log/cron.log
            grep "weekly" "$tmp_jobs_file" | cut -d'|' -f2 | tee -a /var/log/cron.log
        fi

        if grep -q "monthly" "$tmp_jobs_file"; then
            echo -e "\n[INFO] === MONTHLY BACKUPS ===" | tee -a /var/log/cron.log
            grep "monthly" "$tmp_jobs_file" | cut -d'|' -f2 | tee -a /var/log/cron.log
        fi

        if grep -q "yearly" "$tmp_jobs_file"; then
            echo -e "\n[INFO] === YEARLY BACKUPS ===" | tee -a /var/log/cron.log
            grep "yearly" "$tmp_jobs_file" | cut -d'|' -f2 | tee -a /var/log/cron.log
        fi

        # Cleanups section
        if grep -q "cleanup" "$tmp_jobs_file"; then
            echo -e "\n[INFO] === CLEANUP JOBS ===" | tee -a /var/log/cron.log
            grep "cleanup" "$tmp_jobs_file" | cut -d'|' -f2 | tee -a /var/log/cron.log
        fi

        # Remove the temp file
        rm "$tmp_jobs_file"
    else
        echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - Cron file not found: $CRON_FILE" | tee -a /var/log/cron.log
    fi
}

translate_cron_time() {
    local cron_time="$1"

    # Split the cron fields (minute, hour, day of month, month, day of week)
    minute=$(echo "$cron_time" | awk '{print $1}')
    hour=$(echo "$cron_time" | awk '{print $2}')
    day_of_month=$(echo "$cron_time" | awk '{print $3}')
    month=$(echo "$cron_time" | awk '{print $4}')
    day_of_week=$(echo "$cron_time" | awk '{print $5}')

    # Handle minute
    if [[ "$minute" == "*" ]]; then
        readable_minute="00"
    elif [[ "$minute" == */* ]]; then
        interval=$(echo "$minute" | cut -d'/' -f2)
        readable_minute="every $interval minutes"
    else
        readable_minute=$(zero_pad "$minute")
    fi

    # Handle hour
    if [[ "$hour" == "*" ]]; then
        readable_hour="every hour"
    else
        readable_hour=$(zero_pad "$hour")
    fi

    # Translate day of month
    if [[ "$day_of_month" == "*" ]]; then
        readable_day_of_month="every day"
    else
        readable_day_of_month="on $day_of_month"
    fi

    # Translate month
    case "$month" in
        1) readable_month="January" ;;
        2) readable_month="February" ;;
        3) readable_month="March" ;;
        4) readable_month="April" ;;
        5) readable_month="May" ;;
        6) readable_month="June" ;;
        7) readable_month="July" ;;
        8) readable_month="August" ;;
        9) readable_month="September" ;;
        10) readable_month="October" ;;
        11) readable_month="November" ;;
        12) readable_month="December" ;;
        *) readable_month="" ;;
    esac

    # Translate day of week
    case "$day_of_week" in
        1) readable_day_of_week="Monday" ;;
        2) readable_day_of_week="Tuesday" ;;
        3) readable_day_of_week="Wednesday" ;;
        4) readable_day_of_week="Thursday" ;;
        5) readable_day_of_week="Friday" ;;
        6) readable_day_of_week="Saturday" ;;
        7) readable_day_of_week="Sunday" ;;
        *) readable_day_of_week="every day" ;;
    esac

    # Return the final readable format
    echo "$readable_hour:$readable_minute $readable_day_of_month $readable_month @ Weekday: $readable_day_of_week."
}

log_cron_schedule