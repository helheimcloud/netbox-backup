# netbox-backup for netbox-docker

`netbox-backup` is a specialized container designed to integrate seamlessly into the official `netbox-docker` stack. It automates backups for the NetBox database, configuration files, media, reports, and scripts, supporting periodic schedules (daily, weekly, monthly, yearly) as well as manual execution.

## Features

- **Backup types**: Netbox Database, configuration files, media, reports, and scripts.
- **Automated scheduling**: Supports daily, weekly, monthly, and yearly backups using cron jobs configurable via environmental variables.
- **Crontabs announcements**: The configured cronjobs get translated to a human readable format and then announced when the container starts. (e.g. bbackup_database scheduled at 05:00 every day @ Weekday: Monday.)
- **Manual execution**: All backup tasks can also be run manually.
- **Configurable storage**: Backup files can be stored on a mounted volume (e.g., network shares).

## Requirements

- **NetBox Docker**: This setup integrates into an existing netbox-docker stack.
- **SMB or NFS mount**: A mounted volume on the host system where backups will be stored.

## Installation Guide

### 1. Clone this repository

Clone this repository into your existing netbox-docker folder. 

```bash
cd /path/to/netbox-docker
git clone https://github.com/yourusername/netbox-backup
cd netbox-backup
```
### 2. Dockerfile

The provided `Dockerfile` is set up to build a Docker image containing all the backup scripts and utilities needed.

### 3. docker-compose.override.yml

To integrate the backup container into the existing netbox-docker stack, include the following in your `docker-compose.override.yml`.

```yaml
version: '3.4'
services:
## This enables the netbox-backup service and adds it to the netbox-docker stack.   
  netbox-backup:
      build: context: ./netbox-backup
      container_name: netbox-backup
      env_file:
        - netbox-backup/env/netbox-backup.env
      # Make sure to match the volumes below with your environment. 
      volumes:
        - /opt/backup/netbox:/opt/backup/netbox
        - /mnt/smb_backup:/mnt/smb_backup
        - netbox-media-files:/opt/netbox/netbox/media
        - netbox-reports-files:/opt/netbox/netbox/reports
        - netbox-scripts-files:/opt/netbox/netbox/scripts
        - ./configuration:/opt/netbox/netbox/configuration 
      depends_on:
        - postgres # Name of postgres in docker compose stack. Default: postgres
      restart: unless-stopped
 ```     

### 4. Configure Environment Variables

In the `env/netbox-backup.env` file, configure the necessary environment variables such as Postgres credentials, backup directories, and cron schedules. 

### 5. Start the Backup Service

Once the backup container is integrated into the NetBox Docker stack, start the containers with:

```bash
docker-compose up -d
```

### Environment Variables Explained

- **PostgreSQL Database Configuration:**
    
    - `POSTGRES_USER`: Username for the PostgreSQL database.
    - `POSTGRES_PASSWORD`: Password for the PostgreSQL database.
    - `POSTGRES_DB`: Name of the NetBox database.
    - `POSTGRES_HOST`: Hostname or IP address of the PostgreSQL server.
    - `POSTGRES_PORT`: Port for the PostgreSQL connection.
- **Backup Directory Configuration:**
    
    - `MOUNT_DIR`: The host directory where backups will be stored (mounted inside the container).
    - `BACKUP_TEMPDIR`: Temporary directory inside the container for holding backups before moving them to `MOUNT_DIR`.
    - `BACKUP_PREFIX`: Prefix for naming your backup files, useful for distinguishing between different NetBox instances.
- **Backup Type Flags:**
    
    - `DO_SQL_BACKUP`: Set to `true` to enable database backups.
    - `DO_CONFIG_BACKUP`: Set to `true` to enable configuration file backups.
    - `DO_MEDIA_BACKUP`: Set to `true` to enable media file backups.
    - `DO_REPORTS_BACKUP`: Set to `true` to enable reports backups.
    - `DO_SCRIPTS_BACKUP`: Set to `true` to enable scripts backups.

#### Cron Schedule Configuration for Announcement, Backups and Cleanup:
    
- **Database Backup Schedules:**

	- `BACKUP_DATABASE_DAILY_CRON`: Cron schedule for daily database backups.
	- `BACKUP_DATABASE_WEEKLY_CRON`: Cron schedule for weekly database backups.
	- `BACKUP_DATABASE_MONTHLY_CRON`: Cron schedule for monthly database backups.
	- `BACKUP_DATABASE_YEARLY_CRON`: Cron schedule for yearly database backups.

- **File Backup Schedules (Config, Media, Reports, Scripts):**

	- `BACKUP_CONFIG_DAILY_CRON`: Cron schedule for daily config backups.
	    
	- `BACKUP_CONFIG_WEEKLY_CRON`: Cron schedule for weekly config backups.
	    
	- `BACKUP_CONFIG_MONTHLY_CRON`: Cron schedule for monthly config backups.
	    
	- `BACKUP_CONFIG_YEARLY_CRON`: Cron schedule for yearly config backups.
	    
	- `BACKUP_MEDIA_DAILY_CRON`: Cron schedule for daily media backups.
	    
	- `BACKUP_MEDIA_WEEKLY_CRON`: Cron schedule for weekly media backups.
	    
	- `BACKUP_MEDIA_MONTHLY_CRON`: Cron schedule for monthly media backups.
	    
	- `BACKUP_MEDIA_YEARLY_CRON`: Cron schedule for yearly media backups.
	    
	- `BACKUP_REPORTS_DAILY_CRON`: Cron schedule for daily reports backups.
	    
	- `BACKUP_REPORTS_WEEKLY_CRON`: Cron schedule for weekly reports backups.
	    
	- `BACKUP_REPORTS_MONTHLY_CRON`: Cron schedule for monthly reports backups.
	    
	- `BACKUP_REPORTS_YEARLY_CRON`: Cron schedule for yearly reports backups.
	    
	- `BACKUP_SCRIPTS_DAILY_CRON`: Cron schedule for daily scripts backups.
	    
	- `BACKUP_SCRIPTS_WEEKLY_CRON`: Cron schedule for weekly scripts backups.
	    
	- `BACKUP_SCRIPTS_MONTHLY_CRON`: Cron schedule for monthly scripts backups.
	    
	- `BACKUP_SCRIPTS_YEARLY_CRON`: Cron schedule for yearly scripts backups.
	    

- **Cleanup Job Schedules:**

	- `CLEANUP_DAILY_CRON`: Cron schedule for daily cleanup jobs.
	- `CLEANUP_WEEKLY_CRON`: Cron schedule for weekly cleanup jobs.
	- `CLEANUP_MONTHLY_CRON`: Cron schedule for monthly cleanup jobs.
	- `CLEANUP_YEARLY_CRON`: Cron schedule for yearly cleanup jobs.
- **Announcement Configuration:**
    
    - `ANNOUNCE_OFFSET_MINUTES`: Number of minutes before a scheduled backup when an announcement should be logged (e.g., a log entry of an upcoming job).

## Command Overview

### Database Backup

Run database backups for different periods:

```bash
netbox-backup.sh backup_database daily
netbox-backup.sh backup_database weekly
netbox-backup.sh backup_database monthly
netbox-backup.sh backup_database yearly
netbox-backup.sh backup_database manual
```

### Config File Backup

Run configuration file backups for different periods:

```bash
netbox-backup.sh backup_config daily
netbox-backup.sh backup_config weekly
netbox-backup.sh backup_config monthly
netbox-backup.sh backup_config yearly
netbox-backup.sh backup_config manual
```

### Media File Backup

Run media file backups for different periods:

```bash
netbox-backup.sh backup_media daily
netbox-backup.sh backup_media weekly
netbox-backup.sh backup_media monthly
netbox-backup.sh backup_media yearly
netbox-backup.sh backup_media manual
```

### Reports File Backup

Run reports file backups for different periods:

```bash
netbox-backup.sh backup_reports daily
netbox-backup.sh backup_reports weekly
netbox-backup.sh backup_reports monthly
netbox-backup.sh backup_reports yearly
netbox-backup.sh backup_reports manual
```

### Scripts File Backup

Run scripts file backups for different periods:

```bash
netbox-backup.sh backup_scripts daily
netbox-backup.sh backup_scripts weekly
netbox-backup.sh backup_scripts monthly
netbox-backup.sh backup_scripts yearly
netbox-backup.sh backup_scripts manual
```

### Cleanup

Run cleanup for old backups based on the specified period:

```bash
netbox-backup.sh cleanup daily
netbox-backup.sh cleanup weekly
netbox-backup.sh cleanup monthly
netbox-backup.sh cleanup yearly
netbox-backup.sh cleanup manual
```

### Run All Backups and Cleanup

Run all backups (database + files) and perform cleanup:

```bash
netbox-backup.sh all daily
netbox-backup.sh all weekly
netbox-backup.sh all monthly
netbox-backup.sh all yearly
netbox-backup.sh all manual
```

