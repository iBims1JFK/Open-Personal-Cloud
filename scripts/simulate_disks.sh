#!/bin/bash
# Simulate 3 disks using loopback devices

SIM_DIR="/tmp/cloud_sim"
mkdir -p $SIM_DIR

echo "Creating sparse files for disks..."
truncate -s 1G $SIM_DIR/disk0.img
truncate -s 1G $SIM_DIR/disk1.img
truncate -s 1G $SIM_DIR/parity.img

echo "Setting up loop devices..."
sudo losetup -fP $SIM_DIR/disk0.img
sudo losetup -fP $SIM_DIR/disk1.img
sudo losetup -fP $SIM_DIR/parity.img

# Get the loop device names
LOOP0=$(losetup -j $SIM_DIR/disk0.img | cut -d: -f1)
LOOP1=$(losetup -j $SIM_DIR/disk1.img | cut -d: -f1)
LOOPP=$(losetup -j $SIM_DIR/parity.img | cut -d: -f1)

echo "Formatting disks..."
sudo mkfs.ext4 $LOOP0
sudo mkfs.ext4 $LOOP1
sudo mkfs.ext4 $LOOPP

echo "Disks ready at: $LOOP0, $LOOP1, $LOOPP"
echo "Update ansible/group_vars/all.yml with these devices if you want to test storage.yml"
