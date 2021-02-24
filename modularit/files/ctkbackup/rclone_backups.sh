#!/bin/bash
# Rclone Backups to cloud

# rclone backend
BACKEND="azbackups:test/ctkbackups2"

# Subvolumes
VOLUMES="/dat/bck/Backups /dat/bck/Volcados"

# LOG
LOG="/var/log/rclone.log"

echo "** $(date)" > $LOG

for volume in $VOLUMES; do
	# rclone
	name=$(basename ${volume})
	rclone sync -v ${volume} ${BACKEND}/${name} >$LOG 2>&1
done

