package examples

import scala.concurrent.{Future, Await, ExecutionContext}
import scala.concurrent.duration.*
import scala.util.{Success, Failure}

// Global execution context (thread pool)
import scala.concurrent.ExecutionContext.Implicits.global

/**
 * Concurrency in Scala:
 * - Future: asynchronous, non-blocking computations
 * - Composing Futures using map, flatMap, and for-comprehensions
 * - Combining multiple concurrent tasks with Future.sequence
 * - Handling completion callbacks (onComplete)
 */

case class UserProfile(id: Long, name: String)
case class UserPreferences(theme: String, notificationsEnabled: Boolean)

// Simulates an asynchronous database query
def fetchProfile(userId: Long): Future[UserProfile] = Future {
  Thread.sleep(150) // simulate I/O delay
  UserProfile(userId, "Ada Lovelace")
}

// Simulates an asynchronous preferences lookup
def fetchPreferences(userId: Long): Future[UserPreferences] = Future {
  Thread.sleep(100) // simulate network delay
  UserPreferences(theme = "dark", notificationsEnabled = true)
}

// Simulates an asynchronous price calculation
def computePrice(itemId: String): Future[Double] = Future {
  Thread.sleep(80)
  itemId match
    case "item-1" => 29.99
    case "item-2" => 49.99
    case "item-3" => 15.00
    case _        => 0.00
}

@main
def runConcurrency(): Unit =
  println("=== 1. Parallel Execution with For-Comprehensions ===")

  // Start both futures concurrently before the for-comprehension
  val profileFuture = fetchProfile(42L)
  val preferencesFuture = fetchPreferences(42L)

  // Combine results when both complete
  val combinedFuture = for
    profile <- profileFuture
    prefs   <- preferencesFuture
  yield s"Loaded profile '${profile.name}' with ${prefs.theme} theme."

  // Wait for result in this CLI demonstration
  val combinedResult = Await.result(combinedFuture, 2.seconds)
  println(s"Result: $combinedResult")

  println("\n=== 2. Aggregating Multiple Futures (Future.sequence) ===")
  val itemsToQuote = List("item-1", "item-2", "item-3")

  // Kick off concurrent computations for all items
  val futuresList = itemsToQuote.map(computePrice)
  val allPricesFuture: Future[List[Double]] = Future.sequence(futuresList)

  val totalCostFuture = allPricesFuture.map { prices =>
    val sum = prices.sum
    val rounded = BigDecimal(sum).setScale(2, BigDecimal.RoundingMode.HALF_UP).toDouble
    (prices, rounded)
  }

  val (prices, total) = Await.result(totalCostFuture, 2.seconds)
  println(s"Individual prices: $prices")
  println(s"Calculated total: $$$total")
