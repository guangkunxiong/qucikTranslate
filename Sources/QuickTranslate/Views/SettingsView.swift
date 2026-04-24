import QuickTranslateCore
import SwiftUI

struct SettingsView: View {
  @EnvironmentObject private var appModel: AppModel

  @State private var baseURLString = ""
  @State private var apiKey = ""
  @State private var model = ""
  @State private var systemPrompt = ""
  @State private var shortcut = ""
  @State private var automaticallyBidirectional = true
  @State private var statusMessage = ""

  var body: some View {
    Form {
      Section("模型") {
        TextField("接口地址 Base URL", text: $baseURLString)
          .textFieldStyle(.roundedBorder)
        SecureField("API Key", text: $apiKey)
          .textFieldStyle(.roundedBorder)
        TextField("模型", text: $model)
          .textFieldStyle(.roundedBorder)
      }

      Section("翻译") {
        Toggle("自动双向翻译", isOn: $automaticallyBidirectional)
        TextEditor(text: $systemPrompt)
          .font(.body)
          .frame(minHeight: 130)
          .border(.quaternary)
      }

      Section("快捷键") {
        TextField("快捷键", text: $shortcut)
          .textFieldStyle(.roundedBorder)
        Text("默认且当前支持的格式：Option+D")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Section("权限") {
        HStack {
          Label(
            PermissionService.isAccessibilityTrusted ? "辅助功能权限已开启" : "辅助功能权限未开启",
            systemImage: PermissionService.isAccessibilityTrusted ? "checkmark.circle" : "exclamationmark.triangle"
          )
          .foregroundStyle(PermissionService.isAccessibilityTrusted ? .green : .yellow)
          Spacer()
          Button("请求权限") {
            _ = PermissionService.promptForAccessibilityPermission()
          }
        }
      }

      Section {
        HStack {
          Button("保存") {
            save()
          }
          .keyboardShortcut("s", modifiers: [.command])

          if !statusMessage.isEmpty {
            Text(statusMessage)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .formStyle(.grouped)
    .padding()
    .frame(minWidth: 520, minHeight: 520)
    .navigationTitle("设置")
    .onAppear(perform: load)
  }

  private func load() {
    let settings = appModel.settingsStore.settings
    baseURLString = settings.baseURL.absoluteString
    apiKey = appModel.apiKey
    model = settings.model
    systemPrompt = settings.systemPrompt
    shortcut = settings.hotKey.displayString
    automaticallyBidirectional = settings.automaticallyBidirectional
  }

  private func save() {
    guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
      statusMessage = "Base URL 无效"
      return
    }

    guard let hotKey = try? HotKey.parse(shortcut) else {
      statusMessage = "不支持的快捷键"
      return
    }

    let settings = AppSettings(
      baseURL: baseURL,
      model: model.trimmingCharacters(in: .whitespacesAndNewlines),
      hotKey: hotKey,
      systemPrompt: systemPrompt,
      automaticallyBidirectional: automaticallyBidirectional
    )

    appModel.saveSettings(settings)
    appModel.saveAPIKey(apiKey)
    statusMessage = "已保存"
  }
}
