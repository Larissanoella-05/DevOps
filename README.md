# AgriPulse — Crop Price Tracker

> Empowering African farmers and traders with real-time crop market prices.

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

1. **View Crop Prices** — Browse a live table of crop prices from multiple markets
2. **Search by Crop** — Filter prices by crop name in real time
3. **Add New Prices** — Submit updated prices from any market
4. **Mobile Responsive** — Works on low-cost smartphones
5. **REST API** — Accessible endpoints for future integrations

## Technology Stack

| Layer            | Technology                        |
| ---------------- | ---------------------------------- |
| Runtime          | Node.js v22                        |
| Server           | Express.js                         |
| Database         | SQLite (sql.js)                    |
| Frontend         | Vanilla HTML / CSS / JS            |
| Linting          | ESLint                             |
| Testing          | Node.js built-in `node:test`       |
| Git hooks        | Husky + commitlint                 |
| Containerization | Docker + Docker Compose            |
| CI               | GitHub Actions                     |

## Project Structure

```
DevOps/
├── README.md
├── LICENSE
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
│       └── ci.yml              # lint → test → build & push Docker image
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

- Node.js v18 or higher — download at https://nodejs.org

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

- Multi-stage build (`deps` → `runtime`) — devDependencies never ship in the final image
- Runs as the non-root `node` user
- Data persists via the `agripulse-data` named volume, mounted at `/app/data`
- Health check polls the API so the container only reports "healthy" once it's actually serving requests

### Building/running without Compose

```bash
docker build -t agripulse .
docker run -d -p 3000:3000 --name agripulse agripulse
```

## Linting & Tests

```bash
npm run lint     # ESLint across Backend/ and Frontend/
npm test          # Backend unit tests (node:test)
```

Both run automatically via a Husky `pre-commit` hook (lint) before every local commit, and again in CI on every push/PR.

## Continuous Integration

Every push to a non-`main` branch, and every pull request targeting `main`, runs [`.github/workflows/ci.yml`](.github/workflows/ci.yml):

1. **Install dependencies** — root and `Backend/`
2. **Run linter** — `npm run lint`
3. **Run tests** — `npm test`
4. **Build and push Docker image** — to GitHub Container Registry (`ghcr.io`), tagged with the commit SHA

All steps must pass before a PR can merge into `main` (enforced via branch protection's required status checks).

## API Endpoints

| Method | Endpoint                   | Description           |
| ------ | -------------------------- | --------------------- |
| GET    | `/api/prices`              | Get all crop prices   |
| GET    | `/api/prices?search=maize` | Search by crop name   |
| POST   | `/api/prices`              | Add a new price entry |

### POST /api/prices — Request Body

```json
{
  "crop_name": "Maize",
  "market": "Kimironko Market",
  "price": 0.55
}
```

## Links

[Attendance tracker ](https://docs.google.com/spreadsheets/d/1M121T9ddVaMRLpsY1mCgOKTSb2j2lZaEzWKaoS6PIdM/edit?usp=sharing)

## License

MIT License — see [LICENSE](LICENSE) file.
