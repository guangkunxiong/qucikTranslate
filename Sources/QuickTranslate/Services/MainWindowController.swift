import AppKit
import SwiftUI

@MainActor
final class MainWindowController {
  private var window: NSWindow?

  func show(appModel: AppModel) {
    let window = window ?? makeWindow(appModel: appModel)
    self.window = window

    if !window.isVisible {
      window.center()
    }

    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  private func makeWindow(appModel: AppModel) -> NSWindow {
    let contentView = ContentView()
      .environmentObject(appModel)
    let hostingController = NSHostingController(rootView: contentView)
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 780, height: 520),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = "快捷翻译"
    window.contentViewController = hostingController
    window.isReleasedWhenClosed = false
    window.minSize = NSSize(width: 780, height: 520)
    return window
  }
}
