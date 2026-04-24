import AppKit
import Foundation

public struct PasteboardSnapshot {
  struct Item {
    let values: [(NSPasteboard.PasteboardType, Data)]
  }

  let items: [Item]
}

public final class ClipboardService {
  private let pasteboard: NSPasteboard

  public init(pasteboard: NSPasteboard = .general) {
    self.pasteboard = pasteboard
  }

  public func snapshot() -> PasteboardSnapshot {
    let items = pasteboard.pasteboardItems ?? []
    let snapshots = items.map { item in
      let values = item.types.compactMap { type -> (NSPasteboard.PasteboardType, Data)? in
        guard let data = item.data(forType: type) else {
          return nil
        }
        return (type, data)
      }
      return PasteboardSnapshot.Item(values: values)
    }
    return PasteboardSnapshot(items: snapshots)
  }

  public func readString() -> String {
    pasteboard.string(forType: .string) ?? ""
  }

  public var changeCount: Int {
    pasteboard.changeCount
  }

  public func restore(_ snapshot: PasteboardSnapshot) {
    pasteboard.clearContents()
    let items = snapshot.items.map { snapshotItem in
      let item = NSPasteboardItem()
      for (type, data) in snapshotItem.values {
        item.setData(data, forType: type)
      }
      return item
    }
    pasteboard.writeObjects(items)
  }
}
