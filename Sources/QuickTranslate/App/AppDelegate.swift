import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  static weak var appModel: AppModel?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    NSApp.mainMenu?.items.first?.title = "快捷翻译"
    Self.appModel?.start()
  }
}
