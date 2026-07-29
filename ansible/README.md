# AgriPulse — Ansible configuration

Configures the two-tier AgriPulse deployment provisioned by the summative
Terraform: a public **bastion** host and a private **app VM** with no public
IP of its own. The playbook installs Docker, logs in to Azure Container
Registry, deploys the app with Docker Compose, and hardens both hosts.

## Architecture

```
        you / CD pipeline
               │ SSH
               ▼
     ┌───────────────────┐   public subnet
     │  bastion (public)  │   SSH hardened, jump host only
     └─────────┬──────────┘
               │ SSH (ProxyJump)
               ▼
     ┌───────────────────┐   private subnet
     │  app VM (private)  │   Docker + Compose, runs the container
     └────────────────────┘
```

Ansible never talks to the app VM directly — every connection is proxied
through the bastion via `ProxyJump`. `group_vars/app.yml` computes that jump
automatically from whichever host is in the `[bastion]` inventory group, so
this works with either the static or the dynamic inventory without editing
anything by hand.

## Prerequisites

On your control machine (the one running `ansible-playbook`):

- Ansible >= 2.15 (`pip install ansible` or `sudo apt install ansible`)
- The collections this playbook depends on:
  ```bash
  ansible-galaxy collection install -r requirements.yml
  ```
- An SSH key pair, with the **public** key already installed on both VMs
  (Terraform does this via `ssh_public_key_path` / `extra_ssh_public_keys`)
  and the **private** key available locally at the path referenced in
  `inventory.ini` (default `~/.ssh/id_rsa`).
- ACR credentials exported as environment variables (never committed):
  ```bash
  export ACR_LOGIN_SERVER=$(terraform -chdir=../terraform output -raw acr_login_server)
  export ACR_USERNAME=$(terraform -chdir=../terraform output -raw acr_admin_username)
  export ACR_PASSWORD=$(terraform -chdir=../terraform output -raw acr_admin_password)
  ```
- Only needed for the dynamic inventory (see below): the Python packages the
  `azure.azcollection` plugin depends on:
  ```bash
  pip install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt
  ```
  and an active `az login` session (same one Terraform uses).

## Updating inventory.ini with the Terraform IPs

```bash
cd ../terraform
terraform output -raw bastion_public_ip
terraform output -raw app_private_ip
```

Put those in `inventory.ini`:

```ini
[bastion]
<bastion_public_ip> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

[app]
<app_private_ip> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

[app:vars]
ansible_python_interpreter=/usr/bin/python3
```

No `ProxyJump` line is needed here — `group_vars/app.yml` builds it from the
`[bastion]` group at run time.

## Running the playbook

From the `ansible/` directory, with the `ACR_*` variables exported:

```bash
ansible-playbook -i inventory.ini playbook.yml
```

Useful flags while working on it:

```bash
ansible-playbook -i inventory.ini playbook.yml --syntax-check   # validate YAML/module args
ansible-playbook -i inventory.ini playbook.yml --check          # dry run
ansible-playbook -i inventory.ini playbook.yml -vv              # verbose output
```

It's safe to re-run any time. Every task is idempotent, and a second run
with no new image pushed only touches things that actually drifted — the
image pull is compared by digest, so the container is only recreated when
the pulled image actually changed.

The CD pipeline runs this same command as its final deploy step, after
pushing a new image to ACR — that's what makes `docker compose up -d` pick
up the new build.

### Using dynamic inventory instead of the static file

`inventory/azure_rm.yml` queries Azure directly for the bastion and app VMs
by name (`*-bastion` / `*-app-vm`, matching what Terraform names them), so
there's no IP to copy by hand:

```bash
ansible-playbook -i inventory/azure_rm.yml playbook.yml
```

Sanity-check what it finds with `ansible-inventory -i inventory/azure_rm.yml --graph`.

## What gets configured

**Bastion play** (`roles/security` only):
- UFW: default-deny incoming, allow SSH (22), enabled
- Root SSH login and password auth disabled, `sshd_config` validated with
  `sshd -t` before restart, backup kept

**App play** (`roles/docker`, `roles/app`, `roles/security`):

`roles/docker` — install dependencies:
- Adds Docker's official apt repository and installs `docker-ce`,
  `docker-ce-cli`, `containerd.io`, and the buildx/compose plugins
- Installs the Docker SDK for Python (needed by `docker_login`/`docker_image`)
  and adds `ubuntu` to the `docker` group
- Writes `/etc/docker/daemon.json` (log rotation) and restarts the Docker
  daemon only when that file actually changes (handler)

`roles/app` — deploy the app:
- Creates `/opt/agripulse` (compose project) and `/opt/agripulse/data`
  (persisted SQLite data, bind-mounted into the container)
- Writes `docker-compose.yml` from a template (image, port, env vars,
  restart policy, data volume)
- Logs in to Azure Container Registry (`community.docker.docker_login`,
  `no_log: true` so credentials never hit the console/log)
- Pulls the image and compares it by digest; runs `docker compose up -d`,
  forcing a recreate only when the pulled image actually changed — so a
  plain re-run doesn't needlessly restart a container that's already
  running the current image
- Waits for the app to accept TCP connections on port 3000 before finishing

`roles/security` — harden the app VM:
- UFW: default-deny incoming, allow SSH (22) and the app port (3000) only
  from the bastion's subnet (`public_subnet_cidr`, matching the Terraform
  NSG's `allow-*-from-bastion` rules) — not open to the internet
- Root SSH login and password auth disabled the same way as the bastion

Error handling: every role's risky steps (package/repo setup, registry
login, image pull + compose deploy, SSH hardening) run inside `block`/`rescue`
so a failure produces a clear, actionable message — including pulling the
container's own logs on a failed deploy — instead of a bare traceback.

## Verifying the app after the playbook finishes

The app VM has no public IP, so reach it the same way Ansible does — through
the bastion:

```bash
ssh -J ubuntu@<bastion_public_ip> ubuntu@<app_private_ip> 'docker compose -f /opt/agripulse/docker-compose.yml ps'
ssh -J ubuntu@<bastion_public_ip> ubuntu@<app_private_ip> 'curl -s http://localhost:3000/api/prices'
```

- `docker compose ps` should show the `agripulse` service `Up` and healthy.
- The `curl` should return a JSON response (not a connection error).
- `ssh ubuntu@<app_private_ip>` (via the bastion) should still work;
  password logins and root logins should both be refused on either host.

## Notes

- The managed PostgreSQL database Terraform provisions isn't wired into the
  app yet — it still persists to SQLite. Tracked as future work, same as on
  the Terraform side.
- The bastion's NSG also opens the app port (3000) to the internet, intended
  to front public web traffic and proxy it to the private app VM. That
  reverse proxy isn't configured by this playbook yet — today the app is
  only reachable from inside the VNet (or via SSH port-forwarding through
  the bastion), not directly over HTTP from the internet.
