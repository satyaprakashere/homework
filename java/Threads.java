import java.lang.Thread;
import java.util.concurrent.*;
import java.util.List;

void main() throws InterruptedException, ExecutionException {
    final var myThread = Thread.ofVirtual().start(() -> {
        System.out.println("Hello Virtual Threads!");
    });

    myThread.join();

    final var executor = Executors.newVirtualThreadPerTaskExecutor();

    final var res = executor.submit(() -> List.of(1, 2, 3));

    println(String.format("res : %s", res.get()));

    executor.shutdown();
}
