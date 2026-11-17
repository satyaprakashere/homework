value record Point3D(int x, int y, int z) {}
value record Rectangle(Point3D p1, Point3D p2) {}

final int SIZE = 10_000_000;
final int WARMUP_ITERATIONS = 10;
final int MEASUREMENT_ITERATIONS = 20;

void main() {
    var rectangles = new Rectangle[SIZE];
    for (var i = 0; i < SIZE; i++) {
        rectangles[i] = new Rectangle(new Point3D(i, i+7, i+4), new Point3D(i + 10, i + 96, i + 36));
    }

    // Warm-up phase: allows JIT to compile and optimize the loop
    IO.println("Warming up JIT compiler...");
    for (var i = 0; i < WARMUP_ITERATIONS; i++) {
        runBenchmark(rectangles);
    }

    // Measurement phase
    IO.println("Running measurements...");
    long totalTimeNs = 0;

    for (var i = 0; i < MEASUREMENT_ITERATIONS; i++) {
        var startTime = System.nanoTime();
        var result = runBenchmark(rectangles);
        var endTime = System.nanoTime();

        var durationNs = endTime - startTime;
        totalTimeNs += durationNs;
        IO.println("Iteration " + (i + 1) + ": " + (durationNs / 1_000_000) + " ms (checksum: " + result + ")");
    }

    IO.println("----------------------------------------");
    IO.println("Average Time: " + (totalTimeNs / MEASUREMENT_ITERATIONS / 1_000_000) + " ms");
}

long runBenchmark(Rectangle[] rectangles) {
    long sum = 0;
    // Traversing a contiguous array tests CPU cache performance and locality
    for (var i = 0; i < rectangles.length; i++) {
        var r = rectangles[i];
        sum += r.p1.x + r.p2.y + r.p2.z;
    }
    return sum;
}
