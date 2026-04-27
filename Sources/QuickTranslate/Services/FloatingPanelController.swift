import AppKit
import QuickTranslateCore
import SwiftUI

@MainActor
final class FloatingPanelController {
  private let panelCornerRadius: CGFloat = 22
  private let defaultContentSize = NSSize(width: 560, height: 320)
  private var panel: NSPanel?
  private var pinState = FloatingPanelPinState()
  private var localMouseMonitor: Any?
  private var globalMouseMonitor: Any?

  func show(
    state: FloatingPanelState,
    displayedLanguages: [String],
    onStartTranslation: @escaping (TranslationDraft) -> Void = { _ in },
    onCopy: @escaping (String) -> Void,
    onSpeak: @escaping (String, String?) -> Void = { _, _ in }
  ) {
    let rootView = FloatingPanelView(
      state: state,
      displayedLanguages: displayedLanguages,
      isPinned: pinState.isPinned,
      onPinChanged: { [weak self] isPinned in
        self?.setPinned(isPinned)
      },
      onStartTranslation: onStartTranslation,
      onCopy: onCopy,
      onSpeak: onSpeak,
      onClose: { [weak self] in
        self?.close()
      }
    )

    let hostingController = NSHostingController(rootView: rootView)
    hostingController.view.wantsLayer = true
    hostingController.view.layer?.cornerRadius = panelCornerRadius
    hostingController.view.layer?.masksToBounds = true
    hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor

    let panel = panel ?? makePanel()
    let shouldResetSize = !panel.isVisible
    let existingFrame = panel.frame
    panel.contentViewController = hostingController
    panel.contentView?.wantsLayer = true
    panel.contentView?.layer?.cornerRadius = panelCornerRadius
    panel.contentView?.layer?.masksToBounds = true
    panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
    self.panel = panel

    hostingController.view.layoutSubtreeIfNeeded()
    if shouldResetSize {
      let defaultSize = preferredDefaultContentSize()
      hostingController.view.setFrameSize(defaultSize)
      hostingController.view.layoutSubtreeIfNeeded()
      let size = hostingController.view.fittingSize
      panel.setContentSize(preferredContentSize(for: panel, fittingSize: size))
      position(panel)
    } else {
      panel.setFrame(existingFrame, display: true)
    }
    installOutsideClickMonitors()
    panel.makeKeyAndOrderFront(nil)
  }

  func close() {
    pinState = FloatingPanelPinState()
    panel?.orderOut(nil)
    removeOutsideClickMonitors()
  }

  private func makePanel() -> NSPanel {
    let panel = KeyableFloatingPanel(
      contentRect: NSRect(x: 0, y: 0, width: 560, height: 320),
      styleMask: [.nonactivatingPanel, .borderless, .resizable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    panel.level = .floating
    panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
    panel.isReleasedWhenClosed = false
    panel.isMovableByWindowBackground = false
    panel.titleVisibility = .hidden
    panel.titlebarAppearsTransparent = true
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = false
    panel.minSize = NSSize(width: 460, height: 280)
    panel.standardWindowButton(.closeButton)?.isHidden = true
    panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
    panel.standardWindowButton(.zoomButton)?.isHidden = true
    return panel
  }

  private func setPinned(_ isPinned: Bool) {
    if pinState.isPinned != isPinned {
      pinState.toggle()
    }
  }

  private func installOutsideClickMonitors() {
    guard localMouseMonitor == nil, globalMouseMonitor == nil else {
      return
    }

    localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
      guard let self else {
        return event
      }

      MainActor.assumeIsolated {
        self.handleLocalMouseDown(event)
      }
      return event
    }

    globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
      Task { @MainActor in
        self?.handleGlobalMouseDown()
      }
    }
  }

  private func removeOutsideClickMonitors() {
    if let localMouseMonitor {
      NSEvent.removeMonitor(localMouseMonitor)
      self.localMouseMonitor = nil
    }

    if let globalMouseMonitor {
      NSEvent.removeMonitor(globalMouseMonitor)
      self.globalMouseMonitor = nil
    }
  }

  private func handleLocalMouseDown(_ event: NSEvent) {
    guard shouldCloseForOutsideClick else {
      return
    }

    if event.window !== panel {
      close()
    }
  }

  private func handleGlobalMouseDown() {
    guard shouldCloseForOutsideClick, let panel else {
      return
    }

    if !panel.frame.contains(NSEvent.mouseLocation) {
      close()
    }
  }

  private var shouldCloseForOutsideClick: Bool {
    guard let panel, panel.isVisible else {
      return false
    }

    return !pinState.isPinned
  }

  private func preferredContentSize(for panel: NSPanel, fittingSize: NSSize) -> NSSize {
    let screen = screenForPanel()
    let maxHeight = max(280, screen.visibleFrame.height - 72)
    let width = preferredDefaultContentSize().width

    return NSSize(
      width: width,
      height: min(max(fittingSize.height, 320), maxHeight)
    )
  }

  private func preferredDefaultContentSize() -> NSSize {
    let screen = screenForPanel()
    let maxWidth = max(460, screen.visibleFrame.width - 72)
    return NSSize(
      width: min(defaultContentSize.width, maxWidth),
      height: defaultContentSize.height
    )
  }

  private func position(_ panel: NSPanel) {
    let screen = screenForPanel()
    let visibleFrame = screen.visibleFrame
    let frame = panel.frame
    let margin: CGFloat = 18
    let origin = NSPoint(
      x: visibleFrame.maxX - frame.width - margin,
      y: visibleFrame.maxY - frame.height - margin
    )
    panel.setFrameOrigin(origin)
  }

  private func screenForPanel() -> NSScreen {
    let mouse = NSEvent.mouseLocation
    return NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main ?? NSScreen.screens[0]
  }
}

private final class KeyableFloatingPanel: NSPanel {
  override var canBecomeKey: Bool {
    true
  }
}
