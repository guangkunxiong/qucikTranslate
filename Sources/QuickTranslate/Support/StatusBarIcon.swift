import AppKit

enum StatusBarIcon {
  static let image: NSImage = {
    let image = Bundle.module.url(forResource: "StatusBarIcon", withExtension: "png")
      .flatMap(NSImage.init(contentsOf:)) ?? fallbackImage()
    image.isTemplate = true
    image.size = NSSize(width: 18, height: 18)
    return image
  }()

  private static func fallbackImage() -> NSImage {
    let image = NSImage(
      systemSymbolName: "character.book.closed",
      accessibilityDescription: "快捷翻译"
    ) ?? NSImage(size: NSSize(width: 18, height: 18))
    image.isTemplate = true
    image.size = NSSize(width: 18, height: 18)
    return image
  }
}
