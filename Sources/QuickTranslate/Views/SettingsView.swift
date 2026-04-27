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
  @State private var selectedDisplayedLanguages = Set<String>()
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

      Section("语言下拉框") {
        Text("选择浮窗里显示的源语言和目标语言选项。")
          .font(.caption)
          .foregroundStyle(.secondary)

        ForEach(AppSettings.availableLanguages, id: \.self) { language in
          Toggle(language, isOn: displayedLanguageBinding(language))
        }

        Button("恢复默认语言") {
          selectedDisplayedLanguages = Set(AppSettings.defaultDisplayedLanguages)
        }
      }

      Section("快捷键") {
        TextField("快捷键", text: $shortcut)
          .textFieldStyle(.roundedBorder)
        Text("默认且当前支持的格式：Option+D")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Section("权限") {
        VStack(alignment: .leading, spacing: 10) {
          HStack {
            Label(
              PermissionService.isAccessibilityTrusted ? "辅助功能权限已开启" : "辅助功能权限未开启",
              systemImage: PermissionService.isAccessibilityTrusted ? "checkmark.circle" : "exclamationmark.triangle"
            )
            .foregroundStyle(PermissionService.isAccessibilityTrusted ? .green : .yellow)
            Spacer()
            Button("了解并打开系统设置") {
              PermissionRequestPresenter.requestAccessibilityPermission()
            }
          }

          Text(PermissionService.accessibilityPermissionExplanation.message)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
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
    appModel.loadAPIKeyIfNeeded()
    let settings = appModel.settingsStore.settings
    baseURLString = settings.baseURL.absoluteString
    apiKey = appModel.apiKey
    model = settings.model
    systemPrompt = settings.systemPrompt
    shortcut = settings.hotKey.displayString
    automaticallyBidirectional = settings.automaticallyBidirectional
    selectedDisplayedLanguages = Set(settings.displayedLanguages)
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

    let displayedLanguages = AppSettings.availableLanguages.filter {
      selectedDisplayedLanguages.contains($0)
    }
    guard !displayedLanguages.isEmpty else {
      statusMessage = "请至少选择一种语言"
      return
    }

    let settings = AppSettings(
      baseURL: baseURL,
      model: model.trimmingCharacters(in: .whitespacesAndNewlines),
      hotKey: hotKey,
      systemPrompt: systemPrompt,
      automaticallyBidirectional: automaticallyBidirectional,
      displayedLanguages: displayedLanguages
    )

    appModel.saveSettings(settings)
    appModel.saveAPIKey(apiKey)
    statusMessage = "已保存"
  }

  private func displayedLanguageBinding(_ language: String) -> Binding<Bool> {
    Binding {
      selectedDisplayedLanguages.contains(language)
    } set: { isSelected in
      if isSelected {
        selectedDisplayedLanguages.insert(language)
      } else {
        selectedDisplayedLanguages.remove(language)
      }
    }
  }
}
