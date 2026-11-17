package examples

/**
 * Scala Basics:
 * - Immutable (val) vs Mutable (var) variables
 * - Type inference
 * - String interpolation (s, f, raw)
 * - If/else expressions (returns a value)
 * - For comprehensions (yielding new collections)
 * - Tuples and tuple destructuring
 */

@main
def runBasics(): Unit =
  println("=== 1. Variables & Types ===")
  // val is immutable (preferred in Scala / functional programming)
  val language: String = "Scala"
  val version = 3 // Type inference automatically infers Int

  // var is mutable (use sparingly)
  var counter = 0
  counter += 1

  println(s"Language: $language $version (counter: $counter)")

  println("\n=== 2. String Interpolation ===")
  val name = "Ada Lovelace"
  val year = 1815
  val score = 98.4567

  // s-interpolator: evaluate variables and expressions ${...}
  println(s"Pioneer: $name, born in $year (${2026 - year} years ago)")

  // f-interpolator: type-safe printf style formatting
  println(f"Score formatted: $score%.2f")

  // raw-interpolator: ignores escape sequences like \n
  println(raw"Raw path string: C:\new_folder\test")

  println("\n=== 3. If/Else Expressions ===")
  // In Scala, 'if' is an expression that returns a value (like the ternary operator in other languages)
  val userAge = 20
  val accessLevel = if userAge >= 18 then "Adult" else "Minor"
  println(s"Access level for age $userAge: $accessLevel")

  println("\n=== 4. For Loops & For Comprehensions ===")
  // Simple iteration
  print("Count: ")
  for i <- 1 to 5 do
    print(s"$i ")
  println()

  // For-comprehension with 'yield' transforms input into a new sequence
  val squares = for num <- 1 to 5 yield num * num
  println(s"Squares (1 to 5): $squares")

  // For-comprehension with filtering guards
  val evenMultiples = for
    num <- 1 to 10
    if num % 2 == 0
  yield s"[$num x 10 = ${num * 10}]"
  println(s"Even multiples: ${evenMultiples.mkString(", ")}")

  println("\n=== 5. Tuples and Destructuring ===")
  // Tuples group fixed numbers of heterogeneous items
  val coordinates: (Double, Double, String) = (37.7749, -122.4194, "San Francisco")

  // Accessing tuple elements
  println(s"Latitude: ${coordinates(0)}, Longitude: ${coordinates(1)}, City: ${coordinates(2)}")

  // Pattern-matching destructuring
  val (lat, lng, city) = coordinates
  println(s"Destructured -> $city is at ($lat, $lng)")
