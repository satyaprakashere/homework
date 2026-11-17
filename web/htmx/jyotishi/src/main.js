// ── CSS Starfield (replaces GPU-heavy canvas rAF loop) ─────────────────────
const starContainer = document.getElementById("starfield");

function makeCSSStars(count = 120) {
  const frag = document.createDocumentFragment();
  for (let i = 0; i < count; i++) {
    const s = document.createElement("span");
    const size = Math.random() * 2 + 0.5;
    const dur  = Math.random() * 4 + 3;
    const del  = Math.random() * 6;
    s.className = "css-star";
    s.style.cssText = `
      left:${Math.random() * 100}%;
      top:${Math.random() * 100}%;
      width:${size}px;height:${size}px;
      animation-duration:${dur}s;
      animation-delay:-${del}s;
    `;
    frag.appendChild(s);
  }
  starContainer.appendChild(frag);
}

makeCSSStars();

// ── Pause all animations when tab is hidden ─────────────────────────────────
document.addEventListener("visibilitychange", () => {
  const state = document.hidden ? "paused" : "running";
  document.querySelectorAll(
    ".css-star, .orb, .hero-bg, .om-symbol, .scroll-hint, .reveal-btn"
  ).forEach((el) => {
    el.style.animationPlayState = state;
  });
});

// ── Score bar animation on HTMX load ───────────────────────────────────────
document.addEventListener("htmx:afterSwap", () => {
  requestAnimationFrame(() => {
    document.querySelectorAll(".score-bar").forEach((bar) => {
      const val = bar.dataset.val || "0";
      bar.style.width = "0%";
      requestAnimationFrame(() => { bar.style.width = `${val}%`; });
    });
  });

  const result = document.getElementById("horoscope-result");
  if (result && result.children.length > 0) {
    setTimeout(() => result.scrollIntoView({ behavior: "smooth", block: "start" }), 100);
  }
});

// ── Day button active class sync ────────────────────────────────────────────
document.querySelectorAll(".day-btn input").forEach((radio) => {
  radio.addEventListener("change", () => {
    document.querySelectorAll(".day-btn").forEach((btn) => btn.classList.remove("active"));
    radio.closest(".day-btn")?.classList.add("active");
  });
});

// ── Mode Switcher (Quick Rashi vs Janma Kundli) ─────────────────────────────
window.switchJyotishiMode = function (mode) {
  const tabRashi = document.getElementById("tab-rashi");
  const tabKundli = document.getElementById("tab-kundli");
  const panelRashi = document.getElementById("panel-rashi");
  const panelKundli = document.getElementById("panel-kundli");

  if (mode === "rashi") {
    tabRashi?.classList.add("active");
    tabRashi?.setAttribute("aria-selected", "true");
    tabKundli?.classList.remove("active");
    tabKundli?.setAttribute("aria-selected", "false");

    panelRashi?.classList.add("active");
    panelRashi?.removeAttribute("hidden");
    panelKundli?.classList.remove("active");
    panelKundli?.setAttribute("hidden", "true");
  } else {
    tabKundli?.classList.add("active");
    tabKundli?.setAttribute("aria-selected", "true");
    tabRashi?.classList.remove("active");
    tabRashi?.setAttribute("aria-selected", "false");

    panelKundli?.classList.add("active");
    panelKundli?.removeAttribute("hidden");
    panelRashi?.classList.remove("active");
    panelRashi?.setAttribute("hidden", "true");
  }
};

// ── Helper: Timezone string to UTC offset (Hours) ───────────────────────────
function getTimezoneOffsetHours(tzName, date = new Date()) {
  try {
    const formatter = new Intl.DateTimeFormat("en-US", { timeZone: tzName, timeZoneName: "longOffset" });
    const parts = formatter.formatToParts(date);
    const tzPart = parts.find(p => p.type === "timeZoneName")?.value;
    if (tzPart) {
      const match = tzPart.match(/GMT([+-])(\d{1,2}):?(\d{2})?/);
      if (match) {
        const sign = match[1] === "-" ? -1 : 1;
        const hours = parseInt(match[2], 10);
        const mins = match[3] ? parseInt(match[3], 10) : 0;
        return sign * (hours + mins / 60);
      }
    }
  } catch (e) {}
  return 5.5; // default to IST if not found
}

// ── Direct Setter for City, Latitude, Longitude, and Timezone ───────────────
window.setCityValues = function (cityName, lat, lon, tz) {
  const kCity = document.getElementById("k-city");
  const kLat = document.getElementById("k-lat");
  const kLon = document.getElementById("k-lon");
  const kTz = document.getElementById("k-tz");
  const searchInput = document.getElementById("city-search-input");
  const dropdown = document.getElementById("city-results-dropdown");

  if (kCity) kCity.value = cityName;
  if (kLat) kLat.value = parseFloat(lat).toFixed(4);
  if (kLon) kLon.value = parseFloat(lon).toFixed(4);
  if (kTz) kTz.value = tz;
  if (searchInput) searchInput.value = cityName;
  if (dropdown) dropdown.style.display = "none";
};

// ── City Search Autocomplete (Open-Meteo Geocoding) ─────────────────────────
let searchDebounceTimer = null;

window.handleCitySearchInput = function (query) {
  clearTimeout(searchDebounceTimer);
  const dropdown = document.getElementById("city-results-dropdown");
  const spinner = document.getElementById("loc-spinner");
  const trimmed = query.trim();

  if (trimmed.length < 2) {
    if (dropdown) dropdown.style.display = "none";
    if (spinner) spinner.style.display = "none";
    return;
  }

  if (spinner) spinner.style.display = "inline-block";

  searchDebounceTimer = setTimeout(async () => {
    try {
      const res = await fetch(`https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(trimmed)}&count=6&language=en&format=json`);
      if (!res.ok) throw new Error("Search failed");
      const data = await res.json();
      const results = data.results || [];
      renderCityDropdown(results);
    } catch (err) {
      console.warn("Geocoding lookup error:", err);
    } finally {
      if (spinner) spinner.style.display = "none";
    }
  }, 220);
};

function renderCityDropdown(results) {
  const dropdown = document.getElementById("city-results-dropdown");
  if (!dropdown) return;

  if (results.length === 0) {
    dropdown.innerHTML = `<div class="crd-empty">No matching places found. You can enter coordinates directly below.</div>`;
    dropdown.style.display = "block";
    return;
  }

  dropdown.innerHTML = results.map((item) => {
    const parts = [item.name, item.admin1, item.country].filter(Boolean);
    const fullName = parts.join(", ");
    const tzOffset = getTimezoneOffsetHours(item.timezone || "Asia/Kolkata");
    const latStr = item.latitude >= 0 ? `${item.latitude.toFixed(2)}°N` : `${(-item.latitude).toFixed(2)}°S`;
    const lonStr = item.longitude >= 0 ? `${item.longitude.toFixed(2)}°E` : `${(-item.longitude).toFixed(2)}°W`;

    return `
      <div class="crd-item" onclick="window.setCityValues('${fullName.replace(/'/g, "\\'")}', ${item.latitude}, ${item.longitude}, ${tzOffset})">
        <div class="crd-title">${item.name} <span class="crd-country">${item.country || ""}</span></div>
        <div class="crd-sub">${[item.admin1, item.country].filter(Boolean).join(", ")} · ${latStr}, ${lonStr} · UTC${tzOffset >= 0 ? "+" + tzOffset : tzOffset}</div>
      </div>
    `;
  }).join("");

  dropdown.style.display = "block";
}

// Close autocomplete dropdown on click outside
document.addEventListener("click", (evt) => {
  const searchWrap = document.querySelector(".location-search-wrap");
  const dropdown = document.getElementById("city-results-dropdown");
  if (dropdown && searchWrap && !searchWrap.contains(evt.target)) {
    dropdown.style.display = "none";
  }
});

// ── Use Current GPS Location (HTML5 Geolocation) ────────────────────────────
window.useCurrentLocation = function () {
  if (!navigator.geolocation) {
    alert("Geolocation is not supported by your browser.");
    return;
  }
  const searchInput = document.getElementById("city-search-input");
  if (searchInput) searchInput.placeholder = "Detecting your GPS location…";

  navigator.geolocation.getCurrentPosition(
    (pos) => {
      const lat = pos.coords.latitude;
      const lon = pos.coords.longitude;
      const tzName = Intl.DateTimeFormat().resolvedOptions().timeZone || "Asia/Kolkata";
      const tzOffset = getTimezoneOffsetHours(tzName);
      const locName = `Current Location (${lat.toFixed(2)}°, ${lon.toFixed(2)}°)`;
      window.setCityValues(locName, lat, lon, tzOffset);
    },
    (err) => {
      alert("Could not retrieve your location. Please type your city name or enter coordinates manually.");
      if (searchInput) searchInput.placeholder = "Type any city or town worldwide...";
    },
    { timeout: 8000 }
  );
};

// ── Reveal & Kundli button states during HTMX requests ──────────────────────
document.addEventListener("htmx:beforeRequest", (evt) => {
  const elt = evt.detail.elt;
  if (elt.id === "rashi-form") {
    const btn = document.getElementById("reveal-btn");
    if (btn) { btn.querySelector(".btn-text").textContent = "Reading the stars…"; btn.disabled = true; }
  } else if (elt.id === "kundli-form") {
    const btn = document.getElementById("kundli-submit-btn");
    if (btn) { btn.querySelector(".btn-text").textContent = "Calculating Janma Kundli…"; btn.disabled = true; }
  }
});

document.addEventListener("htmx:afterRequest", () => {
  const rBtn = document.getElementById("reveal-btn");
  if (rBtn) { rBtn.querySelector(".btn-text").textContent = "Reveal My Rashifal"; rBtn.disabled = false; }
  const kBtn = document.getElementById("kundli-submit-btn");
  if (kBtn) { kBtn.querySelector(".btn-text").textContent = "Compute Janma Kundli & Transits"; kBtn.disabled = false; }
});


