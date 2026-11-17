using CSharpShowcase.Features;

// Enable UTF-8 console output for symbols and emojis
Console.OutputEncoding = System.Text.Encoding.UTF8;

if (args.Length > 0)
{
    string arg = args[0].ToLowerInvariant().Trim();
    switch (arg)
    {
        case "1" or "modern" or "--modern":
            ModernLanguageFeatures.Run();
            return;
        case "2" or "perf" or "memory" or "--perf":
            HighPerformanceAndMemory.Run();
            return;
        case "3" or "async" or "concurrency" or "--async":
            await AsyncAndConcurrency.RunAsync();
            return;
        case "4" or "linq" or "functional" or "--linq":
            LinqAndFunctional.Run();
            return;
        case "5" or "json" or "serialization" or "--json":
            SerializationAndJson.Run();
            return;
        case "6" or "web" or "api" or "--web":
            await MinimalApiAndWeb.StartServerAsync(args);
            return;
        case "all" or "--all":
            await RunAllAsync();
            return;
        case "help" or "--help" or "-h":
            PrintHelp();
            return;
        default:
            Console.WriteLine($"Unknown option '{args[0]}'. Use '--help' for available options.");
            return;
    }
}

// Interactive Terminal Menu
while (true)
{
    Console.Clear();
    PrintBanner();
    Console.ForegroundColor = ConsoleColor.White;
    Console.WriteLine(" Select a capability showcase to run:\n");
    Console.WriteLine("  [1] Modern C# Language Features    (Primary Ctors, Pattern Matching, Records, Collections)");
    Console.WriteLine("  [2] High-Performance & Memory      (Span<T>, stackalloc, ArrayPool, SIMD Vector<T>)");
    Console.WriteLine("  [3] Async & Concurrency            (Lock, IAsyncEnumerable, Channels, Parallel.ForEachAsync)");
    Console.WriteLine("  [4] LINQ & Functional C#           (.NET 9 CountBy/AggregateBy/Index, Chunk, Zip, Currying)");
    Console.WriteLine("  [5] Serialization & JSON           (Polymorphic JSON, JsonDocument, Utf8JsonWriter)");
    Console.WriteLine("  [6] ASP.NET Core Minimal API & Web (Live Web Server, SSE Streaming, REST Endpoints)");
    Console.WriteLine("  [A] Run All Showcase Modules       (Sequential execution of modules 1 through 5)");
    Console.WriteLine("  [Q] Quit");
    Console.WriteLine();
    Console.ForegroundColor = ConsoleColor.Cyan;
    Console.Write(" Enter choice [1-6, A, Q]: ");
    Console.ResetColor();

    string? input = Console.ReadLine()?.Trim().ToUpperInvariant();
    if (string.IsNullOrEmpty(input)) continue;

    if (input == "Q")
    {
        Console.WriteLine("\nExiting C# showcase. Have a great day!\n");
        break;
    }

    switch (input)
    {
        case "1":
            ModernLanguageFeatures.Run();
            break;
        case "2":
            HighPerformanceAndMemory.Run();
            break;
        case "3":
            await AsyncAndConcurrency.RunAsync();
            break;
        case "4":
            LinqAndFunctional.Run();
            break;
        case "5":
            SerializationAndJson.Run();
            break;
        case "6":
            await MinimalApiAndWeb.StartServerAsync([]);
            break;
        case "A":
            await RunAllAsync();
            break;
        default:
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine("Invalid selection. Press Enter to retry...");
            Console.ResetColor();
            Console.ReadLine();
            continue;
    }

    if (input != "6")
    {
        Console.ForegroundColor = ConsoleColor.DarkGray;
        Console.WriteLine("\n────────────────────────────────────────────────────────");
        Console.WriteLine("Press Enter to return to menu...");
        Console.ResetColor();
        Console.ReadLine();
    }
}

static async Task RunAllAsync()
{
    ModernLanguageFeatures.Run();
    HighPerformanceAndMemory.Run();
    await AsyncAndConcurrency.RunAsync();
    LinqAndFunctional.Run();
    SerializationAndJson.Run();

    Console.ForegroundColor = ConsoleColor.Green;
    Console.WriteLine("\n========================================================");
    Console.WriteLine(" ✅ ALL CLI SHOWCASES COMPLETED SUCCESSFULLY!");
    Console.WriteLine("========================================================\n");
    Console.ResetColor();
}

static void PrintBanner()
{
    Console.ForegroundColor = ConsoleColor.Magenta;
    Console.WriteLine("╔═══════════════════════════════════════════════════════════╗");
    Console.WriteLine("║        ⚡ MODERN C# & .NET 10 CAPABILITIES SHOWCASE        ║");
    Console.WriteLine("║         High Performance • Concurrency • Cloud-Native     ║");
    Console.WriteLine("╚═══════════════════════════════════════════════════════════╝");
    Console.ResetColor();
}

static void PrintHelp()
{
    PrintBanner();
    Console.WriteLine("""
    Usage:
      dotnet run -- [option]

    Options:
      1, modern       Modern C# language features (Pattern matching, primary ctors, records)
      2, perf         High-performance primitives (Span<T>, stackalloc, ArrayPool, SIMD)
      3, async        Asynchronous & concurrency pipelines (Channels, IAsyncEnumerable, Lock)
      4, linq         LINQ and functional paradigms (.NET 9 CountBy, AggregateBy, Index)
      5, json         Serialization & System.Text.Json (Polymorphism, JsonDocument)
      6, web          Start ASP.NET Core Minimal API web server & interactive dashboard
      all             Run all CLI showcases sequentially
      help, -h        Display this help information
    """);
}
