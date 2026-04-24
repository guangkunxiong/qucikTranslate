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
  @Published private(set) var historyRevision = 0
  @Published private(set) var settingsRevision = 0
  @Published var apiKey = ""

  private let openAIClient: OpenAICompatibleClient
  private let selectedTextCaptureService: SelectedTextCaptureService
  private let hotKeyService: HotKeyService
  private let floatingPanelController: FloatingPanelController
  private var started = false
  private var pendingDraft: TranslationDraft?

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
    settingsRevision += 1

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
      await streamTranslate(draft: TranslationDraft(sourceText: record.originalText))
    }
  }

  func deleteHistoryRecord(_ id: UUID) {
    do {
      try historyStore.delete(id)
      historyRevision += 1
    } catch {
      showError(AppError.requestFailed(error.localizedDescription))
    }
  }

  func copyTranslation(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
  }

  private func translateCurrentSelection() async {
    let text = await selectedTextCaptureService.captureSelectedText()
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard !text.isEmpty else {
      if !PermissionService.isAccessibilityTrusted {
        PermissionRequestPresenter.requestAccessibilityPermission()
        return
      }

      showError(AppError.noSelectedText)
      return
    }

    showDraft(text)
  }

  private func showDraft(_ text: String) {
    let draft = TranslationDraft(sourceText: text)
    pendingDraft = draft
    floatingPanelController.show(
      state: .draft(draft),
      onStartTranslation: { [weak self] sourceText in
        self?.startPendingTranslation(sourceText: sourceText)
      },
      onCopy: { [weak self] value in
        self?.copyTranslation(value)
      }
    )
  }

  private func startPendingTranslation(sourceText: String? = nil) {
    guard !isTranslating else {
      return
    }

    Task {
      await beginPendingTranslation(sourceText: sourceText)
    }
  }

  private func beginPendingTranslation(sourceText: String?) async {
    guard let draft = pendingDraft else {
      return
    }

    let editedText = sourceText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? draft.sourceText
    guard !editedText.isEmpty else {
      showError(AppError.noSelectedText)
      return
    }

    let editedDraft = draft.replacingSourceText(editedText)
    pendingDraft = nil
    await streamTranslate(draft: editedDraft)
  }

  private func streamTranslate(draft: TranslationDraft) async {
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
      logger.info("Starting streaming translation request")
      var translatedText = ""
      floatingPanelController.show(
        state: .streaming(draft, translatedText: translatedText),
        onCopy: { [weak self] value in
          self?.copyTranslation(value)
        }
      )

      for try await delta in openAIClient.streamTranslationDeltas(
        draft: draft,
        settings: settings,
        apiKey: trimmedAPIKey
      ) {
        translatedText += delta
        floatingPanelController.show(
          state: .streaming(draft, translatedText: translatedText),
          onCopy: { [weak self] value in
            self?.copyTranslation(value)
          }
        )
      }

      let trimmedTranslation = translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmedTranslation.isEmpty else {
        throw OpenAICompatibleClientError.missingAssistantContent
      }

      let result = TranslationResult(
        originalText: draft.sourceText,
        translatedText: trimmedTranslation,
        detectedLanguage: draft.detectedLanguage,
        targetLanguage: draft.targetLanguage,
        model: trimmedModel
      )
      _ = try historyStore.add(result)
      historyRevision += 1
      floatingPanelController.show(
        state: .result(result, saved: true),
        onCopy: { [weak self] value in
          self?.copyTranslation(value)
        }
      )
      logger.info("Streaming translation completed")
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
