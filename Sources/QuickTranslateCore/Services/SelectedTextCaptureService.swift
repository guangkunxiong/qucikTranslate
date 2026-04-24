import AppKit
import ApplicationServices
import Foundation

@MainActor
public final class SelectedTextCaptureService {
  private let clipboardService: ClipboardService

  public init(clipboardService: ClipboardService = ClipboardService()) {
    self.clipboardService = clipboardService
  }

  public func captureSelectedText() async -> String {
    if let accessibilityText = readAccessibilitySelectedText(), !accessibilityText.isEmpty {
      return accessibilityText
    }

    return await copySelectedTextFallback()
  }

  private func readAccessibilitySelectedText() -> String? {
    let systemWideElement = AXUIElementCreateSystemWide()
    var focusedValue: CFTypeRef?
    let focusedStatus = AXUIElementCopyAttributeValue(
      systemWideElement,
      kAXFocusedUIElementAttribute as CFString,
      &focusedValue
    )

    guard
      focusedStatus == .success,
      let focusedValue
    else {
      return nil
    }

    let focusedElement = focusedValue as! AXUIElement
    var selectedValue: CFTypeRef?
    let selectedStatus = AXUIElementCopyAttributeValue(
      focusedElement,
      kAXSelectedTextAttribute as CFString,
      &selectedValue
    )

    guard selectedStatus == .success else {
      return nil
    }

    return selectedValue as? String
  }

  private func copySelectedTextFallback() async -> String {
    let snapshot = clipboardService.snapshot()
    sendCopyShortcut()

    try? await Task.sleep(nanoseconds: 150_000_000)
    let copiedText = clipboardService.readString()
    clipboardService.restore(snapshot)
    return copiedText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func sendCopyShortcut() {
    let source = CGEventSource(stateID: .combinedSessionState)
    let keyCodeForC: CGKeyCode = 8
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCodeForC, keyDown: true)
    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCodeForC, keyDown: false)
    keyDown?.flags = .maskCommand
    keyUp?.flags = .maskCommand
    keyDown?.post(tap: .cghidEventTap)
    keyUp?.post(tap: .cghidEventTap)
  }
}
