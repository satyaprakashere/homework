// server.ts - Pure Bun implementation (No dependencies)
import { serve, file } from "bun";
import { join } from "path";
const port = process.env.PORT || 3000;
const publicDir = join(import.meta.dir, "public");
// Helper to calculate days in month
function getDaysInMonth(year, month) {
    return new Date(year, month + 1, 0).getDate();
}
function getFirstDayOfMonth(year, month) {
    return new Date(year, month, 1).getDay();
}
// Moon phase approximation for mock Tithi
function getMoonPhaseIndex(date) {
    const epoch = new Date(1999, 7, 11).getTime(); // Known new moon
    const msPerDay = 1000 * 60 * 60 * 24;
    const synodicMonth = 29.53058867;
    const daysSinceEpoch = (date.getTime() - epoch) / msPerDay;
    const phase = (daysSinceEpoch % synodicMonth) / synodicMonth;
    return Math.floor(phase * 30); // 0-29 for 30 Tithis
}
const tithiNames = [
    "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
    "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
    "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Purnima",
    "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
    "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
    "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Amavasya"
];
const nakshatras = ["Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashirsha", "Ardra", "Punarvasu", "Pushya", "Ashlesha", "Magha"]; // Shortened for mock
const yogas = ["Vishkumbha", "Priti", "Ayushman", "Saubhagya", "Shobhana"];
const karanas = ["Bava", "Balava", "Kaulava", "Taitila", "Gara", "Vanija", "Vishti"];
function getMockPanchang(date) {
    const daySeed = date.getDate() + date.getMonth() * 30 + date.getFullYear();
    const tithiIdx = getMoonPhaseIndex(date);
    const paksha = tithiIdx < 15 ? "Shukla" : "Krishna";
    return {
        tithi: { name: `${tithiNames[tithiIdx]} (${paksha} Paksha)`, endTime: "Mock Time" },
        nakshatra: { name: nakshatras[daySeed % nakshatras.length], endTime: "Mock Time" },
        yoga: { name: yogas[daySeed % yogas.length], endTime: "Mock Time" },
        karana: { name: karanas[daySeed % karanas.length], endTime: "Mock Time" },
        sunrise: "06:15 AM",
        sunset: "06:45 PM"
    };
}
// HTML Templates
const layoutHTML = (year, month) => `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hindu Panchang Calendar</title>
    <!-- HTMX -->
    <script src="https://unpkg.com/htmx.org@1.9.6"></script>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/style.css">
</head>
<body>
    <div class="app-container">
        <header class="app-header">
            <h1>Panchang</h1>
            <p>Vedic Timekeeping</p>
        </header>
        <main class="main-content">
            <section class="calendar-section" hx-get="/calendar?year=${year}&month=${month}" hx-trigger="load" hx-swap="innerHTML">
                <div class="loading">Loading calendar...</div>
            </section>
            <section class="details-section" id="panchang-details">
                <div class="empty-state">Select a date to view Panchang details.</div>
            </section>
        </main>
    </div>
</body>
</html>
`;
const calendarHTML = (year, month, monthName, daysInMonth, firstDay, nextMonth, nextYear, prevMonth, prevYear) => {
    let daysHtml = '';
    for (let i = 0; i < firstDay; i++) {
        daysHtml += '<div class="day empty"></div>';
    }
    for (let d = 1; d <= daysInMonth; d++) {
        const mm = String(month + 1).padStart(2, '0');
        const dd = String(d).padStart(2, '0');
        const dateStr = `${year}-${mm}-${dd}`;
        daysHtml += `
            <div class="day" hx-get="/panchang?date=${dateStr}" hx-target="#panchang-details" hx-swap="innerHTML">
                ${d}
            </div>
        `;
    }
    return `
    <div class="calendar-header">
        <button hx-get="/calendar?year=${prevYear}&month=${prevMonth}" hx-target=".calendar-section" hx-swap="innerHTML" class="nav-btn">&larr; Prev</button>
        <h2>${monthName} ${year}</h2>
        <button hx-get="/calendar?year=${nextYear}&month=${nextMonth}" hx-target=".calendar-section" hx-swap="innerHTML" class="nav-btn">Next &rarr;</button>
    </div>
    <div class="calendar-grid">
        <div class="day-name">Sun</div><div class="day-name">Mon</div><div class="day-name">Tue</div>
        <div class="day-name">Wed</div><div class="day-name">Thu</div><div class="day-name">Fri</div><div class="day-name">Sat</div>
        ${daysHtml}
    </div>
    `;
};
const detailsHTML = (date, panchang) => `
<div class="details-card fade-in">
    <h3>Panchang for ${date}</h3>
    <div class="details-grid">
        <div class="detail-item"><span class="label">Sunrise</span><span class="value">${panchang.sunrise}</span></div>
        <div class="detail-item"><span class="label">Sunset</span><span class="value">${panchang.sunset}</span></div>
        <div class="detail-item full-width">
            <span class="label">Tithi</span><span class="value">${panchang.tithi.name}</span>
            <span class="sub-text">ends at ${panchang.tithi.endTime}</span>
        </div>
        <div class="detail-item full-width">
            <span class="label">Nakshatra</span><span class="value">${panchang.nakshatra.name}</span>
        </div>
        <div class="detail-item"><span class="label">Yoga</span><span class="value">${panchang.yoga.name}</span></div>
        <div class="detail-item"><span class="label">Karana</span><span class="value">${panchang.karana.name}</span></div>
    </div>
</div>
`;
serve({
    port,
    async fetch(req) {
        const url = new URL(req.url);
        // Serve static files
        if (url.pathname === "/style.css") {
            return new Response(file(join(publicDir, "style.css")));
        }
        if (url.pathname === "/") {
            const today = new Date();
            return new Response(layoutHTML(today.getFullYear(), today.getMonth()), {
                headers: { "Content-Type": "text/html" }
            });
        }
        if (url.pathname === "/calendar") {
            let year = parseInt(url.searchParams.get("year") || "");
            let month = parseInt(url.searchParams.get("month") || "");
            if (isNaN(year) || isNaN(month)) {
                const today = new Date();
                year = today.getFullYear();
                month = today.getMonth();
            }
            let nextMonth = month + 1;
            let nextYear = year;
            if (nextMonth > 11) {
                nextMonth = 0;
                nextYear++;
            }
            let prevMonth = month - 1;
            let prevYear = year;
            if (prevMonth < 0) {
                prevMonth = 11;
                prevYear--;
            }
            const daysInMonth = getDaysInMonth(year, month);
            const firstDay = getFirstDayOfMonth(year, month);
            const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
            return new Response(calendarHTML(year, month, monthNames[month], daysInMonth, firstDay, nextMonth, nextYear, prevMonth, prevYear), {
                headers: { "Content-Type": "text/html" }
            });
        }
        if (url.pathname === "/panchang") {
            const dateStr = url.searchParams.get("date");
            if (!dateStr)
                return new Response("Date required", { status: 400 });
            const date = new Date(dateStr);
            const panchangData = getMockPanchang(date);
            return new Response(detailsHTML(date.toDateString(), panchangData), {
                headers: { "Content-Type": "text/html" }
            });
        }
        return new Response("Not Found", { status: 404 });
    }
});
console.log(`Panchang HTMX Server running at http://localhost:${port}`);
