#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo " Error: This production script must be run as root." >&2
  exit 1
fi

VG="ubuntu-vg"
VG_FREE=$(vgs | awk 'NR==2 {print $7}')
LV="db-lv"

echo "   Checking Volume Group space availability..."
echo "1. Volume Group with $VG_FREE free space..."
echo "2. Starting Live Storage Expansion..."

echo "====================================="

echo "3. Safely executing live online filesystem expansion..."
lvextend -l +100%FREE /dev/$VG/$LV --resizefs

#Creating a PV newly with extension 
#DISK="/dev/sda3"
#VG="ubuntu-vg"
#LV="db-lv"

#echo "   Starting Live Storage Expansion..."
#echo "1. Initializing Physical Volume on $DISK..."
#pvcreate "$DISK"

#echo "2. Extending Volume Group $VG..."
#vgextend "$VG" "$DISK"

#echo "3. Safely executing live online filesystem expansion..."
#lvextend -l +100%FREE /dev/$VG/$LV --resizefs

#echo "Success! Storage expanded with zero downtime."
#df -h /dev/mapper/${VG}-${LV}