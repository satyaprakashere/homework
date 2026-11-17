# ============================================================
# 09 — Error Handling
# raise, rescue, ensure, retry, custom exceptions
# ============================================================

# ──────────────────────────────────────────────
# Basic begin / rescue / ensure
# ──────────────────────────────────────────────

begin
  puts 10 / 0
rescue ZeroDivisionError => e
  puts "Caught: #{e.message}"   # => divided by 0
ensure
  puts "This always runs."      # cleanup code
end

# ── Multiple rescue clauses ──
def parse_number(str)
  Integer(str)
rescue ArgumentError => e
  puts "Bad input: #{e.message}"
  nil
rescue TypeError => e
  puts "Wrong type: #{e.message}"
  nil
end

puts parse_number("42").inspect   # => 42
puts parse_number("abc").inspect  # => nil (with message)
puts parse_number(nil).inspect    # => nil (with message)

# ── rescue as a one-liner ──
result = Integer("bad") rescue "default"
puts result   # => default

# ──────────────────────────────────────────────
# raise — trigger an exception
# ──────────────────────────────────────────────

def set_age(age)
  raise ArgumentError, "Age must be positive, got #{age}" if age < 0
  raise TypeError, "Age must be an Integer" unless age.is_a?(Integer)
  @age = age
end

begin
  set_age(-5)
rescue ArgumentError => e
  puts "Error: #{e.message}"
end

# Re-raise to propagate
def risky_operation
  begin
    raise "Something went wrong internally"
  rescue RuntimeError => e
    puts "Logging: #{e.message}"
    raise   # re-raise same exception
  end
end

begin
  risky_operation
rescue => e
  puts "Caller caught: #{e.message}"
end

# ──────────────────────────────────────────────
# retry — try the operation again
# ──────────────────────────────────────────────

attempts = 0

begin
  attempts += 1
  puts "Attempt #{attempts}..."
  raise "Transient failure" if attempts < 3
  puts "Success after #{attempts} attempts!"
rescue RuntimeError => e
  retry if attempts < 3
  puts "Giving up: #{e.message}"
end

# ──────────────────────────────────────────────
# Custom exception hierarchy
# ──────────────────────────────────────────────

module AppErrors
  class AppError < StandardError
    def initialize(msg = "An application error occurred")
      super(msg)
    end
  end

  class ValidationError < AppError
    attr_reader :field

    def initialize(field, msg)
      @field = field
      super("Validation failed for '#{field}': #{msg}")
    end
  end

  class NotFoundError < AppError
    def initialize(resource, id)
      super("#{resource} with id=#{id} not found")
    end
  end

  class DatabaseError < AppError; end
end

# Using custom exceptions
def find_user(id)
  raise AppErrors::NotFoundError.new("User", id) if id > 100
  { id: id, name: "User #{id}" }
end

def create_user(params)
  raise AppErrors::ValidationError.new(:email, "can't be blank") if params[:email].nil?
  params
end

[42, 200].each do |id|
  user = find_user(id)
  puts user.inspect
rescue AppErrors::NotFoundError => e
  puts "Not found: #{e.message}"
end

begin
  create_user({ name: "Bob" })
rescue AppErrors::ValidationError => e
  puts "#{e.message} (field: #{e.field})"
rescue AppErrors::AppError => e  # catch-all for app errors
  puts "App error: #{e.message}"
end

# ──────────────────────────────────────────────
# ensure for resource cleanup (like finally)
# ──────────────────────────────────────────────

def read_data(path)
  file = nil
  begin
    file = File.open(path, "r")
    file.read
  rescue Errno::ENOENT => e
    "File not found: #{e.message}"
  ensure
    file&.close   # safe navigation: close only if file is not nil
    puts "File handle released."
  end
end

puts read_data("/nonexistent/file.txt")
