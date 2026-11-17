# ============================================================
# 04 — Methods
# Defining methods, default args, keyword args, splat, return
# ============================================================

# --- Basic method ---
def greet(name)
  "Hello, #{name}!"    # last expression is implicitly returned
end

puts greet("Alice")   # => Hello, Alice!

# --- Default arguments ---
def power(base, exponent = 2)
  base ** exponent
end

puts power(3)     # => 9  (uses default exponent)
puts power(2, 10) # => 1024

# --- Keyword arguments (named params) ---
def describe_person(name:, age:, city: "Unknown")
  "#{name} is #{age} years old, from #{city}."
end

puts describe_person(name: "Bob", age: 25)
puts describe_person(age: 30, name: "Carol", city: "Paris")

# --- Splat (*args) — variable number of positional args ---
def sum(*numbers)
  numbers.sum
end

puts sum(1, 2, 3)        # => 6
puts sum(10, 20, 30, 40) # => 100

# --- Double splat (**kwargs) — variable keyword args ---
def show_options(**opts)
  opts.each { |k, v| puts "  #{k}: #{v}" }
end

show_options(color: "blue", size: "L", qty: 3)

# --- Mixing all arg types ---
def mixed(required, optional = "default", *rest, key:, **extra)
  puts "required: #{required}"
  puts "optional: #{optional}"
  puts "rest:     #{rest.inspect}"
  puts "key:      #{key}"
  puts "extra:    #{extra.inspect}"
end

mixed("must", "opt", 1, 2, 3, key: "k", x: 1, y: 2)

# --- Explicit return ---
def sign(n)
  return "positive" if n > 0
  return "negative" if n < 0
  "zero"
end

puts sign(5)   # => positive
puts sign(-3)  # => negative
puts sign(0)   # => zero

# --- Methods that return multiple values (via array) ---
def min_max(arr)
  [arr.min, arr.max]
end

low, high = min_max([3, 1, 9, 4])
puts "min=#{low}, max=#{high}"

# --- Predicate methods end with ? (return true/false) ---
def adult?(age)
  age >= 18
end

puts adult?(20)  # => true
puts adult?(15)  # => false

# --- Bang methods end with ! (mutate the receiver) ---
name = "hello world"
puts name.upcase    # => HELLO WORLD (name unchanged)
puts name           # => hello world
name.upcase!        # mutate in place
puts name           # => HELLO WORLD

# --- Method aliasing ---
def say_hi
  "Hi there!"
end
alias say_hello say_hi
puts say_hello   # => Hi there!
