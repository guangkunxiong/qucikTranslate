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
  let onStartTranslation: (String) -> Void
  let onCopy: (String) -> Void
  let onClose: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      header

      switch state {
      case let .draft(draft):
        DraftPanelContent(
          draft: draft,
          onStartTranslation: onStartTranslation
        )
      case let .streaming(draft, translatedText):
        sourceContent(draft)
        streamingTranslationContent(translatedText)
      case let .result(result, saved):
        resultContent(result, saved: saved)
      case let .error(message):
        errorContent(message)
      }
    }
    .padding(16)
    .frame(width: 460)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
  }

  private var header: some View {
    HStack {
      Label("快捷翻译", systemImage: "character.book.closed")
        .font(.headline)
      Spacer()
      Button(action: onClose) {
        Image(systemName: "xmark")
      }
      .buttonStyle(.borderless)
      .help("关闭")
    }
  }

  private func sourceContent(_ draft: TranslationDraft) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Label("原文", systemImage: "text.quote")
          .font(.subheadline.weight(.semibold))
        Spacer()
        Text("识别：\(draft.detectedLanguage)  翻译为：\(draft.targetLanguage)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      ScrollView {
        Text(draft.sourceText)
          .font(.body)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(minHeight: 56, maxHeight: 120)
    }
    .padding(12)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
    }
  }

  private func streamingTranslationContent(_ translatedText: String) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Label("译文", systemImage: "text.bubble")
          .font(.subheadline.weight(.semibold))
        Spacer()
        ProgressView()
          .controlSize(.small)
      }

      ScrollView {
        Text(translatedText.isEmpty ? "正在翻译..." : translatedText)
          .foregroundStyle(translatedText.isEmpty ? .secondary : .primary)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
      }
      .frame(maxHeight: 180)
    }
    .padding(12)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
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

      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Label("译文", systemImage: "text.bubble")
            .font(.subheadline.weight(.semibold))
          Spacer()
          Text(saved ? "已保存" : "未保存")
            .font(.caption)
            .foregroundStyle(saved ? .green : .secondary)
        }

        Text(result.translatedText)
          .font(.body)
          .textSelection(.enabled)

        HStack {
          Spacer()
          Button {
            onCopy(result.translatedText)
          } label: {
            Label("复制", systemImage: "doc.on.doc")
          }
        }
      }
      .padding(12)
      .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
      .overlay {
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
      }
    }
  }

  private func errorContent(_ message: String) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: "exclamationmark.triangle")
        .foregroundStyle(.yellow)
      Text(message)
        .foregroundStyle(.primary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

private struct DraftPanelContent: View {
  let draft: TranslationDraft
  let onStartTranslation: (String) -> Void
  @State private var sourceText: String

  init(
    draft: TranslationDraft,
    onStartTranslation: @escaping (String) -> Void
  ) {
    self.draft = draft
    self.onStartTranslation = onStartTranslation
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
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Label("原文", systemImage: "text.quote")
          .font(.subheadline.weight(.semibold))
        Spacer()
        Text("识别：\(editedDraft.detectedLanguage)  翻译为：\(editedDraft.targetLanguage)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      EditableSourceTextView(
        text: $sourceText,
        onSubmit: submit
      )
      .frame(minHeight: 72, maxHeight: 140)
    }
    .padding(12)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
    }
  }

  private var draftTranslationContent: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Label("译文", systemImage: "text.bubble")
          .font(.subheadline.weight(.semibold))
        Spacer()
        Text("待开始")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Text("按 Return 开始翻译")
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)

      HStack {
        Spacer()
        Button {
          submit()
        } label: {
          Label("开始翻译", systemImage: "return")
        }
        .keyboardShortcut(.return, modifiers: [])
        .buttonStyle(.borderedProminent)
        .disabled(trimmedSourceText.isEmpty)
      }
    }
    .padding(12)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
    }
  }

  private func submit() {
    guard !trimmedSourceText.isEmpty else {
      return
    }

    onStartTranslation(trimmedSourceText)
  }
}
