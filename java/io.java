void main() {
    var reader = new BufferedReader(new InputStreamReader(System.in));

    IO.println("Waiting for input n and k....");
    var n = readIntWithTimeout(reader, 3);
    var k = readIntWithTimeout(reader, 3);
    IO.println("n = " + n + " and k = " + k);
}

Integer readIntWithTimeout(BufferedReader reader, int timeoutSeconds) {
    IO.print("Enter an integer: ");
    
    long startTime = System.currentTimeMillis();
    long timeoutMillis = timeoutSeconds * 1000L;
    
    try {
        // Poll until data is available or timeout occurs
        while (true) {
            if (reader.ready()) {
                String line = reader.readLine();
                if (line != null) {
                    return Integer.parseInt(line.trim());
                }
            }
            
            if (System.currentTimeMillis() - startTime > timeoutMillis) {
                IO.println("\n[Timeout reached]");
                return null;
            }
            
            // Sleep briefly to prevent 100% CPU usage while waiting
            Thread.sleep(100);
        }
    } catch (IOException | NumberFormatException | InterruptedException e) {
        IO.println("Error reading the integer: " + e.getMessage());
        return null;
    }
}

Integer readIntWithTimeoutWrong(int timeoutSeconds) {
    var executor = Executors.newSingleThreadExecutor();
    var scanner = new Scanner(System.in);
    Callable<Integer> task = () -> {
        IO.print("Enter an integer: ");
        return scanner.nextInt();
    };
    
    var future = executor.submit(task);
    try {
        return future.get(timeoutSeconds, TimeUnit.SECONDS);
    } catch(TimeoutException | InterruptedException | ExecutionException e) {
        IO.println(e.getMessage());
    } finally {
        executor.shutdownNow();
    }
    IO.println("Error reading the integer");
    return null; // Indicates timeout or error
}
