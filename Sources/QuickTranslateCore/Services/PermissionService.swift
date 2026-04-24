import ApplicationServices
import Foundation

public enum PermissionService {
  public static var isAccessibilityTrusted: Bool {
    AXIsProcessTrusted()
  }

  @discardableResult
  public static func promptForAccessibilityPermission() -> Bool {
    let options = [
      "AXTrustedCheckOptionPrompt": true
    ] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
  }
}
