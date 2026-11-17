package examples

import scala.util.{Try, Success, Failure}

/**
 * Functional Error Handling in Scala:
 * - Option[A] (Some[A] | None) for nullable / optional values
 * - Either[Error, Value] (Left[Error] | Right[Value]) for explicit error types
 * - Try[A] (Success[A] | Failure[Throwable]) for safely wrapping throwing code
 * - Chaining operations safely using map, flatMap, and for-comprehensions
 */

case class Account(id: String, balance: Double)

// 1. Option: Returns Some(account) or None
def findAccount(id: String): Option[Account] =
  val database = Map(
    "acc-1" -> Account("acc-1", 500.0),
    "acc-2" -> Account("acc-2", 50.0)
  )
  database.get(id)

// 2. Either: Explicitly defines what failed (Left) vs succeeded (Right)
enum TransferError:
  case AccountNotFound(id: String)
  case InsufficientFunds(available: Double, requested: Double)
  case InvalidAmount(amount: Double)

def transfer(fromId: String, toId: String, amount: Double): Either[TransferError, String] =
  if amount <= 0 then
    Left(TransferError.InvalidAmount(amount))
  else
    for
      sender   <- findAccount(fromId).toRight(TransferError.AccountNotFound(fromId))
      receiver <- findAccount(toId).toRight(TransferError.AccountNotFound(toId))
      _        <- if sender.balance >= amount then Right(())
                  else Left(TransferError.InsufficientFunds(sender.balance, amount))
    yield
      s"Successfully transferred $$$amount from $fromId to $toId"

// 3. Try: Safely handles traditional Java/Scala methods that throw exceptions
def safeParseInt(text: String): Try[Int] =
  Try(text.trim.toInt)

@main
def runErrorHandling(): Unit =
  println("=== 1. Option (Handling absence) ===")
  val found = findAccount("acc-1")
  val missing = findAccount("acc-999")

  println(s"Found account: ${found.map(_.balance).getOrElse(0.0)}")
  println(s"Missing account fallback: ${missing.map(_.balance).getOrElse(0.0)}")

  println("\n=== 2. Either & For-Comprehensions (Business Logic Validation) ===")
  val testCases = List(
    ("acc-1", "acc-2", 100.0), // Valid
    ("acc-2", "acc-1", 200.0), // Insufficient funds
    ("acc-1", "acc-999", 50.0), // Account not found
    ("acc-1", "acc-2", -20.0)   // Invalid amount
  )

  testCases.foreach { (from, to, amt) =>
    transfer(from, to, amt) match
      case Right(successMsg) =>
        println(s"[SUCCESS] $successMsg")
      case Left(TransferError.AccountNotFound(id)) =>
        println(s"[FAILED] Account '$id' does not exist.")
      case Left(TransferError.InsufficientFunds(avail, req)) =>
        println(s"[FAILED] Insufficient funds: requested $$$req, only $$$avail available.")
      case Left(TransferError.InvalidAmount(amt)) =>
        println(s"[FAILED] Invalid transfer amount: $$$amt.")
  }

  println("\n=== 3. Try (Wrapping exceptions) ===")
  val validNum = safeParseInt("42")
  val invalidNum = safeParseInt("not-a-number")

  validNum match
    case Success(n) => println(s"Parsed successfully: $n")
    case Failure(e) => println(s"Failed: ${e.getMessage}")

  invalidNum match
    case Success(n) => println(s"Parsed successfully: $n")
    case Failure(e) => println(s"Caught expected failure: ${e.getClass.getSimpleName}")
