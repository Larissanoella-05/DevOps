# AgriPulse — Ansible configuration

Configures the two-tier AgriPulse deployment provisioned by the summative
Terraform: a public **bastion** host and a private **app VM** with no public
IP of its own. The playbook installs Docker, logs in to Azure Container
Registry, deploys the app with Docker Compose, hardens both hosts, and runs
an nginx reverse proxy on the bastion so the app is reachable over the web.

## Architecture

```
        you / CD pipeline          web browsers
               │ SSH                    │ HTTP :3000
               ▼                        ▼
     ┌─────────────────────────────────────┐   public subnet
     │  bastion (public)                    │   SSH hardened, jump host,
     │  nginx :3000 ──────────────┐         │   nginx reverse proxy
     └─────────┬───────────────────┼─────────┘
               │ SSH (ProxyJump)   │ HTTP, proxied to the app VM's
               ▼                   ▼ private IP on :3000
     ┌───────────────────┐   private subnet
     │  app VM (private)  │   Docker + Compose, runs the container
     └────────────────────┘
```

Ansible never talks to the app VM directly — every connection is proxied
through the bastion via `ProxyJump`. `group_vars/app.yml` computes that jump
automatically from whichever host is in the `[bastion]` inventory group, so
this works with either the static or the dynamic inventory without editing
anything by hand. End users' web traffic takes a separate path: nginx on the
bastion listens on the app port and forwards it to the app VM's private IP,
computed the same automatic way in `group_vars/bastion.yml`.

## Prerequisites

On your control machine (the one running `ansible-playbook`):

- Ansible >= 2.15 (`pip install ansible` or `sudo apt install ansible`)
- The collections this playbook depends on:
  ```bash
  ansible-galaxy collection install -r requirements.yml
  ```
- An SSH key pair, with the **public** key already installed on both VMs
  (Terraform does this via `ssh_public_key_path` / `extra_ssh_public_keys`).
  Point Ansible at your **private** key with `--private-key`, shown below —
  don't hardcode a path in `inventory.ini` itself. Inventory-level
  `ansible_ssh_private_key_file` takes precedence over `--private-key`, so a
  hardcoded path there silently overrides whatever key you actually meant
  to use, including CD's. That's exactly what broke CD's deploy step: the
  file used to hardcode `~/.ssh/id_ed25519`, which only happened to exist
  on whoever tested locally, never on the GitHub Actions runner.
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
<bastion_public_ip> ansible_user=ubuntu

[app]
<app_private_ip> ansible_user=ubuntu

[app:vars]
ansible_python_interpreter=/usr/bin/python3
```

No `ProxyJump` line is needed here — `group_vars/app.yml` builds it from the
`[bastion]` group at run time. No private key path here either — pass it
explicitly with `--private-key` on every run (see below), so it's always
clear which key is actually being used.

## Running the playbook

From the `ansible/` directory, with the `ACR_*` variables exported:

```bash
ansible-playbook -i inventory.ini playbook.yml --private-key ~/.ssh/id_ed25519
```

Useful flags while working on it:

```bash
ansible-playbook -i inventory.ini playbook.yml --private-key ~/.ssh/id_ed25519 --syntax-check   # validate YAML/module args
ansible-playbook -i inventory.ini playbook.yml --private-key ~/.ssh/id_ed25519 --check          # dry run
ansible-playbook -i inventory.ini playbook.yml --private-key ~/.ssh/id_ed25519 -vv              # verbose output
```

It's safe to re-run any time. Every task is idempotent, and a second run
with no new image pushed only touches things that actually drifted — the
image pull is compared by digest, so the container is only recreated when
the pulled image actually changed.

### `playbook.yml` vs `deploy.yml`

`playbook.yml` is the full setup: hardens the bastion, installs Docker,
deploys the app, hardens the app VM. Run this once against a freshly
provisioned VM (or any time you want everything re-verified/re-hardened).

`deploy.yml` is what the CD pipeline runs on every merge to `main` — just
the app role, targeting the `app` group only. It doesn't touch the bastion
or redo the security/UFW/Docker-install steps every single deploy, since
those don't change between releases. It takes the image and registry
credentials as extra vars, since CD passes those in directly rather than
reading them from `group_vars`:

```bash
ansible-playbook -i inventory.ini deploy.yml \
  --extra-vars "image=<registry>/agripulse:<tag>" \
  --extra-vars "acr_login_server=<registry>" \
  --extra-vars "acr_username=<username>" \
  --extra-vars "acr_password=<password>"
```

### Using dynamic inventory instead of the static file

`inventory/azure_rm.yml` queries Azure directly for the bastion and app VMs
by name (`*-bastion` / `*-app-vm`, matching what Terraform names them), so
there's no IP to copy by hand:

```bash
ansible-playbook -i inventory/azure_rm.yml playbook.yml
```

Sanity-check what it finds with `ansible-inventory -i inventory/azure_rm.yml --graph`.

## What gets configured

**Bastion play** (`roles/security`, `roles/proxy`):

`roles/security` — harden the bastion:
- UFW: default-deny incoming, allow SSH (22), enabled
- Root SSH login and password auth disabled, `sshd_config` validated with
  `sshd -t` before restart, backup kept

`roles/proxy` — front public web traffic:
- Installs nginx and removes its default site
- Writes a reverse proxy config that listens on the app port and forwards
  to the app VM's private IP (`app_upstream_host` in `group_vars/bastion.yml`,
  resolved from the `[app]` inventory group the same way `ProxyJump` is)
- Enables and starts nginx; reloads (not a full restart) only when the
  config actually changes

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

From your own machine, over the internet, through the bastion's reverse proxy:

```bash
curl -s http://<bastion_public_ip>:3000/api/prices
```

That should return a JSON response — no SSH needed for this check, since
nginx on the bastion is now what's actually serving the request.

To check the app VM itself (useful when the `curl` above fails and you need
to see why), reach it the same way Ansible does — through the bastion:

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
