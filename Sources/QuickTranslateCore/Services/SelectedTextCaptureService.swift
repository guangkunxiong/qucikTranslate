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
    let changeCount = clipboardService.changeCount
    sendCopyShortcut()

    let copiedText = await waitForCopiedText(after: changeCount)
    clipboardService.restore(snapshot)
    return copiedText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func waitForCopiedText(after changeCount: Int) async -> String {
    var didChange = false

    for _ in 0..<14 {
      try? await Task.sleep(nanoseconds: 50_000_000)

      if clipboardService.changeCount != changeCount {
        didChange = true
      }

      guard didChange else {
        continue
      }

      let copiedText = clipboardService.readString()
      if !copiedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return copiedText
      }
    }

    return ""
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
