# Implementation Findings & Setup Guide

## 1. Overview
The Open Personal Cloud is a three-node architecture:
- **Node A (Primary):** On-site storage and compute.
- **Node B (Edge):** Public entry point and mail relay.
- **Node C (Vault):** Off-site backup.

## 2. Infrastructure as Code (IaC) Components

### Terraform
- Manages the Hetzner VPS (Node B).
- Uses `cloud-init.yaml` for initial hardening and SSH key setup.
- **Action Required:** Update `terraform/variables.tf` with your SSH keys and provide `hcloud_token`.

### Ansible
- **site.yml:** Orchestrates the entire setup.
- **docker.yml:** Installs Docker on all nodes.
- **security.yml:** Configures UFW and basic security.
- **wireguard.yml:** Establishes a secure tunnel between Node A and Node B.
- **storage.yml:** Configures `mergerfs` and `SnapRAID` on Node A.
- **backup.yml:** Sets up `restic` on Node C.

## 3. Storage Strategy
- **mergerfs:** Pools multiple HDDs into a single mount point (`/mnt/pool`).
- **SnapRAID:** Provides parity protection. It is a snapshot-based RAID, meaning it is not real-time but allows for easy recovery of individual files and supports mixed disk sizes.
- **Restic:** Performs encrypted, deduplicated backups to Node C.

## 4. Security & Networking
- **WireGuard:** All traffic between Edge and Primary nodes is tunneled.
- **Caddy:** Acts as a reverse proxy on Node B, terminating SSL and forwarding requests to Node A over the WireGuard tunnel.
- **Pocket ID:** Provides centralized authentication. Caddy is configured with `forward_auth` to protect services.

## 5. Deployment Steps

1.  **Terraform:**
    ```bash
    cd terraform
    terraform init
    terraform apply
    ```
2.  **Ansible:**
    - Update `ansible/inventory.yml` with your node IPs.
    - Encrypt `ansible/group_vars/secrets.yml` using `ansible-vault`.
    - Run the playbook:
    ```bash
    cd ansible
    ansible-playbook -i inventory.yml site.yml --ask-vault-pass
    ```
3.  **Docker Services:**
    - Deploy services using `docker compose up -d` in their respective directories.

## 6. Friction Points & Findings
- **WireGuard Key Management:** Currently, Ansible generates keys on-the-fly. If a node is re-deployed, keys will change. Consider using a persistent key management strategy.
- **Email Deliverability:** Stalwart is configured as a relay, but you MUST set up SPF, DKIM, and DMARC records in your DNS to avoid being marked as spam.
- **mergerfs Disconnects:** If a USB drive disconnects, `mergerfs` might hang. The current config uses `cache.files=off` to minimize this risk.

## 7. Local Testing Strategy
To iterate faster, we've implemented a local-only testing approach:
- **Disk Simulation:** Uses loopback devices to mimic real HDDs for testing the storage layer.
- **Local Ansible:** The inventory is configured to target `localhost`, allowing you to test playbooks without a remote server.
- **Caddy Local Certs:** Configured to use `local_certs` for HTTPS testing on your local network.

## 8. Bug Fixes & Host Adjustments
During the development and testing of the local DinD environment, several adjustments were made:
- **Host Dependencies:** Installed `ansible` on the host to allow the test runner to orchestrate the container deployment.
- **Pocket ID Fix:** Added a required `ENCRYPTION_KEY` (minimum 16 chars) to `docker/core/docker-compose.yml` to prevent container crash.
- **Ansible Variable Alignment:** Ensured all necessary variables (like `wireguard_port`, `storage_mount_point`, etc.) are defined in `group_vars/all.yml` or passed as `extra-vars` to avoid playbook failures.
- **Docker-in-Docker Compatibility:** Configured the test container with `cgroup: host` and volume mounts for `/var/lib/docker` to prevent overlay-on-overlay filesystem errors.
