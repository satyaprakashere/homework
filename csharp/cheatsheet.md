# C# & .NET Learning Cheat Sheet ⚡

A modern guide for **C# 10 – C# 13/14** and **.NET 10** highlighting language fundamentals, high-performance low-allocation primitives, asynchronous concurrency pipelines, modern LINQ, and ASP.NET Core Minimal APIs.

---

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `dotnet run` | Run the project interactively via the terminal menu. |
| `dotnet run -- 1` | Run specific showcase (e.g. `1`=Language, `2`=Perf, `3`=Async, `4`=LINQ, `5`=JSON, `6`=Web). |
| `dotnet run -- all` | Execute all CLI showcase modules sequentially. |
| `dotnet run -- web` | Start the embedded ASP.NET Core Minimal API server and web dashboard on `http://localhost:5050`. |
| `dotnet build` | Compile the project and check for diagnostic warnings and errors. |
| `dotnet watch` | Hot-reload dev watcher that automatically restarts or updates on file changes. |
| `dotnet test` | Discover and run automated test suites. |
| `dotnet format` | Format and style codebase according to `.editorconfig` rules. |
| `dotnet publish -c Release -r osx-arm64 --self-contained` | Produce a standalone, self-contained native deployment bundle. |
| `dotnet publish -c Release /p:PublishAot=true` | Compile directly to an ahead-of-time (Native AOT) machine code binary without JIT overhead. |

---

## 📂 Showcase Architecture & Capabilities

| Module | File | Key Highlights & Concepts Demonstrated |
| :--- | :--- | :--- |
| **CLI Runner Hub** | **[Program.cs](file:///Users/prakash/Documents/homework/csharp/Program.cs)** | Interactive ANSI colored CLI menu, parameter routing (`--modern`, `--perf`, `--async`, `--linq`, `--json`, `--web`), clean exit handling. |
| **Modern C# Language** | **[Features/01_ModernLanguageFeatures.cs](file:///Users/prakash/Documents/homework/csharp/Features/01_ModernLanguageFeatures.cs)** | Primary constructors, relational/property/list pattern matching, records, `with` non-destructive mutation, collection expressions `[..odds]`, raw strings `"""`, UTF-8 byte literals `"..."u8`. |
| **High Performance & Memory** | **[Features/02_HighPerformanceAndMemory.cs](file:///Users/prakash/Documents/homework/csharp/Features/02_HighPerformanceAndMemory.cs)** | `Span<T>` zero-allocation tokenization and parsing, `stackalloc` buffers, `ref struct`, `ArrayPool<T>.Shared` buffer recycling, SIMD hardware acceleration with `Vector<T>`. |
| **Async & Concurrency** | **[Features/03_AsyncAndConcurrency.cs](file:///Users/prakash/Documents/homework/csharp/Features/03_AsyncAndConcurrency.cs)** | Modern `System.Threading.Lock` (.NET 9+), `IAsyncEnumerable<T>` async streaming, `System.Threading.Channels` backpressured producer-consumer, `Parallel.ForEachAsync` concurrency bounding. |
| **LINQ & Functional C#** | **[Features/04_LinqAndFunctional.cs](file:///Users/prakash/Documents/homework/csharp/Features/04_LinqAndFunctional.cs)** | .NET 9 `CountBy`, `AggregateBy`, and `Index()`, `Chunk`, `Zip`, `DistinctBy`, `MaxBy`, declarative query comprehension syntax, function currying and composition pipelines. |
| **Serialization & JSON** | **[Features/05_SerializationAndJson.cs](file:///Users/prakash/Documents/homework/csharp/Features/05_SerializationAndJson.cs)** | Polymorphic JSON with `[JsonPolymorphic]` & `[JsonDerivedType]`, `JsonDocument` lightweight DOM traversal, `JsonNode` mutations, high-throughput `Utf8JsonWriter`. |
| **Minimal API & Web Dashboard** | **[Features/06_MinimalApiAndWeb.cs](file:///Users/prakash/Documents/homework/csharp/Features/06_MinimalApiAndWeb.cs)** | Self-contained ASP.NET Core web server, route groups, endpoint filters (timing/logging), typed results, Server-Sent Events (SSE) live streaming, embedded dark-mode HTML dashboard. |

---

## 💡 Modern C# Syntax Quick Reference

### 1. Primary Constructors (C# 12+)
```csharp
// Parameters are in scope across the entire class body
public sealed class OrderProcessor(ILogger logger, string connectionString)
{
    public void Process(int orderId) =>
        logger.LogInfo($"Order {orderId} processed via {connectionString}");
}
```

### 2. Pattern Matching (Relational, Property, & List Patterns)
```csharp
// Relational and logical patterns
string status = score switch
{
    >= 90 => "Grade A (Honors)",
    >= 75 and < 90 => "Grade B",
    < 50 => "Failing",
    _ => "Passing"
};

// List & slice patterns
string listSummary = numbers switch
{
    [] => "Empty",
    [var single] => $"Only item: {single}",
    [var head, .. var middle, var tail] => $"Head: {head}, Middle: {middle.Length}, Tail: {tail}"
};

// Property patterns
if (user is { Role: "Admin", IsActive: true, Age: >= 18 })
{
    GrantAccess();
}
```

### 3. Collection Expressions & Spread (C# 12+)
```csharp
int[] first = [1, 2, 3];
int[] second = [4, 5, 6];

// Unified syntax across T[], List<T>, Span<T>, ImmutableArray<T>
int[] combined = [0, ..first, ..second, 7];
ReadOnlySpan<char> chars = ['H', 'e', 'l', 'l', 'o'];
```

### 4. Records & Non-Destructive Mutation
```csharp
// Positional record with value-based equality and deconstruction
public record GeoPoint(double Latitude, double Longitude);

var point1 = new GeoPoint(37.7749, -122.4194);

// Non-destructive mutation ('with' expression)
var point2 = point1 with { Latitude = 47.6062 };

Console.WriteLine(point1 == point2); // False (value equality)
```

### 5. High-Performance Zero-Allocation Slicing (`Span<T>`)
```csharp
string line = "2026-09-08|ERROR|Database timeout";
ReadOnlySpan<char> span = line.AsSpan();

int firstPipe = span.IndexOf('|');
ReadOnlySpan<char> date = span[..firstPipe];               // 0 allocations!
ReadOnlySpan<char> remainder = span[(firstPipe + 1)..];
ReadOnlySpan<char> level = remainder[..remainder.IndexOf('|')]; // 0 allocations!
```

### 6. Modern `System.Threading.Lock` (.NET 9+ / C# 13)
```csharp
public sealed class ThreadSafeQueue
{
    // New dedicated lock object replacing traditional object locks
    private readonly Lock _lock = new();

    public void Enqueue(string item)
    {
        lock (_lock)
        {
            // Lock enters and exits with optimized fast-path CPU primitives
        }
    }
}
```

### 7. Asynchronous Streaming (`IAsyncEnumerable<T>`)
```csharp
public async IAsyncEnumerable<int> GenerateDataAsync([EnumeratorCancellation] CancellationToken ct = default)
{
    for (int i = 0; i < 10; i++)
    {
        await Task.Delay(100, ct);
        yield return i;
    }
}

// Consuming with await foreach
await foreach (var item in GenerateDataAsync())
{
    Console.WriteLine(item);
}
```

### 8. .NET 9 LINQ Enhancements (`CountBy`, `AggregateBy`, `Index`)
```csharp
// Count frequency per key without full GroupBy overhead
foreach (var (country, count) in users.CountBy(u => u.Country))
{
    Console.WriteLine($"{country}: {count}");
}

// Fold values per key
var totalSpendPerCategory = orders.AggregateBy(
    keySelector: o => o.Category,
    seed: 0m,
    func: (acc, o) => acc + o.TotalAmount
);

// Zero-allocation (index, item) enumeration
foreach (var (index, item) in topScores.Index())
{
    Console.WriteLine($"Rank #{index + 1}: {item}");
}
```

### 9. ASP.NET Core Minimal API
```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/api/items/{id:int}", (int id) =>
    id == 42 ? Results.Ok(new { id, name = "Special Item" }) : Results.NotFound());

await app.RunAsync();
```

---

## 🚀 How to Run the Showcase

```bash
cd /Users/prakash/Documents/homework/csharp

# Run all CLI examples sequentially
dotnet run -- all

# Run specific modules
dotnet run -- 1      # Modern C# Language Features
dotnet run -- 2      # High-Performance Memory (Span, SIMD, ArrayPool)
dotnet run -- 3      # Async & Concurrency (Channels, Streams, Lock)
dotnet run -- 4      # LINQ & Functional (.NET 9 CountBy, AggregateBy)
dotnet run -- 5      # JSON & Serialization (Polymorphic JSON)
dotnet run -- 6      # Launch ASP.NET Core Web Server & Dashboard at http://localhost:5050

# Launch interactive menu
dotnet run
```
