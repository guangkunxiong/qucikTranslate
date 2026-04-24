import QuickTranslateCore
import SwiftUI

struct ContentView: View {
  private let settings = AppSettings.defaults

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Quick Translate")
        .font(.title2)
      Text("Default shortcut: \(settings.hotKey.displayString)")
        .foregroundStyle(.secondary)
    }
    .frame(minWidth: 560, minHeight: 360)
    .padding()
  }
}
