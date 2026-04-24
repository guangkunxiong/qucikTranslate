import QuickTranslateCore
import SwiftUI

struct AboutView: View {
  @EnvironmentObject private var appModel: AppModel

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Label("Quick Translate", systemImage: "character.book.closed")
        .font(.title2)

      Text("Select text in any app, press \(appModel.settingsStore.settings.hotKey.displayString), and translate it through an OpenAI-compatible model.")
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
        GridRow {
          Text("Model")
            .foregroundStyle(.secondary)
          Text(appModel.settingsStore.settings.model)
        }
        GridRow {
          Text("Backend")
            .foregroundStyle(.secondary)
          Text(appModel.settingsStore.settings.baseURL.absoluteString)
        }
        GridRow {
          Text("Accessibility")
            .foregroundStyle(.secondary)
          Text(PermissionService.isAccessibilityTrusted ? "Enabled" : "Disabled")
            .foregroundStyle(PermissionService.isAccessibilityTrusted ? .green : .yellow)
        }
      }

      Spacer()
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .navigationTitle("About")
  }
}
