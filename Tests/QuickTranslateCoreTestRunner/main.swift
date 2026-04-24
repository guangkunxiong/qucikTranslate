import Foundation
import QuickTranslateCore

struct TestFailure: Error, CustomStringConvertible {
  let message: String

  var description: String {
    message
  }
}

struct TestCase {
  let name: String
  let run: () throws -> Void
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
  if !condition() {
    throw TestFailure(message: message)
  }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) throws {
  if actual != expected {
    throw TestFailure(message: "\(message). Expected \(expected), got \(actual)")
  }
}

let tests: [TestCase] = [
  TestCase(name: "AppSettingsTests/testDefaultSettingsUseOpenAICompatibleDefaultsAndOptionD") {
    let settings = AppSettings.defaults

    try expectEqual(settings.baseURL.absoluteString, "https://api.openai.com/v1", "default base URL")
    try expectEqual(settings.model, "gpt-4o-mini", "default model")
    try expectEqual(settings.hotKey.displayString, "Option+D", "default hotkey")
    try expect(settings.automaticallyBidirectional, "automatic bidirectional translation should be enabled")
    try expect(settings.systemPrompt.contains("中文原文翻译成英文"), "default prompt should describe Chinese source behavior in Simplified Chinese")
  },
  TestCase(name: "AppErrorTests/testUserFacingErrorsAreSimplifiedChinese") {
    try expectEqual(AppError.noSelectedText.errorDescription, "未检测到选中文本。", "no selected text error")
    try expectEqual(AppError.missingAPIKey.errorDescription, "请先在设置中配置 API Key。", "missing API key error")
    try expectEqual(AppError.missingModel.errorDescription, "请先在设置中配置模型。", "missing model error")
    try expectEqual(AppError.missingAccessibilityPermission.errorDescription, "请在系统设置中为快捷翻译开启辅助功能权限。", "missing permission error")
  },
  TestCase(name: "PermissionServiceTests/testAccessibilityPermissionExplanationIsSpecific") {
    let explanation = PermissionService.accessibilityPermissionExplanation

    try expectEqual(explanation.title, "为什么需要辅助功能权限？", "permission explanation title")
    try expect(explanation.message.contains("Option+D"), "permission explanation should mention shortcut")
    try expect(explanation.message.contains("选中文本"), "permission explanation should mention selected text")
    try expect(explanation.message.contains("Command+C"), "permission explanation should mention copy fallback")
    try expect(explanation.message.contains("不会记录键盘输入"), "permission explanation should state it does not log keystrokes")
    try expect(explanation.message.contains("不会读取屏幕内容"), "permission explanation should state it does not read screen content")
  },
  TestCase(name: "CachedSecretValueTests/testUnchangedLoadedValueDoesNotNeedPersisting") {
    var cache = CachedSecretValue()

    try expect(!cache.isLoaded, "cache should start unloaded")
    try expect(cache.shouldPersist("secret"), "unloaded cache should persist a provided value")

    cache.markLoaded("secret")
    try expect(cache.isLoaded, "cache should be loaded")
    try expectEqual(cache.value, "secret", "loaded value")
    try expect(!cache.shouldPersist("secret"), "unchanged loaded value should not persist again")
    try expect(cache.shouldPersist("new-secret"), "changed loaded value should persist")

    cache.markSaved("new-secret")
    try expectEqual(cache.value, "new-secret", "saved value")
    try expect(!cache.shouldPersist("new-secret"), "unchanged saved value should not persist again")
  },
  TestCase(name: "APIKeyStoreTests/testPersistsAndClearsAPIKeyInUserDefaultsSuite") {
    let suiteName = "APIKeyStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer {
      defaults.removePersistentDomain(forName: suiteName)
    }
    let store = APIKeyStore(userDefaults: defaults)

    try expectEqual(store.loadAPIKey(), "", "missing API key should load as empty")
    store.saveAPIKey("sk-test")
    try expectEqual(store.loadAPIKey(), "sk-test", "saved API key")

    let reloaded = APIKeyStore(userDefaults: defaults)
    try expectEqual(reloaded.loadAPIKey(), "sk-test", "reloaded API key")

    store.deleteAPIKey()
    try expectEqual(store.loadAPIKey(), "", "deleted API key")
  },
  TestCase(name: "FloatingPanelPinStateTests/testDefaultsUnpinnedAndCanToggle") {
    var state = FloatingPanelPinState()

    try expect(!state.isPinned, "panel should default to unpinned")
    state.toggle()
    try expect(state.isPinned, "panel should be pinned after first toggle")
    state.toggle()
    try expect(!state.isPinned, "panel should be unpinned after second toggle")
  },
  TestCase(name: "TranslationResponseParserTests/testParsesStructuredJSONTranslation") {
    let content = """
    {"detected_language":"English","target_language":"Simplified Chinese","translation":"你好"}
    """

    let result = TranslationResponseParser.parseAssistantContent(content, sourceText: "hello", model: "gpt-test")

    try expectEqual(result.originalText, "hello", "original text")
    try expectEqual(result.translatedText, "你好", "translated text")
    try expectEqual(result.detectedLanguage, "English", "detected language")
    try expectEqual(result.targetLanguage, "Simplified Chinese", "target language")
    try expectEqual(result.model, "gpt-test", "model")
  },
  TestCase(name: "TranslationResponseParserTests/testFallsBackToPlainTextWhenJSONCannotBeParsed") {
    let result = TranslationResponseParser.parseAssistantContent("你好", sourceText: "hello", model: "gpt-test")

    try expectEqual(result.translatedText, "你好", "fallback translated text")
    try expectEqual(result.detectedLanguage, "未知", "fallback detected language")
    try expectEqual(result.targetLanguage, "自动", "fallback target language")
  },
  TestCase(name: "OpenAICompatibleClientTests/testBuildsChatCompletionsRequest") {
    let settings = AppSettings.defaults
    let request = try OpenAICompatibleClient.makeRequest(
      baseURL: settings.baseURL,
      apiKey: "test-key",
      model: "gpt-test",
      systemPrompt: "Translate as JSON",
      sourceText: "hello"
    )

    try expectEqual(request.url?.absoluteString, "https://api.openai.com/v1/chat/completions", "request URL")
    try expectEqual(request.httpMethod, "POST", "HTTP method")
    try expectEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key", "authorization header")
    try expectEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json", "content type")

    guard let body = request.httpBody else {
      throw TestFailure(message: "request body should exist")
    }
    let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
    try expectEqual(json?["model"] as? String, "gpt-test", "request model")
    try expect(json?["messages"] != nil, "request messages should exist")
  },
  TestCase(name: "OpenAICompatibleClientTests/testBuildsStreamingRequest") {
    let settings = AppSettings.defaults
    let request = try OpenAICompatibleClient.makeRequest(
      baseURL: settings.baseURL,
      apiKey: "test-key",
      model: "gpt-test",
      systemPrompt: "只输出译文",
      sourceText: "hello",
      stream: true
    )

    guard let body = request.httpBody else {
      throw TestFailure(message: "streaming request body should exist")
    }
    let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
    try expectEqual(json?["stream"] as? Bool, true, "stream flag")
  },
  TestCase(name: "TranslationDraftTests/testInfersChineseToEnglishDirection") {
    let draft = TranslationDraft(sourceText: "你好，世界")

    try expectEqual(draft.detectedLanguage, "中文", "detected language")
    try expectEqual(draft.targetLanguage, "英文", "target language")
  },
  TestCase(name: "TranslationDraftTests/testInfersNonChineseToSimplifiedChineseDirection") {
    let draft = TranslationDraft(sourceText: "hello world")

    try expectEqual(draft.detectedLanguage, "非中文", "detected language")
    try expectEqual(draft.targetLanguage, "简体中文", "target language")
  },
  TestCase(name: "TranslationDraftTests/testReplacingSourceTextKeepsIdentityAndReinfersDirection") {
    let draft = TranslationDraft(sourceText: "hello world")
    let edited = draft.replacingSourceText("你好")

    try expectEqual(edited.id, draft.id, "draft id")
    try expectEqual(edited.sourceText, "你好", "edited source text")
    try expectEqual(edited.detectedLanguage, "中文", "detected language")
    try expectEqual(edited.targetLanguage, "英文", "target language")
  },
  TestCase(name: "StreamingChatCompletionParserTests/testParsesContentDelta") {
    let line = #"data: {"choices":[{"delta":{"content":"你"}}]}"#

    try expectEqual(StreamingChatCompletionParser.delta(fromSSELine: line), "你", "streaming delta")
  },
  TestCase(name: "StreamingChatCompletionParserTests/testIgnoresDoneAndNonDataLines") {
    try expectEqual(StreamingChatCompletionParser.delta(fromSSELine: "data: [DONE]"), nil, "done line")
    try expectEqual(StreamingChatCompletionParser.delta(fromSSELine: ": keep-alive"), nil, "comment line")
  },
  TestCase(name: "SettingsStoreTests/testPersistsSettingsInUserDefaultsSuite") {
    let defaults = UserDefaults(suiteName: "SettingsStoreTests-\(UUID().uuidString)")!
    let store = SettingsStore(userDefaults: defaults)

    var settings = AppSettings.defaults
    settings.model = "deepseek-chat"
    settings.systemPrompt = "Custom prompt"
    store.save(settings)

    let reloaded = SettingsStore(userDefaults: defaults)
    try expectEqual(reloaded.settings.model, "deepseek-chat", "persisted model")
    try expectEqual(reloaded.settings.systemPrompt, "Custom prompt", "persisted prompt")
  },
  TestCase(name: "HistoryStoreTests/testAddsSearchesAndDeletesHistoryRecords") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = HistoryStore(directoryURL: directory)

    let result = TranslationResult(
      originalText: "hello",
      translatedText: "你好",
      detectedLanguage: "English",
      targetLanguage: "Simplified Chinese",
      model: "gpt-test",
      timestamp: Date(timeIntervalSince1970: 1)
    )

    let record = try store.add(result)
    try expectEqual(store.records.count, 1, "history count after add")
    try expectEqual(store.search("hello").map(\.id), [record.id], "search original text")
    try expectEqual(store.search("你好").map(\.id), [record.id], "search translated text")

    try store.delete(record.id)
    try expect(store.records.isEmpty, "history should be empty after delete")
  },
  TestCase(name: "HistoryStoreTests/testSearchCanHideSystemPromptRecords") {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = HistoryStore(directoryURL: directory)

    _ = try store.add(
      TranslationResult(
        originalText: AppSettings.defaultSystemPrompt,
        translatedText: "Hidden prompt translation",
        detectedLanguage: "中文",
        targetLanguage: "英文",
        model: "gpt-test",
        timestamp: Date(timeIntervalSince1970: 1)
      )
    )
    let visible = try store.add(
      TranslationResult(
        originalText: "hello",
        translatedText: "你好",
        detectedLanguage: "非中文",
        targetLanguage: "简体中文",
        model: "gpt-test",
        timestamp: Date(timeIntervalSince1970: 2)
      )
    )

    let allVisible = store.search("", hidingSystemPrompts: [AppSettings.defaultSystemPrompt])
    try expectEqual(allVisible.map(\.id), [visible.id], "empty search should hide system prompt records")

    let promptSearch = store.search("detected_language", hidingSystemPrompts: [AppSettings.defaultSystemPrompt])
    try expect(promptSearch.isEmpty, "prompt search should still hide system prompt records")
  },
  TestCase(name: "HotKeyTests/testOptionDHasDisplayAndCarbonMetadata") {
    let hotKey = HotKey.optionD

    try expectEqual(hotKey.displayString, "Option+D", "hotkey display")
    try expectEqual(hotKey.keyCode, 2, "D key code")
    try expect(hotKey.modifiers.contains(.option), "hotkey should contain option")
    try expectEqual(hotKey.carbonModifiers, 2048, "Carbon option modifier")
    try expectEqual(try HotKey.parse("Option+D"), .optionD, "parse Option+D")
  }
]

let filter = CommandLine.arguments.dropFirst().first
let selectedTests = tests.filter { test in
  guard let filter else {
    return true
  }
  return test.name.contains(filter)
}

if selectedTests.isEmpty {
  FileHandle.standardError.write(Data("No tests matched filter.\n".utf8))
  Foundation.exit(2)
}

var failures: [String] = []
for test in selectedTests {
  do {
    try test.run()
    print("PASS \(test.name)")
  } catch {
    failures.append("FAIL \(test.name): \(error)")
  }
}

if failures.isEmpty {
  print("\(selectedTests.count) test(s), 0 failure(s)")
} else {
  failures.forEach { FileHandle.standardError.write(Data("\($0)\n".utf8)) }
  Foundation.exit(1)
}
