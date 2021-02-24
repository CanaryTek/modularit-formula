#!/bin/bash
# Create BTRFS snapshots for backup volumes

# Number of snapshots to keep
KEEP="5"

# Subvolumes
VOLUMES="/dat/bck/Backups /dat/bck/Volcados"

# LOG
LOG="/var/log/snapshots.log"

echo "** $(date)" > $LOG

for volume in $VOLUMES; do
	# Get data
	base=$(dirname $volume)
	name=$(basename $volume)
	timestamp=$(date +"%Y%m%d_%H%M%S")
	snapdir="${base}/.snapshots"
	
	# Create snapshot dir if needed
	test -d snapdir || mkdir -p $snapdir

	# Create snapshot
	btrfs sub snap -r ${base}/${name} ${snapdir}/${name}-${timestamp} >> ${LOG} 2>&1

	# Delete old snapshots
	for snap in $(ls ${base}/.snapshots | grep ${name} | sort | head -n-${KEEP}); do
		btrfs sub delete ${base}/.snapshots/${snap} >> ${LOG} 2>&1
	done
done

