namespace CSharpShowcase.Features;

using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Serialization;

/// <summary>
/// Demonstrates System.Text.Json capabilities:
/// Polymorphic JSON serialization, JsonDocument DOM traversal, snake_case naming,
/// and low-allocation Utf8JsonReader/Writer.
/// </summary>
public static class SerializationAndJson
{
    public static void Run()
    {
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine("\n========================================================");
        Console.WriteLine(" 05: SERIALIZATION & SYSTEM.TEXT.JSON");
        Console.WriteLine("========================================================");
        Console.ResetColor();

        DemonstratePolymorphicSerialization();
        DemonstrateJsonDomAndDynamicNodes();
        DemonstrateUtf8StreamWriter();
    }

    // --- 1. Polymorphic JSON Serialization ---
    [JsonPolymorphic(TypeDiscriminatorPropertyName = "$kind")]
    [JsonDerivedType(typeof(CreditCardPayment), typeDiscriminator: "credit_card")]
    [JsonDerivedType(typeof(CryptoPayment), typeDiscriminator: "crypto")]
    [JsonDerivedType(typeof(BankTransferPayment), typeDiscriminator: "bank_transfer")]
    private abstract record PaymentMethod(decimal Amount, string Currency);

    private sealed record CreditCardPayment(decimal Amount, string Currency, string Last4, string Network)
        : PaymentMethod(Amount, Currency);

    private sealed record CryptoPayment(decimal Amount, string Currency, string WalletAddress, string NetworkFee)
        : PaymentMethod(Amount, Currency);

    private sealed record BankTransferPayment(decimal Amount, string Currency, string Iban, string SwiftBic)
        : PaymentMethod(Amount, Currency);

    private static void DemonstratePolymorphicSerialization()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[1] Polymorphic Serialization with [JsonDerivedType]");
        Console.ResetColor();

        var options = new JsonSerializerOptions
        {
            WriteIndented = true,
            PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower
        };

        PaymentMethod[] payments =
        [
            new CreditCardPayment(129.99m, "USD", "4242", "Visa"),
            new CryptoPayment(0.045m, "BTC", "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh", "0.0001 BTC"),
            new BankTransferPayment(2400.00m, "EUR", "DE89370400440532013000", "DBEUMM21XXX")
        ];

        string jsonPayload = JsonSerializer.Serialize(payments, options);
        Console.WriteLine("   Serialized Polymorphic Payments (Snake Case & Discriminators):");
        Console.WriteLine(jsonPayload);

        // Deserializing back automatically reconstructs exact concrete subclasses!
        var roundtripped = JsonSerializer.Deserialize<PaymentMethod[]>(jsonPayload, options)!;
        Console.WriteLine("\n   Deserialized Concrete Types:");
        foreach (var p in roundtripped)
        {
            string detail = p switch
            {
                CreditCardPayment cc => $"Card Ending {cc.Last4} ({cc.Network})",
                CryptoPayment cp => $"Wallet {cp.WalletAddress[..12]}... (Fee: {cp.NetworkFee})",
                BankTransferPayment bt => $"IBAN {bt.Iban}",
                _ => "Unknown"
            };
            Console.WriteLine($"     - {p.GetType().Name}: {p.Amount} {p.Currency} [{detail}]");
        }
    }

    // --- 2. JsonDocument & JsonNode (DOM Traversal) ---
    private static void DemonstrateJsonDomAndDynamicNodes()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[2] JsonDocument Lightweight DOM & JsonNode Manipulation");
        Console.ResetColor();

        string samplePayload = """
        {
            "server": "cluster-us-east-1",
            "version": "10.0.1",
            "metrics": {
                "cpu_usage": 34.2,
                "memory_mb": 1024,
                "active_connections": 412
            },
            "tags": ["production", "kubernetes", "arm64"]
        }
        """;

        // JsonDocument is an IDisposable lightweight read-only view over UTF-8 bytes
        using (JsonDocument doc = JsonDocument.Parse(samplePayload))
        {
            var root = doc.RootElement;
            string server = root.GetProperty("server").GetString()!;
            double cpu = root.GetProperty("metrics").GetProperty("cpu_usage").GetDouble();
            int tagsCount = root.GetProperty("tags").GetArrayLength();

            Console.WriteLine($"   JsonDocument parsed -> Server: {server}, CPU: {cpu}%, Tags: {tagsCount}");
        }

        // JsonNode allows mutable in-place DOM modifications:
        var node = JsonNode.Parse(samplePayload)!;
        node["metrics"]!["cpu_usage"] = 52.8;
        node["status"] = "HEALTHY";

        Console.WriteLine($"   Mutated JsonNode updated CPU: {node["metrics"]?["cpu_usage"]}, Status: {node["status"]}");
    }

    // --- 3. Utf8JsonWriter (Zero Allocation Streaming) ---
    private static void DemonstrateUtf8StreamWriter()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[3] Utf8JsonWriter (High-Throughput Streaming Serialization)");
        Console.ResetColor();

        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream, new JsonWriterOptions { Indented = false }))
        {
            writer.WriteStartObject();
            writer.WriteString("status", "ok");
            writer.WriteNumber("timestamp", DateTimeOffset.UtcNow.ToUnixTimeSeconds());
            writer.WriteStartArray("items");
            for (int i = 1; i <= 3; i++)
            {
                writer.WriteStartObject();
                writer.WriteNumber("id", i);
                writer.WriteString("name", $"Item-{i}");
                writer.WriteEndObject();
            }
            writer.WriteEndArray();
            writer.WriteEndObject();
        }

        string rawJson = Encoding.UTF8.GetString(stream.ToArray());
        Console.WriteLine($"   Streamed Compact JSON Output: {rawJson}");
    }
}
