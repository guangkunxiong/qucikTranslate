import QuickTranslateCore
import SwiftUI

struct AboutView: View {
  @EnvironmentObject private var appModel: AppModel

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Label("快捷翻译", systemImage: "character.book.closed")
        .font(.title2)

      Text("在任意 App 中选中文本，按下 \(appModel.settingsStore.settings.hotKey.displayString)，即可通过 OpenAI 兼容模型翻译。")
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
        GridRow {
          Text("模型")
            .foregroundStyle(.secondary)
          Text(appModel.settingsStore.settings.model)
        }
        GridRow {
          Text("后端")
            .foregroundStyle(.secondary)
          Text(appModel.settingsStore.settings.baseURL.absoluteString)
        }
        GridRow {
          Text("辅助功能")
            .foregroundStyle(.secondary)
          Text(PermissionService.isAccessibilityTrusted ? "已开启" : "未开启")
            .foregroundStyle(PermissionService.isAccessibilityTrusted ? .green : .yellow)
        }
      }

      Spacer()
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .navigationTitle("关于")
  }
}
