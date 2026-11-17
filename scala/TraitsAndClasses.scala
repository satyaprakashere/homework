package examples

/**
 * Object-Oriented Programming in Scala:
 * - Traits (interfaces with optional default implementations & mixin composition)
 * - Classes and constructors
 * - Companion objects and the factory `apply` pattern
 * - Trait linearisation and method overriding
 */

// 1. Defining a Trait
trait Printable:
  def format: String
  // Default implementation
  def printOut(): Unit = println(format)

trait Auditable:
  def auditId: String
  def logAction(action: String): Unit =
    println(s"[AUDIT $auditId] $action")

// 2. Class with primary constructor and mixing in multiple traits
class BankCustomer(val id: String, val name: String, private var balance: Double)
    extends Printable
    with Auditable:

  override def auditId: String = id

  def deposit(amount: Double): Unit =
    require(amount > 0, "Deposit amount must be positive")
    balance += amount
    logAction(s"Deposited $$$amount (new balance: $$$balance)")

  def withdraw(amount: Double): Boolean =
    if amount <= balance then
      balance -= amount
      logAction(s"Withdrew $$$amount (remaining: $$$balance)")
      true
    else
      logAction(s"FAILED withdrawal of $$$amount (balance: $$$balance)")
      false

  def currentBalance: Double = balance

  override def format: String =
    s"Customer(id=$id, name='$name', balance=$$$balance)"

// 3. Companion Object (provides static-like factory methods)
object BankCustomer:
  // Factory method allowing syntax: BankCustomer("Alice", 100)
  def apply(name: String, initialDeposit: Double): BankCustomer =
    val generatedId = s"CUST-${(Math.random() * 9000 + 1000).toInt}"
    new BankCustomer(generatedId, name, initialDeposit)

@main
def runTraitsAndClasses(): Unit =
  println("=== 1. Companion Object Factory ===")
  val customer = BankCustomer("Grace Hopper", 1000.0)
  customer.printOut()

  println("\n=== 2. Trait Methods & Mutability Encapsulation ===")
  customer.deposit(250.0)
  customer.withdraw(500.0)
  customer.withdraw(2000.0) // Exceeds balance

  println("\n=== 3. Final State via Printable Trait ===")
  println(customer.format)
