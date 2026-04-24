import ApplicationServices
import Foundation

public struct PermissionExplanation: Equatable, Sendable {
  public let title: String
  public let message: String
  public let primaryButtonTitle: String
  public let secondaryButtonTitle: String
}

public enum PermissionService {
  public static let accessibilityPermissionExplanation = PermissionExplanation(
    title: "为什么需要辅助功能权限？",
    message: """
    快捷翻译只在你按下 Option+D 时使用辅助功能权限，用来读取当前前台 App 的选中文本。

    如果当前 App 不支持直接读取选中文本，快捷翻译会临时模拟一次 Command+C 作为兜底，并在读取后恢复原剪贴板内容。

    快捷翻译不会记录键盘输入、不会读取屏幕内容、不会修改其他 App 数据。
    """,
    primaryButtonTitle: "打开系统设置",
    secondaryButtonTitle: "稍后"
  )

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
