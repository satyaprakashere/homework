void main() throws InterruptedException, ExecutionException {
    final var myThread = Thread.ofVirtual().start(() -> {
        IO.println("Hello Virtual Threads!");
        final var thread = Thread.ofVirtual().start(() -> {
            IO.println("Hello Virtual Threads2!");
        });
        try {
            thread.join();
        } catch (Exception e) {}
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
