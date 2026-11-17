import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

suspend fn fetchUser(id: Int): String {
    delay(1000)
    return "User $id"
}

fun runCoroutinesDemo() = runBlocking {
    println("\n--- 1. Kotlin Coroutines Demo ---")
    val user = async { fetchUser(1) }
    println("Fetched: ${user.await()}")

    println("\n--- 2. Kotlin Flow Demo ---")
    (1..3).asFlow()
        .map { it * it }
        .collect { println("Flow value: $it") }
}
