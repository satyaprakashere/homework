import SwiftUI

struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var message = "Hello, Swift!"

    var body: some View {
        VStack {
            Text(message)
                .font(.largeTitle)
                .padding()

            Button("Tap me") {
                message = "Button tapped!"
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

MyApp.main()