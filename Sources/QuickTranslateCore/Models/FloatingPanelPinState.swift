import Foundation

public struct FloatingPanelPinState: Equatable, Sendable {
  public private(set) var isPinned: Bool

  public init(isPinned: Bool = false) {
    self.isPinned = isPinned
  }

  public mutating func toggle() {
    isPinned.toggle()
  }
}
