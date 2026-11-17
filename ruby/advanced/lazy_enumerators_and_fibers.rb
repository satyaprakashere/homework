# ============================================================
# Advanced Ruby — Lazy Enumerators, Streams & External Iteration
# Processing infinite or massive sequences efficiently
# ============================================================

puts "=== 1. Custom Enumerator with External Iteration ==="

# An Enumerator wraps iteration logic and provides both internal iteration
# (via `each`) and external iteration (via `next`, `peek`, `rewind`).
power_of_two = Enumerator.new do |yielder|
  val = 1
  loop do
    yielder << val # or yielder.yield(val)
    val *= 2
  end
end

puts "First 5 powers of two: #{power_of_two.take(5)}"
puts "External iteration with next: #{power_of_two.next}"
puts "External iteration with next: #{power_of_two.next}"
puts "Peek next value without advancing: #{power_of_two.peek}"
puts "Next after peek: #{power_of_two.next}"

power_of_two.rewind
puts "After rewind: #{power_of_two.next}"


puts "\n=== 2. Handling StopIteration ==="

finite_enum = Enumerator.new do |y|
  y << :first
  y << :second
end

loop do
  # Ruby's `loop` automatically rescues StopIteration and breaks cleanly!
  item = finite_enum.next
  puts "Item: #{item}"
end


puts "\n=== 3. Infinite Streams with Enumerator::Lazy ==="

# Without `.lazy`, calling `select` on an infinite range `(1..Float::INFINITY)`
# would hang indefinitely trying to compute the entire array.
# `.lazy` defers evaluation until terminal operations like `take(n).to_a` or `first`.

primes_lazy = (2..Float::INFINITY).lazy.select do |n|
  (2..Math.sqrt(n)).none? { |d| (n % d).zero? }
end

first_10_primes = primes_lazy.take(10).to_a
puts "First 10 primes: #{first_10_primes.inspect}"

# Chained lazy pipeline
transformed = (1..Float::INFINITY).lazy
                                  .select(&:odd?)
                                  .map { |n| n ** 2 }
                                  .select { |sq| sq.to_s.end_with?("9") }
                                  .take(5)
                                  .to_a

puts "First 5 odd squares ending in 9: #{transformed.inspect}"


puts "\n=== 4. Eager vs Lazy Evaluation Comparison ==="

# Measuring evaluation counts:
eager_eval_count = 0
lazy_eval_count  = 0

# Eager evaluation processes ALL elements in each step
[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].select do |n|
  eager_eval_count += 1
  n.even?
end.take(2)

# Lazy evaluation stops immediately when requirements are satisfied
[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].lazy.select do |n|
  lazy_eval_count += 1
  n.even?
end.take(2).to_a

puts "Eager select checks performed: #{eager_eval_count}" # Evaluated all 10
puts "Lazy select checks performed:  #{lazy_eval_count}"  # Evaluated only until 2 were found (4 checks)


puts "\n=== 5. Coroutine Pipeline Using Fibers ==="

# Fibers can be composed into lightweight Unix-pipe-like processing stages
def filter_stage(upstream_fiber)
  Fiber.new do
    loop do
      value = upstream_fiber.resume
      break unless upstream_fiber.alive?

      Fiber.yield(value) if value % 3 == 0
    end
  end
end

source_fiber = Fiber.new do
  (1..20).each { |n| Fiber.yield(n) }
end

divisible_by_3_fiber = filter_stage(source_fiber)

collected = []
while divisible_by_3_fiber.alive?
  val = divisible_by_3_fiber.resume
  collected << val if val
end

puts "Numbers divisible by 3 from pipeline: #{collected.inspect}"
