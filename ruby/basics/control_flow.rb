# ============================================================
# 02 — Control Flow
# if/elsif/else, unless, case/when, ternary, loops
# ============================================================

# --- if / elsif / else ---
temperature = 28

if temperature > 35
  puts "It's scorching hot!"
elsif temperature > 20
  puts "Nice and warm."       # => this prints
else
  puts "Bundle up!"
end

# --- Inline (trailing) if — the Ruby way ---
puts "Warm day!" if temperature > 20

# --- unless (opposite of if) ---
raining = false
puts "Let's go outside!" unless raining

# --- Ternary ---
age = 20
status = age >= 18 ? "adult" : "minor"
puts status   # => adult

# --- case / when (like switch) ---
day = "Monday"

case day
when "Saturday", "Sunday"
  puts "Weekend! 🎉"
when "Monday"
  puts "Back to work..."    # => this prints
else
  puts "Midweek grind."
end

# --- case with ranges ---
score = 85

grade = case score
        when 90..100 then "A"
        when 80..89  then "B"   # => B
        when 70..79  then "C"
        else              "F"
        end
puts "Grade: #{grade}"

# --- while loop ---
count = 1
while count <= 3
  puts "while: count = #{count}"
  count += 1
end

# --- until loop (opposite of while) ---
n = 3
until n == 0
  puts "Countdown: #{n}"
  n -= 1
end

# --- loop with break ---
i = 0
loop do
  i += 1
  next if i == 2          # skip 2
  break if i > 4          # stop after 4
  puts "loop i = #{i}"
end

# --- times ---
3.times { |i| puts "times: #{i}" }

# --- upto / downto ---
1.upto(3)  { |i| puts "upto #{i}" }
3.downto(1){ |i| puts "downto #{i}" }
