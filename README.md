# Open Personal Cloud (Lean Edition)

A resilient, privacy-focused, and user-friendly personal cloud infrastructure managed through Infrastructure as Code (IaC). This project bridges on-premise hardware with cloud-based accessibility while remaining simple enough for family use.

## 🏗 Current Architecture
- **Primary Node (Node A):** Local compute & storage (mergerfs + SnapRAID).
- **Edge Node (Node B):** Public entry (WireGuard + Caddy + Pocket ID Auth).
- **Vault Node (Node C):** Off-site encrypted backups (Restic).

## 🚀 Getting Started (Local Testing)

The project currently includes a **full integration test harness** that allows you to simulate the entire environment (disks, OS configuration, and services) inside a Docker-in-Docker container.

### Prerequisites
- **Docker** & **Docker Compose**
- **Ansible** (installed on your host machine)
- **Sudo** privileges

### 🛠 Running the Test Harness
To verify the infrastructure and see the services in action:

```bash
# 1. Clone the repository
git clone https://github.com/your-username/Open-Personal-Cloud.git
cd Open-Personal-Cloud

# 2. Run the integration test
# This will spin up a virtual Ubuntu node, simulate disks, 
# run Ansible, and deploy the application stack.
chmod +x tests/run_tests.sh
./tests/run_tests.sh
```

### 🔍 Verifying the Deployment
Once the test script finishes, you can inspect the "Virtual Node":

```bash
# See the services running inside the test container
sudo docker exec opc_test_node docker ps

# Check the health of the storage pool
sudo docker exec opc_test_node df -h /mnt/pool

# Check SnapRAID status
sudo docker exec opc_test_node snapraid status
```

## 📁 Repository Structure
- `ansible/`: Playbooks for OS hardening, WireGuard, and storage setup.
- `docker/`: Service definitions for Pocket ID, Homepage, Caddy, Immich, and more.
- `terraform/`: Configuration for Hetzner VPS and DNS (for production).
- `tests/`: Docker-in-Docker test harness and node simulation.
- `scripts/`: Utilities for disk simulation and maintenance.

## 📝 Documentation
For more detailed information, please refer to:
- [FINDINGS.md](FINDINGS.md): Detailed implementation findings, bug fixes, and architectural notes.
- [TESTING.md](TESTING.md): Detailed guide for local and simulated testing.
- [docs/architecture_requirements.md](docs/architecture_requirements.md): The original project vision and requirements.

## 🛠 Next Steps
- [ ] Automated Backup timers (Restic).
- [ ] Monitoring dashboard (Uptime Kuma).
- [ ] Automated disk scaling playbooks.
