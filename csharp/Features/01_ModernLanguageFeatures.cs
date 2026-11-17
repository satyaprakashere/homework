namespace CSharpShowcase.Features;

/// <summary>
/// Demonstrates cutting-edge C# language syntax from C# 10 through C# 13/14 (.NET 10).
/// Key highlights: Primary constructors, Pattern Matching, Collection Expressions, Records, and Raw Strings.
/// </summary>
public static class ModernLanguageFeatures
{
    public static void Run()
    {
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine("\n========================================================");
        Console.WriteLine(" 01: MODERN C# LANGUAGE FEATURES");
        Console.WriteLine("========================================================");
        Console.ResetColor();

        DemonstratePrimaryConstructors();
        DemonstratePatternMatching();
        DemonstrateCollectionExpressions();
        DemonstrateRecordsAndStructs();
        DemonstrateRawAndUtf8Literals();
    }

    // --- 1. Primary Constructors (C# 12+) ---
    private sealed class UserService(string connectionString, ITimeProvider timeProvider)
    {
        public string GetAuditLog(string user) =>
            $"[{timeProvider.Now:yyyy-MM-dd HH:mm:ss}] User '{user}' verified against DB '{connectionString}'";
    }

    private interface ITimeProvider
    {
        DateTime Now { get; }
    }

    private sealed class SystemTimeProvider : ITimeProvider
    {
        public DateTime Now => DateTime.UtcNow;
    }

    private static void DemonstratePrimaryConstructors()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[1] Primary Constructors (Classes & Dependency Injection)");
        Console.ResetColor();

        var service = new UserService("Server=db.prod;Database=auth", new SystemTimeProvider());
        Console.WriteLine($"   {service.GetAuditLog("alice_99")}");
    }

    // --- 2. Advanced Pattern Matching (C# 9 - C# 12) ---
    private abstract record Shape;
    private sealed record Circle(double Radius) : Shape;
    private sealed record Rectangle(double Width, double Height) : Shape;
    private sealed record Polygon(int Sides, double Perimeter) : Shape;

    private static string ClassifyMeasurement(double temperature, double humidity) =>
        (temperature, humidity) switch
        {
            (< 0, _) => "Freezing conditions!",
            (>= 0 and < 15, > 80) => "Chilly and damp",
            (>= 15 and <= 25, >= 30 and <= 60) => "Optimal comfort zone",
            (> 35, > 70) => "Severe heat & humidity warning!",
            (> 35, _) => "Hot and dry",
            _ => "Moderate conditions"
        };

    private static string DescribeShape(Shape shape) => shape switch
    {
        Circle { Radius: <= 0 } => "Degenerate circle",
        Circle { Radius: > 100 } c => $"Giant circle of radius {c.Radius:F1}",
        Circle c => $"Normal circle with area {Math.PI * c.Radius * c.Radius:F2}",
        Rectangle { Width: var w, Height: var h } when w == h => $"Square of size {w}x{h}",
        Rectangle (var w, var h) => $"Rectangle of size {w}x{h}",
        Polygon { Sides: 3 } => "Triangle",
        Polygon { Sides: var s } => $"{s}-sided polygon",
        _ => "Unknown shape"
    };

    private static string AnalyzeList(int[] numbers) => numbers switch
    {
        [] => "Empty list",
        [var single] => $"Single element: {single}",
        [var first, var second] => $"Pair: ({first}, {second})",
        [var head, .. var middle, var tail] =>
            $"Head: {head}, Tail: {tail}, Elements in between: [{string.Join(", ", middle)}]",
    };

    private static void DemonstratePatternMatching()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[2] Exhaustive Pattern Matching (Relational, Property, & List Patterns)");
        Console.ResetColor();

        // Relational tuple patterns
        Console.WriteLine($"   Comfort (21°C, 45%): {ClassifyMeasurement(21, 45)}");
        Console.WriteLine($"   Extreme (38°C, 85%): {ClassifyMeasurement(38, 85)}");

        // Property and positional patterns
        Shape[] shapes = [new Circle(5), new Circle(120), new Rectangle(10, 10), new Rectangle(4, 8), new Polygon(3, 15)];
        foreach (var shape in shapes)
        {
            Console.WriteLine($"   Shape: {DescribeShape(shape)}");
        }

        // List & slice patterns
        Console.WriteLine($"   List [42]: {AnalyzeList([42])}");
        Console.WriteLine($"   List [1, 2, 3, 4, 5]: {AnalyzeList([1, 2, 3, 4, 5])}");
    }

    // --- 3. Collection Expressions & Spread (C# 12) ---
    private static void DemonstrateCollectionExpressions()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[3] Collection Expressions & Spread Operator (..)");
        Console.ResetColor();

        int[] evens = [2, 4, 6];
        int[] odds = [1, 3, 5];

        // Spread into unified array without Concat()
        int[] combined = [0, ..odds, ..evens, 7, 8];
        Console.WriteLine($"   Spread combined: [{string.Join(", ", combined)}]");

        // Target typing for lists, spans, and sets
        List<string> languages = ["C#", "F#", "Rust", "Go"];
        ReadOnlySpan<char> chars = ['C', '#', '1', '3'];
        HashSet<int> uniqueNumbers = [1, 1, 2, 3, 5, 8];

        Console.WriteLine($"   Languages count: {languages.Count}, Span length: {chars.Length}, Set count: {uniqueNumbers.Count}");
    }

    // --- 4. Records & Non-Destructive Mutation (C# 9+) ---
    private readonly record struct GeoCoordinate(double Latitude, double Longitude);

    private record UserProfile
    {
        public required string Id { get; init; }
        public required string Username { get; init; }
        public string Role { get; init; } = "Member";
        public GeoCoordinate Location { get; init; }
    }

    private static void DemonstrateRecordsAndStructs()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[4] Records, Required Members, & 'with' Mutation");
        Console.ResetColor();

        var admin = new UserProfile
        {
            Id = "usr_001",
            Username = "satya",
            Role = "Administrator",
            Location = new GeoCoordinate(47.6062, -122.3321) // Seattle
        };

        // Non-destructive mutation creates a new shallow copy with modified fields
        var auditor = admin with { Username = "satya_audit", Role = "Auditor" };

        Console.WriteLine($"   Original: {admin.Username} ({admin.Role}) at {admin.Location.Latitude},{admin.Location.Longitude}");
        Console.WriteLine($"   Mutated:  {auditor.Username} ({auditor.Role}) at {auditor.Location.Latitude},{auditor.Location.Longitude}");
        Console.WriteLine($"   Structural equality test (admin == auditor): {admin == auditor}");
        Console.WriteLine($"   Cloned equal test: {admin == (admin with { })}");
    }

    // --- 5. Raw String Literals & UTF-8 Literals (C# 11) ---
    private static void DemonstrateRawAndUtf8Literals()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[5] Raw String Literals (\"\"\") & UTF-8 Literals (\"...\"u8)");
        Console.ResetColor();

        string apiName = "CloudFlare";
        int port = 443;

        // Raw multi-line string eliminates escape characters:
        string configJson = $$"""
        {
            "service": "{{apiName}}",
            "endpoint": {
                "host": "api.gateway.internal",
                "port": {{port}},
                "ssl": true
            },
            "regex": "^[a-z0-9_-]+$"
        }
        """;
        Console.WriteLine("   Raw String JSON (un-escaped quotes and regex):");
        Console.WriteLine(string.Join("\n", configJson.Split('\n').Select(l => "     " + l)));

        // UTF-8 string literal compiles directly into ReadOnlySpan<byte> in assembly rodata
        ReadOnlySpan<byte> httpHeader = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n"u8;
        Console.WriteLine($"   UTF-8 literal span length: {httpHeader.Length} bytes without heap allocation.");
    }
}
