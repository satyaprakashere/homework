# ============================================================
# 01 — Variables & Types
# Ruby is dynamically typed. No type declarations needed.
# ============================================================

# --- Primitive types ---
name    = "Ruby"          # String
version = 3.2             # Float
year    = 1995            # Integer
is_fun  = true            # Boolean (TrueClass)
nothing = nil             # NilClass

puts name.class      # => String
puts version.class   # => Float
puts year.class      # => Integer
puts is_fun.class    # => TrueClass
puts nothing.class   # => NilClass

# --- Everything is an object (even numbers!) ---
puts 42.to_s         # => "42"  (Integer has methods)
puts -7.abs          # => 7
puts 3.14.round      # => 3

# --- Symbols: immutable, reusable labels ---
status = :active
puts status          # => active
puts status.class    # => Symbol
puts :hello.upcase   # => HELLO

# --- String interpolation ---
lang = "Ruby"
puts "Hello from #{lang}!"          # => Hello from Ruby!
puts "1 + 1 = #{1 + 1}"            # => 1 + 1 = 2

# --- Multi-line strings (heredoc) ---
message = <<~TEXT
  Ruby was created by Yukihiro Matsumoto
  and first appeared in #{year}.
TEXT
puts message

# --- Variable scope sigils ---
local_var    = "I'm local"           # local variable
$global_var  = "I'm global"          # global variable (avoid when possible)
CONSTANT     = "I never change"      # constant (ALL_CAPS)

puts local_var
puts $global_var
puts CONSTANT

# --- Type conversion ---
puts "42".to_i        # String -> Integer: 42
puts "3.14".to_f      # String -> Float:   3.14
puts 100.to_s         # Integer -> String: "100"
puts nil.to_a         # nil -> Array:      []
puts nil.to_s         # nil -> String:     ""
