#!/bin/bash
set -e

# 1. Start Test Environment
echo "Starting test environment..."
sudo docker compose -f tests/docker-compose.test.yml down -v # Clean up old state
sudo docker compose -f tests/docker-compose.test.yml up -d --build

# 2. Wait for systemd
echo "Waiting for systemd to settle..."
sleep 5

# 3. Simulate Disks inside the container
echo "Creating loop devices inside container..."
sudo docker exec opc_test_node bash -c "mkdir -p /tmp/cloud_sim"
sudo docker exec opc_test_node bash -c "truncate -s 1G /tmp/cloud_sim/disk0.img"
sudo docker exec opc_test_node bash -c "truncate -s 1G /tmp/cloud_sim/disk1.img"
sudo docker exec opc_test_node bash -c "truncate -s 1G /tmp/cloud_sim/parity.img"

# Use losetup
# Note: In DinD, loop devices might share host namespace if not carefully isolated, but privileged container should handle it.
# We create them and parse their output to update inventory variables if needed.
# For simplicity, we assume /dev/loop0, /dev/loop1 etc if no other loops are used.
# But better to be robust.

SETUP_SCRIPT=$(cat <<EOF
losetup -fP /tmp/cloud_sim/disk0.img
losetup -fP /tmp/cloud_sim/disk1.img
losetup -fP /tmp/cloud_sim/parity.img
losetup -a
mkfs.ext4 /dev/loop0
mkfs.ext4 /dev/loop1
mkfs.ext4 /dev/loop2
EOF
)

# Pass script to docker exec safely
sudo docker exec opc_test_node bash -c "losetup -fP /tmp/cloud_sim/disk0.img"
sudo docker exec opc_test_node bash -c "losetup -fP /tmp/cloud_sim/disk1.img"
sudo docker exec opc_test_node bash -c "losetup -fP /tmp/cloud_sim/parity.img"
sudo docker exec opc_test_node bash -c "mkfs.ext4 /dev/loop0 || true"
sudo docker exec opc_test_node bash -c "mkfs.ext4 /dev/loop1 || true"
sudo docker exec opc_test_node bash -c "mkfs.ext4 /dev/loop2 || true"

# 4. Run Ansible
echo "Running Ansible Playbook..."
# We run ansible from the host, connecting to the container via 'docker' plugin.
# We need to install 'docker' python library if not present? No, 'docker' connection uses `docker exec`.
# But we need 'community.docker' collection? The 'docker' connection is built-in.

export ANSIBLE_HOST_KEY_CHECKING=False

# Run against test inventory
sudo ansible-playbook -i tests/inventory.yml ansible/site.yml --extra-vars "storage_disks=['/dev/loop0','/dev/loop1'] storage_parity_disk='/dev/loop2' storage_parity_mount='/mnt/parity' storage_mount_point='/mnt/storage' storage_pool_point='/mnt/pool' ansible_become_pass='test' wireguard_port=51820 domain=local.test" --connection=docker --user=root

# 5. Verify Infrastructure
echo "Verifying services..."
sudo docker exec opc_test_node systemctl status docker --no-pager
sudo docker exec opc_test_node mount | grep mergerfs

# 6. Deploy Application Stack
echo "Deploying Application Stack..."
# Copy docker configs to test node
sudo docker cp docker opc_test_node:/root/docker

# Create Caddy networks and data dirs if needed (handled by compose usually, but let's be safe)
sudo docker exec opc_test_node bash -c "mkdir -p /root/docker/core/data/caddy"
sudo docker exec opc_test_node ls -R /root/docker

# Start Core Services
echo "Starting Core Services..."
sudo docker exec opc_test_node bash -c "cd /root/docker/core && docker compose up -d"

# Wait for healthy
sleep 10
sudo docker exec opc_test_node docker ps

echo "Test Complete."
