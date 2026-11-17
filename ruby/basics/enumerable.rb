# ============================================================
# 06 — Enumerable: map, select, reduce & friends
# "The Ruby Way" of working with collections
# ============================================================

numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# ── map / collect ── transform each element
puts numbers.map  { |n| n * 2 }.inspect   # => [2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
puts numbers.map  { |n| n ** 2 }.inspect  # => [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]
puts numbers.map(&:to_s).inspect          # => ["1", "2", ..., "10"]

# ── select / filter ── keep matching elements
puts numbers.select { |n| n.even? }.inspect  # => [2, 4, 6, 8, 10]
puts numbers.select { |n| n > 5 }.inspect   # => [6, 7, 8, 9, 10]

# ── reject ── drop matching elements (opposite of select)
puts numbers.reject { |n| n.even? }.inspect  # => [1, 3, 5, 7, 9]

# ── reduce / inject ── fold collection to a single value
sum     = numbers.reduce(0) { |acc, n| acc + n }
product = numbers.reduce(1, :*)    # using symbol shorthand
puts "sum=#{sum}, product=#{product}"

# ── each_with_object ── build up an object while iterating
result = numbers.each_with_object([]) do |n, arr|
  arr << n * 3 if n.odd?
end
puts result.inspect   # => [3, 9, 15, 21, 27]

# ── find / detect ── first matching element
puts numbers.find   { |n| n > 5 }        # => 6
puts numbers.detect { |n| n.even? }      # => 2

# ── all? / any? / none? / one? ── boolean checks
puts numbers.all?  { |n| n > 0 }         # => true
puts numbers.any?  { |n| n > 9 }         # => true
puts numbers.none? { |n| n > 10 }        # => true
puts numbers.one?  { |n| n == 5 }        # => true

# ── count ── count matches
puts numbers.count { |n| n.odd? }        # => 5

# ── flat_map ── map + flatten (one level)
puts [[1,2],[3,4]].flat_map { |a| a.map { |x| x * 10 } }.inspect
# => [10, 20, 30, 40]

# ── each_with_index ── iterate with index
["a", "b", "c"].each_with_index do |char, idx|
  puts "#{idx}: #{char}"
end

# ── each_slice / each_cons ── chunk an array
puts "── each_slice(3) ──"
numbers.each_slice(3) { |s| puts s.inspect }

puts "── each_cons(3) ──"
[1,2,3,4,5].each_cons(3) { |c| puts c.inspect }

# ── group_by ── group elements into a hash by block result
grouped = numbers.group_by { |n| n.even? ? :even : :odd }
puts grouped[:even].inspect   # => [2, 4, 6, 8, 10]
puts grouped[:odd].inspect    # => [1, 3, 5, 7, 9]

words = %w[apple ant banana bear cherry cat]
by_letter = words.group_by { |w| w[0] }
puts by_letter.inspect

# ── tally ── count occurrences
rolls = [1, 2, 3, 2, 1, 3, 3, 6]
puts rolls.tally.inspect   # => {1=>2, 2=>2, 3=>3, 6=>1}

# ── min_by / max_by / sort_by ──
people = [
  { name: "Charlie", age: 35 },
  { name: "Alice",   age: 28 },
  { name: "Bob",     age: 31 },
]

youngest = people.min_by { |p| p[:age] }
puts "Youngest: #{youngest[:name]}"        # => Alice

sorted = people.sort_by { |p| p[:age] }
sorted.each { |p| puts "#{p[:name]}: #{p[:age]}" }

# ── zip ──
puts [1,2,3].zip([4,5,6]).map { |a,b| a + b }.inspect   # => [5, 7, 9]

# ── Chaining (the real power) ──
result = (1..20)
  .select { |n| n.odd? }
  .map    { |n| n ** 2 }
  .reject { |n| n > 100 }
  .sum
puts "Chained result: #{result}"   # => 1+9+25+49+81 = 165
