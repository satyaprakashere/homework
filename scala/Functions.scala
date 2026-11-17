package examples

import scala.annotation.tailrec

/**
 * Functions in Scala:
 * - Named arguments and default parameter values
 * - First-class functions and lambdas (anonymous functions)
 * - Higher-Order Functions (functions as parameters and return values)
 * - Currying (multiple parameter lists)
 * - Tail-call optimization with @tailrec
 */

// 1. Basic function with default values
def greet(name: String, greeting: String = "Hello", punctuation: String = "!"): String =
  s"$greeting, $name$punctuation"

// 2. Higher-order function: accepts a transformation function
def transformList(numbers: List[Int], operation: Int => Int): List[Int] =
  numbers.map(operation)

// 3. Higher-order function: returns a new function (Function Factory)
def createMultiplier(factor: Double): Double => Double =
  (amount: Double) => amount * factor

// 4. Curried function with multiple parameter lists
def logMessage(level: String)(message: String): String =
  s"[$level] $message"

// 5. Tail-recursive factorial computation
def factorial(n: BigInt): BigInt =
  @tailrec
  def loop(current: BigInt, accumulator: BigInt): BigInt =
    if current <= 1 then accumulator
    else loop(current - 1, accumulator * current)

  loop(n, 1)

@main
def runFunctions(): Unit =
  println("=== 1. Named & Default Arguments ===")
  println(greet("Alice"))
  println(greet("Bob", greeting = "Good morning"))
  // Using named arguments to skip preceding defaults
  println(greet("Charlie", punctuation = "!!!"))

  println("\n=== 2. First-Class Functions and Lambdas ===")
  val numbers = List(1, 2, 3, 4, 5)

  // Full lambda syntax
  val doubled = transformList(numbers, (x: Int) => x * 2)
  // Short syntax with placeholder wildcard '_'
  val tripled = transformList(numbers, _ * 3)

  println(s"Original: $numbers")
  println(s"Doubled:  $doubled")
  println(s"Tripled:  $tripled")

  println("\n=== 3. Function Factories ===")
  val usdToEur = createMultiplier(0.92)
  val usdToJpy = createMultiplier(155.4)

  val amount = 100.0
  println(f"$$$amount%.0f in EUR: €${usdToEur(amount)}%.2f")
  println(f"$$$amount%.0f in JPY: ¥${usdToJpy(amount)}%.2f")

  println("\n=== 4. Currying and Partial Application ===")
  // Partially applying the first argument
  val infoLog = logMessage("INFO")
  val errorLog = logMessage("ERROR")

  println(infoLog("Application started successfully."))
  println(errorLog("Database connection timed out."))

  println("\n=== 5. Tail-Recursive Factorial ===")
  println(s"Factorial of 5  = ${factorial(5)}")
  println(s"Factorial of 20 = ${factorial(20)}")
