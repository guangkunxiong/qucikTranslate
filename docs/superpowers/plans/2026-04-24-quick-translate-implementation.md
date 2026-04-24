# Quick Translate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS quick translation app that translates the current selected text with `Option+D`, uses an OpenAI-compatible backend, shows a top-right floating result panel, and saves successful translations to history.

**Architecture:** Use a SwiftPM package with a tested `QuickTranslateCore` library and a `QuickTranslate` SwiftUI/AppKit executable. SwiftUI owns normal UI, settings, and history; narrow AppKit services own global hotkeys, Accessibility text capture, pasteboard fallback, and floating `NSPanel` presentation.

**Tech Stack:** Swift 6.3, SwiftPM, SwiftUI, AppKit, Carbon hotkeys, Accessibility APIs, Security Keychain, project-local Swift test runner, macOS 13+.

---

## File Structure

- Create `Package.swift`: SwiftPM package with `QuickTranslateCore`, `QuickTranslate`, and `QuickTranslateCoreTests`.
- Create `Sources/QuickTranslateCore/Models/AppSettings.swift`: persisted settings model and defaults.
- Create `Sources/QuickTranslateCore/Models/HotKey.swift`: hotkey parsing, display, and Carbon key metadata for `Option+D`.
- Create `Sources/QuickTranslateCore/Models/TranslationModels.swift`: translation request/result and API DTOs.
- Create `Sources/QuickTranslateCore/Models/HistoryRecord.swift`: history record value model.
- Create `Sources/QuickTranslateCore/Stores/SettingsStore.swift`: local settings persistence through `UserDefaults`.
- Create `Sources/QuickTranslateCore/Stores/HistoryStore.swift`: JSON file-backed translation history.
- Create `Sources/QuickTranslateCore/Stores/KeychainStore.swift`: API key storage through macOS Keychain.
- Create `Sources/QuickTranslateCore/Services/TranslationResponseParser.swift`: structured JSON response parsing with plain-text fallback.
- Create `Sources/QuickTranslateCore/Services/OpenAICompatibleClient.swift`: OpenAI-compatible request construction and HTTP call.
- Create `Sources/QuickTranslateCore/Services/ClipboardService.swift`: pasteboard snapshot, read, and restore.
- Create `Sources/QuickTranslateCore/Services/SelectedTextCaptureService.swift`: Accessibility selected-text read with simulated copy fallback.
- Create `Sources/QuickTranslateCore/Services/PermissionService.swift`: Accessibility permission status and prompt.
- Create `Sources/QuickTranslateCore/Services/HotKeyService.swift`: Carbon global hotkey registration.
- Create `Sources/QuickTranslateCore/Support/AppError.swift`: user-facing error types.
- Create `Sources/QuickTranslate/App/QuickTranslateApp.swift`: SwiftUI app scenes and menu bar entry.
- Create `Sources/QuickTranslate/App/AppDelegate.swift`: activation policy and foreground launch behavior.
- Create `Sources/QuickTranslate/App/AppModel.swift`: main coordinator for hotkey, capture, translation, history, and panel presentation.
- Create `Sources/QuickTranslate/Views/ContentView.swift`: main window shell.
- Create `Sources/QuickTranslate/Views/HistoryView.swift`: history search, copy, re-translate, and delete.
- Create `Sources/QuickTranslate/Views/SettingsView.swift`: endpoint/model/API key/system prompt/shortcut/permission settings.
- Create `Sources/QuickTranslate/Views/AboutView.swift`: app and permission summary.
- Create `Sources/QuickTranslate/Views/FloatingPanelView.swift`: result and error panel content.
- Create `Sources/QuickTranslate/Services/FloatingPanelController.swift`: top-right `NSPanel` lifecycle.
- Create `Tests/QuickTranslateCoreTestRunner/main.swift`: project-local unit test runner for models, parser, stores, and request building.
- Create `script/build_and_run.sh`: one build/run/debug/log/telemetry/verify entrypoint.
- Create `.codex/environments/environment.toml`: Codex Run action.
- Create `.gitignore`: ignore `.build/`, `dist/`, `.worktrees/`, and editor noise.

Execution note: this environment has Command Line Tools without `XCTest` or Swift `Testing`, so implementation uses the `QuickTranslateCoreTestRunner` executable instead of `swift test`. Commands that mention `swift test --filter <name>` are executed as `swift run QuickTranslateCoreTestRunner <name>`.

## Task 1: Bootstrap SwiftPM Package And Local Run Loop

**Files:**
- Create: `Package.swift`
- Create: `.gitignore`
- Create: `Sources/QuickTranslateCore/Models/AppSettings.swift`
- Create: `Sources/QuickTranslate/App/QuickTranslateApp.swift`
- Create: `Sources/QuickTranslate/App/AppDelegate.swift`
- Create: `Sources/QuickTranslate/Views/ContentView.swift`
- Create: `Tests/QuickTranslateCoreTests/AppSettingsTests.swift`
- Create: `script/build_and_run.sh`
- Create: `.codex/environments/environment.toml`

- [ ] **Step 1: Write failing settings defaults test**

```swift
import XCTest
@testable import QuickTranslateCore

final class AppSettingsTests: XCTestCase {
  func testDefaultSettingsUseOpenAICompatibleDefaultsAndOptionD() {
    let settings = AppSettings.defaults

    XCTAssertEqual(settings.baseURL.absoluteString, "https://api.openai.com/v1")
    XCTAssertEqual(settings.model, "gpt-4o-mini")
    XCTAssertEqual(settings.hotKey.displayString, "Option+D")
    XCTAssertTrue(settings.automaticallyBidirectional)
    XCTAssertTrue(settings.systemPrompt.contains("Chinese source text"))
  }
}
```

- [ ] **Step 2: Run the test to verify RED**

Run: `swift test --filter AppSettingsTests/testDefaultSettingsUseOpenAICompatibleDefaultsAndOptionD`

Expected: fail because `Package.swift` or `AppSettings` does not exist.

- [ ] **Step 3: Add package, minimal defaults, app shell, run script, and Codex Run action**

Create `Package.swift` with a macOS 13 package, library target `QuickTranslateCore`, executable target `QuickTranslate`, and test target `QuickTranslateCoreTests`.

Create `AppSettings` with defaults: base URL `https://api.openai.com/v1`, model `gpt-4o-mini`, hotkey `Option+D`, automatic bidirectional translation enabled, and a default prompt that requires JSON output with detected language, target language, and translation.

Create a minimal `QuickTranslateApp` with `WindowGroup`, `Settings`, and `MenuBarExtra`, plus `AppDelegate` that calls `NSApp.setActivationPolicy(.regular)` and `NSApp.activate(ignoringOtherApps: true)`.

Create `script/build_and_run.sh` using the Build macOS Apps SwiftPM GUI app pattern. Use:

```bash
APP_NAME="QuickTranslate"
BUNDLE_ID="com.only77.QuickTranslate"
MIN_SYSTEM_VERSION="13.0"
```

Create `.codex/environments/environment.toml`:

```toml
# THIS IS AUTOGENERATED. DO NOT EDIT MANUALLY
version = 1
name = "dict"

[setup]
script = ""

[[actions]]
name = "Run"
icon = "run"
command = "./script/build_and_run.sh"
```

- [ ] **Step 4: Run GREEN verification**

Run: `swift test --filter AppSettingsTests/testDefaultSettingsUseOpenAICompatibleDefaultsAndOptionD`

Expected: pass.

- [ ] **Step 5: Run app build verification**

Run: `./script/build_and_run.sh --verify`

Expected: SwiftPM builds, `dist/QuickTranslate.app` is staged, and `pgrep -x QuickTranslate` succeeds.

- [ ] **Step 6: Commit**

```bash
git add Package.swift .gitignore Sources Tests script .codex
git commit -m "feat: bootstrap quick translate app"
```

## Task 2: Add Translation Models, Response Parser, And Request Builder

**Files:**
- Create: `Sources/QuickTranslateCore/Models/TranslationModels.swift`
- Create: `Sources/QuickTranslateCore/Services/TranslationResponseParser.swift`
- Create: `Sources/QuickTranslateCore/Services/OpenAICompatibleClient.swift`
- Create: `Tests/QuickTranslateCoreTests/TranslationResponseParserTests.swift`
- Create: `Tests/QuickTranslateCoreTests/OpenAICompatibleClientTests.swift`

- [ ] **Step 1: Write parser tests**

```swift
import XCTest
@testable import QuickTranslateCore

final class TranslationResponseParserTests: XCTestCase {
  func testParsesStructuredJSONTranslation() throws {
    let content = """
    {"detected_language":"English","target_language":"Simplified Chinese","translation":"你好"}
    """

    let result = TranslationResponseParser.parseAssistantContent(content, sourceText: "hello", model: "gpt-test")

    XCTAssertEqual(result.originalText, "hello")
    XCTAssertEqual(result.translatedText, "你好")
    XCTAssertEqual(result.detectedLanguage, "English")
    XCTAssertEqual(result.targetLanguage, "Simplified Chinese")
    XCTAssertEqual(result.model, "gpt-test")
  }

  func testFallsBackToPlainTextWhenJSONCannotBeParsed() {
    let result = TranslationResponseParser.parseAssistantContent("你好", sourceText: "hello", model: "gpt-test")

    XCTAssertEqual(result.translatedText, "你好")
    XCTAssertEqual(result.detectedLanguage, "Unknown")
    XCTAssertEqual(result.targetLanguage, "Auto")
  }
}
```

- [ ] **Step 2: Write request builder test**

```swift
import XCTest
@testable import QuickTranslateCore

final class OpenAICompatibleClientTests: XCTestCase {
  func testBuildsChatCompletionsRequest() throws {
    let settings = AppSettings.defaults
    let request = try OpenAICompatibleClient.makeRequest(
      baseURL: settings.baseURL,
      apiKey: "test-key",
      model: "gpt-test",
      systemPrompt: "Translate as JSON",
      sourceText: "hello"
    )

    XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/chat/completions")
    XCTAssertEqual(request.httpMethod, "POST")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

    let body = try XCTUnwrap(request.httpBody)
    let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
    XCTAssertEqual(json?["model"] as? String, "gpt-test")
    XCTAssertNotNil(json?["messages"])
  }
}
```

- [ ] **Step 3: Run parser and client tests to verify RED**

Run: `swift test --filter TranslationResponseParserTests && swift test --filter OpenAICompatibleClientTests`

Expected: fail because parser/client types do not exist.

- [ ] **Step 4: Implement models, parser, request builder, and async send**

Implement:

- `TranslationResult`: original text, translated text, detected language, target language, model, timestamp.
- `TranslationResponseParser.parseAssistantContent(_:sourceText:model:)`.
- `OpenAICompatibleClient.makeRequest(...)`.
- `OpenAICompatibleClient.translate(...) async throws`, decoding `choices[0].message.content`.

The request body must call `/chat/completions`, include system and user messages, and ask for JSON while staying compatible with providers that ignore `response_format`.

- [ ] **Step 5: Run GREEN verification**

Run: `swift test --filter TranslationResponseParserTests && swift test --filter OpenAICompatibleClientTests`

Expected: pass.

- [ ] **Step 6: Commit**

```bash
git add Sources/QuickTranslateCore Tests/QuickTranslateCoreTests
git commit -m "feat: add OpenAI compatible translation core"
```

## Task 3: Add Settings, Keychain, And History Stores

**Files:**
- Create: `Sources/QuickTranslateCore/Models/HistoryRecord.swift`
- Create: `Sources/QuickTranslateCore/Stores/SettingsStore.swift`
- Create: `Sources/QuickTranslateCore/Stores/HistoryStore.swift`
- Create: `Sources/QuickTranslateCore/Stores/KeychainStore.swift`
- Create: `Tests/QuickTranslateCoreTests/SettingsStoreTests.swift`
- Create: `Tests/QuickTranslateCoreTests/HistoryStoreTests.swift`

- [ ] **Step 1: Write settings store tests**

```swift
import XCTest
@testable import QuickTranslateCore

final class SettingsStoreTests: XCTestCase {
  func testPersistsSettingsInUserDefaultsSuite() throws {
    let defaults = UserDefaults(suiteName: "SettingsStoreTests-\(UUID().uuidString)")!
    let store = SettingsStore(userDefaults: defaults)

    var settings = AppSettings.defaults
    settings.model = "deepseek-chat"
    settings.systemPrompt = "Custom prompt"
    store.save(settings)

    let reloaded = SettingsStore(userDefaults: defaults)
    XCTAssertEqual(reloaded.settings.model, "deepseek-chat")
    XCTAssertEqual(reloaded.settings.systemPrompt, "Custom prompt")
  }
}
```

- [ ] **Step 2: Write history store tests**

```swift
import XCTest
@testable import QuickTranslateCore

final class HistoryStoreTests: XCTestCase {
  func testAddsSearchesAndDeletesHistoryRecords() throws {
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
    XCTAssertEqual(store.records.count, 1)
    XCTAssertEqual(store.search("hello").map(\.id), [record.id])
    XCTAssertEqual(store.search("你好").map(\.id), [record.id])

    try store.delete(record.id)
    XCTAssertTrue(store.records.isEmpty)
  }
}
```

- [ ] **Step 3: Run store tests to verify RED**

Run: `swift test --filter SettingsStoreTests && swift test --filter HistoryStoreTests`

Expected: fail because store types do not exist.

- [ ] **Step 4: Implement stores**

Implement `SettingsStore` as an `ObservableObject` wrapping Codable settings in `UserDefaults`.

Implement `HistoryStore` as an `ObservableObject` that persists `[HistoryRecord]` to `history.json` under an injected directory. Default directory should be Application Support `QuickTranslate`.

Implement `KeychainStore` with `saveAPIKey(_:)`, `loadAPIKey()`, and `deleteAPIKey()` using service `com.only77.QuickTranslate` and account `openai-compatible-api-key`.

- [ ] **Step 5: Run GREEN verification**

Run: `swift test --filter SettingsStoreTests && swift test --filter HistoryStoreTests`

Expected: pass.

- [ ] **Step 6: Commit**

```bash
git add Sources/QuickTranslateCore Tests/QuickTranslateCoreTests
git commit -m "feat: persist settings and translation history"
```

## Task 4: Add macOS Integration Services

**Files:**
- Create: `Sources/QuickTranslateCore/Support/AppError.swift`
- Create: `Sources/QuickTranslateCore/Services/ClipboardService.swift`
- Create: `Sources/QuickTranslateCore/Services/SelectedTextCaptureService.swift`
- Create: `Sources/QuickTranslateCore/Services/PermissionService.swift`
- Create: `Sources/QuickTranslateCore/Services/HotKeyService.swift`
- Create: `Tests/QuickTranslateCoreTests/HotKeyTests.swift`

- [ ] **Step 1: Write hotkey tests**

```swift
import XCTest
@testable import QuickTranslateCore

final class HotKeyTests: XCTestCase {
  func testOptionDHasDisplayAndCarbonMetadata() throws {
    let hotKey = HotKey.optionD

    XCTAssertEqual(hotKey.displayString, "Option+D")
    XCTAssertEqual(hotKey.keyCode, 2)
    XCTAssertTrue(hotKey.modifiers.contains(.option))
    XCTAssertEqual(try HotKey.parse("Option+D"), .optionD)
  }
}
```

- [ ] **Step 2: Run hotkey test to verify RED**

Run: `swift test --filter HotKeyTests/testOptionDHasDisplayAndCarbonMetadata`

Expected: fail because hotkey type or parser metadata is incomplete.

- [ ] **Step 3: Implement system services**

Implement:

- `AppError`: no selected text, missing API key, missing model, missing Accessibility permission, request failure.
- `ClipboardService`: snapshot pasteboard items as type/data pairs, read string, restore snapshot.
- `SelectedTextCaptureService`: read `kAXFocusedUIElementAttribute` then `kAXSelectedTextAttribute`; if empty, simulate `Cmd+C`, read pasteboard string, then restore prior pasteboard.
- `PermissionService`: `AXIsProcessTrusted()` and prompt via `AXIsProcessTrustedWithOptions`.
- `HotKeyService`: Carbon `RegisterEventHotKey` with callback closure, unregister on deinit.

- [ ] **Step 4: Run GREEN and package build verification**

Run: `swift test --filter HotKeyTests && swift build`

Expected: pass and build.

- [ ] **Step 5: Commit**

```bash
git add Sources/QuickTranslateCore Tests/QuickTranslateCoreTests
git commit -m "feat: add macOS shortcut and text capture services"
```

## Task 5: Build Main App Coordinator And Floating Panel

**Files:**
- Create: `Sources/QuickTranslate/App/AppModel.swift`
- Create: `Sources/QuickTranslate/Views/FloatingPanelView.swift`
- Create: `Sources/QuickTranslate/Services/FloatingPanelController.swift`
- Modify: `Sources/QuickTranslate/App/QuickTranslateApp.swift`
- Modify: `Sources/QuickTranslate/Views/ContentView.swift`

- [ ] **Step 1: Add coordinator and panel code**

Implement `AppModel` as `@MainActor final class AppModel: ObservableObject` with:

- `settingsStore`
- `historyStore`
- `keychainStore`
- `openAIClient`
- `selectedTextCaptureService`
- `permissionService`
- `hotKeyService`
- `floatingPanelController`
- `start()`
- `translateSelection()`
- `translate(text:)`
- `copyTranslation(_:)`

Validation order in `translateSelection()`:

1. capture selected text
2. show no-selected-text error if empty
3. load API key
4. validate model
5. call client
6. save history
7. show floating result panel

Implement `FloatingPanelController` with a retained borderless or titled utility `NSPanel`, positioned at top-right of the screen under the menu bar. The content is a SwiftUI `FloatingPanelView`.

- [ ] **Step 2: Wire app scenes to AppModel**

Update `QuickTranslateApp` so the main `WindowGroup`, `Settings`, and `MenuBarExtra` share the same `@StateObject AppModel`.

Call `appModel.start()` from the main content lifecycle and menu-bar entry path. Add menu actions:

- Translate Selection
- Open Main Window
- Open Settings
- Quit

- [ ] **Step 3: Run build verification**

Run: `swift build`

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add Sources/QuickTranslate
git commit -m "feat: coordinate shortcut translation flow"
```

## Task 6: Build History, Settings, And About UI

**Files:**
- Create: `Sources/QuickTranslate/Views/HistoryView.swift`
- Create: `Sources/QuickTranslate/Views/SettingsView.swift`
- Create: `Sources/QuickTranslate/Views/AboutView.swift`
- Modify: `Sources/QuickTranslate/Views/ContentView.swift`

- [ ] **Step 1: Implement main navigation**

Implement `ContentView` with a native `NavigationSplitView` sidebar containing:

- History
- Settings
- About

Keep sidebar rows simple with system icons and one title line.

- [ ] **Step 2: Implement HistoryView**

Include:

- search field
- list of records
- original text preview
- translated text preview
- timestamp/model metadata
- copy translation button
- re-translate button
- delete button

- [ ] **Step 3: Implement SettingsView**

Include fields for:

- Base URL
- API Key
- Model
- System Prompt
- Shortcut display string
- Auto Bidirectional Translation toggle
- Accessibility permission status
- button to request Accessibility permission

Saving API key writes to `KeychainStore`; saving other settings writes through `SettingsStore`.

- [ ] **Step 4: Implement AboutView**

Show app purpose, current shortcut, backend model, and Accessibility permission status.

- [ ] **Step 5: Run build verification**

Run: `swift build`

Expected: build succeeds.

- [ ] **Step 6: Commit**

```bash
git add Sources/QuickTranslate/Views
git commit -m "feat: add history and settings UI"
```

## Task 7: End-To-End Build, Launch, And Verification

**Files:**
- Modify as needed based on compiler/runtime issues.

- [ ] **Step 1: Run all tests**

Run: `swift test`

Expected: all tests pass.

- [ ] **Step 2: Run app verification**

Run: `./script/build_and_run.sh --verify`

Expected: app builds, launches as `dist/QuickTranslate.app`, and `pgrep -x QuickTranslate` succeeds.

- [ ] **Step 3: Run telemetry/log verification path**

Run: `./script/build_and_run.sh --telemetry`

Expected: app launches and `log stream` is available for subsystem `com.only77.QuickTranslate`. Stop the stream after confirming launch logs or after a short timeout.

- [ ] **Step 4: Manual app checks**

Check:

- main window appears
- settings page renders
- history page renders
- about page renders
- missing API key path shows a floating error
- missing selected text path shows a floating error

- [ ] **Step 5: Commit final fixes**

```bash
git add Sources Tests script .codex Package.swift .gitignore
git commit -m "fix: verify quick translate app flow"
```

Only create this commit if there are fixes after Task 6. If there are no changes, skip the commit.

## Self-Review Checklist

- Spec coverage: tasks cover SwiftPM app, OpenAI-compatible backend, `Option+D`, Accessibility-first capture, copy fallback, top-right panel, settings, Keychain API key storage, history, build script, and Codex Run action.
- Placeholder scan: this plan intentionally avoids placeholder markers and unnamed future work.
- Type consistency: `AppSettings`, `HotKey`, `TranslationResult`, `HistoryRecord`, `SettingsStore`, `HistoryStore`, `OpenAICompatibleClient`, `SelectedTextCaptureService`, `HotKeyService`, `AppModel`, and `FloatingPanelController` are consistently named across tasks.
