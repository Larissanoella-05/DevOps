# Security

This repository runs three automated security scans on every pull request
(see `.github/workflows/ci.yml`), plus manual server-hardening in Terraform
and Ansible. This document records what each scan has found and how it was
addressed.

## 1. Dependency scanning — `npm audit`

Runs against both the root `package.json` and `Backend/package.json`
(`--audit-level=high`, fails the build on high/critical findings).

| Finding | Severity | Where | Status |
| --- | --- | --- | --- |
| `body-parser` below 1.20.6 (DoS via a malformed request) | Low | `Backend/package-lock.json` | Fixed — bumped to 1.20.6 via `npm audit fix` (commit `0cfe74b`) |
| `brace-expansion` 3.0.0–5.0.6 ReDoS | High | `Backend/package-lock.json` | Fixed — bumped to 5.0.7 via `npm audit fix` (commit `0cfe74b`) |
| `brace-expansion` below 1.1.16 ([GHSA-3jxr-9vmj-r5cp](https://github.com/advisories/GHSA-3jxr-9vmj-r5cp)) ReDoS, pulled in transitively via `eslint` → `minimatch` | High | root `package-lock.json` | Fixed via `npm audit fix` |

The root-level finding had been slipping past CI because the dependency scan
step only ever ran `--prefix Backend` — the root lockfile was never audited.
CI now runs `npm audit` at the root as well as in `Backend/`, so this class of
gap won't recur silently.

## 2. Container image scanning — Trivy

Scans the image CI builds and pushes to GHCR (`--severity CRITICAL
--exit-code 1`), skipping npm's own bundled `node_modules` inside the base
image (`--skip-dirs /usr/local/lib/node_modules/npm`) to avoid false
positives from npm's internals rather than the app's own dependencies.

**Current result: 0 CRITICAL findings**, across both OS packages
(`node:22-alpine`) and the application's `node_modules`. The `Dockerfile`
already follows several image-hardening practices that keep this clean: a
multi-stage build (build tooling never ships in the runtime image),
`npm ci --omit=dev` (no dev dependencies in production), and running as the
non-root `node` user.

## 3. IaC scanning — tfsec

Scans `terraform/` on every pull request.

| Finding | Severity | Status |
| --- | --- | --- |
| `azure-network-no-public-ingress` — SSH (port 22) open to `0.0.0.0/0` | Critical | **Fixed** — `ssh_ingress_cidrs` is now a required variable restricted to named admin IPs (commit `a3788ef`). There is no permissive default; Terraform won't apply without an explicit, scoped CIDR list. |
| `azure-network-no-public-ingress` — app port (3000) open to `0.0.0.0/0` | Critical | **Accepted risk, explicitly suppressed.** AgriPulse is a public web app — this port is meant to be reachable from the internet. Suppressed inline in `terraform/modules/security/main.tf` with a `tfsec:ignore` comment and a justification, rather than silently ignored. |

This scan originally ran with `soft_fail: true` while the SSH finding above
was still open, so the pipeline wouldn't block on other work. Now that the
one real finding is fixed and the one accepted-risk finding is explicitly
suppressed (not just tolerated by a blanket soft-fail), `soft_fail` has been
removed — tfsec now **hard-fails** the pipeline on any new IaC issue.

## Other hardening in place

- **SSH**: key-only login (`disable_password_authentication = true` in
  Terraform; `PermitRootLogin no` and `PasswordAuthentication no` applied by
  Ansible's `security` role, only after confirming an `authorized_keys` entry
  exists so a misconfigured run can't lock everyone out).
- **Firewall**: UFW default-denies incoming traffic on the VM, explicitly
  allowing only SSH and the web ports (80/443 on the bastion; the app port
  only from the bastion's subnet on the app VM).
- **Transport encryption**: the public app URL is HTTPS-only — nginx on the
  bastion holds a real Let's Encrypt certificate (`roles/proxy` in Ansible),
  and HTTP requests get a 301 redirect to HTTPS rather than being served in
  plaintext. The bastion's NSG rule (`terraform/modules/security/main.tf`)
  opens 80 and 443, not a raw app port, matching this.
- **Access control**: each teammate uses their own SSH key pair
  (`extra_ssh_public_keys` in Terraform installs each public key
  individually) — no shared private keys.
- **Disk encryption**: Azure encrypts managed disks at rest by default
  (platform-managed keys); noted explicitly in `modules/compute/main.tf` so
  it's visible to reviewers instead of being an invisible default.
- **Container registry access**: `terraform/modules/registry/main.tf` sets
  `admin_enabled = true` on the ACR — a shared username/password credential,
  rather than identity-based access (e.g. a managed identity with `AcrPull`/
  `AcrPush`). **Accepted tradeoff**, same reasoning as the open app port:
  it keeps the CD pipeline's `docker login` step simple for a small student
  team, at the cost of a shared credential instead of per-identity, auditable
  access. Rotate the admin password (`az acr credential renew`) if it's ever
  suspected to have leaked, since — unlike a managed identity — anyone with
  it can push/pull until it's rotated.
- **CD's Azure credentials**: no long-lived secret at all — the CD pipeline
  authenticates via an OIDC federated credential (`azure/login@v2` with only
  `client-id`/`tenant-id`/`subscription-id`, no `client-secret`), trusted
  only for `repo:Larissanoella-05/DevOps:ref:refs/heads/main`. Its Azure
  role assignments are scoped narrowly: `AcrPush` on the resource group, and
  `Network Contributor` on the bastion's NSG specifically (not the resource
  group) so it can temporarily allow its own runner IP through for the
  Ansible deploy step, and nothing broader.

## Reporting a vulnerability

This is a student project (ALU Summative, building on Formatives 1–3). If
you find a security issue, open a GitHub issue or contact the maintainers
directly rather than a public disclosure.
