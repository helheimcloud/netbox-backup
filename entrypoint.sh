#!/bin/bash

# Output the environment variables to /etc/environment so that cron can access them
printenv | grep -v "no_proxy" >> /etc/environment

/usr/local/bin/setup_cron.sh

/usr/local/bin/announce_schedule.sh

cron -f