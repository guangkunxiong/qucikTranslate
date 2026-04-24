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
      "No selected text was detected."
    case .missingAPIKey:
      "Configure an API key before translating."
    case .missingModel:
      "Configure a model before translating."
    case .missingAccessibilityPermission:
      "Enable Accessibility permission for Quick Translate."
    case let .hotKeyRegistrationFailed(message):
      "Global shortcut registration failed: \(message)"
    case let .requestFailed(message):
      message
    }
  }
}
