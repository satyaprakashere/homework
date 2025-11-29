final int ThreadScaling = 100000;
List<Integer> RandomList(int size) {
    final var r = new Random();
    return r.doubles()
        .limit(ThreadScaling)
        .mapToInt(a -> (int) a * ThreadScaling)
        .boxed()
        .collect(Collectors.toList());
}

void main() throws Exception {
        long start = System.nanoTime();
//    testVirtualThreads();
        long end = System.nanoTime();
        long duration = end - start; // duration in nanoseconds
        String measurement1 = "Time taken: " + duration + " ns";
    
        start = System.nanoTime();
    testExecutorService();
        end = System.nanoTime();
        duration = end - start; // duration in nanoseconds
        String measurement2 = "Time taken: " + duration + " ns";
    
        start = System.nanoTime();
//    testExecutorService1();
        end = System.nanoTime();
        duration = end - start; // duration in nanoseconds
        String measurement3 = "Time taken: " + duration + " ns";
    
    IO.println(ThreadScaling + " Virtual Threads | " + measurement1);
    IO.println(ThreadScaling + " Executor Service Threads | " + measurement2);
    IO.println(ThreadScaling + " Executor Service with IO Threads | " + measurement3);
}

void testRandom() throws InterruptedException, ExecutionException {
    final var myThread = Thread.ofVirtual().start(() -> {
        IO.println("Hello Virtual Threads!");
    });

    myThread.join();

    try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {

        final var res = executor.submit(() -> List.of(1, 2, 3));
        IO.println(String.format("res : %s", res.get()));

        executor.shutdown();
    }
}

void testVirtualThreads() throws IOException {
    var output = new BufferedWriter(new OutputStreamWriter(System.out));
    IntStream.range(0, ThreadScaling).forEach((i) -> {
        try {
            Thread.ofVirtual().start(() -> {
                try {
                    output.write("Hello There! from thread \n");
                } catch (Exception _) {}
            }).join();
        } catch (Exception _) {}
    });
    
    output.flush();
}

void testExecutorService() throws IOException {
    var output = new BufferedWriter(new OutputStreamWriter(System.out));
    output.write("Hello World\n");

    try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
        final var results = IntStream.range(0, ThreadScaling)
            .mapToObj(i -> executor.submit(() -> "Result from virtual thread\n"));

        results.forEach(x -> {
            try { output.write(x.get());} catch (Exception _) {} });
    }
    
    output.flush();  // Don't forget to flush at the end!
}

void testExecutorService1() throws IOException {
    var output = new BufferedWriter(new OutputStreamWriter(System.out));
    output.write("Hello World\n");
    
    try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
        IntStream.range(0, ThreadScaling)
            .forEach(i -> executor.submit(() -> { try {
                output.write("Result from virtual thread\n");
            } catch (Exception e) {}}));
    } catch (Exception e) {
        
    }
    output.flush();  // Don't forget to flush at the end!
}