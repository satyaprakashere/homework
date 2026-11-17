import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const PORT = process.env.PORT || 3008;

// In-memory data store for the showcase
let velocity = 6;
let gpuAcceleration = true;
let activeCategory = 'All';

let services = [
  { id: 1, name: 'api-gateway-edge', category: 'Network', latency: 12, status: 'active' },
  { id: 2, name: 'vector-search-engine', category: 'Compute', latency: 28, status: 'active' },
  { id: 3, name: 'redis-cache-cluster', category: 'Storage', latency: 4, status: 'active' },
  { id: 4, name: 'neural-inference-worker', category: 'Compute', latency: 64, status: 'standby' },
  { id: 5, name: 's3-blob-replicator', category: 'Storage', latency: 45, status: 'active' },
];

function renderMetricsHtml() {
  const throughput = (velocity * 482).toLocaleString();
  const memoryUtilization = Math.min(96, Math.round(32 + velocity * 3.2));
  const activeCount = services.length;
  const avgLatency = gpuAcceleration ? '14.2 ms' : '28.6 ms';
  const latencyBadge = gpuAcceleration ? '-50% Latency' : 'Standard';

  return `
    <div class="glass-panel metric-card">
      <div class="metric-card-top">
        <span class="metric-label">Cluster Throughput</span>
        <div class="metric-icon-box" style="background: rgba(56, 189, 248, 0.2); box-shadow: 0 0 16px rgba(56, 189, 248, 0.4);">⚡</div>
      </div>
      <div class="metric-value">${throughput} req/s</div>
      <div class="metric-footer">
        <span class="badge-growth-pos">+18.4%</span>
        <span style="color: var(--text-muted)">vs previous period</span>
      </div>
      <div class="progress-bar-track">
        <div class="progress-bar-fill" style="width: ${Math.min(100, velocity * 5)}%"></div>
      </div>
    </div>

    <div class="glass-panel metric-card">
      <div class="metric-card-top">
        <span class="metric-label">Memory Allocation</span>
        <div class="metric-icon-box" style="background: rgba(168, 85, 247, 0.2); box-shadow: 0 0 16px rgba(168, 85, 247, 0.4);">🧠</div>
      </div>
      <div class="metric-value">${memoryUtilization}%</div>
      <div class="metric-footer">
        <span class="badge-growth-neutral">${gpuAcceleration ? 'GPU Offload' : 'CPU Only'}</span>
        <span style="color: var(--text-muted)">vs previous period</span>
      </div>
      <div class="progress-bar-track">
        <div class="progress-bar-fill" style="width: ${memoryUtilization}%"></div>
      </div>
    </div>

    <div class="glass-panel metric-card">
      <div class="metric-card-top">
        <span class="metric-label">Active Nodes</span>
        <div class="metric-icon-box" style="background: rgba(168, 185, 129, 0.2); box-shadow: 0 0 16px rgba(16, 185, 129, 0.4);">🌐</div>
      </div>
      <div class="metric-value">${activeCount}</div>
      <div class="metric-footer">
        <span class="badge-growth-pos">+2 Nodes</span>
        <span style="color: var(--text-muted)">vs previous period</span>
      </div>
      <div class="progress-bar-track">
        <div class="progress-bar-fill" style="width: ${Math.min(100, activeCount * 15)}%"></div>
      </div>
    </div>

    <div class="glass-panel metric-card">
      <div class="metric-card-top">
        <span class="metric-label">Average Latency</span>
        <div class="metric-icon-box" style="background: rgba(245, 158, 11, 0.2); box-shadow: 0 0 16px rgba(245, 158, 11, 0.4);">⏱️</div>
      </div>
      <div class="metric-value">${avgLatency}</div>
      <div class="metric-footer">
        <span class="badge-growth-pos">${latencyBadge}</span>
        <span style="color: var(--text-muted)">vs previous period</span>
      </div>
    </div>
  `;
}

function renderServiceItemHtml(item) {
  const isAct = item.status === 'active';
  return `
    <div id="service-${item.id}" class="data-item">
      <div>
        <div style="font-weight: 600; font-size: 0.9rem;">${item.name}</div>
        <div style="font-size: 0.75rem; color: var(--text-muted); font-family: var(--font-mono);">
          ${item.category} • Latency: ${item.latency}ms
        </div>
      </div>
      <button
        hx-post="/api/services/${item.id}/toggle"
        hx-target="#service-${item.id}"
        hx-swap="outerHTML"
        class="status-badge ${isAct ? 'status-active' : 'status-standby'}"
        style="border: none; cursor: pointer;"
        title="Click to toggle status via HTMX swap"
      >
        ${item.status} ⚡
      </button>
    </div>
  `;
}

function renderServiceListHtml(search = '', category = 'All') {
  const filtered = services.filter((item) => {
    const matchesSearch = item.name.toLowerCase().includes(search.toLowerCase());
    const matchesCat = category === 'All' || item.category === category;
    return matchesSearch && matchesCat;
  });

  if (filtered.length === 0) {
    return `<div style="text-align: center; padding: 2rem; color: var(--text-muted);">
      No services match "${search}" in category "${category}"
    </div>`;
  }

  return filtered.map(renderServiceItemHtml).join('');
}

const server = http.createServer(async (req, res) => {
  const parsedUrl = new URL(req.url, `http://${req.headers.host}`);
  const pathname = parsedUrl.pathname;

  // Serve static files
  if (pathname === '/' || pathname === '/index.html') {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    fs.createReadStream(path.join(__dirname, 'index.html')).pipe(res);
    return;
  }

  if (pathname === '/public/style.css') {
    res.writeHead(200, { 'Content-Type': 'text/css' });
    fs.createReadStream(path.join(__dirname, 'public', 'style.css')).pipe(res);
    return;
  }

  if (pathname === '/public/htmx.min.js') {
    res.writeHead(200, { 'Content-Type': 'application/javascript' });
    fs.createReadStream(path.join(__dirname, 'public', 'htmx.min.js')).pipe(res);
    return;
  }

  // HTMX Fragment: Metrics Update
  if (pathname === '/api/metrics' && req.method === 'GET') {
    const vel = parsedUrl.searchParams.get('velocity');
    if (vel) velocity = parseInt(vel, 10);
    const gpu = parsedUrl.searchParams.get('gpu');
    if (gpu !== null) gpuAcceleration = gpu === 'true' || gpu === 'on';

    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(renderMetricsHtml());
    return;
  }

  // HTMX Fragment: Services list / Search-as-you-type
  if (pathname === '/api/services' && req.method === 'GET') {
    const search = parsedUrl.searchParams.get('search') || '';
    const cat = parsedUrl.searchParams.get('category') || activeCategory;
    activeCategory = cat;

    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(renderServiceListHtml(search, activeCategory));
    return;
  }

  // HTMX Fragment: Set active category tab
  if (pathname === '/api/category' && req.method === 'POST') {
    const cat = parsedUrl.searchParams.get('cat') || 'All';
    activeCategory = cat;
    const search = parsedUrl.searchParams.get('search') || '';

    // Re-render categories tabs + services
    const tabs = ['All', 'Compute', 'Storage', 'Network'].map((c) => {
      const active = c === activeCategory ? 'active' : '';
      return `<button
        role="tab"
        hx-post="/api/category?cat=${c}"
        hx-target="#tab-and-services"
        hx-swap="outerHTML"
        class="segmented-button ${active}"
      >${c}</button>`;
    }).join('');

    const html = `
      <div id="tab-and-services">
        <div class="control-group">
          <div class="control-label">
            <span>Active Viewport</span>
            <span class="control-hint">hx-post / HTML Fragment Swap</span>
          </div>
          <div class="segmented-nav" role="tablist">
            ${tabs}
          </div>
        </div>
        <div id="services-container" class="data-list">
          ${renderServiceListHtml(search, activeCategory)}
        </div>
      </div>
    `;

    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(html);
    return;
  }

  // HTMX Fragment: Add New Service
  if (pathname === '/api/services' && req.method === 'POST') {
    let body = '';
    req.on('data', (chunk) => (body += chunk));
    req.on('end', () => {
      const params = new URLSearchParams(body);
      const name = (params.get('name') || '').trim();
      const cat = params.get('category') || 'Compute';

      if (name) {
        const newService = {
          id: Date.now(),
          name,
          category: cat,
          latency: Math.floor(Math.random() * 40) + 5,
          status: 'active',
        };
        services.unshift(newService);
        res.writeHead(200, {
          'Content-Type': 'text/html; charset=utf-8',
          'HX-Trigger': 'serviceAdded',
        });
        res.end(renderServiceItemHtml(newService));
      } else {
        res.writeHead(400);
        res.end();
      }
    });
    return;
  }

  // HTMX Fragment: Toggle service status inline
  const toggleMatch = pathname.match(/^\/api\/services\/(\d+)\/toggle$/);
  if (toggleMatch && req.method === 'POST') {
    const id = parseInt(toggleMatch[1], 10);
    const item = services.find((s) => s.id === id);
    if (item) {
      item.status = item.status === 'active' ? 'standby' : 'active';
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(renderServiceItemHtml(item));
    } else {
      res.writeHead(404);
      res.end();
    }
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

let currentPort = PORT;

function startServer(port) {
  currentPort = port;
  server.listen(port, () => {
    console.log(`⚡ HTMX UI Studio server listening at http://localhost:${server.address().port}`);
  });
}

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE' && currentPort < PORT + 10) {
    currentPort += 1;
    console.log(`Port in use, trying ${currentPort}...`);
    startServer(currentPort);
  } else {
    console.error(`Server error: ${err.message}`);
    process.exit(1);
  }
});

startServer(PORT);
