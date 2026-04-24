import QuickTranslateCore
import SwiftUI

struct ContentView: View {
  @EnvironmentObject private var appModel: AppModel
  private let settings = AppSettings.defaults

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Quick Translate")
        .font(.title2)
      Text("Default shortcut: \(appModel.settingsStore.settings.hotKey.displayString)")
        .foregroundStyle(.secondary)
      if appModel.isTranslating {
        ProgressView()
      }
    }
    .frame(minWidth: 560, minHeight: 360)
    .padding()
  }
}
