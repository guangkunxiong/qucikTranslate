import Foundation

public struct CachedSecretValue: Equatable, Sendable {
  public private(set) var value: String
  public private(set) var isLoaded: Bool

  public init(value: String = "", isLoaded: Bool = false) {
    self.value = value
    self.isLoaded = isLoaded
  }

  public func shouldPersist(_ newValue: String) -> Bool {
    !isLoaded || newValue != value
  }

  public mutating func markLoaded(_ value: String) {
    self.value = value
    isLoaded = true
  }

  public mutating func markSaved(_ value: String) {
    self.value = value
    isLoaded = true
  }
}
