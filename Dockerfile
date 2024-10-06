FROM ubuntu:22.04

# Install required packages
RUN apt-get update && apt-get install -y \
    cron \
    nano \
    rsync \
    pigz \
    wget \
    gnupg \
    lsb-release \
    && wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y postgresql-client-16 \
    && apt-get clean

# Copy all backup scripts
COPY bin/backup_database.sh /usr/local/bin/backup_database.sh
COPY bin/announce_schedule.sh /usr/local/bin/announce_schedule.sh
COPY bin/backup_files.sh /usr/local/bin/backup_files.sh
COPY bin/cleanup_old_backups.sh /usr/local/bin/cleanup_old_backups.sh
COPY bin/netbox-backup.sh /usr/local/bin/netbox-backup.sh
COPY bin/check_health.sh /usr/local/bin/check_health.sh
COPY bin/retry_operation.sh /usr/local/bin/retry_operation.sh
COPY bin/setup_cron.sh /usr/local/bin/setup_cron.sh

RUN chmod +x /usr/local/bin/*.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /usr/local/bin/check_health.sh || exit 1    

# Start cron in the foreground
CMD /usr/local/bin/setup_cron.sh && /usr/local/bin/announce_schedule.sh && cron -f
