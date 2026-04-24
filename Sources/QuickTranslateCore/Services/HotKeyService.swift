import Carbon
import Foundation

public enum HotKeyServiceError: Error {
  case installHandlerFailed(OSStatus)
  case registerFailed(OSStatus)
}

public final class HotKeyService: @unchecked Sendable {
  private let signature = OSType(0x5154_524E)
  private var hotKeyRef: EventHotKeyRef?
  private var eventHandlerRef: EventHandlerRef?
  private var callback: (@MainActor () -> Void)?

  public init() {}

  deinit {
    unregister()
  }

  public func register(_ hotKey: HotKey, callback: @escaping @MainActor () -> Void) throws {
    unregister()
    self.callback = callback

    var eventSpec = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard),
      eventKind: UInt32(kEventHotKeyPressed)
    )

    let handlerStatus = InstallEventHandler(
      GetApplicationEventTarget(),
      { _, _, userData in
        guard let userData else {
          return noErr
        }

        let service = Unmanaged<HotKeyService>.fromOpaque(userData).takeUnretainedValue()
        Task { @MainActor in
          service.handleHotKey()
        }
        return noErr
      },
      1,
      &eventSpec,
      Unmanaged.passUnretained(self).toOpaque(),
      &eventHandlerRef
    )

    guard handlerStatus == noErr else {
      throw HotKeyServiceError.installHandlerFailed(handlerStatus)
    }

    let hotKeyID = EventHotKeyID(signature: signature, id: 1)
    let registerStatus = RegisterEventHotKey(
      hotKey.keyCode,
      hotKey.carbonModifiers,
      hotKeyID,
      GetApplicationEventTarget(),
      0,
      &hotKeyRef
    )

    guard registerStatus == noErr else {
      throw HotKeyServiceError.registerFailed(registerStatus)
    }
  }

  public func unregister() {
    if let hotKeyRef {
      UnregisterEventHotKey(hotKeyRef)
      self.hotKeyRef = nil
    }

    if let eventHandlerRef {
      RemoveEventHandler(eventHandlerRef)
      self.eventHandlerRef = nil
    }

    callback = nil
  }

  @MainActor
  private func handleHotKey() {
    callback?()
  }
}
