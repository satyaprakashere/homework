namespace CSharpShowcase.Features;

using System.Buffers;
using System.Diagnostics;
using System.Numerics;
using System.Runtime.InteropServices;

/// <summary>
/// Demonstrates .NET's low-allocation, high-performance systems programming capabilities:
/// Span<T>, Memory<T>, stackalloc, ArrayPool<T>, ref structs, and SIMD Vectorization.
/// </summary>
public static class HighPerformanceAndMemory
{
    public static void Run()
    {
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine("\n========================================================");
        Console.WriteLine(" 02: HIGH-PERFORMANCE & LOW-ALLOCATION MEMORY PRIMITIVES");
        Console.WriteLine("========================================================");
        Console.ResetColor();

        DemonstrateSpanAndZeroAllocationParsing();
        DemonstrateStackallocAndRefStruct();
        DemonstrateArrayPool();
        DemonstrateSimdVectorization();
    }

    // --- 1. Span<T> & Zero-Allocation Slicing ---
    private static void DemonstrateSpanAndZeroAllocationParsing()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[1] Span<T> & Zero-Allocation String Slicing/Parsing");
        Console.ResetColor();

        // Sample log line: "2026-09-08 13:05:22|INFO|192.168.1.42|GET /api/v1/orders HTTP/1.1|200|45ms"
        string logLine = "2026-09-08 13:05:22|INFO|192.168.1.42|GET /api/v1/orders HTTP/1.1|200|45ms";
        ReadOnlySpan<char> span = logLine.AsSpan();

        Console.WriteLine($"   Raw Log Line: {logLine}");

        // Zero-allocation token extraction by slicing indices
        int firstPipe = span.IndexOf('|');
        ReadOnlySpan<char> timestamp = span[..firstPipe];

        ReadOnlySpan<char> remainder = span[(firstPipe + 1)..];
        int secondPipe = remainder.IndexOf('|');
        ReadOnlySpan<char> level = remainder[..secondPipe];

        remainder = remainder[(secondPipe + 1)..];
        int thirdPipe = remainder.IndexOf('|');
        ReadOnlySpan<char> ip = remainder[..thirdPipe];

        remainder = remainder[(thirdPipe + 1)..];
        int fourthPipe = remainder.IndexOf('|');
        ReadOnlySpan<char> request = remainder[..fourthPipe];

        remainder = remainder[(fourthPipe + 1)..];
        int fifthPipe = remainder.IndexOf('|');
        ReadOnlySpan<char> statusCodeSpan = remainder[..fifthPipe];
        ReadOnlySpan<char> latencySpan = remainder[(fifthPipe + 1)..];

        // Parse integer directly from span without allocating a string!
        int statusCode = int.Parse(statusCodeSpan);

        Console.WriteLine($"   Extracted Timestamp: {timestamp}");
        Console.WriteLine($"   Extracted Level:     {level}");
        Console.WriteLine($"   Extracted IP:        {ip}");
        Console.WriteLine($"   Extracted Request:   {request}");
        Console.WriteLine($"   Parsed Status Code:  {statusCode} (int)");
        Console.WriteLine($"   Extracted Latency:   {latencySpan}");
        Console.WriteLine("   -> Zero heap allocations occurred during this extraction!");
    }

    // --- 2. stackalloc & Ref Structs ---
    // A ref struct is guaranteed by the compiler to only live on the stack (never boxed or placed on heap).
    private readonly ref struct FastBufferWriter
    {
        public static int FormatHexToken(Span<char> destination, ReadOnlySpan<byte> bytes)
        {
            const string hexDigits = "0123456789ABCDEF";
            int idx = 0;
            foreach (byte b in bytes)
            {
                destination[idx++] = hexDigits[b >> 4];
                destination[idx++] = hexDigits[b & 0x0F];
            }
            return idx;
        }
    }

    private static void DemonstrateStackallocAndRefStruct()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[2] Stackalloc & Ref Structs (Zero GC Burden)");
        Console.ResetColor();

        // Allocate memory directly on the execution stack frame
        Span<byte> randomBytes = stackalloc byte[16];
        new Random(42).NextBytes(randomBytes);

        Span<char> hexChars = stackalloc char[32];
        int written = FastBufferWriter.FormatHexToken(hexChars, randomBytes);

        Console.WriteLine($"   Generated 16 stack-allocated bytes transformed to Hex on stack:");
        Console.WriteLine($"   Token: {hexChars[..written]}");
    }

    // --- 3. ArrayPool<T> for High-Throughput Buffers ---
    private static void DemonstrateArrayPool()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[3] ArrayPool<T>.Shared Buffer Recycling");
        Console.ResetColor();

        const int requestedSize = 65536; // 64 KB buffer
        var pool = ArrayPool<byte>.Shared;

        // Rent a buffer from the pool (avoids allocating new byte[] every time)
        byte[] rentedBuffer = pool.Rent(requestedSize);
        try
        {
            Console.WriteLine($"   Requested {requestedSize} bytes, rented buffer of actual size {rentedBuffer.Length} from ArrayPool");
            // Fill slice with dummy data
            Span<byte> activeSlice = rentedBuffer.AsSpan(0, requestedSize);
            activeSlice.Fill(0xAA);
            Console.WriteLine($"   Buffer slice filled successfully. Memory recycled back to pool on return.");
        }
        finally
        {
            // Always return buffer to prevent pool depletion
            pool.Return(rentedBuffer, clearArray: false);
        }
    }

    // --- 4. SIMD Hardware Intrinsics with System.Numerics.Vector<T> ---
    private static void DemonstrateSimdVectorization()
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n[4] SIMD / Hardware Intrinsics (Vector<T> Acceleration)");
        Console.ResetColor();

        int vectorSize = Vector<float>.Count;
        Console.WriteLine($"   SIMD Hardware Acceleration Supported: {Vector.IsHardwareAccelerated}");
        Console.WriteLine($"   Single SIMD Vector<float> lane capacity: {vectorSize} floats ({vectorSize * 32} bits wide)");

        const int dataSize = 100_000;
        float[] a = new float[dataSize];
        float[] b = new float[dataSize];
        float[] resultSimd = new float[dataSize];
        float[] resultScalar = new float[dataSize];

        for (int i = 0; i < dataSize; i++)
        {
            a[i] = i * 0.5f;
            b[i] = 2.0f;
        }

        // SIMD Vectorized addition
        var sw = Stopwatch.StartNew();
        int simdLength = dataSize - (dataSize % vectorSize);
        for (int i = 0; i < simdLength; i += vectorSize)
        {
            var va = new Vector<float>(a, i);
            var vb = new Vector<float>(b, i);
            var vr = va * vb;
            vr.CopyTo(resultSimd, i);
        }
        // Handle remainder
        for (int i = simdLength; i < dataSize; i++)
        {
            resultSimd[i] = a[i] * b[i];
        }
        sw.Stop();
        long simdTicks = sw.ElapsedTicks;

        // Scalar addition
        sw.Restart();
        for (int i = 0; i < dataSize; i++)
        {
            resultScalar[i] = a[i] * b[i];
        }
        sw.Stop();
        long scalarTicks = sw.ElapsedTicks;

        Console.WriteLine($"   Processed {dataSize:N0} elements:");
        Console.WriteLine($"   SIMD computation ticks:   {simdTicks}");
        Console.WriteLine($"   Scalar computation ticks: {scalarTicks}");
        Console.WriteLine($"   Sample verified output: a[10]={a[10]}, b[10]={b[10]} => result={resultSimd[10]}");
    }
}
