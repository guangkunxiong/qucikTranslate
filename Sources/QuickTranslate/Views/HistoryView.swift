import QuickTranslateCore
import SwiftUI

struct HistoryView: View {
  @EnvironmentObject private var appModel: AppModel
  @State private var searchText = ""

  private var records: [HistoryRecord] {
    _ = appModel.historyRevision
    _ = appModel.settingsRevision
    return appModel.historyStore.search(
      searchText,
      hidingSystemPrompts: [
        appModel.settingsStore.settings.systemPrompt,
        AppSettings.defaultSystemPrompt
      ]
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.secondary)
        TextField("搜索历史", text: $searchText)
          .textFieldStyle(.plain)
      }
      .padding(10)
      .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
      .padding([.horizontal, .top])

      if records.isEmpty {
        EmptyHistoryView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List(records) { record in
          HistoryRow(record: record)
            .environmentObject(appModel)
            .padding(.vertical, 4)
        }
        .listStyle(.inset)
      }
    }
    .navigationTitle("历史")
  }
}

private struct EmptyHistoryView: View {
  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: "clock.arrow.circlepath")
        .font(.largeTitle)
        .foregroundStyle(.secondary)
      Text("暂无历史")
        .font(.headline)
      Text("成功翻译后会显示在这里。")
        .foregroundStyle(.secondary)
    }
  }
}

private struct HistoryRow: View {
  @EnvironmentObject private var appModel: AppModel
  let record: HistoryRecord

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        Text(record.originalText)
          .font(.headline)
          .lineLimit(2)
        Spacer()
        Text(record.timestamp, style: .date)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Text(record.translatedText)
        .font(.body)
        .lineLimit(3)
        .textSelection(.enabled)

      HStack {
        Text("\(record.detectedLanguage) -> \(record.targetLanguage)")
        Text(record.model)
        Spacer()
        Button {
          appModel.copyTranslation(record.translatedText)
        } label: {
          Image(systemName: "doc.on.doc")
        }
        .help("复制译文")

        Button {
          appModel.translate(record: record)
        } label: {
          Image(systemName: "arrow.clockwise")
        }
        .help("重新翻译")

        Button(role: .destructive) {
          appModel.deleteHistoryRecord(record.id)
        } label: {
          Image(systemName: "trash")
        }
        .help("删除")
      }
      .font(.caption)
      .foregroundStyle(.secondary)
      .buttonStyle(.borderless)
    }
  }
}
