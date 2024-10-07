#!/bin/bash

# Check if cron service is running
if ! pgrep cron > /dev/null; then
  echo "ERROR: Cron is not running"
  exit 1
fi

# Check if the cron log file exists
LOG_FILE="/var/log/cron.log"
if [ ! -f "$LOG_FILE" ]; then
  echo "ERROR: Cron log file not found"
  exit 1
fi

echo "Cron is running. Last few cron logs:"
tail -n 5 "$LOG_FILE"
