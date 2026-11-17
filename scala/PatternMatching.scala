package examples

/**
 * Pattern Matching in Scala:
 * - Constant & wildcard patterns
 * - Matching on Types
 * - Pattern Guards ('if' inside case)
 * - Case class decomposition
 * - Variable binding (@ syntax)
 * - Sequence and list matching (head :: tail)
 */

case class Device(name: String, modelYear: Int, isOnline: Boolean)

// 1. Matching on arbitrary types
def describeAny(value: Any): String = value match
  case 0                   => "Zero"
  case true                => "Boolean True"
  case s: String           => s"A string of length ${s.length}: '$s'"
  case (x, y)              => s"Tuple of two elements: ($x, $y)"
  case List(a, b, c)       => s"A 3-element list: $a, $b, $c"
  case d: Device           => s"Device object: ${d.name}"
  case _                   => "Something else entirely"

// 2. Matching with pattern guards and case class extraction
def assessDevice(device: Device): String = device match
  case Device(name, year, true) if year >= 2024 =>
    s"$name is a brand-new active device."
  case Device(name, _, false) =>
    s"$name is currently OFFLINE."
  case Device(name, year, true) =>
    s"$name is online but from $year."

// 3. Recursive list pattern matching
def sumList(numbers: List[Int]): Int = numbers match
  case Nil          => 0
  case head :: tail => head + sumList(tail)

@main
def runPatternMatching(): Unit =
  println("=== 1. Matching on Types & Constants ===")
  val samples = List(0, "Scala 3", true, (10, "apples"), List(1, 2, 3), 3.14159)
  samples.foreach { item =>
    println(s"$item -> ${describeAny(item)}")
  }

  println("\n=== 2. Case Class Matching with Guards ===")
  val devices = List(
    Device("MacBook Pro", 2025, isOnline = true),
    Device("Old iPad", 2018, isOnline = false),
    Device("Work Desktop", 2021, isOnline = true)
  )

  devices.foreach { dev =>
    println(assessDevice(dev))
  }

  println("\n=== 3. List Deconstruction (head :: tail) ===")
  val nums = List(10, 20, 30, 40)
  println(s"Sum of $nums: ${sumList(nums)}")

  println("\n=== 4. Variable Binding Pattern (@) ===")
  def processDevice(device: Device): String = device match
    case d @ Device("MacBook Pro", _, _) =>
      s"Special handling for Apple flagship: $d"
    case other =>
      s"Standard handling: ${other.name}"

  println(processDevice(devices.head))
