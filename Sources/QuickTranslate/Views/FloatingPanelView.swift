import QuickTranslateCore
import SwiftUI

enum FloatingPanelState: Identifiable {
  case result(TranslationResult, saved: Bool)
  case error(String)

  var id: String {
    switch self {
    case let .result(result, _):
      result.id.uuidString
    case let .error(message):
      "error-\(message)"
    }
  }
}

struct FloatingPanelView: View {
  let state: FloatingPanelState
  let onCopy: (String) -> Void
  let onClose: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      header

      switch state {
      case let .result(result, saved):
        resultContent(result, saved: saved)
      case let .error(message):
        errorContent(message)
      }
    }
    .padding(16)
    .frame(width: 380)
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

  private func resultContent(_ result: TranslationResult, saved: Bool) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(result.originalText)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(3)

      Text(result.translatedText)
        .font(.body)
        .textSelection(.enabled)

      HStack {
        Text("\(result.detectedLanguage) -> \(result.targetLanguage)")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        Text(saved ? "已保存" : "未保存")
          .font(.caption)
          .foregroundStyle(saved ? .green : .secondary)
      }

      HStack {
        Spacer()
        Button {
          onCopy(result.translatedText)
        } label: {
          Label("复制", systemImage: "doc.on.doc")
        }
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
