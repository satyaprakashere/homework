# ============================================================
# Advanced Ruby — Domain-Specific Languages (DSLs)
# Building declarative, readable DSLs using Ruby's block mechanics
# ============================================================

puts "=== 1. Block Yielding vs instance_eval Pattern ==="

# Pattern A: Yielding self (explicit block parameter)
# Advantage: Preserves access to surrounding lexical scope
class TableBuilderYield
  def initialize
    @columns = []
  end

  def column(name, type)
    @columns << { name: name, type: type }
  end

  def render
    @columns.map { |col| "#{col[:name]} (#{col[:type]})" }.join(", ")
  end

  def self.build
    builder = new
    yield(builder) if block_given?
    builder
  end
end

table_a = TableBuilderYield.build do |t|
  t.column :id, :integer
  t.column :email, :string
end
puts "Explicit receiver DSL: #{table_a.render}"


# Pattern B: instance_eval (implicit receiver)
# Advantage: Ultra-clean declarative syntax without 't.' prefix
class TableBuilderEval
  def initialize
    @columns = []
  end

  def column(name, type)
    @columns << { name: name, type: type }
  end

  def render
    @columns.map { |col| "#{col[:name]} (#{col[:type]})" }.join(", ")
  end

  def self.build(&block)
    builder = new
    builder.instance_eval(&block) if block
    builder
  end
end

table_b = TableBuilderEval.build do
  column :uuid, :string
  column :created_at, :datetime
end
puts "Clean instance_eval DSL: #{table_b.render}"


puts "\n=== 2. Fluent Chaining / Query Builder DSL ==="

class QueryBuilder
  def initialize(table)
    @table = table
    @conditions = []
    @selected_fields = ["*"]
    @limit_val = nil
  end

  def select(*fields)
    @selected_fields = fields.map(&:to_s)
    self # Return self to allow method chaining
  end

  def where(condition)
    @conditions << condition
    self
  end

  def limit(n)
    @limit_val = n
    self
  end

  def to_sql
    sql = "SELECT #{@selected_fields.join(', ')} FROM #{@table}"
    sql << " WHERE #{@conditions.join(' AND ')}" unless @conditions.empty?
    sql << " LIMIT #{@limit_val}" if @limit_val
    sql
  end
end

query = QueryBuilder.new(:users)
                    .select(:id, :name, :email)
                    .where("active = true")
                    .where("age >= 18")
                    .limit(10)

puts "Generated SQL: #{query.to_sql}"


puts "\n=== 3. Micro Web Framework Route DSL (Sinatra-style) ==="

class SimpleRouter
  Route = Struct.new(:method, :path, :handler)

  def initialize
    @routes = []
  end

  %w[get post put delete].each do |http_verb|
    define_method(http_verb) do |path, &block|
      @routes << Route.new(http_verb.upcase, path, block)
    end
  end

  def dispatch(method, path)
    route = @routes.find { |r| r.method == method.upcase && r.path == path }
    if route
      route.handler.call
    else
      "404 Not Found: #{method} #{path}"
    end
  end

  def self.draw(&block)
    router = new
    router.instance_eval(&block)
    router
  end
end

api = SimpleRouter.draw do
  get "/" do
    "Welcome to the Root API"
  end

  get "/health" do
    '{"status": "ok", "uptime": 3600}'
  end

  post "/items" do
    "Created 1 item"
  end
end

puts api.dispatch("GET", "/")
puts api.dispatch("GET", "/health")
puts api.dispatch("POST", "/items")
puts api.dispatch("DELETE", "/secret")


puts "\n=== 4. Nested Tag / Markup Builder DSL ==="

# Tip: Real-world DSL builders (like Builder::XmlMarkup) often inherit from
# BasicObject to avoid method collision with Kernel methods (such as `test`, `gem`, `select`).
class XMLNode
  def initialize(name, attrs = {}, &block)
    @name = name
    @attrs = attrs
    @children = []
    @text = nil

    if block
      if block.arity.zero?
        instance_eval(&block)
      else
        block.call(self)
      end
    end
  end

  def text(val)
    @text = val
  end

  def method_missing(name, *args, &block)
    attrs = args.find { |a| a.is_a?(Hash) } || {}
    node = XMLNode.new(name, attrs, &block)
    str_arg = args.find { |a| a.is_a?(String) }
    node.text(str_arg) if str_arg
    @children << node
    node
  end

  def respond_to_missing?(name, include_private = false)
    true
  end

  def render(indent = 0)
    spaces = "  " * indent
    attr_str = @attrs.empty? ? "" : " " + @attrs.map { |k, v| %(#{k}="#{v}") }.join(" ")

    if @children.empty?
      "#{spaces}<#{@name}#{attr_str}>#{@text}</#{@name}>"
    else
      child_xml = @children.map { |c| c.render(indent + 1) }.join("\n")
      "#{spaces}<#{@name}#{attr_str}>\n#{child_xml}\n#{spaces}</#{@name}>"
    end
  end
end

def document(root_name, &block)
  XMLNode.new(root_name, &block).render
end

xml_output = document(:project) do
  name "Ruby Homework"
  version "3.2.0"
  dependencies do
    pkg "rack", version: "~> 3.0"
    pkg "puma", version: "~> 6.0"
  end
end

puts xml_output
