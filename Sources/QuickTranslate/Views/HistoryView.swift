import QuickTranslateCore
import SwiftUI

struct HistoryView: View {
  @EnvironmentObject private var appModel: AppModel
  @State private var searchText = ""

  private var records: [HistoryRecord] {
    _ = appModel.historyRevision
    return appModel.historyStore.search(searchText)
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.secondary)
        TextField("Search history", text: $searchText)
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
    .navigationTitle("History")
  }
}

private struct EmptyHistoryView: View {
  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: "clock.arrow.circlepath")
        .font(.largeTitle)
        .foregroundStyle(.secondary)
      Text("No History")
        .font(.headline)
      Text("Successful translations will appear here.")
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
        .help("Copy translation")

        Button {
          appModel.translate(record: record)
        } label: {
          Image(systemName: "arrow.clockwise")
        }
        .help("Translate again")

        Button(role: .destructive) {
          appModel.deleteHistoryRecord(record.id)
        } label: {
          Image(systemName: "trash")
        }
        .help("Delete")
      }
      .font(.caption)
      .foregroundStyle(.secondary)
      .buttonStyle(.borderless)
    }
  }
}
