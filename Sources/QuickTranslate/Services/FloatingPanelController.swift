import AppKit
import QuickTranslateCore
import SwiftUI

@MainActor
final class FloatingPanelController {
  private var panel: NSPanel?
  private var pinState = FloatingPanelPinState()
  private var localMouseMonitor: Any?
  private var globalMouseMonitor: Any?

  func show(
    state: FloatingPanelState,
    onStartTranslation: @escaping (String) -> Void = { _ in },
    onCopy: @escaping (String) -> Void,
    onSpeak: @escaping (String, String?) -> Void = { _, _ in }
  ) {
    let rootView = FloatingPanelView(
      state: state,
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
    let panel = panel ?? makePanel()
    let shouldResetSize = !panel.isVisible
    let existingFrame = panel.frame
    panel.contentViewController = hostingController
    self.panel = panel

    hostingController.view.layoutSubtreeIfNeeded()
    if shouldResetSize {
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
      contentRect: NSRect(x: 0, y: 0, width: 620, height: 500),
      styleMask: [.nonactivatingPanel, .titled, .utilityWindow, .resizable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    panel.level = .floating
    panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
    panel.isReleasedWhenClosed = false
    panel.isMovableByWindowBackground = true
    panel.titleVisibility = .hidden
    panel.titlebarAppearsTransparent = true
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = true
    panel.minSize = NSSize(width: 520, height: 360)
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
    let maxHeight = max(260, screen.visibleFrame.height - 72)
    let maxWidth = max(520, screen.visibleFrame.width - 72)

    return NSSize(
      width: min(max(fittingSize.width, 620), maxWidth),
      height: min(max(fittingSize.height, 500), maxHeight)
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
