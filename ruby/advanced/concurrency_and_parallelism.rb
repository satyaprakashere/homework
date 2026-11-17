# ============================================================
# Advanced Ruby — Concurrency & Parallelism
# Threads, Mutexes, Queues, Fibers, and Ractors
# ============================================================

puts "=== 1. Multi-threading (Thread) ==="

# Threads run concurrently; on CRuby / MRI, execution of Ruby bytecode
# is governed by the GVL (Global VM Lock), but IO operations release the GVL.
threads = 3.times.map do |i|
  Thread.new(i) do |id|
    # Thread-local storage
    Thread.current[:name] = "Worker-#{id}"
    sleep(0.01) # Simulate IO wait (releases GVL)
    "#{Thread.current[:name]} completed"
  end
end

results = threads.map(&:value) # .value implicitly calls .join and returns block value
puts results.join(", ")


puts "\n=== 2. Thread Synchronization with Mutex ==="

# Race conditions occur when multiple threads mutate shared state concurrently.
class BankAccount
  attr_reader :balance

  def initialize(initial)
    @balance = initial
    @mutex = Thread::Mutex.new
  end

  def deposit(amount)
    @mutex.synchronize do
      current = @balance
      # Sleep briefly to exaggerate race window if unprotected
      sleep(0.001)
      @balance = current + amount
    end
  end
end

account = BankAccount.new(100)
deposit_threads = 10.times.map do
  Thread.new { account.deposit(10) }
end
deposit_threads.each(&:join)
puts "Account balance (expected 200): #{account.balance}"


puts "\n=== 3. Producer-Consumer Pipeline with Thread::Queue ==="

# Thread::Queue is thread-safe and blocks when popping from an empty queue.
queue = Thread::Queue.new
consumed_items = []
collector_mutex = Thread::Mutex.new

# Consumer thread
consumer = Thread.new do
  loop do
    item = queue.pop # Blocks until an item is available
    break if item == :done # Sentinel value to signal termination

    collector_mutex.synchronize { consumed_items << "Processed #{item}" }
  end
end

# Producer thread
producer = Thread.new do
  5.times do |i|
    queue.push("Job-#{i + 1}")
    sleep(0.002)
  end
  queue.push(:done) # Send poison pill
end

[producer, consumer].each(&:join)
puts "Queue results: #{consumed_items.join(', ')}"


puts "\n=== 4. Fibers (Coroutines & Cooperative Multitasking) ==="

# Fibers are lightweight execution units with manual scheduling (Fiber.yield / resume).
# Unlike threads, they don't preempt; control is yielded cooperatively.
generator = Fiber.new do
  a, b = 0, 1
  loop do
    Fiber.yield a
    a, b = b, a + b
  end
end

fib_sequence = 8.times.map { generator.resume }
puts "Fibonacci sequence from Fiber: #{fib_sequence.inspect}"

# Passing data bidirectionally between caller and Fiber
greeter = Fiber.new do |initial_name|
  name = initial_name
  loop do
    reply = Fiber.yield "Hello, #{name}!"
    name = reply if reply
  end
end

puts greeter.resume("Alice")
puts greeter.resume("Bob")
puts greeter.resume("Charlie")


puts "\n=== 5. Ractors (Share-Nothing Parallel Actor Model) ==="

# Introduced in Ruby 3, Ractors provide true parallel execution across multiple
# CPU cores without being constrained by the GVL.
# Objects communicated between Ractors must be shareable (immutable / frozen)
# or moved (transferred ownership).

workers = 4.times.map do |i|
  Ractor.new(i) do |worker_id|
    # Compute intensive task (e.g. sum of squares)
    total = (1..50_000).sum { |n| (n * (worker_id + 1)) % 97 }
    "Ractor-#{worker_id}: #{total}"
  end
end

# Collect results from all parallel workers
# (Ruby 3 uses `take`, Ruby 4 uses `value`)
ractor_results = workers.map do |r|
  r.respond_to?(:value) ? r.value : r.take
end
puts "Parallel Ractor results:"
ractor_results.each { |res| puts "  #{res}" }
