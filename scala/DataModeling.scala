package examples

/**
 * Domain Modeling in Scala 3:
 * - Case Classes: lightweight immutable records with copy, equality, and destructuring
 * - Scala 3 Enums: replacing old sealed trait hierarchies
 * - Algebraic Data Types (ADTs): Sum types (choice) and Product types (combination)
 */

// 1. Simple Enum (Sum Type)
enum Priority:
  case Low, Medium, High, Critical

// 2. Case Class (Product Type)
case class User(
  id: Long,
  username: String,
  email: String,
  isActive: Boolean = true
)

// 3. ADT using Scala 3 Enum with parameters & methods
enum PaymentMethod:
  case CreditCard(cardNumber: String, expiryMonth: Int, expiryYear: Int)
  case PayPal(email: String)
  case Crypto(walletAddress: String, network: String)

  def maskedSummary: String = this match
    case CreditCard(num, _, _) => s"Card ending in ${num.takeRight(4)}"
    case PayPal(em)            => s"PayPal ($em)"
    case Crypto(addr, net)     => s"$net wallet ${addr.take(6)}...${addr.takeRight(4)}"

// 4. Expression ADT (classic compiler / calculator example)
enum Expr:
  case Number(value: Double)
  case Add(left: Expr, right: Expr)
  case Multiply(left: Expr, right: Expr)

def evaluate(expr: Expr): Double = expr match
  case Expr.Number(v)        => v
  case Expr.Add(lhs, rhs)    => evaluate(lhs) + evaluate(rhs)
  case Expr.Multiply(lhs, rhs) => evaluate(lhs) * evaluate(rhs)

@main
def runDataModeling(): Unit =
  println("=== 1. Enums ===")
  val priority = Priority.High
  println(s"Current priority: $priority (ordinal: ${priority.ordinal})")
  println(s"All priority levels: ${Priority.values.mkString(", ")}")

  println("\n=== 2. Case Classes & Immutable Copies ===")
  val user1 = User(101L, "prakash", "prakash@example.com")
  println(s"User 1: $user1")

  // The .copy method creates a new instance with selected fields modified
  val updatedUser = user1.copy(email = "new_email@example.com")
  println(s"Updated User: $updatedUser")
  println(s"Original untouched: $user1")
  println(s"Are user1 and updatedUser equal? ${user1 == updatedUser}")

  println("\n=== 3. Parameterized Enums (Payment Methods) ===")
  val payment1: PaymentMethod = PaymentMethod.CreditCard("4111222233334567", 12, 2028)
  val payment2: PaymentMethod = PaymentMethod.PayPal("developer@scala.org")
  val payment3: PaymentMethod = PaymentMethod.Crypto("0x71C...8976", "Ethereum")

  val payments = List(payment1, payment2, payment3)
  payments.foreach(p => println(s"  - ${p.maskedSummary}"))

  println("\n=== 4. Expression Tree Evaluation ===")
  // Represents: (3 + 5) * 2
  val expression = Expr.Multiply(
    Expr.Add(Expr.Number(3), Expr.Number(5)),
    Expr.Number(2)
  )
  println(s"Evaluated (3 + 5) * 2 = ${evaluate(expression)}")
