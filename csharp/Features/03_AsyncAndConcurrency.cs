namespace CSharpShowcase.Features;

using System.Diagnostics;
using System.Runtime.CompilerServices;
using System.Threading.Channels;

/// <summary>
/// Demonstrates modern C# / .NET asynchronous workflows and concurrency patterns:
/// C# 13 System.Threading.Lock, IAsyncEnumerable streaming, Channels, and Parallel.ForEachAsync.
/// </summary>
public static class AsyncAndConcurrency
{
    public static async Task RunAsync()
    {
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine("\n========================================================");
        Console.WriteLine(" 03: ASYNC & CONCURRENCY CAPABILITIES");
        Console.WriteLine("========================================================");
        Console.ResetColor();

        DemonstrateModernLock();
        await DemonstrateAsyncStreamsAsync();
        await DemonstrateChannelsProducerConsumerAsync();
        await DemonstrateParallelForEachAsync();
    }

    // --- 1. System.Threading.Lock (C# 13 / .NET 9+) ---
    private sealed class ThreadSafeCounter
    {
        // In .NET 9 / C# 13, System.Threading.Lock provides faster, cleaner monitor locks
        private readonly Lock _gate = new();
        private int _count;

        public void Increment()
        {
            lock (_gate)
            {
                _count++;
            }
        }

        public int Value
        {
            get
            {
                lock (_gate)
                {
                    return _count;
                }
            }
        }
    }

    private static void DemonstrateModernLock()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[1] Modern System.Threading.Lock (C# 13 / .NET 9+)");
        Console.ResetColor();

        var counter = new ThreadSafeCounter();
        const int iterations = 50_000;

        Parallel.For(0, iterations, _ => counter.Increment());

        Console.WriteLine($"   Completed {iterations:N0} concurrent increments across thread pool.");
        Console.WriteLine($"   Final counter value: {counter.Value:N0} (Matches expectation: {counter.Value == iterations})");
    }

    // --- 2. IAsyncEnumerable<T> Asynchronous Streaming ---
    private static async IAsyncEnumerable<StockTick> StreamStockTicksAsync(
        string symbol,
        int count,
        [EnumeratorCancellation] CancellationToken ct = default)
    {
        var random = new Random(77);
        decimal price = 180.50m;

        for (int i = 0; i < count; i++)
        {
            if (ct.IsCancellationRequested) yield break;

            await Task.Delay(40, ct); // Simulate asynchronous network payload arrival
            decimal delta = (decimal)(random.NextDouble() * 4.0 - 2.0);
            price = Math.Round(price + delta, 2);

            yield return new StockTick(symbol, price, DateTime.UtcNow);
        }
    }

    private readonly record struct StockTick(string Symbol, decimal Price, DateTime Timestamp);

    private static async Task DemonstrateAsyncStreamsAsync()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[2] IAsyncEnumerable<T> Asynchronous Streaming (await foreach)");
        Console.ResetColor();

        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(3));

        Console.WriteLine("   Subscribing to live mock price feed for 'MSFT'...");
        await foreach (var tick in StreamStockTicksAsync("MSFT", 5, cts.Token))
        {
            Console.WriteLine($"   [{tick.Timestamp:HH:mm:ss.fff}] {tick.Symbol} => ${tick.Price}");
        }
    }

    // --- 3. High-Throughput Channels (System.Threading.Channels) ---
    private static async Task DemonstrateChannelsProducerConsumerAsync()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[3] High-Performance Channels (Producer-Consumer Pattern)");
        Console.ResetColor();

        // Bounded channel provides backpressure when consumer falls behind
        var channel = Channel.CreateBounded<string>(new BoundedChannelOptions(capacity: 5)
        {
            FullMode = BoundedChannelFullMode.Wait,
            SingleWriter = false,
            SingleReader = true
        });

        // Producer task
        var producer = Task.Run(async () =>
        {
            for (int i = 1; i <= 6; i++)
            {
                string job = $"Task-Payload-#{i}";
                await channel.Writer.WriteAsync(job);
                Console.WriteLine($"     [Producer] Dispatched -> {job}");
                await Task.Delay(25);
            }
            channel.Writer.Complete();
        });

        // Consumer task
        var consumer = Task.Run(async () =>
        {
            while (await channel.Reader.WaitToReadAsync())
            {
                while (channel.Reader.TryRead(out string? job))
                {
                    await Task.Delay(50); // Simulate processing work
                    Console.WriteLine($"     [Consumer] Processed  <- {job}");
                }
            }
        });

        await Task.WhenAll(producer, consumer);
        Console.WriteLine("   Channel completed with clean buffer flush.");
    }

    // --- 4. Parallel.ForEachAsync (Controlled Concurrency) ---
    private static async Task DemonstrateParallelForEachAsync()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[4] Parallel.ForEachAsync with Controlled Degree of Parallelism");
        Console.ResetColor();

        string[] endpoints =
        [
            "https://api.gateway.internal/orders",
            "https://api.gateway.internal/users",
            "https://api.gateway.internal/inventory",
            "https://api.gateway.internal/payments",
            "https://api.gateway.internal/notifications",
            "https://api.gateway.internal/telemetry"
        ];

        var options = new ParallelOptions
        {
            MaxDegreeOfParallelism = 3 // Max 3 concurrent HTTP tasks
        };

        var sw = Stopwatch.StartNew();
        await Parallel.ForEachAsync(endpoints, options, async (url, token) =>
        {
            int simulatedLatency = new Random().Next(40, 80);
            await Task.Delay(simulatedLatency, token);
            Console.WriteLine($"   Fetched {url} (Simulated {simulatedLatency}ms on Thread {Environment.CurrentManagedThreadId})");
        });
        sw.Stop();

        Console.WriteLine($"   Processed all {endpoints.Length} endpoints in {sw.ElapsedMilliseconds}ms (bounded concurrency).");
    }
}
