import AppKit

<<<<<<< HEAD:swift/swiftUI/MyApp.swift
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
=======
final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let screenRect = NSScreen.main?.frame ?? .init(x: 0, y: 0, width: 800, height: 600)
        let size = NSMakeRect(
            screenRect.midX - 200,
            screenRect.midY - 150,
            400,
            300
        )

        window = NSWindow(
            contentRect: size,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Hello AppKit"
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

// “main”
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026):swift/MyApp.swift
