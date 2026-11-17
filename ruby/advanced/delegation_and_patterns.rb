# ============================================================
# Advanced Ruby — Delegation & Idiomatic Design Patterns
# Forwardable, SimpleDelegator, Method Objects & PubSub
# ============================================================

require "forwardable"
require "delegate"

puts "=== 1. Selective Delegation with Forwardable ==="

# Forwardable allows a class to explicitly delegate specific methods to an internal collaborator.
class ShoppingCart
  extend Forwardable

  # Delegate size, each, and empty? to the internal @items array
  def_delegators :@items, :size, :empty?, :each
  # Delegate first to @items, renaming it to primary_item
  def_delegator :@items, :first, :primary_item

  def initialize
    @items = []
  end

  def add(item)
    @items << item
  end
end

cart = ShoppingCart.new
cart.add("Mechanical Keyboard")
cart.add("USB-C Hub")

puts "Cart size: #{cart.size}"
puts "Cart empty? #{cart.empty?}"
puts "Primary item: #{cart.primary_item}"
print "Items via delegated each: "
cart.each { |item| print "#{item} | " }
puts


puts "\n=== 2. Decorator Pattern with SimpleDelegator ==="

# SimpleDelegator forwards ALL undefined methods to the underlying object.
# Perfect for decorators and presenters.
class Order
  attr_reader :id, :total, :created_at

  def initialize(id, total)
    @id = id
    @total = total
    @created_at = Time.now
  end
end

class OrderPresenter < SimpleDelegator
  # Decorate or override specific presentation methods
  def formatted_total
    format("$%.2f", total)
  end

  def invoice_number
    "INV-%06d" % id
  end
end

raw_order = Order.new(1042, 189.5)
decorated = OrderPresenter.new(raw_order)

# Delegated methods pass directly to raw_order:
puts "Invoice Number (decorated): #{decorated.invoice_number}"
puts "Formatted Total (decorated): #{decorated.formatted_total}"
puts "Direct delegated created_at: #{decorated.created_at}"
puts "Is decorated an OrderPresenter? #{decorated.is_a?(OrderPresenter)}"
puts "Underlying target object: #{decorated.__getobj__}"


puts "\n=== 3. First-Class Method Objects & Symbol#to_proc ==="

class TaxCalculator
  def initialize(rate)
    @rate = rate
  end

  def compute(amount)
    (amount * (1.0 + @rate)).round(2)
  end
end

tax_calc = TaxCalculator.new(0.08)

# Convert a method on an object into a standalone Method object
tax_fn = tax_calc.method(:compute)
puts "Method object inspection: #{tax_fn}"
puts "Calling method object: #{tax_fn.call(100)}"

# Method objects can be converted directly into Procs and passed with &
prices = [10.0, 25.0, 50.0]
taxed_prices = prices.map(&tax_fn)
puts "Taxed prices using &tax_fn: #{taxed_prices.inspect}"

# How Symbol#to_proc works under the hood:
# :upcase.to_proc is equivalent to ->(obj) { obj.upcase }
words = %w[ruby rails gems]
puts "Symbol to proc: #{words.map(&:upcase).inspect}"


puts "\n=== 4. Event Bus / PubSub Pattern ==="

class EventBus
  def initialize
    @listeners = Hash.new { |h, k| h[k] = [] }
  end

  def subscribe(event_type, &listener)
    @listeners[event_type.to_sym] << listener
  end

  def publish(event_type, payload = {})
    handlers = @listeners[event_type.to_sym]
    handlers.each { |handler| handler.call(payload) }
  end
end

bus = EventBus.new

bus.subscribe(:user_registered) do |data|
  puts "[Email Service] Welcome email dispatched to #{data[:email]}"
end

bus.subscribe(:user_registered) do |data|
  puts "[Metrics Service] Increment user signup count (Plan: #{data[:plan]})"
end

bus.publish(:user_registered, email: "dev@example.com", plan: "Pro")
