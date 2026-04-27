import QuickTranslateCore
import SwiftUI

enum FloatingPanelState: Identifiable {
  case draft(TranslationDraft)
  case streaming(TranslationDraft, translatedText: String)
  case result(TranslationResult, saved: Bool)
  case error(String)

  var id: String {
    switch self {
    case let .draft(draft):
      "draft-\(draft.id.uuidString)"
    case let .streaming(draft, translatedText):
      "streaming-\(draft.id.uuidString)-\(translatedText.count)"
    case let .result(result, _):
      result.id.uuidString
    case let .error(message):
      "error-\(message)"
    }
  }
}

struct FloatingPanelView: View {
  private let panelShape = RoundedRectangle(cornerRadius: 22, style: .continuous)

  let state: FloatingPanelState
  let displayedLanguages: [String]
  let onPinChanged: (Bool) -> Void
  let onStartTranslation: (TranslationDraft) -> Void
  let onCopy: (String) -> Void
  let onSpeak: (String, String?) -> Void
  let onClose: () -> Void
  @State private var pinned: Bool

  init(
    state: FloatingPanelState,
    displayedLanguages: [String],
    isPinned: Bool,
    onPinChanged: @escaping (Bool) -> Void,
    onStartTranslation: @escaping (TranslationDraft) -> Void,
    onCopy: @escaping (String) -> Void,
    onSpeak: @escaping (String, String?) -> Void,
    onClose: @escaping () -> Void
  ) {
    self.state = state
    self.displayedLanguages = displayedLanguages
    self.onPinChanged = onPinChanged
    self.onStartTranslation = onStartTranslation
    self.onCopy = onCopy
    self.onSpeak = onSpeak
    self.onClose = onClose
    _pinned = State(initialValue: isPinned)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      header
      contentArea
    }
    .padding(10)
    .frame(minWidth: 460, maxWidth: .infinity, minHeight: 280, maxHeight: .infinity, alignment: .topLeading)
    .foregroundStyle(.white)
    .background {
      panelShape
        .fill(Color.black)
        .overlay {
          LinearGradient(
            colors: [
              Color.white.opacity(0.12),
              Color(red: 0.06, green: 0.08, blue: 0.10).opacity(0.5),
              Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
          .clipShape(panelShape)
        }
    }
    .clipShape(panelShape)
    .shadow(color: .black.opacity(0.46), radius: 18, x: 0, y: 10)
    .preferredColorScheme(.dark)
  }

  @ViewBuilder
  private var contentArea: some View {
    switch state {
    case let .draft(draft):
      filledContentArea {
        DraftPanelContent(
          draft: draft,
          displayedLanguages: displayedLanguages,
          onStartTranslation: onStartTranslation,
          onSpeak: onSpeak
        )
      }
    case let .streaming(draft, translatedText):
      filledContentArea {
        VStack(alignment: .leading, spacing: 6) {
          sourceContent(draft)
          streamingTranslationContent(translatedText, targetLanguage: draft.targetLanguage)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
    case let .result(result, saved):
      filledContentArea {
        resultContent(result, saved: saved)
      }
    case let .error(message):
      ScrollView {
        GlassEffectContainer(spacing: 6) {
          errorContent(message)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
      }
    }
  }

  private func filledContentArea<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    GlassEffectContainer(spacing: 6) {
      content()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var header: some View {
    HStack(spacing: 8) {
      Button {
        pinned.toggle()
        onPinChanged(pinned)
      } label: {
        Image(systemName: pinned ? "pin.fill" : "pin")
          .frame(width: 14, height: 14)
      }
      .buttonStyle(.glass)
      .buttonBorderShape(.circle)
      .controlSize(.small)
      .help(pinned ? "取消固定" : "固定弹窗，点击其他区域不收起")

      HStack {
        Text("快捷翻译")
          .font(.headline.weight(.semibold))
        Spacer()
      }
      .contentShape(Rectangle())
      .gesture(WindowDragGesture())
      .allowsWindowActivationEvents(true)

      Button(action: onClose) {
        Image(systemName: "xmark")
          .frame(width: 14, height: 14)
      }
      .buttonStyle(.glass)
      .buttonBorderShape(.circle)
      .controlSize(.small)
      .help("关闭")
    }
  }

  private func sourceContent(_ draft: TranslationDraft) -> some View {
    EditableSourcePanelContent(
      draft: draft,
      displayedLanguages: displayedLanguages,
      onStartTranslation: onStartTranslation,
      onSpeak: onSpeak
    )
  }

  private func streamingTranslationContent(_ translatedText: String, targetLanguage: String) -> some View {
    GlassPanel(fillsAvailableHeight: true) {
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Label("译文", systemImage: "text.bubble")
            .font(.headline)
          Spacer()
          ProgressView()
            .controlSize(.small)
            .tint(.white)
          SpeechButton(
            text: translatedText,
            languageHint: targetLanguage,
            help: "朗读译文",
            onSpeak: onSpeak
          )
        }

        textBlock(
          translatedText.isEmpty ? "正在翻译..." : translatedText,
          isPlaceholder: translatedText.isEmpty
        )
        .frame(minHeight: 64, alignment: .topLeading)
      }
    }
    .layoutPriority(1)
  }

  private func resultContent(_ result: TranslationResult, saved: Bool) -> some View {
    ResultPanelContent(
      result: result,
      saved: saved,
      displayedLanguages: displayedLanguages,
      onStartTranslation: onStartTranslation,
      onCopy: onCopy,
      onSpeak: onSpeak
    )
  }

  private func errorContent(_ message: String) -> some View {
    GlassPanel {
      HStack(alignment: .top, spacing: 10) {
        Image(systemName: "exclamationmark.triangle")
          .foregroundStyle(.yellow)
        Text(message)
          .foregroundStyle(.white)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private func textBlock(_ text: String, isPlaceholder: Bool = false) -> some View {
    Text(verbatim: text)
      .font(.body)
      .foregroundStyle(isPlaceholder ? .white.opacity(0.55) : .white.opacity(0.92))
      .lineLimit(nil)
      .multilineTextAlignment(.leading)
      .textSelection(.enabled)
      .frame(maxWidth: .infinity, alignment: .topLeading)
  }
}

private struct ResultPanelContent: View {
  let result: TranslationResult
  let saved: Bool
  let displayedLanguages: [String]
  let onStartTranslation: (TranslationDraft) -> Void
  let onCopy: (String) -> Void
  let onSpeak: (String, String?) -> Void
  @State private var sourceText: String
  @State private var sourceLanguage: String
  @State private var targetLanguage: String
  @State private var autoSourceLanguage: String
  @State private var autoTargetLanguage: String

  init(
    result: TranslationResult,
    saved: Bool,
    displayedLanguages: [String],
    onStartTranslation: @escaping (TranslationDraft) -> Void,
    onCopy: @escaping (String) -> Void,
    onSpeak: @escaping (String, String?) -> Void
  ) {
    self.result = result
    self.saved = saved
    self.displayedLanguages = displayedLanguages
    self.onStartTranslation = onStartTranslation
    self.onCopy = onCopy
    self.onSpeak = onSpeak
    let inferredSourceLanguage = TranslationDraft.inferredSourceLanguage(for: result.originalText)
    let inferredTargetLanguage = TranslationDraft.defaultTargetLanguage(for: inferredSourceLanguage)
    _sourceText = State(initialValue: result.originalText)
    _sourceLanguage = State(initialValue: normalizedLanguageName(result.detectedLanguage, fallback: inferredSourceLanguage))
    _targetLanguage = State(initialValue: normalizedLanguageName(result.targetLanguage, fallback: inferredTargetLanguage))
    _autoSourceLanguage = State(initialValue: inferredSourceLanguage)
    _autoTargetLanguage = State(initialValue: inferredTargetLanguage)
  }

  private var trimmedSourceText: String {
    sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      editableSourceContent

      GlassPanel(fillsAvailableHeight: true) {
        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Label("译文", systemImage: "text.bubble")
              .font(.headline)
            Spacer()
            Text(saved ? "已保存" : "未保存")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundStyle(saved ? .green : .white.opacity(0.6))
            SpeechButton(
              text: result.translatedText,
              languageHint: result.targetLanguage,
              help: "朗读译文",
              onSpeak: onSpeak
            )
          }

          textBlock(result.translatedText)
            .frame(minHeight: 72, alignment: .topLeading)

          HStack {
            Spacer()
            Button {
              submit()
            } label: {
              Label("重新翻译", systemImage: "return")
            }
            .keyboardShortcut(.return, modifiers: [])
            .buttonStyle(.glassProminent)
            .controlSize(.small)
            .disabled(trimmedSourceText.isEmpty)

            Button {
              onCopy(result.translatedText)
            } label: {
              Label("复制", systemImage: "doc.on.doc")
            }
            .buttonStyle(.glass)
            .controlSize(.small)
          }
        }
      }
      .layoutPriority(1)
    }
    .frame(maxHeight: .infinity, alignment: .topLeading)
  }

  private var editableSourceContent: some View {
    GlassPanel {
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Label("原文", systemImage: "text.quote")
            .font(.headline)
          Spacer()
          LanguageDirectionPicker(
            sourceLanguage: $sourceLanguage,
            targetLanguage: $targetLanguage,
            displayedLanguages: displayedLanguages
          )
          SpeechButton(
            text: sourceText,
            languageHint: sourceLanguage,
            help: "朗读原文",
            onSpeak: onSpeak
          )
        }

        EditableSourceTextView(
          text: $sourceText,
          onSubmit: submit
        )
        .frame(minHeight: 64, idealHeight: 82, maxHeight: 180)
        .onChange(of: sourceText) { _, newValue in
          updateAutomaticLanguages(for: newValue)
        }
      }
    }
  }

  private func submit() {
    guard !trimmedSourceText.isEmpty else {
      return
    }

    onStartTranslation(
      TranslationDraft(
        id: result.id,
        sourceText: trimmedSourceText,
        detectedLanguage: sourceLanguage,
        targetLanguage: targetLanguage
      )
    )
  }

  private func textBlock(_ text: String, isPlaceholder: Bool = false) -> some View {
    Text(verbatim: text)
      .font(.body)
      .foregroundStyle(isPlaceholder ? .white.opacity(0.55) : .white.opacity(0.92))
      .lineLimit(nil)
      .multilineTextAlignment(.leading)
      .textSelection(.enabled)
      .frame(maxWidth: .infinity, alignment: .topLeading)
  }

  private func updateAutomaticLanguages(for text: String) {
    let inferredSourceLanguage = TranslationDraft.inferredSourceLanguage(for: text)
    let inferredTargetLanguage = TranslationDraft.defaultTargetLanguage(for: inferredSourceLanguage)

    if sourceLanguage == autoSourceLanguage {
      sourceLanguage = inferredSourceLanguage
    }

    if targetLanguage == autoTargetLanguage {
      targetLanguage = inferredTargetLanguage
    }

    autoSourceLanguage = inferredSourceLanguage
    autoTargetLanguage = inferredTargetLanguage
  }
}

private struct GlassPanel<Content: View>: View {
  let content: Content
  let fillsAvailableHeight: Bool

  init(fillsAvailableHeight: Bool = false, @ViewBuilder content: () -> Content) {
    self.content = content()
    self.fillsAvailableHeight = fillsAvailableHeight
  }

  var body: some View {
    content
      .padding(10)
      .frame(
        maxWidth: .infinity,
        maxHeight: fillsAvailableHeight ? .infinity : nil,
        alignment: .topLeading
      )
      .glassEffect(
        .regular.tint(.white.opacity(0.05)),
        in: RoundedRectangle(cornerRadius: 15, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
          .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
      }
  }
}

private struct SpeechButton: View {
  let text: String
  let languageHint: String?
  let help: String
  let onSpeak: (String, String?) -> Void

  private var isDisabled: Bool {
    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    Button {
      onSpeak(text, languageHint)
    } label: {
      Image(systemName: "speaker.wave.2")
        .frame(width: 14, height: 14)
    }
    .buttonStyle(.glass)
    .buttonBorderShape(.circle)
    .controlSize(.small)
    .disabled(isDisabled)
    .help(help)
  }
}

private struct LanguageDirectionPicker: View {
  @Binding var sourceLanguage: String
  @Binding var targetLanguage: String
  let displayedLanguages: [String]

  var body: some View {
    HStack(spacing: 6) {
      Text("识别")
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(.white.opacity(0.62))
      languagePicker("识别语言", selection: $sourceLanguage, currentValue: sourceLanguage)

      Text("翻译为")
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(.white.opacity(0.62))
      languagePicker("目标语言", selection: $targetLanguage, currentValue: targetLanguage)
    }
  }

  private func languagePicker(
    _ title: String,
    selection: Binding<String>,
    currentValue: String
  ) -> some View {
    Picker(title, selection: selection) {
      ForEach(languageOptions(including: currentValue), id: \.self) { language in
        Text(language).tag(language)
      }
    }
    .labelsHidden()
    .pickerStyle(.menu)
    .frame(width: 86)
  }

  private func languageOptions(including currentValue: String) -> [String] {
    normalizedLanguageOptions(from: displayedLanguages, including: [currentValue])
  }
}

private func normalizedLanguageOptions(from languages: [String], including currentValues: [String] = []) -> [String] {
  var seen = Set<String>()
  let values = languages + currentValues
  let normalized = values.compactMap { language -> String? in
    let value = language.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, !seen.contains(value) else {
      return nil
    }
    seen.insert(value)
    return value
  }

  return normalized.isEmpty ? AppSettings.defaultDisplayedLanguages : normalized
}

private func normalizedLanguageName(_ language: String, fallback: String) -> String {
  let value = language.trimmingCharacters(in: .whitespacesAndNewlines)
  switch value.lowercased() {
  case "", "unknown", "auto", "自动", "非中文":
    return fallback
  case "english":
    return "英文"
  case "chinese", "simplified chinese", "traditional chinese":
    return "中文"
  case "japanese":
    return "日语"
  case "korean":
    return "韩语"
  case "thai":
    return "泰语"
  case "french":
    return "法语"
  case "german":
    return "德语"
  case "spanish":
    return "西班牙语"
  default:
    return value
  }
}

private struct EditableSourcePanelContent: View {
  let draft: TranslationDraft
  let displayedLanguages: [String]
  let onStartTranslation: (TranslationDraft) -> Void
  let onSpeak: (String, String?) -> Void
  @State private var sourceText: String
  @State private var sourceLanguage: String
  @State private var targetLanguage: String
  @State private var autoSourceLanguage: String
  @State private var autoTargetLanguage: String

  init(
    draft: TranslationDraft,
    displayedLanguages: [String],
    onStartTranslation: @escaping (TranslationDraft) -> Void,
    onSpeak: @escaping (String, String?) -> Void
  ) {
    self.draft = draft
    self.displayedLanguages = displayedLanguages
    self.onStartTranslation = onStartTranslation
    self.onSpeak = onSpeak
    let inferredSourceLanguage = TranslationDraft.inferredSourceLanguage(for: draft.sourceText)
    let inferredTargetLanguage = TranslationDraft.defaultTargetLanguage(for: inferredSourceLanguage)
    _sourceText = State(initialValue: draft.sourceText)
    _sourceLanguage = State(initialValue: normalizedLanguageName(draft.detectedLanguage, fallback: inferredSourceLanguage))
    _targetLanguage = State(initialValue: normalizedLanguageName(draft.targetLanguage, fallback: inferredTargetLanguage))
    _autoSourceLanguage = State(initialValue: inferredSourceLanguage)
    _autoTargetLanguage = State(initialValue: inferredTargetLanguage)
  }

  private var trimmedSourceText: String {
    sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    GlassPanel {
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Label("原文", systemImage: "text.quote")
            .font(.headline)
          Spacer()
          LanguageDirectionPicker(
            sourceLanguage: $sourceLanguage,
            targetLanguage: $targetLanguage,
            displayedLanguages: displayedLanguages
          )
          SpeechButton(
            text: sourceText,
            languageHint: sourceLanguage,
            help: "朗读原文",
            onSpeak: onSpeak
          )
        }

        EditableSourceTextView(
          text: $sourceText,
          onSubmit: submit
        )
        .frame(minHeight: 64, idealHeight: 82, maxHeight: 180)
        .onChange(of: sourceText) { _, newValue in
          updateAutomaticLanguages(for: newValue)
        }
      }
    }
  }

  private func submit() {
    guard !trimmedSourceText.isEmpty else {
      return
    }

    onStartTranslation(
      TranslationDraft(
        id: draft.id,
        sourceText: trimmedSourceText,
        detectedLanguage: sourceLanguage,
        targetLanguage: targetLanguage
      )
    )
  }

  private func updateAutomaticLanguages(for text: String) {
    let inferredSourceLanguage = TranslationDraft.inferredSourceLanguage(for: text)
    let inferredTargetLanguage = TranslationDraft.defaultTargetLanguage(for: inferredSourceLanguage)

    if sourceLanguage == autoSourceLanguage {
      sourceLanguage = inferredSourceLanguage
    }

    if targetLanguage == autoTargetLanguage {
      targetLanguage = inferredTargetLanguage
    }

    autoSourceLanguage = inferredSourceLanguage
    autoTargetLanguage = inferredTargetLanguage
  }
}

private struct DraftPanelContent: View {
  let draft: TranslationDraft
  let displayedLanguages: [String]
  let onStartTranslation: (TranslationDraft) -> Void
  let onSpeak: (String, String?) -> Void
  @State private var sourceText: String
  @State private var sourceLanguage: String
  @State private var targetLanguage: String
  @State private var autoSourceLanguage: String
  @State private var autoTargetLanguage: String

  init(
    draft: TranslationDraft,
    displayedLanguages: [String],
    onStartTranslation: @escaping (TranslationDraft) -> Void,
    onSpeak: @escaping (String, String?) -> Void
  ) {
    self.draft = draft
    self.displayedLanguages = displayedLanguages
    self.onStartTranslation = onStartTranslation
    self.onSpeak = onSpeak
    let inferredSourceLanguage = TranslationDraft.inferredSourceLanguage(for: draft.sourceText)
    let inferredTargetLanguage = TranslationDraft.defaultTargetLanguage(for: inferredSourceLanguage)
    _sourceText = State(initialValue: draft.sourceText)
    _sourceLanguage = State(initialValue: normalizedLanguageName(draft.detectedLanguage, fallback: inferredSourceLanguage))
    _targetLanguage = State(initialValue: normalizedLanguageName(draft.targetLanguage, fallback: inferredTargetLanguage))
    _autoSourceLanguage = State(initialValue: inferredSourceLanguage)
    _autoTargetLanguage = State(initialValue: inferredTargetLanguage)
  }

  private var trimmedSourceText: String {
    sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      editableSourceContent
      draftTranslationContent
    }
    .frame(maxHeight: .infinity, alignment: .topLeading)
  }

  private var editableSourceContent: some View {
    GlassPanel {
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Label("原文", systemImage: "text.quote")
            .font(.headline)
          Spacer()
          LanguageDirectionPicker(
            sourceLanguage: $sourceLanguage,
            targetLanguage: $targetLanguage,
            displayedLanguages: displayedLanguages
          )
          SpeechButton(
            text: sourceText,
            languageHint: sourceLanguage,
            help: "朗读原文",
            onSpeak: onSpeak
          )
        }

        EditableSourceTextView(
          text: $sourceText,
          onSubmit: submit
        )
        .frame(minHeight: 64, idealHeight: 82, maxHeight: 180)
        .onChange(of: sourceText) { _, newValue in
          updateAutomaticLanguages(for: newValue)
        }
      }
    }
  }

  private var draftTranslationContent: some View {
    GlassPanel(fillsAvailableHeight: true) {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Label("译文", systemImage: "text.bubble")
            .font(.headline)
          Spacer()
          Text("待开始")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.white.opacity(0.55))
        }

        Text("按 Return 开始翻译")
          .foregroundStyle(.white.opacity(0.55))
          .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)

        HStack {
          Spacer()
          Button {
            submit()
          } label: {
            Label("开始翻译", systemImage: "return")
          }
          .keyboardShortcut(.return, modifiers: [])
          .buttonStyle(.glassProminent)
          .disabled(trimmedSourceText.isEmpty)
        }
      }
    }
    .layoutPriority(1)
  }

  private func submit() {
    guard !trimmedSourceText.isEmpty else {
      return
    }

    onStartTranslation(
      TranslationDraft(
        id: draft.id,
        sourceText: trimmedSourceText,
        detectedLanguage: sourceLanguage,
        targetLanguage: targetLanguage
      )
    )
  }

  private func updateAutomaticLanguages(for text: String) {
    let inferredSourceLanguage = TranslationDraft.inferredSourceLanguage(for: text)
    let inferredTargetLanguage = TranslationDraft.defaultTargetLanguage(for: inferredSourceLanguage)

    if sourceLanguage == autoSourceLanguage {
      sourceLanguage = inferredSourceLanguage
    }

    if targetLanguage == autoTargetLanguage {
      targetLanguage = inferredTargetLanguage
    }

    autoSourceLanguage = inferredSourceLanguage
    autoTargetLanguage = inferredTargetLanguage
  }
}
