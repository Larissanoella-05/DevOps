# AgriPulse: Crop Price Tracker

> Empowering African farmers and traders with real-time crop market prices.

**Live app:** http://20.219.14.108:3000 _(see [Live Deployment](#live-deployment) below.)_

---

## Problem Statement

Smallholder farmers across Africa often sell their crops at unfair prices
because they lack access to current market information. Traders exploit
this information gap. AgriPulse bridges this gap by providing a simple,
accessible platform to view and compare crop prices across different markets.

## Team

| Name     | GitHub    | Role                      |
| -------- | --------- | ------------------------- |
| OJ       | @oj       | Team Lead & Documentation |
| Larissa  | @larissa  | Repo Admin & Design       |
| Emerance | @emerance | Project Planning          |
| Joshua   | @joshua   | Backend & Codebase        |

## Target Users

- Smallholder farmers in Rwanda and East Africa
- Market traders and agro-dealers
- Agricultural extension officers
- NGOs working in food security

## Core Features

1. **View Crop Prices**: browse a live table of crop prices from multiple markets
2. **Search by Crop**: filter prices by crop name in real time
3. **Add New Prices**: submit updated prices from any market
4. **Mobile Responsive**: works on low-cost smartphones
5. **REST API**: accessible endpoints for future integrations

## Technology Stack

| Layer             | Technology                                            |
| ------------------ | ------------------------------------------------------ |
| Runtime            | Node.js v22                                            |
| Server             | Express.js                                             |
| Database           | SQLite (sql.js). See [Notes](#notes) on the provisioned PostgreSQL |
| Frontend           | Vanilla HTML / CSS / JS                                |
| Linting            | ESLint                                                 |
| Testing            | Node.js built-in `node:test`                           |
| Git hooks          | Husky + commitlint                                     |
| Containerization   | Docker + Docker Compose                                |
| Infrastructure     | Terraform (Azure)                                      |
| Config management  | Ansible                                                |
| CI                 | GitHub Actions (lint, test, Trivy, tfsec, npm audit)   |
| CD                 | GitHub Actions (build, push to ACR, deploy via Ansible)|

## Live Deployment

**http://20.219.14.108:3000**

The infrastructure is provisioned on demand with Terraform rather than
hosted permanently, so the IP changes if the bastion is ever recreated. If
the link above is down, the infrastructure probably just isn't deployed
right now. See [terraform/README.md](terraform/README.md) to bring it back
up. TLS (nginx + Let's Encrypt on the bastion) is in progress on a separate
branch and isn't part of this deployment yet, so the app is served over
plain HTTP directly on its container port for now.

```bash
curl http://20.219.14.108:3000/api/prices
```

## Architecture

```
   push / PR                                    merge to main
       │                                              │
       ▼                                              ▼
 ┌───────────────┐                          ┌────────────────────┐
 │  CI Pipeline   │◀────── reused by ────────│   CD Pipeline       │
 │  lint, test,   │         workflow_call    │   build + push      │
 │  Trivy, tfsec, │                          │   image to ACR,     │
 │  npm audit     │                          │   deploy via Ansible│
 └───────────────┘                          └──────────┬──────────┘
                                                         │
                                                         ▼
                                   ┌──────────────────────────────────┐
                                   │  Azure, provisioned by Terraform  │
                                   │                                    │
                                   │        internet                   │
                                   │           │ HTTP :3000             │
                                   │           ▼                       │
                                   │   ┌─────────────────┐  public     │
                                   │   │ Bastion          │  subnet    │
                                   │   │ nginx reverse    │            │
                                   │   │ proxy            │            │
                                   │   └────────┬─────────┘            │
                                   │            │ proxy (VNet only)     │
                                   │            ▼                       │
                                   │   ┌─────────────────┐  private    │
                                   │   │ App VM           │  subnet    │
                                   │   │ Docker Compose   │            │
                                   │   └────────┬─────────┘            │
                                   │            │                       │
                                   │            ▼                       │
                                   │   ┌─────────────────┐  delegated  │
                                   │   │ PostgreSQL       │  subnet    │
                                   │   │ (private, not    │            │
                                   │   │  yet wired up)   │            │
                                   │   └─────────────────┘             │
                                   │                                    │
                                   │   Azure Container Registry ───────▶│ image source
                                   └──────────────────────────────────┘
```

The app VM has **no public IP**. Only the bastion is internet-facing, and
only on ports 22 (SSH, restricted to named admin IPs) and 3000 (the app,
proxied to the private VM). The database has no public endpoint either.
Full detail lives in [terraform/README.md](terraform/README.md).

## Infrastructure & Deployment

- **[terraform/](terraform/)**: provisions the Azure environment. A
  three-tier VNet, a public bastion, a private app VM, managed PostgreSQL,
  and a private container registry, split into modules (network, security,
  bastion, compute, database, registry) with dev/staging/prod environments
  and remote state. See [terraform/README.md](terraform/README.md).
- **[ansible/](ansible/)**: configures the provisioned VMs. Installs
  Docker, deploys the app with Docker Compose, hardens SSH and the
  firewall on both hosts, and runs an nginx reverse proxy on the bastion.
  See [ansible/README.md](ansible/README.md).
- **[.github/workflows/cd.yml](.github/workflows/cd.yml)**: on every merge
  to `main`, runs the full CI suite, builds and pushes the image to Azure
  Container Registry, then deploys it by running the Ansible playbook
  through the bastion.
- **[SECURITY.md](SECURITY.md)**: what each CI security scan (dependency,
  container image, IaC) has found and how it was addressed, with severity
  and commit references.
- **[CHANGELOG.md](CHANGELOG.md)**: what shipped in Formative 1, 2, 3, and
  the Summative, built from the actual git history.

## Project Structure

```
DevOps/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── SECURITY.md
├── package.json              # root scripts (lint/test) + eslint/husky/commitlint devDeps
├── package-lock.json
├── eslint.config.js           # lint rules for Backend (Node) and Frontend (browser)
├── commitlint.config.js       # enforces Conventional Commits on every commit message
├── Dockerfile                  # multi-stage build, non-root user, health check
├── docker-compose.yml          # single-command local run, named volume, health check
├── .dockerignore
├── .gitignore
├── .husky/
│   ├── pre-commit             # runs `npm run lint` before every commit
│   └── commit-msg             # validates commit message format via commitlint
├── .github/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/
│       ├── ci.yml               # lint, test, Trivy/tfsec/npm audit, build & push (GHCR)
│       └── cd.yml               # on merge to main: CI, build & push (ACR), deploy via Ansible
├── terraform/                  # Azure infrastructure, see terraform/README.md
│   ├── main.tf, variables.tf, outputs.tf
│   ├── environments/           # dev (default), staging, prod tfvars
│   └── modules/                # network, security, bastion, compute, database, registry
├── ansible/                    # server configuration, see ansible/README.md
│   ├── playbook.yml             # full setup (bastion + app)
│   ├── deploy.yml               # CD's fast path (app only)
│   └── roles/                   # docker, app, security, proxy
├── Backend/
│   ├── server.js               # Express app & API routes
│   ├── database.js             # sql.js init, seed data, query/run helpers
│   ├── package.json
│   └── tests/
│       └── database.test.js
└── Frontend/
    ├── index.html
    ├── styles.css
    └── app.js
```

## How to Run Locally (without Docker)

### Prerequisites

- Node.js v18 or higher (download at https://nodejs.org)

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/Larissanoella-05/DevOps.git
cd DevOps

# 2. Install dependencies (root tooling + backend)
npm install
npm run install:backend

# 3. Start the server
npm start

# 4. Open in browser
# Visit http://localhost:3000
```

The database is created and seeded automatically on first run.

## Running with Docker

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) with the Compose plugin (`docker compose version` should work)

### Quick start

```bash
docker compose up -d --build
curl http://localhost:3000/api/prices   # seeded crop price data
```

Open `http://localhost:3000` in a browser for the UI. Stop with `docker compose down` (data persists in a named volume) or `docker compose down -v` (also deletes the data volume).

If port `3000` is already in use on your machine:

```bash
PORT=3010 docker compose up -d --build
```

### What's in the image

- Multi-stage build (`deps` → `runtime`), so devDependencies never ship in the final image
- Runs as the non-root `node` user
- Data persists via the `agripulse-data` named volume, mounted at `/app/data`
- Health check polls the API so the container only reports "healthy" once it's actually serving requests

### Building/running without Compose

```bash
docker build -t agripulse .
docker run -d -p 3000:3000 --name agripulse agripulse
```

## Deploying to Azure

Full instructions live in [terraform/README.md](terraform/README.md) and
[ansible/README.md](ansible/README.md). Short version:

```bash
# 1. Provision the infrastructure
cd terraform
az login
export TF_VAR_db_admin_password='<a-strong-password>'
terraform init
terraform apply

# 2. Configure and deploy the app
cd ../ansible
terraform -chdir=../terraform output -raw bastion_public_ip   # update inventory.ini with this
export ACR_LOGIN_SERVER=$(terraform -chdir=../terraform output -raw acr_login_server)
export ACR_USERNAME=$(terraform -chdir=../terraform output -raw acr_admin_username)
export ACR_PASSWORD=$(terraform -chdir=../terraform output -raw acr_admin_password)
ansible-playbook -i inventory.ini playbook.yml
```

After that, every merge to `main` redeploys automatically through
[`cd.yml`](.github/workflows/cd.yml), so routine updates need no manual
steps. Manual runs are only for the first provision or infrastructure
changes.

## Linting & Tests

```bash
npm run lint     # ESLint across Backend/ and Frontend/
npm test          # Backend unit tests (node:test)
```

Both run automatically through a Husky `pre-commit` hook (lint) before every local commit, and again in CI on every push/PR.

## Continuous Integration

Every push to a non-`main` branch, and every pull request targeting `main`, runs [`.github/workflows/ci.yml`](.github/workflows/ci.yml):

1. **Install dependencies**: root and `Backend/`
2. **Run linter**: `npm run lint`
3. **Run tests**: `npm test`
4. **Build and push Docker image**: to GitHub Container Registry (`ghcr.io`), tagged with the commit SHA
5. **Dependency scan**: `npm audit`, root and `Backend/`, fails on high/critical
6. **Container image scan**: Trivy, fails on critical findings
7. **Terraform IaC scan**: tfsec, fails on any unaddressed finding

All steps must pass before a PR can merge into `main`, enforced through
branch protection's required status checks. Findings from the three scans,
and how each was addressed, are documented in [SECURITY.md](SECURITY.md).

## Continuous Deployment

Every merge into `main` runs [`.github/workflows/cd.yml`](.github/workflows/cd.yml):

1. Runs the full CI suite, reused through `workflow_call` instead of duplicated
2. Authenticates to Azure with an OIDC federated credential (no stored secret)
3. Builds the image and pushes it to Azure Container Registry
4. Deploys it by running `ansible/deploy.yml` through the bastion

CD's Azure identity is scoped narrowly: `AcrPush` on the resource group,
and `Network Contributor` on just the bastion's network security group, so
it can temporarily let its own runner IP through for the SSH-based deploy
step and nothing more. More detail in [SECURITY.md](SECURITY.md).

## API Endpoints

| Method | Endpoint                   | Description           |
| ------ | -------------------------- | --------------------- |
| GET    | `/api/prices`              | Get all crop prices   |
| GET    | `/api/prices?search=maize` | Search by crop name   |
| POST   | `/api/prices`              | Add a new price entry |

### POST /api/prices request body

```json
{
  "crop_name": "Maize",
  "market": "Kimironko Market",
  "price": 0.55
}
```

## Notes

- The managed PostgreSQL database Terraform provisions isn't wired into the
  app yet. It still persists to SQLite. This is a deliberate, documented
  scope decision, not an oversight: the database exists to satisfy the
  infrastructure requirement, and wiring the app to it is tracked as
  future work in both [terraform/README.md](terraform/README.md) and
  [ansible/README.md](ansible/README.md).

## Links

[Attendance tracker ](https://docs.google.com/spreadsheets/d/1M121T9ddVaMRLpsY1mCgOKTSb2j2lZaEzWKaoS6PIdM/edit?usp=sharing)


## Demo Video

[ Watch Demo Video](https://drive.google.com/drive/folders/1OimMTxARGeHqXD4DPYCcjWVZx-UM_p0C?usp=sharing)

## License

MIT License. See the [LICENSE](LICENSE) file.
