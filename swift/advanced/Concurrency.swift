import Foundation

func fetchData() async throws -> String {
    // Simulate network delay
    try await Task.sleep(nanoseconds: 1 * 1000_000_000)
    return "Data from server"
}

func runConcurrencyDemo() async {
    do {
        let result = try await fetchData()
        print("Received: \(result)")
    } catch {
        print("Error: \(error)")
    }
}

await runConcurrencyDemo()