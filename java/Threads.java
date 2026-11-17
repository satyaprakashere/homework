void main() throws Exception {
    var N = 100_000;
    // none of these are working concurrently, because we are eagerly waiting on results for each invocation
//  testVirtualThreads(N);
//  testVirtualThreadsWithoutBuffer(N);

//  testExecutorService(N);
//  testExecutorServiceWithoutBuffer(N);
}

void testVirtualThreads(int N) throws IOException {
    var output = new BufferedWriter(new OutputStreamWriter(System.out));

    IntStream.range(0, N).forEach((i) -> {
        try {
            Thread.ofVirtual().start(() -> {
                try {
                    output.write("Hello There! from Virtual thread\n");
                } catch (Exception e) {}
            }).join(); // join here makes it sequencial, so virtual thread is useless here
        } catch (Exception e) {}
    });
    output.flush();
}

void testVirtualThreadsWithoutBuffer(int N) {
    IntStream.range(0, N).forEach((i) -> {
        try {
            Thread.ofVirtual().start(() -> {
                IO.println("Hello There! from thread " + i);
            }).join();
        } catch (Exception e) {}
    });
}

void testExecutorServiceWithoutBuffer(int N) throws IOException {
    try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
        IntStream.range(0, N).forEach((i) -> {
            Future<String> future = executor.submit(() -> {
                return "Result from virtual thread";
            });

            // Wait and get the result
            try {
                String result = future.get();
                IO.println(result);
            } catch (Exception e) {}
        });
    }
}

void testExecutorService(int N) throws IOException {
    var output = new BufferedWriter(new OutputStreamWriter(System.out));
    output.write("Hello World\n");

    try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
        IntStream.range(0, N).forEach((i) -> {
            Future<String> future = executor.submit(() -> {
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
