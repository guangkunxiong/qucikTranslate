import AppKit
import SwiftUI

@main
struct QuickTranslateApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var appModel: AppModel

  init() {
    let appModel = AppModel()
    _appModel = StateObject(wrappedValue: appModel)
    AppDelegate.appModel = appModel
  }

  var body: some Scene {
    MenuBarExtra("快捷翻译", systemImage: "character.book.closed") {
      Button("翻译选中文本") {
        appModel.translateSelection()
      }
      Button("打开主窗口") {
        appModel.showMainWindow()
      }
      Divider()
      Button("退出") {
        NSApplication.shared.terminate(nil)
      }
    }
  }
}
