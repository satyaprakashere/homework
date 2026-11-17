# ============================================================
# 05 — Blocks, Procs & Lambdas
# Core to "the Ruby way" — passing behavior as data
# ============================================================

# ──────────────────────────────────────────────
# BLOCKS — anonymous code chunks passed to methods
# ──────────────────────────────────────────────

# A method that accepts a block with `yield`
def repeat(n)
  n.times { yield }
end

repeat(3) { print "Ruby! " }
puts

# Passing block arguments via yield
def greet_each(names)
  names.each { |name| yield name }
end

greet_each(["Alice", "Bob"]) { |n| puts "Hello, #{n}!" }

# Check if a block was given
def maybe_yield
  if block_given?
    yield
  else
    puts "No block provided."
  end
end

maybe_yield { puts "Block ran!" }
maybe_yield

# do...end vs curly braces (functionally identical, style differs)
[1, 2, 3].each do |n|
  puts "do/end: #{n}"
end

[1, 2, 3].each { |n| puts "braces: #{n}" }

# ──────────────────────────────────────────────
# PROCS — saved blocks (first-class objects)
# ──────────────────────────────────────────────

square = Proc.new { |x| x ** 2 }
cube   = proc { |x| x ** 3 }     # shorthand

puts square.call(4)   # => 16
puts cube.call(3)     # => 27
puts square.(5)       # => 25   (alternative call syntax)
puts cube[2]          # => 8    (another call syntax)

# Proc stored and reused
double = proc { |n| n * 2 }
puts [1, 2, 3, 4].map(&double).inspect   # => [2, 4, 6, 8]

# Procs are lenient about arity (argument count)
lenient = Proc.new { |a, b| "a=#{a.inspect}, b=#{b.inspect}" }
puts lenient.call(1)       # => a=1, b=nil  (no error for missing arg)
puts lenient.call(1, 2, 3) # => a=1, b=2    (extra args silently ignored)

# ──────────────────────────────────────────────
# LAMBDAS — stricter Procs with method-like behavior
# ──────────────────────────────────────────────

add  = lambda { |a, b| a + b }
mul  = ->(a, b) { a * b }       # stabby lambda (modern syntax)

puts add.call(3, 4)   # => 7
puts mul.(5, 6)       # => 30

# Lambdas ARE strict about arity
strict = lambda { |a, b| "#{a}, #{b}" }
puts strict.call(1, 2)
# strict.call(1)      # => ArgumentError!
# strict.call(1,2,3)  # => ArgumentError!

# Key difference: return inside a lambda returns from the lambda,
#                 return inside a Proc returns from the enclosing method.
def demo_proc_return
  p = Proc.new { return "from proc" }
  p.call
  "after proc"   # never reached
end

def demo_lambda_return
  l = -> { return "from lambda" }
  l.call
  "after lambda"   # this IS reached
end

puts demo_proc_return   # => from proc
puts demo_lambda_return # => after lambda

# ──────────────────────────────────────────────
# & — converting Procs/Symbols to blocks
# ──────────────────────────────────────────────

# Method reference via symbol with &
words = ["hello", "world", "ruby"]
puts words.map(&:upcase).inspect    # => ["HELLO", "WORLD", "RUBY"]
puts words.map(&:length).inspect    # => [5, 5, 4]

# Capture a block into a named parameter with &
def capture(&block)
  puts "Block class: #{block.class}"
  block.call(10)
end

capture { |n| puts "Got: #{n}" }

# Composing procs/lambdas (Ruby 2.6+)
double_it = ->(x) { x * 2 }
add_one   = ->(x) { x + 1 }

double_then_add = add_one << double_it   # right-to-left: double first
add_then_double = add_one >> double_it   # left-to-right: add first

puts double_then_add.call(5)  # => 11  (5*2=10, 10+1=11)
puts add_then_double.call(5)  # => 12  (5+1=6, 6*2=12)
