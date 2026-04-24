import AppKit
import SwiftUI

@main
struct QuickTranslateApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    WindowGroup("Quick Translate") {
      ContentView()
    }

    Settings {
      Text("Settings")
        .frame(width: 420, height: 260)
        .padding()
    }

    MenuBarExtra("Quick Translate", systemImage: "character.book.closed") {
      Button("Translate Selection") {}
      Divider()
      Button("Quit") {
        NSApplication.shared.terminate(nil)
      }
    }
  }
}
