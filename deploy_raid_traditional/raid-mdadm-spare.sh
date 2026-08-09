#!/bin/bash
#
# deploy_raid.sh
# Builds a RAID1 array with a hot spare using mdadm, formats it with XFS,
# and mounts it persistently.
#
# Active mirror: /dev/sdb, /dev/sdc
# Hot spare:     /dev/sda
# Not used:      /dev/sdd
#
# Tested on AlmaLinux and Ubuntu.

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Run this as root (or with sudo)."
    exit 1
fi

MOUNT_PATH="/mnt/secure_vault"
RAID_DEVICES="/dev/sdb /dev/sdc"
SPARE_DEVICE="/dev/sda"

echo "[1/4] Installing mdadm and xfsprogs"
if command -v apt &> /dev/null; then
    apt update && apt install -y mdadm xfsprogs
else
    dnf install -y mdadm xfsprogs
fi

echo "[2/4] Wiping target disks and building the array"
umount "$MOUNT_PATH" 2>/dev/null || true
mdadm --stop /dev/md0 2>/dev/null || true

wipefs -a $RAID_DEVICES $SPARE_DEVICE
mdadm --create /dev/md0 --run --level=1 --raid-devices=2 --spare-devices=1 \
    $RAID_DEVICES $SPARE_DEVICE

echo "[3/4] Formatting, mounting, and persisting the config"
mkfs.xfs -f /dev/md0
mkdir -p "$MOUNT_PATH"
mount /dev/md0 "$MOUNT_PATH"
echo "raid1 test file" > "$MOUNT_PATH/vault.txt"

sed -i '/\/dev\/md0/d' /etc/fstab
echo "/dev/md0 $MOUNT_PATH xfs defaults 0 0" >> /etc/fstab

sed -i '/^ARRAY \/dev\/md0/d' /etc/mdadm.conf 2>/dev/null || true
mdadm --detail --scan >> /etc/mdadm.conf

echo "[4/4] Verifying the array"
mdadm --detail /dev/md0 | grep -E "State :|Active Devices :|Spare Devices :"
echo
cat "$MOUNT_PATH/vault.txt"

echo
echo "Done. Array is mounted at $MOUNT_PATH."
echo "To test failover: mdadm --manage /dev/md0 --fail /dev/sdc && cat /proc/mdstat"