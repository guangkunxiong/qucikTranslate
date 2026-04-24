import Foundation

public final class APIKeyStore {
  private let userDefaults: UserDefaults
  private let key: String

  public init(
    userDefaults: UserDefaults = .standard,
    key: String = "quickTranslate.apiKey.v1"
  ) {
    self.userDefaults = userDefaults
    self.key = key
  }

  public func saveAPIKey(_ apiKey: String) {
    userDefaults.set(apiKey, forKey: key)
  }

  public func loadAPIKey() -> String {
    userDefaults.string(forKey: key) ?? ""
  }

  public func deleteAPIKey() {
    userDefaults.removeObject(forKey: key)
  }
}
