# ============================================================
# Advanced Ruby — Object Model, Singleton Classes & Method Lookup
# The hidden machinery behind Ruby's classes, objects, and dispatch
# ============================================================

puts "=== 1. Ruby Class & Metaclass Hierarchy ==="

# Everything in Ruby is an object, and every class is an instance of Class
puts "Class of String:          #{String.class}"
puts "Class of Class:           #{Class.class}"
puts "Superclass of Class:      #{Class.superclass}"
puts "Superclass of Module:     #{Module.superclass}"
puts "Superclass of Object:     #{Object.superclass}"
puts "Superclass of BasicObject: #{BasicObject.superclass.inspect}"


puts "\n=== 2. Singleton Class (Eigenclass / Metaclass) ==="

# Every single Ruby object has a hidden singleton class that can hold
# methods exclusive to that specific instance.
greeting = "Hello"

def greeting.shout
  upcase + "!!!"
end

puts "Custom shout on greeting: #{greeting.shout}"
puts "Does another string have shout? #{'World'.respond_to?(:shout)}"
puts "Singleton class of greeting: #{greeting.singleton_class}"

# Alternative syntax: Opening the singleton class directly
class << greeting
  def whisper
    downcase + "..."
  end
end

puts "Greeting whisper: #{greeting.whisper}"


puts "\n=== 3. Class Methods Are Just Singleton Methods ==="

# In Ruby, there are no special "static methods".
# Class methods are simply singleton methods defined on the Class object!
class Article
  # Style A
  def self.popular
    "Top articles"
  end

  # Style B (opening the singleton class of Article)
  class << self
    def trending
      "Trending today"
    end
  end
end

puts "Article.popular:  #{Article.popular}"
puts "Article.trending: #{Article.trending}"
puts "Singleton methods of Article: #{Article.singleton_methods}"


puts "\n=== 4. Method Lookup Chain: prepend vs include vs extend ==="

module LoggingWrapper
  def perform
    "[LOG START] " + super + " [LOG END]"
  end
end

module DiagnosticHelpers
  def info
    "Diagnostics OK"
  end
end

class Task
  def perform
    "Executing core task"
  end
end

# 1. include: Places module AFTER the class in ancestors (class overrides module)
# 2. prepend: Places module BEFORE the class in ancestors (module wraps class)
# 3. extend: Mixes methods into the object's SINGLETON class

class InstrumentedTask < Task
  prepend LoggingWrapper     # Runs BEFORE Task#perform, can call super!
end

task = InstrumentedTask.new
puts "Instrumented result: #{task.perform}"
puts "Ancestors lookup order: #{InstrumentedTask.ancestors}"

# Using `extend` to add class-level methods
class Report
  extend DiagnosticHelpers
end

puts "Report.info (via extend): #{Report.info}"
puts "Report singleton ancestors: #{Report.singleton_class.ancestors.first(3)}"


puts "\n=== 5. Singleton Class Inheritance ==="

# Why can a subclass call class methods defined on its parent?
# Because the singleton class of Child inherits from the singleton class of Parent!
class Vehicle
  def self.category; "Transportation"; end
end

class ElectricCar < Vehicle
end

puts "ElectricCar.category: #{ElectricCar.category}"
puts "ElectricCar singleton class superclass: #{ElectricCar.singleton_class.superclass}"
puts "Is equal to Vehicle.singleton_class? #{ElectricCar.singleton_class.superclass == Vehicle.singleton_class}"
