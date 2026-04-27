import AppKit
import SwiftUI

struct EditableSourceTextView: NSViewRepresentable {
  @Binding var text: String
  let onSubmit: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text)
  }

  func makeNSView(context: Context) -> NSScrollView {
    let scrollView = NSScrollView()
    scrollView.drawsBackground = false
    scrollView.hasVerticalScroller = true
    scrollView.borderType = .noBorder

    let textView = SubmittingTextView()
    textView.string = text
    textView.delegate = context.coordinator
    textView.onSubmit = onSubmit
    textView.font = .preferredFont(forTextStyle: .body)
    textView.textColor = .white
    textView.insertionPointColor = .white
    textView.drawsBackground = false
    textView.isRichText = false
    textView.allowsUndo = true
    textView.isVerticallyResizable = true
    textView.isHorizontallyResizable = false
    textView.autoresizingMask = [.width]
    textView.textContainer?.widthTracksTextView = true
    textView.textContainerInset = NSSize(width: 0, height: 2)

    scrollView.documentView = textView
    context.coordinator.textView = textView

    DispatchQueue.main.async {
      textView.window?.makeFirstResponder(textView)
    }

    return scrollView
  }

  func updateNSView(_ scrollView: NSScrollView, context: Context) {
    guard let textView = scrollView.documentView as? SubmittingTextView else {
      return
    }

    textView.onSubmit = onSubmit
    textView.textColor = .white
    textView.insertionPointColor = .white
    if textView.string != text {
      textView.string = text
    }
  }

  final class Coordinator: NSObject, NSTextViewDelegate {
    @Binding var text: String
    weak var textView: NSTextView?

    init(text: Binding<String>) {
      _text = text
    }

    func textDidChange(_ notification: Notification) {
      guard let textView = notification.object as? NSTextView else {
        return
      }

      text = textView.string
    }
  }
}

private final class SubmittingTextView: NSTextView {
  var onSubmit: (() -> Void)?

  override func keyDown(with event: NSEvent) {
    if event.keyCode == 36, !event.modifierFlags.contains(.shift) {
      onSubmit?()
      return
    }

    super.keyDown(with: event)
  }
}
