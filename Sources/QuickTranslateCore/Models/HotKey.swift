import Foundation

public struct HotKey: Codable, Equatable, Sendable {
  public struct Modifiers: OptionSet, Codable, Equatable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }

    public static let option = Modifiers(rawValue: 1 << 0)
  }

  public var key: String
  public var keyCode: UInt32
  public var modifiers: Modifiers

  public init(key: String, keyCode: UInt32, modifiers: Modifiers) {
    self.key = key
    self.keyCode = keyCode
    self.modifiers = modifiers
  }

  public static let optionD = HotKey(key: "D", keyCode: 2, modifiers: [.option])

  public var displayString: String {
    var parts: [String] = []
    if modifiers.contains(.option) {
      parts.append("Option")
    }
    parts.append(key.uppercased())
    return parts.joined(separator: "+")
  }

  public static func parse(_ value: String) throws -> HotKey {
    let normalized = value
      .replacingOccurrences(of: " ", with: "")
      .lowercased()

    if normalized == "option+d" || normalized == "alt+d" {
      return .optionD
    }

    throw HotKeyParseError.unsupportedShortcut(value)
  }
}

public enum HotKeyParseError: Error, Equatable {
  case unsupportedShortcut(String)
}
