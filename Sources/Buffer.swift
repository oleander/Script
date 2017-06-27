import Foundation

class Buffer {
  private static let defaultDelimiter = "~~~\n"
  private var store = Data()
  private var rest = Data()
  private var isEmpty: Bool { return store.isEmpty }
  private var isClosed = false
  private var isStreamable = false
  private let delimiter: String

  public var isStream = false

  init(withDelimiter delimiter: String = Buffer.defaultDelimiter, id: Int = -1) {
    self.delimiter = delimiter
  }

  public func append(_ data: Data) {
    store.append(data)
    // TODO
    // rest.append(data)
  }

  public func toString() -> String {
    return store.string ?? ""
  }

  public func clearMainBuffer() {
    rest = Data()
  }

  public func close() {
    isClosed = true
  }

  public var string: String? {
    return store.string
  }

  public func everything() throws -> String? {
    if isStream { throw BufferError.isStream }
    return rest.string
  }

  public var tilTheEnd: [String] {
    if store.isEmpty { return [] }
    guard let remaining = store.string else { return [] }
    if remaining.isEmpty { return [] }
    return [remaining]
  }

  public var output: [String] {
    return recursiveOutput()
  }

  private func recursiveOutput() -> [String] {
    if isEmpty { return [] }

    guard var newString = string else { return [] }
    guard let delRange = newString.range(of: delimiter) else { return [] }
    let resultRange = Range(newString.startIndex..<delRange.upperBound)
    let newOutput = newString.substring(to: delRange.upperBound).replace(delimiter, "")
    newString.removeSubrange(resultRange)

    guard let newStore = newString.data(using: .utf8) else {
      return []
    }

    store = newStore
    let items = [newOutput] + recursiveOutput()

    guard isClosed else { return items }
    guard let remaining = store.string else { return items }
    return items + [remaining]
  }
}
