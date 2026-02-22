void main() throws Exception {
//  testVirtualThreads();
    testExecutorService();
}

void testRandom() throws InterruptedException, ExecutionException {
    final var myThread = Thread.ofVirtual().start(() -> {
        IO.println("Hello Virtual Threads!");
    });
    
    myThread.join();

//  final var executor = Executors.newVirtualThreadPerTaskExecutor();
//
//  final var res = executor.submit(() -> List.of(1, 2, 3));
//
//  IO.println(String.format("res : %s", res.get()));
//
//  executor.shutdown();
}

void testVirtualThreads() {
    IntStream.range(0, 100000).forEach((i) -> {
        try {
            Thread.ofVirtual().start(() -> {
                IO.println("Hello There! from thread " + i);
            }).join();
        } catch (Exception e) {}
    });
}

void testExecutorService() throws IOException {
    BufferedWriter output = new BufferedWriter(new OutputStreamWriter(System.out));
    output.write("Hello World\n");
    
    try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
        IntStream.range(0, 100000).forEach((i) -> {
            Future<String> future = executor.submit(() -> {
                // Simulate task
//              Thread.sleep(500);
                return "Result from virtual thread\n";
            });
            
            // Wait and get the result
            try {
                String result = future.get();
                output.write(result);
            } catch (Exception e) {}
        });
    }
    output.flush();  // Don't forget to flush at the end!
}