package examples

/**
 * Scala Collections:
 * - List (linked list, fast prepend with ::)
 * - Vector (indexed sequence, fast random access and updates)
 * - Set (unique elements)
 * - Map (key-value associations)
 * - Transformation methods: map, filter, flatMap, foldLeft, groupBy
 */

@main
def runCollections(): Unit =
  println("=== 1. List & Prepending ===")
  // Lists are immutable singly-linked lists
  val numbers = List(1, 2, 3)
  val prepended = 0 :: numbers // Prepending with :: is O(1)
  val concatenated = prepended ::: List(4, 5) // Concatenation with :::
  println(s"Constructed list: $concatenated")
  println(s"Head: ${concatenated.head}, Tail: ${concatenated.tail}")

  println("\n=== 2. Transforming with map, filter, & flatMap ===")
  val scores = List(45, 78, 92, 60, 85, 33)
  val passingScores = scores.filter(_ >= 60)
  val gradeLetters = passingScores.map(s => if s >= 90 then "A" else "B")

  println(s"Passing scores: $passingScores")
  println(s"Letter grades:  $gradeLetters")

  // flatMap: maps each element to a collection and flattens the result
  val words = List("scala", "functional", "programming")
  val characters = words.flatMap(_.toList)
  println(s"Unique characters: ${characters.distinct.sorted.mkString(", ")}")

  println("\n=== 3. Aggregations with foldLeft ===")
  // foldLeft takes an initial accumulator value and a combiner function
  val sum = scores.foldLeft(0)(_ + _)
  val formattedString = words.foldLeft("")((acc, w) => if acc.isEmpty then w else s"$acc -> $w")
  println(s"Sum of scores: $sum")
  println(s"Chain: $formattedString")

  println("\n=== 4. Grouping & Partitioning ===")
  case class Student(name: String, gradeYear: Int, major: String)
  val students = List(
    Student("Alice", 1, "Computer Science"),
    Student("Bob", 2, "Physics"),
    Student("Charlie", 1, "Mathematics"),
    Student("Diana", 2, "Computer Science"),
    Student("Ethan", 1, "Computer Science")
  )

  // groupBy creates a Map[K, List[V]]
  val byMajor = students.groupBy(_.major)
  println("Students grouped by major:")
  byMajor.foreach { (major, roster) =>
    val names = roster.map(_.name).mkString(", ")
    println(s"  $major: $names")
  }

  // partition splits a collection into two lists based on a predicate
  val (firstYears, upperYears) = students.partition(_.gradeYear == 1)
  println(s"First year count: ${firstYears.size}, Upper years count: ${upperYears.size}")

  println("\n=== 5. Maps and Sets ===")
  val countryCodes = Map("US" -> "United States", "DE" -> "Germany", "JP" -> "Japan")
  val updatedCodes = countryCodes + ("FR" -> "France") // Adds entry immutably
  println(s"Lookup DE: ${updatedCodes.getOrElse("DE", "Unknown")}")
  println(s"Lookup BR: ${updatedCodes.getOrElse("BR", "Unknown")}")

  val tags = Set("scala", "jvm", "backend", "scala") // Duplicates eliminated
  println(s"Unique tags: $tags (contains 'jvm'? ${tags.contains("jvm")})")
