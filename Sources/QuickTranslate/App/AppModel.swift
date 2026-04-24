import AppKit
import Foundation
import OSLog
import QuickTranslateCore

@MainActor
final class AppModel: ObservableObject {
  let settingsStore: SettingsStore
  let historyStore: HistoryStore
  let apiKeyStore: APIKeyStore

  @Published private(set) var isTranslating = false
  @Published private(set) var historyRevision = 0
  @Published private(set) var settingsRevision = 0
  @Published var apiKey = ""

  private let openAIClient: OpenAICompatibleClient
  private let selectedTextCaptureService: SelectedTextCaptureService
  private let hotKeyService: HotKeyService
  private let floatingPanelController: FloatingPanelController
  private let mainWindowController: MainWindowController
  private var started = false
  private var pendingDraft: TranslationDraft?
  private var apiKeyCache = CachedSecretValue()

  private let logger = Logger(
    subsystem: "com.only77.QuickTranslate",
    category: "Translation"
  )

  init(
    settingsStore: SettingsStore = SettingsStore(),
    historyStore: HistoryStore = HistoryStore(),
    apiKeyStore: APIKeyStore = APIKeyStore(),
    openAIClient: OpenAICompatibleClient = OpenAICompatibleClient(),
    selectedTextCaptureService: SelectedTextCaptureService = SelectedTextCaptureService(),
    hotKeyService: HotKeyService = HotKeyService(),
    floatingPanelController: FloatingPanelController = FloatingPanelController(),
    mainWindowController: MainWindowController = MainWindowController()
  ) {
    self.settingsStore = settingsStore
    self.historyStore = historyStore
    self.apiKeyStore = apiKeyStore
    self.openAIClient = openAIClient
    self.selectedTextCaptureService = selectedTextCaptureService
    self.hotKeyService = hotKeyService
    self.floatingPanelController = floatingPanelController
    self.mainWindowController = mainWindowController
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
    let normalizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard apiKeyCache.shouldPersist(normalizedValue) else {
      apiKey = normalizedValue
      return
    }

    if normalizedValue.isEmpty {
      apiKeyStore.deleteAPIKey()
    } else {
      apiKeyStore.saveAPIKey(normalizedValue)
    }
    apiKeyCache.markSaved(normalizedValue)
    apiKey = normalizedValue
  }

  func loadAPIKeyIfNeeded() {
    guard !apiKeyCache.isLoaded else {
      apiKey = apiKeyCache.value
      return
    }

    let loadedValue = apiKeyStore.loadAPIKey()
    apiKeyCache.markLoaded(loadedValue)
    apiKey = loadedValue
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

  func showMainWindow() {
    mainWindowController.show(appModel: self)
  }

  func deleteHistoryRecord(_ id: UUID) {
    do {
      try historyStore.delete(id)
      historyRevision += 1
    } catch {
      showError(AppError.requestFailed(error.localizedDescription))
    }
  }

  func clearHistoryRecords() {
    do {
      try historyStore.clear()
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
    showDraft(text)
  }

  private func showDraft(_ text: String) {
    let draft = TranslationDraft.fromCapturedSelection(text)
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
    loadAPIKeyIfNeeded()

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
