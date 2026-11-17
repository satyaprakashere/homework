-- ==============================================================================
-- metatables_oop.lua: Metatables, Metamethods, and OOP in Lua
-- Compatible with: LuaJIT
-- Run with: luajit metatables_oop.lua
-- ==============================================================================

print("=== 1. Metatable Fundamentals ===")
-- Metatables allow changing the behavior of tables (operator overloading,
-- method lookups, intercepts on read/write).

local vector_mt = {}

-- Metamethod: __add (overloads the '+' operator)
vector_mt.__add = function(v1, v2)
    return setmetatable({ x = v1.x + v2.x, y = v1.y + v2.y }, vector_mt)
end

-- Metamethod: __tostring (called by tostring() and print())
vector_mt.__tostring = function(v)
    return string.format("Vector2D(%.1f, %.1f)", v.x, v.y)
end

-- Metamethod: __eq (overloads '==')
vector_mt.__eq = function(v1, v2)
    return v1.x == v2.x and v1.y == v2.y
end

local function Vector(x, y)
    return setmetatable({ x = x, y = y }, vector_mt)
end

local v1 = Vector(2.0, 3.5)
local v2 = Vector(1.0, 4.5)
local v3 = v1 + v2

print("v1:", v1)
print("v2:", v2)
print("v1 + v2 =", v3)
print("v3 == Vector(3.0, 8.0):", v3 == Vector(3.0, 8.0))

print("\n=== 2. __index Metamethod: Fallback Lookups ===")
-- When a key does not exist in table 't', Lua consults getmetatable(t).__index.
-- __index can be either another table (prototype lookup) OR a function.

local defaults = { host = "localhost", port = 5432, timeout = 30 }
local config = { port = 8080 } -- override only port

setmetatable(config, { __index = defaults })

print("config.port (own key):", config.port)          -- 8080
print("config.host (from defaults):", config.host)    -- "localhost"
print("config.timeout (from defaults):", config.timeout) -- 30

print("\n=== 3. __call: Callable Tables ===")
-- Tables can behave like functions when __call is defined:
local multiplier = setmetatable({ factor = 10 }, {
    __call = function(self, value)
        return self.factor * value
    end
})

print("multiplier(5):", multiplier(5)) -- 50

print("\n=== 4. Class-Based OOP and Single Inheritance ===")
-- In Lua, classes are constructed using tables and metatables with the colon syntax.
-- 'obj:method(arg)' is syntactic sugar for 'obj.method(obj, arg)'.

-- Base Class: Animal
local Animal = {}
Animal.__index = Animal

function Animal:new(name, sound)
    local instance = setmetatable({}, self)
    instance.name = name or "Unnamed"
    instance.sound = sound or "..."
    return instance
end

function Animal:speak()
    return string.format("%s says: %s", self.name, self.sound)
end

-- Derived Class: Dog inherits from Animal
local Dog = setmetatable({}, { __index = Animal })
Dog.__index = Dog

function Dog:new(name, breed)
    -- Call super constructor
    local instance = Animal.new(self, name, "Woof!")
    instance.breed = breed or "Unknown"
    return instance
end

-- Overriding / extending methods
function Dog:fetch(item)
    return string.format("%s the %s excitedly fetches the %s!", self.name, self.breed, item)
end

-- Derived Class: Cat inherits from Animal
local Cat = setmetatable({}, { __index = Animal })
Cat.__index = Cat

function Cat:new(name)
    return Animal.new(self, name, "Meow~")
end

-- Test Polymorphism
local pet1 = Dog:new("Rex", "Golden Retriever")
local pet2 = Cat:new("Luna")

print(pet1:speak())
print(pet1:fetch("tennis ball"))
print(pet2:speak())

-- Verifying inheritance
print("pet1 is Dog?", getmetatable(pet1) == Dog)
print("pet2 is Cat?", getmetatable(pet2) == Cat)

print("\n[OK] metatables_oop.lua completed successfully.")
