import java.lang.Thread;
import java.util.concurrent.*;
import java.util.List;

void main() throws InterruptedException, ExecutionException {
    final var myThread = Thread.ofVirtual().start(() -> {
        System.out.println("Hello Virtual Threads!");
    });

    myThread.join();
    
    final ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor();
    
    final Future<List<Integer>> res = executor.submit(() -> List.of(1, 2, 3));
    
    System.out.println(String.format("res : %s", res.get()));
    
    executor.shutdown();
}
