import AppKit
import QuickTranslateCore

@MainActor
enum PermissionRequestPresenter {
  static func requestAccessibilityPermission() {
    let explanation = PermissionService.accessibilityPermissionExplanation
    let alert = NSAlert()
    alert.messageText = explanation.title
    alert.informativeText = explanation.message
    alert.alertStyle = .informational
    alert.addButton(withTitle: explanation.primaryButtonTitle)
    alert.addButton(withTitle: explanation.secondaryButtonTitle)

    if alert.runModal() == .alertFirstButtonReturn {
      _ = PermissionService.promptForAccessibilityPermission()
    }
  }
}
