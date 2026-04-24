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
      Section("Model") {
        TextField("Base URL", text: $baseURLString)
          .textFieldStyle(.roundedBorder)
        SecureField("API Key", text: $apiKey)
          .textFieldStyle(.roundedBorder)
        TextField("Model", text: $model)
          .textFieldStyle(.roundedBorder)
      }

      Section("Translation") {
        Toggle("Automatic bidirectional translation", isOn: $automaticallyBidirectional)
        TextEditor(text: $systemPrompt)
          .font(.body)
          .frame(minHeight: 130)
          .border(.quaternary)
      }

      Section("Shortcut") {
        TextField("Shortcut", text: $shortcut)
          .textFieldStyle(.roundedBorder)
        Text("Default and supported format: Option+D")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Section("Permissions") {
        HStack {
          Label(
            PermissionService.isAccessibilityTrusted ? "Accessibility enabled" : "Accessibility disabled",
            systemImage: PermissionService.isAccessibilityTrusted ? "checkmark.circle" : "exclamationmark.triangle"
          )
          .foregroundStyle(PermissionService.isAccessibilityTrusted ? .green : .yellow)
          Spacer()
          Button("Request Permission") {
            _ = PermissionService.promptForAccessibilityPermission()
          }
        }
      }

      Section {
        HStack {
          Button("Save") {
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
    .navigationTitle("Settings")
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
      statusMessage = "Invalid Base URL"
      return
    }

    guard let hotKey = try? HotKey.parse(shortcut) else {
      statusMessage = "Unsupported shortcut"
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
    statusMessage = "Saved"
  }
}
