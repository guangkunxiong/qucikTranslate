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
    FloatingPanelChrome {
      VStack(alignment: .leading, spacing: 16) {
        header

        ScrollView {
          GlassEffectContainer(spacing: 18) {
            panelContent
              .frame(maxWidth: .infinity, alignment: .topLeading)
          }
        }
      }
    }
  }

  @ViewBuilder
  private var panelContent: some View {
    VStack(alignment: .leading, spacing: 16) {
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
    HStack(spacing: 14) {
      IconGlassButton(
        systemName: pinned ? "pin.fill" : "pin",
        help: pinned ? "取消固定" : "固定弹窗，点击其他区域不收起"
      ) {
        pinned.toggle()
        onPinChanged(pinned)
      }

      HeaderIdentity()
      Spacer()

      IconGlassButton(systemName: "xmark", help: "关闭", action: onClose)
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
        SectionHeader(
          title: "译文",
          systemImage: "text.bubble"
        ) {
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
          SectionHeader(
            title: "译文",
            systemImage: "text.bubble"
          ) {
            Spacer()
            StatusPill(text: saved ? "已保存" : "未保存", isActive: saved)
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
            .buttonBorderShape(.capsule)
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

private struct FloatingPanelChrome<Content: View>: View {
  private let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .padding(20)
      .frame(minWidth: 540, maxWidth: .infinity, minHeight: 380, maxHeight: .infinity, alignment: .topLeading)
      .foregroundStyle(.white)
      .background {
        shape
          .fill(Color.black)
          .overlay {
            LiquidGlassBackdrop()
              .clipShape(shape)
          }
      }
      .overlay {
        shape
          .strokeBorder(
            LinearGradient(
              colors: [
                Color.white.opacity(0.42),
                Color.white.opacity(0.12),
                Color.white.opacity(0.04)
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 1
          )
      }
      .overlay(alignment: .topLeading) {
        shape
          .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.5)
          .blur(radius: 0.4)
          .padding(1)
      }
      .clipShape(shape)
      .shadow(color: .black.opacity(0.65), radius: 36, x: 0, y: 24)
      .shadow(color: Color(red: 0.1, green: 0.48, blue: 1).opacity(0.18), radius: 44, x: -12, y: -10)
      .preferredColorScheme(.dark)
  }
}

private struct LiquidGlassBackdrop: View {
  var body: some View {
    ZStack {
      Color.black

      LinearGradient(
        colors: [
          Color.white.opacity(0.18),
          Color.white.opacity(0.04),
          Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .center
      )

      LinearGradient(
        colors: [
          Color(red: 0.05, green: 0.55, blue: 1).opacity(0.26),
          Color.clear,
          Color(red: 0.1, green: 1, blue: 0.82).opacity(0.14)
        ],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
      )
      .blendMode(.screen)

      DiagonalGlassSheen()
        .stroke(Color.white.opacity(0.09), lineWidth: 1)
        .blur(radius: 0.3)
        .padding(24)
    }
  }
}

private struct DiagonalGlassSheen: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let offsets: [CGFloat] = [-0.25, 0.1, 0.45, 0.8]

    for offset in offsets {
      let start = CGPoint(x: rect.minX + rect.width * offset, y: rect.minY)
      let end = CGPoint(x: rect.minX + rect.width * (offset + 0.35), y: rect.maxY)
      path.move(to: start)
      path.addLine(to: end)
    }

    return path
  }
}

private struct GlassPanel<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .padding(18)
      .frame(maxWidth: .infinity, alignment: .topLeading)
      .glassEffect(
        .regular.interactive().tint(.white.opacity(0.12)),
        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .strokeBorder(
            LinearGradient(
              colors: [
                Color.white.opacity(0.32),
                Color.white.opacity(0.08),
                Color.white.opacity(0.18)
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 1
          )
      }
      .shadow(color: .black.opacity(0.24), radius: 18, x: 0, y: 10)
  }
}

private struct HeaderIdentity: View {
  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "character.book.closed")
        .font(.title3.weight(.semibold))
        .symbolRenderingMode(.hierarchical)

      VStack(alignment: .leading, spacing: 2) {
        Text("快捷翻译")
          .font(.title3.weight(.semibold))
        Text("Liquid Glass")
          .font(.caption2.weight(.medium))
          .foregroundStyle(.white.opacity(0.5))
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .glassEffect(
      .regular.interactive().tint(.white.opacity(0.08)),
      in: Capsule()
    )
  }
}

private struct SectionHeader<Trailing: View>: View {
  let title: String
  let systemImage: String
  let trailing: Trailing

  init(
    title: String,
    systemImage: String,
    @ViewBuilder trailing: () -> Trailing
  ) {
    self.title = title
    self.systemImage = systemImage
    self.trailing = trailing()
  }

  var body: some View {
    HStack(spacing: 10) {
      Label(title, systemImage: systemImage)
        .font(.headline)
        .symbolRenderingMode(.hierarchical)
      trailing
    }
  }
}

private struct StatusPill: View {
  let text: String
  let isActive: Bool

  var body: some View {
    Text(text)
      .font(.caption.weight(.semibold))
      .foregroundStyle(isActive ? Color.green : Color.white.opacity(0.62))
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .glassEffect(
        .regular.interactive().tint((isActive ? Color.green : Color.white).opacity(isActive ? 0.16 : 0.08)),
        in: Capsule()
      )
  }
}

private struct IconGlassButton: View {
  let systemName: String
  let help: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: systemName)
        .frame(width: 16, height: 16)
    }
    .buttonStyle(.glass)
    .buttonBorderShape(.circle)
    .controlSize(.small)
    .help(help)
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
    IconGlassButton(systemName: "speaker.wave.2", help: help) {
      onSpeak(text, languageHint)
    }
    .disabled(isDisabled)
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
        SectionHeader(
          title: "原文",
          systemImage: "text.quote"
        ) {
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
        SectionHeader(
          title: "原文",
          systemImage: "text.quote"
        ) {
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
        SectionHeader(
          title: "译文",
          systemImage: "text.bubble"
        ) {
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
