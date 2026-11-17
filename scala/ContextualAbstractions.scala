package examples

/**
 * Modern Contextual Abstractions in Scala 3:
 * - Extension Methods: add methods to existing types without inheritance
 * - Type Classes: defining abstract behavior over types
 * - Given Instances: providing implicit implementations
 * - Using Clauses: accepting contextual parameters
 */

// 1. Extension Methods: Add functionality directly to String and Int
extension (s: String)
  def shout: String = s.toUpperCase + "!!!"
  def isPalindrome: Boolean =
    val clean = s.toLowerCase.replaceAll("[^a-z0-9]", "")
    clean == clean.reverse

extension (n: Int)
  def isEven: Boolean = n % 2 == 0
  def squared: Int = n * n

// 2. Type Class definition: JsonSerializer
trait JsonSerializer[T]:
  def toJson(value: T): String

// Companion / given instances for standard types
given JsonSerializer[String] with
  def toJson(value: String): String = s"\"$value\""

given JsonSerializer[Int] with
  def toJson(value: Int): String = value.toString

given JsonSerializer[Boolean] with
  def toJson(value: Boolean): String = value.toString

// Given instance for custom case class
case class Product(id: Long, name: String, price: Double)

given JsonSerializer[Product] with
  def toJson(p: Product): String =
    s"""{"id": ${p.id}, "name": "${p.name}", "price": ${p.price}}"""

// Extension method taking advantage of the type class with `using`
extension [T](value: T)
  def serializeToJson(using serializer: JsonSerializer[T]): String =
    serializer.toJson(value)

// 3. Using clause for context (e.g. Configuration or Security context)
case class UserSession(username: String, role: String)

def executeAdminTask(taskName: String)(using session: UserSession): String =
  if session.role == "ADMIN" then
    s"Success: Executing '$taskName' for admin user '${session.username}'"
  else
    s"Denied: User '${session.username}' is not authorized to run '$taskName'"

@main
def runContextualAbstractions(): Unit =
  println("=== 1. Extension Methods ===")
  println("scala is awesome".shout)
  println(s"Is 'racecar' a palindrome? ${"racecar".isPalindrome}")
  println(s"Is 'hello' a palindrome?   ${"hello".isPalindrome}")
  println(s"7 squared is ${7.squared}, is 7 even? ${7.isEven}")

  println("\n=== 2. Type Classes with 'given' and 'using' ===")
  val laptop = Product(42L, "MacBook Pro", 2499.0)
  println(s"Serialized String:  ${"hello".serializeToJson}")
  println(s"Serialized Int:     ${1234.serializeToJson}")
  println(s"Serialized Product: ${laptop.serializeToJson}")

  println("\n=== 3. Context Parameters with 'using' ===")
  // Define a given session in scope
  given adminSession: UserSession = UserSession("super_admin", "ADMIN")

  // executeAdminTask automatically picks up adminSession via `using`
  println(executeAdminTask("Database Migration"))

  // Can also pass explicitly if desired
  val guestSession = UserSession("guest_user", "VIEWER")
  println(executeAdminTask("Reset System")(using guestSession))
