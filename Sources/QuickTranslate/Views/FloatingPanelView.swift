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
  private let panelShape = RoundedRectangle(cornerRadius: 24, style: .continuous)

  let state: FloatingPanelState
  let onPinChanged: (Bool) -> Void
  let onStartTranslation: (String) -> Void
  let onCopy: (String) -> Void
  let onSpeak: (String, String?) -> Void
  let onClose: () -> Void
  @State private var pinned: Bool

  init(
    state: FloatingPanelState,
    isPinned: Bool,
    onPinChanged: @escaping (Bool) -> Void,
    onStartTranslation: @escaping (String) -> Void,
    onCopy: @escaping (String) -> Void,
    onSpeak: @escaping (String, String?) -> Void,
    onClose: @escaping () -> Void
  ) {
    self.state = state
    self.onPinChanged = onPinChanged
    self.onStartTranslation = onStartTranslation
    self.onCopy = onCopy
    self.onSpeak = onSpeak
    self.onClose = onClose
    _pinned = State(initialValue: isPinned)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      header

      ScrollView {
        GlassEffectContainer(spacing: 12) {
          panelContent
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
      }
    }
    .padding(18)
    .frame(minWidth: 520, maxWidth: .infinity, minHeight: 360, maxHeight: .infinity, alignment: .topLeading)
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
    .overlay {
      panelShape
        .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
    }
    .clipShape(panelShape)
    .shadow(color: .black.opacity(0.45), radius: 28, x: 0, y: 18)
    .preferredColorScheme(.dark)
  }

  @ViewBuilder
  private var panelContent: some View {
    VStack(alignment: .leading, spacing: 12) {
      switch state {
      case let .draft(draft):
        DraftPanelContent(
          draft: draft,
          onStartTranslation: onStartTranslation,
          onSpeak: onSpeak
        )
      case let .streaming(draft, translatedText):
        sourceContent(draft)
        streamingTranslationContent(translatedText, targetLanguage: draft.targetLanguage)
      case let .result(result, saved):
        resultContent(result, saved: saved)
      case let .error(message):
        errorContent(message)
      }
    }
  }

  private var header: some View {
    HStack(spacing: 12) {
      Button {
        pinned.toggle()
        onPinChanged(pinned)
      } label: {
        Image(systemName: pinned ? "pin.fill" : "pin")
      }
      .buttonStyle(.glass)
      .buttonBorderShape(.circle)
      .controlSize(.small)
      .help(pinned ? "取消固定" : "固定弹窗，点击其他区域不收起")

      Label("快捷翻译", systemImage: "character.book.closed")
        .font(.title3.weight(.semibold))
        .labelStyle(.titleAndIcon)
      Spacer()
      Button(action: onClose) {
        Image(systemName: "xmark")
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
      onStartTranslation: onStartTranslation,
      onSpeak: onSpeak
    )
  }

  private func streamingTranslationContent(_ translatedText: String, targetLanguage: String) -> some View {
    GlassPanel {
      VStack(alignment: .leading, spacing: 12) {
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
        .frame(minHeight: 100, alignment: .topLeading)
      }
    }
  }

  private func resultContent(_ result: TranslationResult, saved: Bool) -> some View {
    let draft = TranslationDraft(
      id: result.id,
      sourceText: result.originalText,
      detectedLanguage: result.detectedLanguage,
      targetLanguage: result.targetLanguage
    )

    return VStack(alignment: .leading, spacing: 12) {
      sourceContent(draft)

      GlassPanel {
        VStack(alignment: .leading, spacing: 12) {
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
            .frame(minHeight: 120, alignment: .topLeading)

          HStack {
            Spacer()
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
    }
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

private struct GlassPanel<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .topLeading)
      .glassEffect(
        .regular.tint(.white.opacity(0.06)),
        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
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
    }
    .buttonStyle(.glass)
    .buttonBorderShape(.circle)
    .controlSize(.small)
    .disabled(isDisabled)
    .help(help)
  }
}

private struct EditableSourcePanelContent: View {
  let draft: TranslationDraft
  let onStartTranslation: (String) -> Void
  let onSpeak: (String, String?) -> Void
  @State private var sourceText: String

  init(
    draft: TranslationDraft,
    onStartTranslation: @escaping (String) -> Void,
    onSpeak: @escaping (String, String?) -> Void
  ) {
    self.draft = draft
    self.onStartTranslation = onStartTranslation
    self.onSpeak = onSpeak
    _sourceText = State(initialValue: draft.sourceText)
  }

  private var editedDraft: TranslationDraft {
    draft.replacingSourceText(sourceText)
  }

  private var trimmedSourceText: String {
    sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    GlassPanel {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Label("原文", systemImage: "text.quote")
            .font(.headline)
          Spacer()
          Text("识别：\(editedDraft.detectedLanguage)  翻译为：\(editedDraft.targetLanguage)")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.white.opacity(0.62))
          SpeechButton(
            text: sourceText,
            languageHint: editedDraft.detectedLanguage,
            help: "朗读原文",
            onSpeak: onSpeak
          )
        }

        EditableSourceTextView(
          text: $sourceText,
          onSubmit: submit
        )
        .frame(minHeight: 116, idealHeight: 150, maxHeight: 260)
      }
    }
  }

  private func submit() {
    guard !trimmedSourceText.isEmpty else {
      return
    }

    onStartTranslation(trimmedSourceText)
  }
}

private struct DraftPanelContent: View {
  let draft: TranslationDraft
  let onStartTranslation: (String) -> Void
  let onSpeak: (String, String?) -> Void
  @State private var sourceText: String

  init(
    draft: TranslationDraft,
    onStartTranslation: @escaping (String) -> Void,
    onSpeak: @escaping (String, String?) -> Void
  ) {
    self.draft = draft
    self.onStartTranslation = onStartTranslation
    self.onSpeak = onSpeak
    _sourceText = State(initialValue: draft.sourceText)
  }

  private var editedDraft: TranslationDraft {
    draft.replacingSourceText(sourceText)
  }

  private var trimmedSourceText: String {
    sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      editableSourceContent
      draftTranslationContent
    }
  }

  private var editableSourceContent: some View {
    GlassPanel {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Label("原文", systemImage: "text.quote")
            .font(.headline)
          Spacer()
          Text("识别：\(editedDraft.detectedLanguage)  翻译为：\(editedDraft.targetLanguage)")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.white.opacity(0.62))
          SpeechButton(
            text: sourceText,
            languageHint: editedDraft.detectedLanguage,
            help: "朗读原文",
            onSpeak: onSpeak
          )
        }

        EditableSourceTextView(
          text: $sourceText,
          onSubmit: submit
        )
        .frame(minHeight: 116, idealHeight: 150, maxHeight: 260)
      }
    }
  }

  private var draftTranslationContent: some View {
    GlassPanel {
      VStack(alignment: .leading, spacing: 14) {
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
          .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)

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
  }

  private func submit() {
    guard !trimmedSourceText.isEmpty else {
      return
    }

    onStartTranslation(trimmedSourceText)
  }
}
