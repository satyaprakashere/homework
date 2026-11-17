void main() {
    try { testRandom(); } catch (Exception e) {}
}

void testRandom() throws InterruptedException, ExecutionException {
    var future = new CompletableFuture<Integer>();
    
    var myThread = Thread.ofVirtual().start(() -> {
        IO.println("Hello Virtual Threads!");
        future.complete(0);
    });
    
    var value = future.join(); // Gets the return value
    IO.println(value);
}
