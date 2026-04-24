import AppKit
import SwiftUI

@main
struct QuickTranslateApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @Environment(\.openWindow) private var openWindow
  @StateObject private var appModel = AppModel()

  var body: some Scene {
    WindowGroup("Quick Translate", id: "main") {
      ContentView()
        .environmentObject(appModel)
        .onAppear {
          appModel.start()
        }
    }

    Settings {
      Text("Settings")
        .frame(width: 420, height: 260)
        .padding()
        .environmentObject(appModel)
    }

    MenuBarExtra("Quick Translate", systemImage: "character.book.closed") {
      Button("Translate Selection") {
        appModel.translateSelection()
      }
      Button("Open Main Window") {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
      }
      Divider()
      Button("Quit") {
        NSApplication.shared.terminate(nil)
      }
    }
  }
}
