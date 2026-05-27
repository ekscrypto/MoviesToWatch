import SwiftUI
import AppKit
import DomainLogic

@main
struct MoviesToWatchApp: App {
    @State private var appState = AppState()

    init() {
        // SwiftPM executables default to .prohibited activation policy, which
        // hides the window and dock icon. Force regular so the demo is
        // visible whether the app is launched from `swift run`, `open`, or
        // double-clicked in Finder.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
