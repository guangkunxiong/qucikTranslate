import QuickTranslateCore
import SwiftUI

private enum SidebarSelection: String, CaseIterable, Identifiable {
  case history
  case settings
  case about

  var id: String { rawValue }

  var title: String {
    switch self {
    case .history: "History"
    case .settings: "Settings"
    case .about: "About"
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
  @State private var selection: SidebarSelection? = .history

  var body: some View {
    NavigationSplitView {
      List(selection: $selection) {
        ForEach(SidebarSelection.allCases) { item in
          Label(item.title, systemImage: item.systemImage)
            .tag(item)
        }
      }
      .listStyle(.sidebar)
      .navigationTitle("Quick Translate")
    } detail: {
      switch selection ?? .history {
      case .history:
        HistoryView()
      case .settings:
        SettingsView()
      case .about:
        AboutView()
      }
    }
    .environmentObject(appModel)
    .frame(minWidth: 780, minHeight: 520)
  }
}
