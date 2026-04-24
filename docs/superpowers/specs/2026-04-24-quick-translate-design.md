# Quick Translate macOS App Design

## Context

This project starts from an empty directory at `/Users/a77/Code/github/dict`.
The first release is a native macOS quick translation app inspired by Bob, focused on selected-text translation by global shortcut. OCR is explicitly out of scope for this phase.

## Goals

- Let the user select text in any macOS app, press `Option+D`, and translate the selected text.
- Use an OpenAI-compatible chat completions endpoint as the translation backend.
- Show translation results in a lightweight floating panel at the top-right of the screen.
- Save successful translations to local history.
- Provide settings for model endpoint, API key, model name, global shortcut, system prompt, and auto bidirectional translation.

## Non-Goals

- OCR or screenshot translation.
- Always-on selection monitoring.
- Translating stale clipboard content when no current selection exists.
- Multi-provider-specific configuration screens.
- Cloud sync for settings or history.

## Product Behavior

The app runs as a native macOS utility with a main window and menu bar entry. The main user flow is:

1. The user selects text in another app.
2. The user presses `Option+D`.
3. The app captures the current selected text.
4. The app sends the text to the configured OpenAI-compatible API.
5. The app displays the result in a floating panel near the top-right of the active screen.
6. The app saves successful translations into local history.

The app does not translate unless the shortcut is triggered. It does not watch selection changes continuously.

## Translation Strategy

The translation backend uses an OpenAI-compatible `/v1/chat/completions` request with configurable:

- Base URL
- API key
- Model
- System prompt

The default translation strategy is automatic bidirectional translation:

- Chinese source text translates to English.
- Non-Chinese source text translates to Simplified Chinese.

Language detection is performed in the same AI request as translation. The default prompt asks the model to detect the source language and return structured output containing:

- detected language
- target language
- translated text

The first implementation should not depend strictly on OpenAI `response_format`, because some compatible providers do not fully support it. The client should request JSON, attempt to parse it, and fall back to treating the response as plain translated text if parsing fails. In fallback mode the detected language is shown as unknown.

## macOS Interaction Design

### Global Shortcut

The default shortcut is `Option+D`. The shortcut should be user-configurable in settings.

The global shortcut implementation is an AppKit service, because SwiftUI does not directly model global hotkey registration. The service reports shortcut events to the app coordinator.

### Selected Text Capture

Selected text capture uses a two-step strategy:

1. First attempt to read selected text through macOS Accessibility APIs from the focused UI element.
2. If Accessibility selection reading fails, temporarily simulate `Cmd+C`, read the pasteboard, and restore the prior clipboard contents when possible.

Accessibility permission is required for reliable selected-text capture and key event simulation. The app should display permission status in settings and show a clear floating error when permission is missing.

### Floating Result Panel

Translation results appear in a lightweight `NSPanel` managed through a narrow AppKit bridge. SwiftUI owns the panel content view, while AppKit owns panel placement, level, activation behavior, and dismissal.

The panel appears at the top-right of the active screen and contains:

- source text summary
- detected language
- translated text
- copy translation action
- visible status for saved history or error state

The panel should be transient and lightweight, not a replacement for the main window.

## Main Window

The main window uses SwiftUI. It contains:

- History view
- Settings view
- About and permissions status

The app also has a concise menu bar entry with actions to open the main window, open settings, trigger translation, and quit.

## Settings

Settings are split between local preferences and Keychain:

- API key is stored in macOS Keychain.
- Base URL, model, system prompt, auto bidirectional translation flag, and shortcut are stored as local app preferences.

Settings fields:

- Base URL
- API Key
- Model
- System Prompt
- Shortcut
- Auto Bidirectional Translation

The default shortcut is `Option+D`. The default system prompt describes automatic bidirectional translation and asks for JSON-like structured output.

## History

Each successful translation creates one history record with:

- original text
- translated text
- detected source language
- target language
- model
- timestamp

History supports:

- search
- copy translated text
- re-translate
- delete a single record

Failed translations are not saved to history.

## Architecture

The app is implemented as a SwiftPM native macOS app using SwiftUI for normal UI and small AppKit bridges for system integration.

Suggested file boundaries:

- `App/`: app entry point, app delegate, scene wiring, service assembly
- `Views/`: main window, history view, settings view, floating panel content
- `Models/`: translation request, translation result, history record, configuration value types
- `Stores/`: settings store, keychain wrapper, history store
- `Services/`: OpenAI-compatible client, translation coordinator, hotkey service, selected text capture service, clipboard service, floating panel controller, permission service
- `Support/`: formatters, small helpers, user-facing error descriptions

SwiftUI owns app state, main window layout, settings, and history presentation. AppKit owns only capabilities SwiftUI cannot express cleanly:

- global shortcut registration
- Accessibility selected-text access
- simulated copy fallback
- floating panel window management

## Data Flow

1. `HotkeyService` receives `Option+D`.
2. `TranslationCoordinator` asks `SelectedTextCaptureService` for selected text.
3. `SelectedTextCaptureService` tries Accessibility selected text, then simulated copy fallback.
4. `TranslationCoordinator` validates settings.
5. `OpenAICompatibleTranslationClient` sends the request.
6. `TranslationCoordinator` parses structured output or falls back to plain text.
7. `HistoryStore` persists successful results.
8. `FloatingPanelController` presents the SwiftUI result view in the top-right panel.

## Error Handling

- No selected text: show a floating message that no selected text was detected.
- Missing API key or model: show a floating message asking the user to complete settings.
- Missing Accessibility permission: show a floating message and expose permission status in settings.
- API request failure: show an error summary; do not save a history record.
- Unparseable structured response: show the returned text as translation, mark detected language as unknown, and save it as a successful translation.

## Build And Run

The implementation phase should create:

- a SwiftPM package for the macOS app
- `script/build_and_run.sh` as the single local build and launch entry point
- `.codex/environments/environment.toml` pointing the Codex Run action at the script

The app should build and launch as a project-local `.app` bundle rather than running a raw SwiftPM executable directly.

## Verification Plan

The first implementation is considered complete when:

- `./script/build_and_run.sh` builds and launches the app.
- The main window opens.
- Settings can store Base URL, model, system prompt, shortcut, and API key.
- The app registers `Option+D`.
- Triggering the shortcut attempts selected-text capture.
- Missing permission, missing selected text, and missing configuration errors appear in the floating panel.
- A successful mocked or real OpenAI-compatible response appears in the floating panel.
- Successful translations are saved to history and can be searched, copied, re-translated, and deleted.

## Open Decisions Resolved

- Platform: native macOS.
- Project shape: SwiftPM app with SwiftUI and small AppKit bridges.
- Backend: OpenAI-compatible chat completions.
- First shortcut: `Option+D`.
- Capture strategy: Accessibility first, simulated copy fallback.
- Display: top-right lightweight floating panel.
- Translation target: automatic bidirectional translation.
- OCR: out of scope for this phase.
