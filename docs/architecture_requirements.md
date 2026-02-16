# Opinionated Self-Hosted Cloud: Requirements & Architecture

## 1. Project Vision

To build a resilient, privacy-focused, and user-friendly personal cloud infrastructure managed through Infrastructure as Code (IaC). The system must bridge on-premise hardware with cloud-based accessibility while remaining simple enough for non-technical family members to use.

## 2. Infrastructure Architecture

### 2.1 Primary Node (On-Site)
- **Role:** Main compute and high-performance storage provider.
- **Hardware Target:** Intel N150 (or similar low-power x86), 16GB RAM.
- **Storage:** Direct Attached Storage (DAS) with support for dynamic scaling (adding/removing HDDs without full system re-configurations).
- **Connectivity:** High-speed local network, VPN/Tunnel to VPS.

### 2.2 Backup Node (Off-Site)
- **Role:** Disaster recovery and immutable backup storage.
- **Hardware Target:** Low-performance ARM (e.g., Raspberry Pi).
- **Logic:** Must receive encrypted incremental backups from the Primary Node at scheduled intervals.

### 2.3 Edge Node (VPC/VPS)
- **Role:** Public entry point, SSL termination, and static IP provider.
- **Provider:** Hetzner VPS.
- **Networking:** Secure tunnel (e.g., WireGuard) to the Primary Node to expose services without opening home router ports.
- **Mail Gateway:** Act as the initial entry/relay point for email traffic to avoid home IP blacklisting.

## 3. Core Functional Requirements

### 3.1 Identity & Access Management (IAM)
- **Centralized Auth:** Implementation of OpenID Connect (OIDC) / OAuth2 for all services.
- **User Experience:** Single Sign-On (SSO) dashboard for family and friends.
- **Security:** Enforced Multi-Factor Authentication (MFA) for public-facing entry points.

### 3.2 Data Management (NAS)
- **Multi-Tenancy:** Each user must have a private, encrypted workspace.
- **Sharing:** Ability to share specific folders/files between users or via public links.
- **Scaling:** Storage must be expandable at the hardware level with minimal downtime.

### 3.3 Communication & Security
- **Password Management:** Secure, self-hosted vault for credentials and TOTP secrets.
- **Email Infrastructure:** Private email storage and access (IMAP/Webmail). System should prioritize storage longevity and searchability over complex mailing list features.

### 3.4 Media & Automation
- **Photo Management:** Automated backup from mobile devices (iOS/Android) with AI-assisted sorting or facial recognition capabilities.
- **Smart Home:** Dedicated environment for home automation logic, isolated from general user traffic for security.

## 4. Technical Non-Functional Requirements

### 4.1 Maintainability (The "GitOps" Requirement)
- **IaC:** The entire stack (OS config, Docker containers, Network rules) must be defined in a GitHub repository.
- **Deployment:** Changes pushed to the repo should be deployable to the hardware with minimal manual intervention.
- **Documentation:** Configuration should be "self-documenting" via clear IaC structure.
- **Software Selection:** Prioritize software that is actively maintained, free, and utilizes restrictive copyleft licenses (e.g., GPL, AGPL) to maximize openness and ensure the project remains truly free.

### 4.2 Security
- **Zero-Trust:** No services exposed directly to the internet; all traffic must pass through the Edge Node or a VPN.
- **Encryption:** Data-at-rest encryption for the DAS and end-to-end encryption for off-site backups.

### 4.3 Reliability
- **Automated Backups:** Daily off-site synchronization.
- **Health Monitoring:** Simple dashboard to check if nodes are online and storage is healthy.

---

# Architecture Design: Open Personal Cloud (Lean Edition)

## 1. System Topology

### Node A: The Powerhouse (On-Site N150)
- **Operating System:** Ubuntu Server 24.04 LTS.
- **Storage Pool:** mergerfs (GPL) for pooling + SnapRAID (GPLv3) for parity.
- **Identity:** Pocket ID (MIT/GPL-compatible) — Ultra-lightweight OIDC provider.
- **Portal:** Homepage (GPLv3) — Centralized landing page for family/friends to access services.
- **Core Services:** Immich, Vaultwarden, Home Assistant.
- **Email Access:** Stalwart Mail (AGPLv3) — Modern IMAP/JMAP storage.

### Node B: The Edge (Hetzner VPS)
- **Role:** WireGuard Peer, Reverse Proxy (Caddy), and Mail Gateway.
- **Mail Entry:** Stalwart Mail (SMTP relay).

### Node C: The Vault (Off-Site Raspberry Pi)
- **Role:** Restic Repository (Encrypted off-site backups).

## 2. Updated Software Stack

| Component | Software | License | Why |
| :--- | :--- | :--- | :--- |
| **Identity (OIDC)** | Pocket ID | MIT | Extremely low resource usage; perfect for N150/16GB RAM. |
| **User Portal** | Homepage | GPLv3 | Provides the "App Grid" UI that Pocket ID lacks. |
| **Storage Pooling** | mergerfs | MIT | Transparent disk pooling. |
| **Redundancy** | SnapRAID | GPLv3 | Parity-based protection for the DAS. |
| **Email Server** | Stalwart | AGPLv3 | Modern Rust-based mail stack. |
| **Reverse Proxy** | Caddy | Apache 2.0 | Automatic SSL via DNS challenge. |
| **Backup** | Restic | BSD-2 | Deduplicated, encrypted backups. |

## 3. Repository Structure (IaC Layout)

To maintain HearthCloud via GitHub, the repository will follow this structure:

```
Open-Personal-Cloud/
├── terraform/               # Hetzner VPS, Firewall, and DNS
│   ├── hetzner.tf
│   └── variables.tf
├── ansible/                 # OS configuration & hardening
│   ├── inventory.yml        # IPs for Node A, B, and C
│   ├── playbooks/
│   │   ├── storage.yml      # mergerfs & SnapRAID setup
│   │   └── security.yml     # WireGuard, SSH, & Firewall
│   └── roles/               # Reusable configuration blocks
└── docker/                  # Service definitions
    ├── core/                # Pocket ID, Homepage, Caddy
    ├── storage/             # Immich, Vaultwarden
    └── email/               # Stalwart
        └── docker-compose.yml
```

## 4. Why Pocket ID over Authentik?

The pivot to Pocket ID prioritizes system performance and simplicity:
- **Low Overhead:** Pocket ID uses minimal RAM and CPU compared to Authentik's multi-container architecture.
- **Ease of Config:** It focuses purely on OIDC, making the "Identity" layer much easier to maintain.
- **Simplicity:** Fewer moving parts means a lower "Bus Factor" for the administrator.

## 5. The "Front Door" Strategy

Because Pocket ID does not provide a user dashboard:
- **Homepage** will be configured via `services.yaml` in the GitHub repo.
- It will display links to Immich, Vaultwarden, etc.
- We can use Caddy's `forward_auth` to ensure that even the Dashboard itself is protected by Pocket ID.

## 6. Potential Friction Points

While the architecture is sound, these specific areas will require careful configuration and monitoring:

### 6.1 Email Deliverability (Stalwart)
- **Challenge:** Even with a clean VPS IP, maintaining email reputation is difficult. Microsoft (Outlook) and Google (Gmail) have strict filtering.
- **Mitigation:**
    - Strict SPF, DKIM, and DMARC enforcement.
    - Start with low volume.
    - Monitor blacklists (DNSBL) regularly.

### 6.2 USB & DAS Reliability
- **Challenge:** N150 systems are often Mini PCs using USB-based DAS. USB disconnects can hang `mergerfs` or cause write errors.
- **Mitigation:**
    - Use a DAS with **UASP** support and an independent power supply.
    - Avoid USB hubs; connect directly to the host ports.
    - Tune `mergerfs` with options like `cache.files=off` to handle disconnects gracefully.

### 6.3 The "Bus Factor" & Network Dependency
- **Challenge:** The system relies on the WireGuard tunnel between Home and VPS. If this tunnel drops, all public-facing services go offline.
- **Mitigation:**
    - Use `KeepAlive` in WireGuard configs.
    - Implement a "dead man's switch" script to restart the tunnel if pings fail.
    - Ensure `docker` restart policies are set to `unless-stopped`.

## 7. System Testing Strategy

To ensure reliability without a dedicated QA team, we will use a layered testing approach:

### 7.1 Infrastructure Testing (The "Dry Run")
- **IaC Validation:**
    - `terraform plan`: Must pass without errors before applying.
    - `ansible-playbook --check`: verify configuration changes without applying them.
- **Disaster Recovery Drill:**
    - Once a quarter, power off the Primary Node and attempt to restore a critical file from the Backup Node (Raspberry Pi/Restic).

### 7.2 Service Health Checks
- **Automated Monitoring:**
    - **Uptime Kuma** (hosted on VPS or separate cheap Pi) to ping public endpoints (e.g., `https://immich.example.com`).
    - **Docker Healthchecks:** define `healthcheck` blocks in `docker-compose.yml` for every service (e.g., `curl -f http://localhost:8080 || exit 1`).

### 7.3 Security Audits
- **SSL Labs:** Periodic scan of the Caddy public endpoint to ensure A+ rating.
- **Open Relay Test:** Regularly test the Stalwart Mail Server to ensure it is not an open relay.

### 7.4 "The Spouse Test" (User Acceptance)
- **Metric:** Can a non-technical user log in, view photos, and find a password without asking for help?
- **Method:** Periodic implementation of "Shadow IT" prevention—if users switch to Google Drive/Photos, the self-hosted solution needs UI/UX improvement.
