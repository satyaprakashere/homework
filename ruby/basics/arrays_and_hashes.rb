# ============================================================
# 03 — Collections: Arrays & Hashes
# Ruby's most-used data structures
# ============================================================

# ──────────────────────────────────────────────
# ARRAYS
# ──────────────────────────────────────────────

fruits = ["apple", "banana", "cherry"]

# Accessing elements
puts fruits[0]        # => apple
puts fruits[-1]       # => cherry (negative index from end)
puts fruits[1..2]     # => banana, cherry (range slice)

# Modifying
fruits.push("date")           # add to end
fruits.unshift("avocado")     # add to front
fruits.pop                    # remove from end
fruits.shift                  # remove from front
puts fruits.inspect           # => ["banana", "cherry", "date"]

# Useful array methods
numbers = [3, 1, 4, 1, 5, 9, 2, 6]

puts numbers.length           # => 8
puts numbers.sort.inspect     # => [1, 1, 2, 3, 4, 5, 6, 9]
puts numbers.uniq.inspect     # => [3, 1, 4, 5, 9, 2, 6]
puts numbers.min              # => 1
puts numbers.max              # => 9
puts numbers.sum              # => 31
puts numbers.include?(5)      # => true
puts numbers.reverse.inspect  # => [6, 2, 9, 5, 1, 4, 1, 3]
puts numbers.first(3).inspect # => [3, 1, 4]

# Iteration
["a", "b", "c"].each { |x| print "#{x} " }
puts

# %w[] shorthand for array of strings
colors = %w[red green blue]
puts colors.inspect   # => ["red", "green", "blue"]

# Flatten nested arrays
nested = [1, [2, 3], [4, [5, 6]]]
puts nested.flatten.inspect    # => [1, 2, 3, 4, 5, 6]
puts nested.flatten(1).inspect # => [1, 2, 3, 4, [5, 6]] (one level deep)

# Zip two arrays together
a = [1, 2, 3]
b = ["a", "b", "c"]
puts a.zip(b).inspect   # => [[1, "a"], [2, "b"], [3, "c"]]

# ──────────────────────────────────────────────
# HASHES  (key => value pairs)
# ──────────────────────────────────────────────

# Old "hash rocket" syntax
person_old = { "name" => "Alice", "age" => 30 }

# Modern symbol key syntax (preferred)
person = { name: "Alice", age: 30, city: "Tokyo" }

puts person[:name]   # => Alice
puts person[:age]    # => 30

# Add / update keys
person[:hobby] = "climbing"
person[:age]   = 31
puts person.inspect

# Remove a key
person.delete(:city)
puts person.keys.inspect    # => [:name, :age, :hobby]
puts person.values.inspect  # => ["Alice", 31, "climbing"]

# Check existence
puts person.key?(:name)    # => true
puts person.value?("Alice")# => true

# Iteration
person.each do |key, value|
  puts "#{key}: #{value}"
end

# Useful hash methods
scores = { alice: 95, bob: 82, carol: 91 }

puts scores.min_by { |_, v| v }.inspect  # => [:bob, 82]
puts scores.max_by { |_, v| v }.inspect  # => [:alice, 95]
puts scores.sort_by { |_, v| v }.inspect # sorted array of pairs
puts scores.select { |_, v| v >= 90 }.inspect  # => {alice: 95, carol: 91}
puts scores.map    { |k, v| [k, v * 1.1] }.to_h.inspect  # scale values

# Default values for missing keys
inventory = Hash.new(0)    # default value is 0
inventory[:apples] += 3
inventory[:apples] += 2
puts inventory[:apples]    # => 5
puts inventory[:bananas]   # => 0  (default, not nil)

# Merging hashes
defaults = { color: "blue", size: "M", qty: 1 }
overrides = { color: "red", qty: 5 }
merged = defaults.merge(overrides)
puts merged.inspect   # => {color: "red", size: "M", qty: 5}
