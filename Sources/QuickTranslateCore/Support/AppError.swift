import Foundation

public enum AppError: Error, LocalizedError, Equatable {
  case noSelectedText
  case missingAPIKey
  case missingModel
  case missingAccessibilityPermission
  case hotKeyRegistrationFailed(String)
  case requestFailed(String)

  public var errorDescription: String? {
    switch self {
    case .noSelectedText:
      "未检测到选中文本。"
    case .missingAPIKey:
      "请先在设置中配置 API Key。"
    case .missingModel:
      "请先在设置中配置模型。"
    case .missingAccessibilityPermission:
      "请在系统设置中为快捷翻译开启辅助功能权限。"
    case let .hotKeyRegistrationFailed(message):
      "全局快捷键注册失败：\(message)"
    case let .requestFailed(message):
      message
    }
  }
}
