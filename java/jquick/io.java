
void main() throws IOException {
  final var br = new BufferedReader(new InputStreamReader(System.in));
  final var st = new StringTokenizer(br.readLine());

  int n = Integer.parseInt(st.nextToken());
  int k = Integer.parseInt(st.nextToken());
  IO.println("n = " + n + " and k = " + k);
}

public static Integer readIntWithTimeout(int timeoutSeconds) {
  ExecutorService executor = Executors.newSingleThreadExecutor();
  Callable<Integer> task = () -> {
    System.out.print("Enter an integer: ");
    Scanner scanner = new Scanner(System.in);
    return scanner.nextInt();
  };
  
  Future<Integer> future = executor.submit(task);
  try {
    return future.get(timeoutSeconds, TimeUnit.SECONDS);
  } catch (TimeoutException e) {
    System.out.println("\nTimeout reached.");
    future.cancel(true);
  } catch (InterruptedException | ExecutionException e) {
    System.out.println("\nException occurred.");
  } finally {
    executor.shutdownNow();
  }
  return null; // Indicates timeout or error
}