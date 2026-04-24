import AppKit
import SwiftUI

@MainActor
final class FloatingPanelController {
  private var panel: NSPanel?

  func show(
    state: FloatingPanelState,
    onCopy: @escaping (String) -> Void
  ) {
    let rootView = FloatingPanelView(
      state: state,
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
    panel.setContentSize(NSSize(width: max(size.width, 380), height: max(size.height, 120)))
    position(panel)
    panel.orderFrontRegardless()
  }

  func close() {
    panel?.orderOut(nil)
  }

  private func makePanel() -> NSPanel {
    let panel = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: 380, height: 180),
      styleMask: [.nonactivatingPanel, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    panel.level = .floating
    panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
    panel.isReleasedWhenClosed = false
    panel.isMovableByWindowBackground = true
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = true
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
