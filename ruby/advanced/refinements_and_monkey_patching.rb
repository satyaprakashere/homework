# ============================================================
# Advanced Ruby — Refinements & Scoped Monkey Patching
# Safe monkey-patching with lexical scope to avoid global collision
# ============================================================

puts "=== 1. The Perils of Global Monkey Patching ==="

# In standard Ruby, reopening core classes modifies them GLOBALLY for all gems and code:
class String
  def legacy_reverse_words
    split.reverse.join(" ")
  end
end

puts "Global monkey patch on String: #{'hello world'.legacy_reverse_words}"
# While powerful, doing this in libraries often causes naming clashes and bugs.


puts "\n=== 2. Defining Refinements (Lexically Scoped Extensions) ==="

# Refinements restrict monkey patching strictly to the lexical scope where `using` is declared!
module StringExtensions
  refine String do
    def to_slug
      downcase.strip.gsub(/[^\w\s-]/, '').gsub(/[\s_-]+/, '-').gsub(/^-+|-+$/, '')
    end

    def truncate(length = 20, ellipsis = "...")
      return self if self.length <= length
      self[0...(length - ellipsis.length)] + ellipsis
    end
  end
end

module NumberExtensions
  refine Numeric do
    def to_currency(symbol = "$")
      format("#{symbol}%.2f", self)
    end
  end
end


puts "\n=== 3. Using Refinements Inside a Class Scope ==="

class BlogPost
  # Activate the refinement ONLY within this class scope
  using StringExtensions
  using NumberExtensions

  attr_reader :title, :price

  def initialize(title, price)
    @title = title
    @price = price
  end

  def slug
    @title.to_slug # Refinement active here!
  end

  def summary
    @title.truncate(15)
  end

  def formatted_price
    @price.to_currency("€") # Refinement active here!
  end
end

post = BlogPost.new("Advanced Ruby 3 & 4 Metaprogramming Guide", 49.95)
puts "Post slug: #{post.slug}"
puts "Post summary: #{post.summary}"
puts "Formatted price: #{post.formatted_price}"


puts "\n=== 4. Lexical Isolation Verification ==="

# Outside the class where `using` was called, String and Numeric remain untouched!
sample = "Advanced Ruby 3 & 4 Metaprogramming Guide"
puts "Can sample call to_slug outside the class? #{sample.respond_to?(:to_slug)}"

begin
  sample.to_slug
rescue NoMethodError => e
  puts "Caught expected error outside scope: #{e.class} - #{e.message.lines.first.chomp}"
end


puts "\n=== 5. Activating Refinements in a File / Script Scope ==="

# You can also activate refinements at the top-level of a file or module:
using StringExtensions

puts "Now active in this file scope: #{'Lexical Scoping in Ruby is Clean'.to_slug}"
