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
    try expect(settings.systemPrompt.contains("Chinese source text"), "default prompt should describe Chinese source behavior")
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
    try expectEqual(result.detectedLanguage, "Unknown", "fallback detected language")
    try expectEqual(result.targetLanguage, "Auto", "fallback target language")
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
