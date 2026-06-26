const express = require("express");
const cors = require("cors");
const path = require("path");
const initDatabase = require("./database");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, "../frontend")));

initDatabase()
  .then(({ query, run }) => {
    app.get("/api/prices", (req, res) => {
      try {
        const { search } = req.query;
        let rows;
        if (search && search.trim()) {
          rows = query(
            `SELECT * FROM prices
           WHERE LOWER(crop_name) LIKE LOWER(?)
           ORDER BY created_at DESC`,
            [`%${search.trim()}%`],
          );
        } else {
          rows = query("SELECT * FROM prices ORDER BY created_at DESC");
        }
        res.json({ success: true, data: rows });
      } catch (err) {
        console.error("GET /api/prices:", err);
        res
          .status(500)
          .json({ success: false, message: "Failed to fetch prices." });
      }
    });

    app.post("/api/prices", (req, res) => {
      try {
        const { crop_name, market, price } = req.body;

        if (!crop_name || !market || price === undefined) {
          return res.status(400).json({
            success: false,
            message: "crop_name, market, and price are all required.",
          });
        }

        const parsedPrice = parseFloat(price);
        if (isNaN(parsedPrice) || parsedPrice < 0) {
          return res.status(400).json({
            success: false,
            message: "price must be a non-negative number.",
          });
        }

        const now = new Date().toISOString().replace("T", " ").substring(0, 19);
        const lastId = run(
          `INSERT INTO prices (crop_name, market, price, created_at)
         VALUES (?, ?, ?, ?)`,
          [crop_name.trim(), market.trim(), parsedPrice, now],
        );

        const [newRow] = query("SELECT * FROM prices WHERE id = ?", [lastId]);
        res.status(201).json({ success: true, data: newRow });
      } catch (err) {
        console.error("POST /api/prices:", err);
        res
          .status(500)
          .json({ success: false, message: "Failed to save price." });
      }
    });

    app.get("*", (_req, res) => {
      res.sendFile(path.join(__dirname, "../frontend/index.html"));
    });

    app.listen(PORT, () => {
      console.log(`🌱 AgriPulse running → http://localhost:${PORT}`);
    });
  })
  .catch((err) => {
    console.error("❌ Failed to initialise database:", err);
    process.exit(1);
  });
