# AgriPulse — Crop Price Tracker

> Empowering African farmers and traders with real-time crop market prices.

---

## Problem Statement

Smallholder farmers across Africa often sell their crops at unfair prices
because they lack access to current market information. Traders exploit
this information gap. AgriPulse bridges this gap by providing a simple,
accessible platform to view and compare crop prices across different markets.

##  Team

| Name | GitHub | Role |
|------|--------|------|
| OJ | @oj | Team Lead & Documentation  |
| Larissa | @larissa | Repo Admin & Design |
| Emerance | @emerance | Project Planning |
| Joshua | @joshua | Backend & Codebase |

## Target Users

- Smallholder farmers in Rwanda and East Africa
- Market traders and agro-dealers
- Agricultural extension officers
- NGOs working in food security

##  Core Features

1. **View Crop Prices** — Browse a live table of crop prices from multiple markets
2. **Search by Crop** — Filter prices by crop name in real time
3. **Add New Prices** — Submit updated prices from any market
4. **Mobile Responsive** — Works on low-cost smartphones
5. **REST API** — Accessible endpoints for future integrations

##  Technology Stack

| Layer    | Technology              |
|----------|-------------------------|
| Runtime  | Node.js v18+            |
| Server   | Express.js              |
| Database | SQLite (sql.js)         |
| Frontend | Vanilla HTML / CSS / JS |

##  Project Structure
agripulse/

├── backend/

│   ├── server.js       # Express server & API routes

│   ├── database.js     # SQLite setup and seeding

│   └── package.json

├── frontend/

│   ├── index.html      # Main UI

│   ├── style.css       # Responsive styles

│   └── app.js          # API calls and rendering

├── .gitignore

├── LICENSE

└── README.md

##  How to Run Locally

### Prerequisites
- Node.js v18 or higher — download at https://nodejs.org

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/<your-org>/agripulse.git
cd agripulse

# 2. Install dependencies
cd backend
npm install

# 3. Start the server
node server.js

# 4. Open in browser
# Visit http://localhost:3000
```

The database is created and seeded automatically on first run.

##  API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/prices` | Get all crop prices |
| GET | `/api/prices?search=maize` | Search by crop name |
| POST | `/api/prices` | Add a new price entry |

### POST /api/prices — Request Body

```json
{
  "crop_name": "Maize",
  "market": "Kimironko Market",
  "price": 0.55
}
```



##  License

MIT License — see [LICENSE](LICENSE) file.
