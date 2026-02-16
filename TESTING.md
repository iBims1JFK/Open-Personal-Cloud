# Local Testing Guide

## Option 1: Quick Local Simulation (Host-based)
If you want to test the storage logic on your current machine without installing everything:
1. Run the simulation script:
   ```bash
   chmod +x scripts/simulate_disks.sh
   ./scripts/simulate_disks.sh
   ```
2. This creates loopback devices (virtual disks) at `/dev/loopX`.

## Option 2: Full Integration Test (Docker-based)
We have created a complete test harness that spins up a "Virtual Node" (Ubuntu 24.04 container) and deploys the entire stack inside it. This is the safest way to verify everything.

### Prerequisites
- Docker
- Ansible (installed on the host)
- `sudo` access (to run the test harness and access docker socket)

### How to Run
1. Execute the test runner:
   ```bash
   chmod +x tests/run_tests.sh
   ./tests/run_tests.sh
   ```
   
### What it does
1. Builds a custom Ubuntu 24.04 Docker image (`tests/Dockerfile.node`).
2. Starts the container (`opc_test_node`) with systemd support.
3. Creates virtual loopback disks *inside* the container.
4. Runs the Ansible playbooks against this container to:
   - Install Docker & dependencies.
   - Configure `mergerfs` and `SnapRAID`.
   - Setup WireGuard & Firewall.
5. Deploys the application stack (Pocket ID, Homepage, Caddy) inside the container.
6. Verifies everything is running.

### Verifying the Result
You can inspect the running test node:
```bash
# Check running containers inside the node
sudo docker exec opc_test_node docker ps

# Check storage pool
sudo docker exec opc_test_node df -h /mnt/pool
```

To tear down the test environment:
```bash
sudo docker compose -f tests/docker-compose.test.yml down -v
```
