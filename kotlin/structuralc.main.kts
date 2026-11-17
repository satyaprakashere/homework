// structuralc.main.kts
@file:DependsOn("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.8.0")

import kotlinx.coroutines.*

data class UserData(val profile: String, val posts: List<String>)

suspend fun fetchProfile(): String {
    delay(500)
    return "Alex"
}

suspend fun fetchPosts(): List<String> {
    delay(1000)
    return listOf("Hello World", "Kotlin Coroutines")
}

suspend fun fetchUserData(): UserData = coroutineScope {
    val profileDeferred = async { fetchProfile() }
    val postsDeferred = async { fetchPosts() }

    UserData(profileDeferred.await(), postsDeferred.await())
}

runBlocking {
    println("Fetching data concurrently...")
    val userData = fetchUserData()
    println("Received: $userData")
}