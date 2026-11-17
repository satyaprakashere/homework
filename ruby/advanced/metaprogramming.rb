# ============================================================
# Advanced Ruby — Metaprogramming & Dynamic Behavior
# Code that writes, inspects, and modifies code at runtime
# ============================================================

puts "=== 1. Dynamic Method Dispatch (send & public_send) ==="

class Calculator
  def add(a, b); a + b; end
  def multiply(a, b); a * b; end

  private

  def secret_formula; "42 (confidential)"; end
end

calc = Calculator.new
operation = :multiply

# public_send respects access control (preferred for external input)
puts "calc.public_send(:add, 10, 5): #{calc.public_send(:add, 10, 5)}"
puts "calc.public_send(operation, 6, 7): #{calc.public_send(operation, 6, 7)}"

# send can bypass private visibility (use judiciously in tests/frameworks)
puts "calc.send(:secret_formula): #{calc.send(:secret_formula)}"


puts "\n=== 2. Dynamic Method Definition (define_method) ==="

class HTMLBuilder
  # Dynamically define tag wrapper methods
  %i[h1 h2 p div strong em].each do |tag_name|
    define_method(tag_name) do |content|
      "<#{tag_name}>#{content}</#{tag_name}>"
    end
  end
end

builder = HTMLBuilder.new
puts builder.h1("Welcome to Ruby")
puts builder.p("Metaprogramming makes code concise.")
puts builder.strong("Important announcement")


puts "\n=== 3. Ghost Methods (method_missing & respond_to_missing?) ==="

class DynamicConfig
  def initialize(hash = {})
    @data = hash.transform_keys(&:to_sym)
  end

  def method_missing(name, *args, &block)
    # Handle setter methods (e.g. host=)
    if name.end_with?("=")
      key = name.to_s.chomp("=").to_sym
      @data[key] = args.first
    elsif @data.key?(name)
      @data[name]
    else
      super
    end
  end

  # CRITICAL: Always implement respond_to_missing? when overriding method_missing
  def respond_to_missing?(name, include_private = false)
    name.end_with?("=") || @data.key?(name) || super
  end
end

config = DynamicConfig.new(host: "localhost", port: 5432)
puts "Host: #{config.host}"
puts "Port: #{config.port}"

config.timeout = 30
puts "Timeout: #{config.timeout}"
puts "Responds to timeout? #{config.respond_to?(:timeout)}"
puts "Responds to unknown? #{config.respond_to?(:unknown)}"


puts "\n=== 4. Evaluation Contexts (instance_eval vs class_eval) ==="

class Person
  attr_accessor :name, :role
  def initialize(name); @name = name; end
end

alice = Person.new("Alice")

# instance_eval evaluates code in the context of an INSTANCE (self is alice)
alice.instance_eval do
  @role = "Architect"     # Access private instance variables directly
  def superpower         # Defines a singleton method only on alice
    "Instant Refactoring"
  end
end

puts "#{alice.name} is an #{alice.role} with superpower: #{alice.superpower}"

# class_eval evaluates code in the context of a CLASS (re-opens the class)
Person.class_eval do
  def introduce
    "Hi, I'm #{@name} (#{@role || 'Member'})"
  end
end

puts alice.introduce


puts "\n=== 5. Reflection & Introspection ==="

puts "Person instance methods (custom): #{Person.instance_methods(false)}"
puts "Alice instance variables: #{alice.instance_variables}"
puts "Reading @role dynamically: #{alice.instance_variable_get(:@role)}"

alice.instance_variable_set(:@role, "Principal Architect")
puts "Updated @role: #{alice.instance_variable_get(:@role)}"

# Dynamic constant resolution
const_name = "Person"
resolved_class = Object.const_get(const_name)
puts "Resolved #{const_name} to class: #{resolved_class}"


puts "\n=== 6. Lifecycle Hooks (inherited, included, prepended, method_added) ==="

module Auditable
  def self.included(base)
    puts "[Hook] #{self} was included in #{base}"
  end

  def self.prepended(base)
    puts "[Hook] #{self} was prepended to #{base}"
  end
end

class BaseRecord
  # Subclass tracking registry
  @subclasses = []

  class << self
    attr_reader :subclasses

    def inherited(subclass)
      super
      puts "[Hook] New model detected: #{subclass}"
      @subclasses << subclass
    end

    def method_added(method_name)
      puts "[Hook] Method defined on #{self}: #{method_name}"
    end
  end
end

class User < BaseRecord
  include Auditable

  def authenticate; true; end
end

class Order < BaseRecord; end

puts "All recorded models: #{BaseRecord.subclasses}"
