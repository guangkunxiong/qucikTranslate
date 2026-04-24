import Combine
import Foundation

public final class SettingsStore: ObservableObject {
  private let userDefaults: UserDefaults
  private let key = "quickTranslate.settings.v1"

  @Published public private(set) var settings: AppSettings

  public init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults

    if
      let data = userDefaults.data(forKey: key),
      let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
    {
      self.settings = decoded
    } else {
      self.settings = .defaults
    }
  }

  public func save(_ settings: AppSettings) {
    self.settings = settings
    if let data = try? JSONEncoder().encode(settings) {
      userDefaults.set(data, forKey: key)
    }
  }
}
