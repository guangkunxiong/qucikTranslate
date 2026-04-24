import AppKit
import Foundation
import OSLog
import QuickTranslateCore

@MainActor
final class AppModel: ObservableObject {
  let settingsStore: SettingsStore
  let historyStore: HistoryStore
  let keychainStore: KeychainStore

  @Published private(set) var isTranslating = false
  @Published var apiKey = ""

  private let openAIClient: OpenAICompatibleClient
  private let selectedTextCaptureService: SelectedTextCaptureService
  private let hotKeyService: HotKeyService
  private let floatingPanelController: FloatingPanelController
  private var started = false

  private let logger = Logger(
    subsystem: "com.only77.QuickTranslate",
    category: "Translation"
  )

  init(
    settingsStore: SettingsStore = SettingsStore(),
    historyStore: HistoryStore = HistoryStore(),
    keychainStore: KeychainStore = KeychainStore(),
    openAIClient: OpenAICompatibleClient = OpenAICompatibleClient(),
    selectedTextCaptureService: SelectedTextCaptureService = SelectedTextCaptureService(),
    hotKeyService: HotKeyService = HotKeyService(),
    floatingPanelController: FloatingPanelController = FloatingPanelController()
  ) {
    self.settingsStore = settingsStore
    self.historyStore = historyStore
    self.keychainStore = keychainStore
    self.openAIClient = openAIClient
    self.selectedTextCaptureService = selectedTextCaptureService
    self.hotKeyService = hotKeyService
    self.floatingPanelController = floatingPanelController
    self.apiKey = (try? keychainStore.loadAPIKey()) ?? ""
  }

  func start() {
    guard !started else {
      return
    }
    started = true

    do {
      try hotKeyService.register(settingsStore.settings.hotKey) { [weak self] in
        self?.translateSelection()
      }
      logger.info("Registered global shortcut: \(self.settingsStore.settings.hotKey.displayString, privacy: .public)")
    } catch {
      showError(AppError.hotKeyRegistrationFailed(String(describing: error)))
    }
  }

  func saveSettings(_ settings: AppSettings) {
    settingsStore.save(settings)

    do {
      try hotKeyService.register(settings.hotKey) { [weak self] in
        self?.translateSelection()
      }
    } catch {
      showError(AppError.hotKeyRegistrationFailed(String(describing: error)))
    }
  }

  func saveAPIKey(_ value: String) {
    apiKey = value
    do {
      if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        try keychainStore.deleteAPIKey()
      } else {
        try keychainStore.saveAPIKey(value)
      }
    } catch {
      showError(AppError.requestFailed(error.localizedDescription))
    }
  }

  func translateSelection() {
    Task {
      await translateCurrentSelection()
    }
  }

  func translate(record: HistoryRecord) {
    Task {
      await translate(text: record.originalText)
    }
  }

  func copyTranslation(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
  }

  private func translateCurrentSelection() async {
    guard PermissionService.isAccessibilityTrusted else {
      showError(AppError.missingAccessibilityPermission)
      return
    }

    let text = await selectedTextCaptureService.captureSelectedText()
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard !text.isEmpty else {
      showError(AppError.noSelectedText)
      return
    }

    await translate(text: text)
  }

  private func translate(text: String) async {
    let settings = settingsStore.settings
    let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedModel = settings.model.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedAPIKey.isEmpty else {
      showError(AppError.missingAPIKey)
      return
    }

    guard !trimmedModel.isEmpty else {
      showError(AppError.missingModel)
      return
    }

    isTranslating = true
    defer { isTranslating = false }

    do {
      logger.info("Starting translation request")
      let result = try await openAIClient.translate(
        sourceText: text,
        settings: settings,
        apiKey: trimmedAPIKey
      )
      _ = try historyStore.add(result)
      floatingPanelController.show(
        state: .result(result, saved: true),
        onCopy: { [weak self] value in
          self?.copyTranslation(value)
        }
      )
      logger.info("Translation completed")
    } catch {
      showError(AppError.requestFailed(error.localizedDescription))
    }
  }

  private func showError(_ error: Error) {
    let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    logger.error("Translation error: \(message, privacy: .public)")
    floatingPanelController.show(
      state: .error(message),
      onCopy: { [weak self] value in
        self?.copyTranslation(value)
      }
    )
  }
}
