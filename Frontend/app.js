const API_BASE = "/api";

const tableBody = document.getElementById("tableBody");
const mobileCards = document.getElementById("mobileCards");
const emptyState = document.getElementById("emptyState");
const statTotal = document.getElementById("statTotal");
const searchInput = document.getElementById("searchInput");
const clearSearch = document.getElementById("clearSearch");
const cropNameInput = document.getElementById("cropName");
const marketInput = document.getElementById("market");
const priceInput = document.getElementById("price");
const submitBtn = document.getElementById("submitBtn");
const formMsg = document.getElementById("formMsg");

function formatDate(isoString) {
  if (!isoString) return "—";
  const normalized = isoString.endsWith("Z") ? isoString : isoString + "Z";
  const d = new Date(normalized);
  if (isNaN(d)) return isoString;
  return d.toLocaleString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatPrice(price) {
  return "$" + Number(price).toFixed(2);
}

function showFormMsg(text, type = "success") {
  formMsg.textContent = text;
  formMsg.className = `form-msg visible ${type}`;
  setTimeout(() => {
    formMsg.className = "form-msg";
  }, 3500);
}

function escHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function renderTable(prices, highlightId = null) {
  statTotal.innerHTML = `<strong>${prices.length}</strong> ${prices.length === 1 ? "entry" : "entries"} shown`;

  const isEmpty = prices.length === 0;
  emptyState.style.display = isEmpty ? "block" : "none";
  document.querySelector(".table-wrap").style.display = isEmpty ? "none" : "";

  if (isEmpty) {
    mobileCards.innerHTML = "";
    return;
  }

  tableBody.innerHTML = prices
    .map((row, idx) => {
      const isNew = highlightId && row.id === highlightId;
      return `
      <tr class="${isNew ? "new-row" : ""}">
        <td>${idx + 1}</td>
        <td><span class="crop-badge">${escHtml(row.crop_name)}</span></td>
        <td>${escHtml(row.market)}</td>
        <td class="price-cell">${formatPrice(row.price)}</td>
        <td class="date-cell">${formatDate(row.created_at)}</td>
      </tr>`;
    })
    .join("");

  mobileCards.innerHTML = prices
    .map(
      (row) => `
    <div class="price-card">
      <div class="price-card-top">
        <span class="price-card-name">${escHtml(row.crop_name)}</span>
        <span class="price-card-price">${formatPrice(row.price)}<small>/kg</small></span>
      </div>
      <div class="price-card-market">📍 ${escHtml(row.market)}</div>
      <div class="price-card-date">🕑 ${formatDate(row.created_at)}</div>
    </div>`,
    )
    .join("");
}

async function fetchPrices(search = "") {
  try {
    const url = search
      ? `${API_BASE}/prices?search=${encodeURIComponent(search)}`
      : `${API_BASE}/prices`;
    const res = await fetch(url);
    const json = await res.json();
    if (!json.success) throw new Error(json.message);
    renderTable(json.data);
  } catch (err) {
    tableBody.innerHTML = `<tr><td colspan="5" class="loading-row" style="color:var(--red-500)">
      ⚠️ Could not load prices. Is the server running?
    </td></tr>`;
    console.error("fetchPrices:", err);
  }
}

async function submitPrice() {
  const crop_name = cropNameInput.value.trim();
  const market = marketInput.value.trim();
  const price = priceInput.value.trim();

  if (!crop_name || !market || !price) {
    showFormMsg("Please fill in all three fields.", "error");
    return;
  }
  if (isNaN(parseFloat(price)) || parseFloat(price) < 0) {
    showFormMsg("Price must be a valid positive number.", "error");
    priceInput.focus();
    return;
  }

  submitBtn.disabled = true;
  submitBtn.textContent = "Saving…";

  try {
    const res = await fetch(`${API_BASE}/prices`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ crop_name, market, price: parseFloat(price) }),
    });
    const json = await res.json();
    if (!json.success) throw new Error(json.message);

    cropNameInput.value = "";
    marketInput.value = "";
    priceInput.value = "";

    showFormMsg(`✅ "${json.data.crop_name}" saved successfully!`);
    await fetchPrices(searchInput.value.trim());
    document
      .querySelector(".table-card")
      .scrollIntoView({ behavior: "smooth" });
  } catch (err) {
    showFormMsg(`⚠️ ${err.message || "Failed to save. Try again."}`, "error");
    console.error("submitPrice:", err);
  } finally {
    submitBtn.disabled = false;
    submitBtn.textContent = "Save Price";
  }
}

submitBtn.addEventListener("click", submitPrice);

[cropNameInput, marketInput, priceInput].forEach((input) => {
  input.addEventListener("keydown", (e) => {
    if (e.key === "Enter") submitPrice();
  });
});

let searchTimer;
searchInput.addEventListener("input", () => {
  const val = searchInput.value.trim();
  clearSearch.style.display = val ? "inline-flex" : "none";
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => fetchPrices(val), 300);
});

clearSearch.addEventListener("click", () => {
  searchInput.value = "";
  clearSearch.style.display = "none";
  fetchPrices();
  searchInput.focus();
});

fetchPrices();
