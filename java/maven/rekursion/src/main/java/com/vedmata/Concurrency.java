package com.vedmata;

class Concurrency {
    static void testLightThreads() throws InterruptedException {
        final var thread = Thread.ofVirtual().start(() -> {
            IO.println("Hello There!");
        });

        thread.join();
    }
}
