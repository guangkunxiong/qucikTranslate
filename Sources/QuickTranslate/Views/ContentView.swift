import QuickTranslateCore
import SwiftUI

private enum SidebarSelection: String, CaseIterable, Identifiable {
  case history
  case settings
  case about

  var id: String { rawValue }

  var title: String {
    switch self {
    case .history: "历史"
    case .settings: "设置"
    case .about: "关于"
    }
  }

  var systemImage: String {
    switch self {
    case .history: "clock.arrow.circlepath"
    case .settings: "gearshape"
    case .about: "info.circle"
    }
  }
}

struct ContentView: View {
  @EnvironmentObject private var appModel: AppModel
  @State private var selection: SidebarSelection = .history

  var body: some View {
    HStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 8) {
        Text("快捷翻译")
          .font(.headline)
          .padding(.horizontal, 12)
          .padding(.top, 14)

        ForEach(SidebarSelection.allCases) { item in
          Button {
            selection = item
          } label: {
            HStack(spacing: 10) {
              Image(systemName: item.systemImage)
                .frame(width: 16)
              Text(item.title)
              Spacer(minLength: 0)
            }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.vertical, 7)
              .padding(.horizontal, 10)
              .contentShape(Rectangle())
              .background(selection == item ? Color.accentColor.opacity(0.18) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
          }
          .buttonStyle(.plain)
          .frame(maxWidth: .infinity, alignment: .leading)
          .foregroundStyle(selection == item ? .primary : .secondary)
          .padding(.horizontal, 8)
        }

        Spacer()
      }
      .frame(width: 190)
      .background(.bar)

      Divider()

      detailView
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .environmentObject(appModel)
    .frame(minWidth: 780, minHeight: 520)
  }

  @ViewBuilder
  private var detailView: some View {
    switch selection {
    case .history:
      HistoryView()
    case .settings:
      SettingsView()
    case .about:
      AboutView()
    }
  }
}
