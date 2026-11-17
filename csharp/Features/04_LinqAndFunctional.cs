namespace CSharpShowcase.Features;

using System.Collections.Immutable;

/// <summary>
/// Demonstrates LINQ and modern functional programming capabilities in C# / .NET:
/// .NET 9 LINQ additions (CountBy, AggregateBy, Index), Chunk, Zip, DistinctBy,
/// query syntax vs method syntax, and functional composition.
/// </summary>
public static class LinqAndFunctional
{
    public static void Run()
    {
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine("\n========================================================");
        Console.WriteLine(" 04: LINQ & FUNCTIONAL C# CAPABILITIES");
        Console.WriteLine("========================================================");
        Console.ResetColor();

        DemonstrateDotNet9LinqMethods();
        DemonstrateModernLinqOperations();
        DemonstrateQuerySyntaxVsFluent();
        DemonstrateFunctionalComposition();
    }

    private sealed record Sale(string Region, string Category, decimal Amount);

    // --- 1. .NET 9 LINQ Methods: CountBy, AggregateBy, Index ---
    private static void DemonstrateDotNet9LinqMethods()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[1] .NET 9 LINQ: CountBy, AggregateBy, & Index()");
        Console.ResetColor();

        Sale[] transactions =
        [
            new("North", "Electronics", 1200m),
            new("South", "Furniture", 450m),
            new("North", "Furniture", 800m),
            new("East",  "Electronics", 1500m),
            new("North", "Electronics", 300m),
            new("South", "Electronics", 600m),
            new("West",  "Supplies", 120m),
        ];

        // 1. CountBy: O(N) frequency count without allocating full grouped collections
        Console.WriteLine("   Transactions CountBy Region:");
        foreach (var (region, count) in transactions.CountBy(t => t.Region))
        {
            Console.WriteLine($"     - Region '{region}': {count} orders");
        }

        // 2. AggregateBy: Key-based folding (Total revenue and count per Category)
        Console.WriteLine("\n   AggregateBy Category (Total Revenue):");
        var revenueByCategory = transactions.AggregateBy(
            keySelector: t => t.Category,
            seed: 0m,
            func: (total, item) => total + item.Amount
        );

        foreach (var (category, total) in revenueByCategory)
        {
            Console.WriteLine($"     - Category '{category}': ${total:N2}");
        }

        // 3. Index(): Modern zero-allocation replacement for .Select((item, idx) => ...)
        Console.WriteLine("\n   Index() Enumeration (Ranked Top Transactions):");
        var topSales = transactions.OrderByDescending(t => t.Amount).Take(3);
        foreach (var (index, sale) in topSales.Index())
        {
            Console.WriteLine($"     #{index + 1}: ${sale.Amount:N2} in {sale.Region} ({sale.Category})");
        }
    }

    // --- 2. Modern LINQ: Chunk, Zip, DistinctBy, MaxBy ---
    private static void DemonstrateModernLinqOperations()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[2] Modern LINQ Operators: Chunk, Zip, DistinctBy, MaxBy");
        Console.ResetColor();

        int[] data = [10, 20, 30, 40, 50, 60, 70, 80];

        // Chunking into pages / batches of 3
        Console.WriteLine("   Chunking elements into batches of size 3:");
        int batchNum = 1;
        foreach (int[] chunk in data.Chunk(3))
        {
            Console.WriteLine($"     Batch {batchNum++}: [{string.Join(", ", chunk)}]");
        }

        // Zip two sequences into tuples
        string[] names = ["Alice", "Bob", "Charlie"];
        int[] scores = [95, 88, 92];

        var pairings = names.Zip(scores, (name, score) => $"{name} => {score} pts");
        Console.WriteLine($"   Zipped Roster: {string.Join(" | ", pairings)}");

        // DistinctBy and MaxBy
        List<Sale> sampleSales =
        [
            new("North", "Tech", 100m),
            new("South", "Tech", 500m),
            new("North", "Retail", 200m),
            new("East", "Retail", 400m)
        ];

        var maxSale = sampleSales.MaxBy(s => s.Amount);
        Console.WriteLine($"   Max sale: {maxSale?.Region} with ${maxSale?.Amount:N2}");

        var distinctCategories = sampleSales.DistinctBy(s => s.Category).Select(s => s.Category);
        Console.WriteLine($"   Unique categories: {string.Join(", ", distinctCategories)}");
    }

    // --- 3. Query Comprehension Syntax vs Fluent Method Syntax ---
    private static void DemonstrateQuerySyntaxVsFluent()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[3] Query Comprehension Syntax vs Fluent Method Syntax");
        Console.ResetColor();

        int[] numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

        // Declarative SQL-like query comprehension syntax
        var querySyntaxResult =
            from n in numbers
            where n % 2 == 0
            let square = n * n
            where square > 20
            orderby square descending
            select new { Number = n, Square = square };

        // Fluent method syntax equivalent
        var fluentSyntaxResult = numbers
            .Where(n => n % 2 == 0)
            .Select(n => new { Number = n, Square = n * n })
            .Where(x => x.Square > 20)
            .OrderByDescending(x => x.Square);

        Console.WriteLine("   Even numbers whose squares > 20 (Ordered Desc):");
        foreach (var item in querySyntaxResult)
        {
            Console.WriteLine($"     {item.Number}^2 = {item.Square}");
        }
    }

    // --- 4. Functional Composition & Immutability ---
    private static void DemonstrateFunctionalComposition()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[4] Functional Programming: Currying & Pipeline Composition");
        Console.ResetColor();

        // Higher-order function: Compose f(g(x))
        static Func<T, R> Compose<T, U, R>(Func<T, U> f, Func<U, R> g) => x => g(f(x));

        // Curried multiplier
        static Func<int, int> MultiplyBy(int factor) => x => x * factor;

        Func<string, string> trimAndUpper = s => s.Trim().ToUpperInvariant();
        Func<string, string> addPrefix = s => $"[EVENT] {s}";

        var pipeline = Compose(trimAndUpper, addPrefix);

        string rawEvent = "   system disk warning alert   ";
        Console.WriteLine($"   Raw Input:  '{rawEvent}'");
        Console.WriteLine($"   Transformed: '{pipeline(rawEvent)}'");

        // Curried scaling
        var doubler = MultiplyBy(2);
        var tripler = MultiplyBy(3);

        Console.WriteLine($"   Curried: doubler(14) = {doubler(14)}, tripler(14) = {tripler(14)}");

        // Immutable collections
        ImmutableArray<string> immutableColors = ["Red", "Green", "Blue"];
        var updatedColors = immutableColors.Add("Amber");

        Console.WriteLine($"   Original immutable count: {immutableColors.Length}, New instance count: {updatedColors.Length}");
    }
}
