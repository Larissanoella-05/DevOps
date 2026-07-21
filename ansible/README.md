# AgriPulse — Ansible configuration

Configures a fresh Ubuntu 22.04 server (provisioned by Joshua's Terraform) into
a running AgriPulse deployment: installs dependencies, deploys the
containerized app, and hardens the server.

## Prerequisites

On your control machine (the one running `ansible-playbook`):

- Ansible >= 2.15 (`pip install ansible` or `sudo apt install ansible`)
- The collections this playbook depends on:
  ```bash
  ansible-galaxy collection install -r requirements.yml
  ```
- An SSH key pair, with the **public** key already installed on the target
  server (Terraform does this via `ssh_public_key_path` /
  `terraform/variables.tf`) and the **private** key available locally at the
  path referenced in `inventory.ini` (default `~/.ssh/id_rsa`).
- Only needed for the dynamic inventory (see below): the Python packages the
  `azure.azcollection` plugin depends on:
  ```bash
  pip install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt
  ```
  and an active `az login` session (same one Terraform uses — see
  `terraform/README.md`).

## Updating inventory.ini with the Terraform IP

After Joshua applies the Terraform, get the server IP:

```bash
cd ../terraform
terraform output vm_public_ip
```

Open `inventory.ini` and replace `your-server-ip` with that value:

```ini
[agripulse_servers]
203.0.113.42 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

[agripulse_servers:vars]
ansible_python_interpreter=/usr/bin/python3
```

## Running the playbook

From the `ansible/` directory:

```bash
ansible-playbook -i inventory.ini playbook.yml
```

Useful flags while working on it:

```bash
ansible-playbook -i inventory.ini playbook.yml --syntax-check   # validate YAML/module args
ansible-playbook -i inventory.ini playbook.yml --check          # dry run
ansible-playbook -i inventory.ini playbook.yml -vv              # verbose output
```

It's safe to re-run the playbook any time — every task is idempotent, so a
second run only touches things that actually drifted.

### Using dynamic inventory instead of the static file

`inventory/azure_rm.yml` queries Azure directly for any VM in a resource
group matching `agripulse-*-rg` (Terraform names resource groups
`${project_name}-${environment}-rg`) tagged `Project=agripulse` (the tag
Terraform's `local.tags` applies), so there's no IP to copy by hand:

```bash
ansible-playbook -i inventory/azure_rm.yml playbook.yml
```

Sanity-check what it finds with `ansible-inventory -i inventory/azure_rm.yml --graph`.

## What gets configured

**`roles/docker`** — Step 1, install dependencies:
- Adds Docker's official apt repository and installs `docker-ce`,
  `docker-ce-cli`, `containerd.io`, and the buildx/compose plugins
- Installs the Docker SDK for Python (needed by the app role's container
  tasks) and adds `ubuntu` to the `docker` group
- Installs Node.js (NodeSource repo) and required system packages
  (`ca-certificates`, `curl`, `gnupg`, etc.)
- Writes `/etc/docker/daemon.json` (log rotation) and restarts the Docker
  daemon only when that file actually changes (handler)

**`roles/app`** — Step 2, deploy the app:
- Creates `/opt/agripulse` (env file) and `/opt/agripulse/data` (persisted
  SQLite data, bind-mounted into the container)
- Gets the image onto the server — either `docker pull`s
  `app_registry_image` (currently the GHCR image the CI pipeline builds and
  Trivy-scans on every merge to `main`) or copies/loads a local tarball,
  depending on `app_deploy_method` in `group_vars/agripulse_servers.yml`.
  **GHCR packages built via `GITHUB_TOKEN` default to private** — either make
  the package public (repo → Packages → package settings → Change
  visibility) or add a `docker login ghcr.io` step ahead of the pull, or the
  pull will fail with an authorization error.
- Runs the container with port mapping `3000:3000`, the env vars
  `NODE_ENV`, `PORT`, `DB_PATH`, and `restart_policy: unless-stopped`
- Waits for the app to accept TCP connections on port 3000 before
  finishing; restarts the container (handler) only when the env file
  actually changes

**`roles/security`** — Step 3, harden the server:
- UFW: default-deny incoming, default-allow outgoing, explicitly allow
  22 (SSH) and 3000 (app), then enables the firewall
- Disables root SSH login (`PermitRootLogin no`)
- Disables SSH password authentication (`PasswordAuthentication no`,
  key-only) — only after confirming `ansible_user` already has an
  `authorized_keys` entry, so the play fails loudly instead of locking
  you out
- Validates `sshd_config` with `sshd -t` before restarting `ssh`
  (handler), and keeps a backup of the file

Error handling: each role's risky steps (package/repo setup, image
deployment + container start, SSH hardening) run inside `block`/`rescue` so
a failure produces a clear, actionable message instead of a bare traceback.

## Verifying the app after the playbook finishes

```bash
ssh -i ~/.ssh/id_rsa ubuntu@<server-ip> 'docker ps --filter name=agripulse'
curl http://<server-ip>:3000/api/prices
```

- `docker ps` should show the `agripulse` container with status `Up` and
  port `3000->3000`.
- The `curl` should return a JSON response (not a connection error).
- `ssh ubuntu@<server-ip>` should still work; `ssh root@<server-ip>` and
  password-based logins should both be refused.
