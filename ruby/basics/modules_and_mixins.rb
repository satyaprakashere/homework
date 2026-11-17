# ============================================================
# 08 — Modules & Mixins
# Namespacing + sharing behavior without multiple inheritance
# ============================================================

# ──────────────────────────────────────────────
# Module as a namespace
# ──────────────────────────────────────────────

module Geometry
  PI = 3.14159265358979

  class Circle
    def initialize(radius)
      @radius = radius
    end

    def area
      PI * @radius ** 2
    end

    def circumference
      2 * PI * @radius
    end

    def to_s
      "Circle(r=#{@radius})"
    end
  end

  class Rectangle
    def initialize(width, height)
      @width  = width
      @height = height
    end

    def area
      @width * @height
    end

    def perimeter
      2 * (@width + @height)
    end

    def to_s
      "Rectangle(#{@width}x#{@height})"
    end
  end
end

c = Geometry::Circle.new(5)
r = Geometry::Rectangle.new(4, 6)
puts "#{c} area=#{c.area.round(2)}, circ=#{c.circumference.round(2)}"
puts "#{r} area=#{r.area}, perimeter=#{r.perimeter}"

# ──────────────────────────────────────────────
# Module as a Mixin — `include` adds instance methods
# ──────────────────────────────────────────────

module Greetable
  def greet
    "Hello, I am #{name}!"
  end

  def farewell
    "Goodbye from #{name}."
  end
end

module Serializable
  def to_json_like
    vars = instance_variables.map do |var|
      "\"#{var.to_s[1..]}\": \"#{instance_variable_get(var)}\""
    end
    "{ #{vars.join(", ")} }"
  end
end

class Person
  include Greetable
  include Serializable

  attr_reader :name, :age

  def initialize(name, age)
    @name = name
    @age  = age
  end
end

class Robot
  include Greetable

  attr_reader :name, :model

  def initialize(name, model)
    @name  = name
    @model = model
  end
end

alice = Person.new("Alice", 30)
r2    = Robot.new("R2-D2", "Astromech")

puts alice.greet         # => Hello, I am Alice!
puts r2.greet            # => Hello, I am R2-D2!
puts alice.farewell      # => Goodbye from Alice.
puts alice.to_json_like  # pseudo-JSON serialization

# Check inheritance chain
puts Person.ancestors.inspect
# => [Person, Serializable, Greetable, Object, Kernel, BasicObject]

# ──────────────────────────────────────────────
# extend — adds module methods as CLASS methods
# ──────────────────────────────────────────────

module ClassHelpers
  def description
    "I am the #{self.name} class."
  end

  def create(*args)
    new(*args)
  end
end

class Product
  extend ClassHelpers

  attr_reader :name, :price

  def initialize(name, price)
    @name  = name
    @price = price
  end
end

puts Product.description          # => I am the Product class.
p = Product.create("Widget", 9.99)
puts "#{p.name}: $#{p.price}"

# ──────────────────────────────────────────────
# Hook method: included — runs when module is mixed in
# ──────────────────────────────────────────────

module Trackable
  def self.included(base)
    puts "Trackable was included in #{base.name}"
    base.instance_variable_set(:@tracked_instances, [])
    base.extend(ClassMethods)
  end

  module ClassMethods
    def track(instance)
      @tracked_instances << instance
    end

    def all_tracked
      @tracked_instances
    end
  end

  def register
    self.class.track(self)
    self
  end
end

class Vehicle
  include Trackable

  attr_reader :plate

  def initialize(plate)
    @plate = plate
    register
  end

  def to_s
    "Vehicle(#{@plate})"
  end
end

Vehicle.new("ABC-123")
Vehicle.new("XYZ-789")
puts Vehicle.all_tracked.map(&:to_s).inspect
