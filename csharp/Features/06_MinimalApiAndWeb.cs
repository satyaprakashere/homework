namespace CSharpShowcase.Features;

using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

/// <summary>
/// Demonstrates modern ASP.NET Core Minimal APIs (.NET 10):
/// Route groups, endpoint filters, typed results, streaming endpoints, and dependency injection.
/// Also serves an interactive web dashboard directly at root "/".
/// </summary>
public static class MinimalApiAndWeb
{
    public sealed record Item(int Id, string Name, string Category, decimal Price);
    public sealed record CreateItemRequest(string Name, string Category, decimal Price);

    public static async Task StartServerAsync(string[] args, int port = 5050)
    {
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine("\n========================================================");
        Console.WriteLine(" 06: ASP.NET CORE MINIMAL APIS & WEB SERVER");
        Console.WriteLine("========================================================");
        Console.ResetColor();

        var builder = WebApplication.CreateBuilder(args);
        builder.Services.AddProblemDetails();

        // In-memory thread-safe state store
        builder.Services.AddSingleton<ItemRepository>();

        var app = builder.Build();

        var repo = app.Services.GetRequiredService<ItemRepository>();

        // 1. Root: Serves a rich, modern HTML dashboard
        app.MapGet("/", () => Results.Content(GetHtmlDashboard(), "text/html"));

        // 2. Health & System Telemetry Endpoint
        app.MapGet("/health", () => Results.Ok(new
        {
            status = "HEALTHY",
            framework = Environment.Version.ToString(),
            os = Environment.OSVersion.ToString(),
            processorCount = Environment.ProcessorCount,
            memoryAllocatedMb = GC.GetTotalMemory(false) / (1024 * 1024),
            timestamp = DateTime.UtcNow
        }));

        // 3. API Route Group with Logging / Timing Endpoint Filter
        var api = app.MapGroup("/api/items")
            .AddEndpointFilter(async (invocationContext, next) =>
            {
                var stopwatch = System.Diagnostics.Stopwatch.StartNew();
                var result = await next(invocationContext);
                stopwatch.Stop();
                Console.WriteLine($"   [API Filter] {invocationContext.HttpContext.Request.Method} {invocationContext.HttpContext.Request.Path} completed in {stopwatch.ElapsedMilliseconds}ms");
                return result;
            });

        // GET all items
        api.MapGet("/", (ItemRepository r) => Results.Ok(r.GetAll()));

        // GET by ID
        api.MapGet("/{id:int}", (int id, ItemRepository r) =>
        {
            var item = r.GetById(id);
            return item is not null ? Results.Ok(item) : Results.NotFound(new { message = $"Item with ID {id} was not found." });
        });

        // POST create item
        api.MapPost("/", (CreateItemRequest request, ItemRepository r) =>
        {
            if (string.IsNullOrWhiteSpace(request.Name) || request.Price <= 0)
            {
                return Results.BadRequest(new { message = "Valid name and positive price are required." });
            }

            var created = r.Add(request.Name, request.Category, request.Price);
            return Results.Created($"/api/items/{created.Id}", created);
        });

        // 4. Server-Sent Events (SSE) Live Stream Endpoint
        app.MapGet("/api/events", async (HttpContext context, CancellationToken ct) =>
        {
            context.Response.Headers.Append("Content-Type", "text/event-stream");
            context.Response.Headers.Append("Cache-Control", "no-cache");
            context.Response.Headers.Append("Connection", "keep-alive");

            int tick = 0;
            while (!ct.IsCancellationRequested && tick < 10)
            {
                tick++;
                string eventData = $"data: {{\"event\": \"heartbeat\", \"seq\": {tick}, \"time\": \"{DateTime.UtcNow:HH:mm:ss.fff}\"}}\n\n";
                await context.Response.WriteAsync(eventData, ct);
                await context.Response.Body.FlushAsync(ct);
                await Task.Delay(1000, ct);
            }
        });

        string url = $"http://localhost:{port}";
        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine($"\n🚀 Minimal API server is launching at: {url}");
        Console.WriteLine($"   - Interactive Web Dashboard: {url}/");
        Console.WriteLine($"   - Health & Telemetry:        {url}/health");
        Console.WriteLine($"   - Items API:                 {url}/api/items");
        Console.WriteLine($"   - Server-Sent Events (SSE):  {url}/api/events");
        Console.ForegroundColor = ConsoleColor.DarkGray;
        Console.WriteLine("   Press Ctrl+C in terminal to stop server.\n");
        Console.ResetColor();

        await app.RunAsync(url);
    }

    public sealed class ItemRepository
    {
        private readonly List<Item> _items =
        [
            new(1, "High-Throughput Microservice", "Cloud", 120.00m),
            new(2, "Native AOT ARM64 Binary", "Performance", 85.50m),
            new(3, "Zero-Allocation Span Parser", "Memory", 45.00m)
        ];
        private int _nextId = 4;
        private readonly Lock _lock = new();

        public IReadOnlyList<Item> GetAll()
        {
            lock (_lock) return [.._items];
        }

        public Item? GetById(int id)
        {
            lock (_lock) return _items.FirstOrDefault(i => i.Id == id);
        }

        public Item Add(string name, string category, decimal price)
        {
            lock (_lock)
            {
                var item = new Item(_nextId++, name, category, price);
                _items.Add(item);
                return item;
            }
        }
    }

    private static string GetHtmlDashboard() => """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>.NET 10 & C# Capabilities Showcase</title>
        <style>
            :root {
                --bg: #0d1117;
                --surface: #161b22;
                --surface-hover: #1f242c;
                --border: #30363d;
                --primary: #6366f1;
                --primary-glow: rgba(99, 102, 241, 0.25);
                --accent: #10b981;
                --text: #f0f6fc;
                --text-muted: #8b949e;
                --code-bg: #090d12;
            }
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                background-color: var(--bg);
                color: var(--text);
                line-height: 1.6;
                padding: 2rem;
            }
            .container { max-width: 1100px; margin: 0 auto; }
            header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                border-bottom: 1px solid var(--border);
                padding-bottom: 1.5rem;
                margin-bottom: 2rem;
            }
            .badge {
                background: linear-gradient(135deg, #6366f1, #a855f7);
                color: white;
                font-size: 0.8rem;
                font-weight: 700;
                padding: 0.3rem 0.8rem;
                border-radius: 9999px;
                text-transform: uppercase;
                letter-spacing: 0.05em;
            }
            h1 { font-size: 2rem; font-weight: 800; display: flex; align-items: center; gap: 0.75rem; }
            p.sub { color: var(--text-muted); font-size: 1.05rem; }
            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 1.5rem; margin-bottom: 2rem; }
            .card {
                background-color: var(--surface);
                border: 1px solid var(--border);
                border-radius: 12px;
                padding: 1.5rem;
                transition: transform 0.2s ease, border-color 0.2s ease;
            }
            .card:hover {
                transform: translateY(-2px);
                border-color: var(--primary);
                box-shadow: 0 8px 24px var(--primary-glow);
            }
            .card h3 { font-size: 1.25rem; margin-bottom: 0.75rem; color: #fff; }
            .card p { color: var(--text-muted); font-size: 0.95rem; margin-bottom: 1rem; }
            .btn {
                display: inline-block;
                background-color: var(--primary);
                color: white;
                text-decoration: none;
                padding: 0.5rem 1rem;
                border-radius: 6px;
                font-weight: 600;
                font-size: 0.9rem;
                cursor: pointer;
                border: none;
                transition: background-color 0.2s ease;
            }
            .btn:hover { background-color: #4f46e5; }
            .btn-secondary {
                background-color: #21262d;
                color: var(--text);
                border: 1px solid var(--border);
            }
            .btn-secondary:hover { background-color: #30363d; }
            pre {
                background-color: var(--code-bg);
                border: 1px solid var(--border);
                border-radius: 8px;
                padding: 1rem;
                font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
                font-size: 0.85rem;
                overflow-x: auto;
                color: #58a6ff;
            }
            #live-feed {
                height: 140px;
                overflow-y: auto;
                font-size: 0.85rem;
                padding: 0.75rem;
                background: var(--code-bg);
                border-radius: 6px;
                border: 1px solid var(--border);
                color: var(--accent);
            }
        </style>
    </head>
    <body>
        <div class="container">
            <header>
                <div>
                    <h1>⚡ .NET 10 & C# Minimal API</h1>
                    <p class="sub">High-Performance ASP.NET Core Minimal API Showcase</p>
                </div>
                <div class="badge">.NET 10.0 Native</div>
            </header>

            <div class="grid">
                <div class="card">
                    <h3>🩺 Telemetry & Health</h3>
                    <p>Live endpoint exposing runtime metrics, memory utilization, and hardware cores.</p>
                    <a href="/health" target="_blank" class="btn btn-secondary">Open /health</a>
                </div>
                <div class="card">
                    <h3>📦 RESTful Items Collection</h3>
                    <p>Thread-safe CRUD operations with modern endpoint filters & typed results.</p>
                    <a href="/api/items" target="_blank" class="btn btn-secondary">Open /api/items</a>
                </div>
                <div class="card">
                    <h3>📡 Live Server-Sent Events (SSE)</h3>
                    <p>Asynchronous HTTP event streaming with zero-allocation buffers.</p>
                    <button class="btn" onclick="startStream()">Connect Event Stream</button>
                </div>
            </div>

            <div class="card" style="margin-bottom: 2rem;">
                <h3>Live SSE Stream Feed</h3>
                <div id="live-feed">Click "Connect Event Stream" above to listen to live asynchronous events...</div>
            </div>

            <div class="card">
                <h3>Try Adding An Item via POST</h3>
                <div style="display: flex; gap: 0.5rem; margin-top: 1rem;">
                    <input type="text" id="itemName" placeholder="Item Name" style="background:#090d12; border:1px solid #30363d; color:#fff; padding:0.5rem; border-radius:6px; flex:2;">
                    <input type="text" id="itemCategory" placeholder="Category" style="background:#090d12; border:1px solid #30363d; color:#fff; padding:0.5rem; border-radius:6px; flex:1;">
                    <input type="number" id="itemPrice" placeholder="Price" style="background:#090d12; border:1px solid #30363d; color:#fff; padding:0.5rem; border-radius:6px; width:100px;">
                    <button class="btn" onclick="createItem()">Add Item</button>
                </div>
                <pre id="post-result" style="margin-top: 1rem; display: none;"></pre>
            </div>
        </div>

        <script>
            function startStream() {
                const feed = document.getElementById('live-feed');
                feed.innerHTML = "Subscribed to /api/events...<br>";
                const es = new EventSource('/api/events');
                es.onmessage = (event) => {
                    const row = document.createElement('div');
                    row.textContent = `[${new Date().toLocaleTimeString()}] SSE: ` + event.data;
                    feed.prepend(row);
                };
                es.onerror = () => {
                    feed.prepend(document.createTextNode("Stream connection closed.\n"));
                    es.close();
                };
            }

            async function createItem() {
                const name = document.getElementById('itemName').value;
                const category = document.getElementById('itemCategory').value;
                const price = parseFloat(document.getElementById('itemPrice').value);
                const resPre = document.getElementById('post-result');

                const res = await fetch('/api/items', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ name, category, price })
                });
                const data = await res.json();
                resPre.style.display = 'block';
                resPre.textContent = JSON.stringify(data, null, 2);
            }
        </script>
    </body>
    </html>
    """;
}
