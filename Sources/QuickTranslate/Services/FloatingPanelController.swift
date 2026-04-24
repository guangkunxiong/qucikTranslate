import AppKit
import SwiftUI

@MainActor
final class FloatingPanelController {
  private var panel: NSPanel?

  func show(
    state: FloatingPanelState,
    onStartTranslation: @escaping (String) -> Void = { _ in },
    onCopy: @escaping (String) -> Void
  ) {
    let rootView = FloatingPanelView(
      state: state,
      onStartTranslation: onStartTranslation,
      onCopy: onCopy,
      onClose: { [weak self] in
        self?.close()
      }
    )

    let hostingController = NSHostingController(rootView: rootView)
    let panel = panel ?? makePanel()
    panel.contentViewController = hostingController
    self.panel = panel

    hostingController.view.layoutSubtreeIfNeeded()
    let size = hostingController.view.fittingSize
    panel.setContentSize(NSSize(width: max(size.width, 460), height: max(size.height, 240)))
    position(panel)
    panel.makeKeyAndOrderFront(nil)
  }

  func close() {
    panel?.orderOut(nil)
  }

  private func makePanel() -> NSPanel {
    let panel = KeyableFloatingPanel(
      contentRect: NSRect(x: 0, y: 0, width: 460, height: 260),
      styleMask: [.nonactivatingPanel, .titled, .utilityWindow, .fullSizeContentView],
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
    panel.standardWindowButton(.closeButton)?.isHidden = true
    panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
    panel.standardWindowButton(.zoomButton)?.isHidden = true
    return panel
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
