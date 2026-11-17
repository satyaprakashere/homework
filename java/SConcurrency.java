import java.util.concurrent.ExecutionException;
import java.util.concurrent.StructuredTaskScope;
import java.util.concurrent.StructuredTaskScope.Joiner;

record UserProfile(String name) {}
record UserOrders(int orderCount) {}
record UserAggregate(UserProfile profile, UserOrders orders) {}

void main() throws InterruptedException, ExecutionException {
    IO.println("--- example 1: all-or-nothing (short-circuit on failure) ---");
    runShutdownOnFailure();

    IO.println("\n--- example 2: first responder / race (short-circuit on success) ---");
    runShutdownOnSuccess();

    IO.println("\n--- example 2: Shutdown on timeout ---");
    runShutdownOnTimeout();
}

// =========================================================================
// 1. All-or-Nothing Execution
// Joiner.allSuccessful() waits for all subtasks to finish successfully.
// If any subtask fails, it short-circuits and cancels all siblings immediately.
// =========================================================================
void runShutdownOnFailure() throws InterruptedException, ExecutionException {
    try (var scope = StructuredTaskScope.open(Joiner.allSuccessfulOrThrow())) {
        var profileTask = scope.fork(this::fetchUserProfile);
        var ordersTask  = scope.fork(this::fetchUserOrders);

        scope.join();

        var userAggregate = new UserAggregate(profileTask.get(), ordersTask.get());
        IO.println("Successfully fetched: " + userAggregate);
    }
}

// =========================================================================
// 2. First Responder / Race
// Joiner.anySuccessfulResultOrThrow() returns the result of the first task
// to succeed, automatically interrupting and cancelling slower tasks.
// =========================================================================
void runShutdownOnSuccess() throws InterruptedException, ExecutionException {
    try (var scope = StructuredTaskScope.open(Joiner.<String>anySuccessfulOrThrow())) {
        scope.fork(() -> queryMirror("Server Alpha", 300));
        scope.fork(() -> queryMirror("Server Beta", 100));  // Fast server
        scope.fork(() -> queryMirror("Server Gamma", 500));

        // Block until the first subtask succeeds (or all fail)
        // In JDK 27, scope.join() returns the winning result directly for this Joiner policy
        var winner = scope.join();
        IO.println("Winner result: " + winner);
    }
}

void runShutdownOnTimeout() throws InterruptedException, ExecutionException {
    var timeout = Duration.ofSeconds(1);
    try (var scope = StructuredTaskScope.open(cfg -> cfg.withTimeout(timeout))) {
        var profileTask = scope.fork(this::fetchUserProfile);
        var ordersTask  = scope.fork(this::fetchUserOrders);

        scope.join();

        var userAggregate = new UserAggregate(profileTask.get(), ordersTask.get());
        IO.println("Successfully fetched: " + userAggregate);
    }
}

// Helpers
UserProfile fetchUserProfile() throws InterruptedException {
    Thread.sleep(120);
    return new UserProfile("Prakash");
}

UserOrders fetchUserOrders() throws InterruptedException {
    Thread.sleep(80);
    return new UserOrders(5);
}

String queryMirror(String serverName, long delayMs) throws InterruptedException {
    Thread.sleep(delayMs);
    return "Response from " + serverName;
}
