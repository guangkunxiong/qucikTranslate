import AppKit
import SwiftUI

@main
struct QuickTranslateApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @Environment(\.openWindow) private var openWindow
  @StateObject private var appModel = AppModel()

  var body: some Scene {
    WindowGroup("快捷翻译", id: "main") {
      ContentView()
        .environmentObject(appModel)
        .onAppear {
          appModel.start()
        }
    }

    Settings {
      SettingsView()
        .environmentObject(appModel)
    }

    MenuBarExtra("快捷翻译", systemImage: "character.book.closed") {
      Button("翻译选中文本") {
        appModel.translateSelection()
      }
      Button("打开主窗口") {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
      }
      Divider()
      Button("退出") {
        NSApplication.shared.terminate(nil)
      }
    }
  }
}
