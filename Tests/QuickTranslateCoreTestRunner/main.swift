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
