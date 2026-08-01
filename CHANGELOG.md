# Changelog

Dates and PR numbers below are pulled directly from the repository's merge
history, not reconstructed from memory.

## Summative — 2026-07-30 to present

Upgraded the single-VM Formative 3 deployment into the full summative
topology, plus a working CD pipeline.

- **Terraform** (#20): three-tier network (public/private/database
  subnets), a public **bastion** host, the app VM moved into a **private**
  subnet with no public IP, a managed **PostgreSQL** flexible server with
  no public endpoint, and a private **Azure Container Registry** — six
  reusable modules total.
- **Ansible** (#21): reworked for the bastion/private-VM topology —
  `ProxyJump` through the bastion, ACR login, Docker Compose deployment.
- **CD pipeline** (#24): GitHub Actions workflow that runs CI, builds and
  pushes the image to ACR, and deploys via Ansible on every merge to `main`.
- **nginx reverse proxy** (#25): closes the gap where the bastion's NSG
  allowed public web traffic in but nothing forwarded it to the private app
  VM — added an nginx role on the bastion.
- **CD pipeline fixes** (#26, #27, #28, and the dynamic-bastion-SSH-access
  fix): the pipeline didn't work on first merge — a missing
  `ansible/deploy.yml`, a wrong SSH username, a `packages: write`
  permissions gap causing `startup_failure` on every run, and the bastion's
  IP-restricted NSG blocking GitHub's runner IPs. Diagnosed and fixed one
  at a time, each verified against the actual GitHub Actions run output
  before merging (not fixed as guesses).
- **Dependency fix** (#22): a `brace-expansion`/`fast-uri` npm audit
  finding that surfaced after Formative 3 and was failing CI for every PR
  regardless of what it touched.

## Formative 3 — 2026-07-20 to 2026-07-21

Added Infrastructure as Code, configuration management, and security
scanning to the pipeline for the first time.

- **Terraform** (#15, #16): first IaC pass — a VNet, a single Azure VM,
  a security group, modular `terraform/` layout with variables and outputs.
- **Ansible** (#17): playbook to install Docker and deploy the
  containerized app to the VM Terraform provisions.
- **DevSecOps scanning** (#18): added Trivy (container image) and tfsec
  (IaC) scanning to the CI pipeline, configured to fail on findings.
- **Fixes and docs** (#19): closed review gaps found on the Terraform and
  Ansible PRs (SSH restricted to admin IPs instead of open to the
  internet, security-group values pulled out of hardcoded resource
  blocks into variables) and added `SECURITY.md` documenting what each
  scan found and how it was addressed.

## Formative 2 — 2026-07-03

- **CI workflow** (#10): GitHub Actions pipeline — lint, test, build and
  push a Docker image.
- **Docker Compose** (#12): single-command local run with a named volume
  and health check.
- **Dependency and process updates** (#13, #14): PR template, dependency
  bumps.

## Formative 1 — 2026-06-27 to 2026-06-28

- Initial Express + SQLite (`sql.js`) backend and vanilla HTML/CSS/JS
  frontend for AgriPulse — a crop price tracker.
- README, LICENSE, and team documentation (#2, #3, #4).
