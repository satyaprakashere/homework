void main() throws InterruptedException {
    var messageQueue = new LinkedBlockingQueue<String>();
    
    // 1. Start the virtual threads without calling .join() immediately
    Thread t1 = Thread.ofVirtual().start(() -> client(messageQueue));
    Thread t2 = Thread.ofVirtual().start(() -> client(messageQueue));
    
    // 2. Put messages into the queue (now the threads are running and waiting for them)
    messageQueue.put("Task 1 Data");
    messageQueue.put("Task 2 Data");
    messageQueue.put("STOP"); // Send STOP to terminate one client
    messageQueue.put("STOP"); // Send a second STOP to terminate the second client
    
    // 3. Wait for the threads to finish processing
    t1.join();
    t2.join();
}

void client(BlockingQueue<String> messageQueue) {
    try {
        while (true) {
            var message = messageQueue.take(); 
            if ("STOP".equals(message)) break;
            IO.println("Processed message: " + message);
        }
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
    }
}