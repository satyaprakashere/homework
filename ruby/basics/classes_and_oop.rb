# ============================================================
# 07 — Classes & Object-Oriented Programming
# Objects, inheritance, access control, comparable
# ============================================================

# ──────────────────────────────────────────────
# Basic class
# ──────────────────────────────────────────────

class Animal
  # Class-level variable (shared across all instances)
  @@count = 0

  # attr_accessor creates getter AND setter
  # attr_reader  creates getter only
  # attr_writer  creates setter only
  attr_accessor :name, :age
  attr_reader   :species

  def initialize(name, age, species)
    @name    = name       # instance variable
    @age     = age
    @species = species
    @@count += 1
  end

  def speak
    "..."
  end

  def to_s
    "#{@species} named #{@name} (age #{@age})"
  end

  def self.count            # class method
    @@count
  end
end

a = Animal.new("Rex", 5, "Dog")
puts a.name        # => Rex
puts a.age         # => 5
a.age = 6          # setter
puts a             # => Dog named Rex (age 6)  (calls to_s)

# ──────────────────────────────────────────────
# Inheritance
# ──────────────────────────────────────────────

class Dog < Animal
  attr_reader :breed

  def initialize(name, age, breed)
    super(name, age, "Dog")   # call parent's initialize
    @breed = breed
  end

  def speak
    "Woof!"
  end

  def fetch(item)
    "#{@name} fetches the #{item}!"
  end
end

class Cat < Animal
  def initialize(name, age)
    super(name, age, "Cat")
  end

  def speak
    "Meow!"
  end
end

rex  = Dog.new("Rex", 3, "Labrador")
luna = Cat.new("Luna", 2)

puts rex.speak         # => Woof!
puts luna.speak        # => Meow!
puts rex.fetch("ball") # => Rex fetches the ball!
puts Animal.count      # => 3  (a, rex, luna)

# Polymorphism — same method, different behavior
[rex, luna, a].each do |animal|
  puts "#{animal.name} says: #{animal.speak}"
end

# ──────────────────────────────────────────────
# Access control: public / protected / private
# ──────────────────────────────────────────────

class BankAccount
  def initialize(owner, balance)
    @owner   = owner
    @balance = balance
  end

  # public by default
  def deposit(amount)
    @balance += validate_amount(amount)
    "Deposited #{amount}. New balance: #{@balance}"
  end

  def >(other)
    @balance > other.balance     # calls protected method on other
  end

  protected

  def balance         # accessible to subclasses and same-class instances
    @balance
  end

  private

  def validate_amount(amount)   # only callable from within the class
    raise ArgumentError, "Amount must be positive" unless amount > 0
    amount
  end
end

acc = BankAccount.new("Alice", 1000)
puts acc.deposit(500)
# acc.balance          # => NoMethodError (protected)
# acc.validate_amount  # => NoMethodError (private)

# ──────────────────────────────────────────────
# Comparable mixin — add <=> and get free: <, <=, >, >=, between?
# ──────────────────────────────────────────────

class Temperature
  include Comparable

  attr_reader :degrees

  def initialize(degrees)
    @degrees = degrees
  end

  def <=>(other)
    @degrees <=> other.degrees
  end

  def to_s
    "#{@degrees}°"
  end
end

temps = [Temperature.new(30), Temperature.new(15), Temperature.new(25)]
puts temps.sort.map(&:to_s).inspect   # => ["15°", "25°", "30°"]
puts temps.max                         # => 30°
puts Temperature.new(20).between?(Temperature.new(15), Temperature.new(25)) # => true

# ──────────────────────────────────────────────
# Struct — lightweight value objects
# ──────────────────────────────────────────────

Point = Struct.new(:x, :y) do
  def distance_to(other)
    Math.sqrt((x - other.x)**2 + (y - other.y)**2)
  end

  def to_s
    "(#{x}, #{y})"
  end
end

p1 = Point.new(0, 0)
p2 = Point.new(3, 4)
puts p1                          # => (0, 0)
puts p1.distance_to(p2).round(2) # => 5.0
