import Foundation

class Buffer: Mutex, Log {
  private static let defaultDelimiter = "~~~\n"
  internal let queue = Buffer.new(queue: "Buffer")
  private var store = Data()
  private var rest = Data()
  private var isEmpty: Bool { return store.isEmpty }
  private var isClosed = false
  private var isStreamable = false
  private let delimiter: String
  internal let id: Int

  init(withDelimiter delimiter: String = Buffer.defaultDelimiter, id: Int = -1) {
    self.delimiter = delimiter
    self.id = id
  }

  public func append(_ data: Data) {
    invoke { [weak self] in
      guard let this = self else { return }
      guard !this.isClosed else { return }
      this.store.append(data)
      this.rest.append(data)
    }
  }

  public func toString() -> String {
    return store.string ?? ""
  }

  public func close()  {
    isClosed = true
  }

  public var string: String? {
    return store.string
  }

  public var everything: String? {
    return rest.string
  }

  public func output(block: @escaping ([String]) -> Void) {
    invoke { [weak self] in
      guard let this = self else { return print("[Log] Buffer has been deallocated") }
      guard let items = try? this.nonThreadSafeOutput() else {
        return this.err("Could not get items from buffer")
      }

      block(items)
    }
  }

  public func tilTheEnd(block: @escaping ([String]) -> Void) {
    invoke { [weak self] in
      guard let this = self else { return print("[LOG] Buffer has been deallocated") }
      guard let rem = this.store.string else { return }
      guard !rem.isEmpty else { return }
      block([rem])
    }
  }

  private func nonThreadSafeOutput() throws -> [String] {
    if isClosed { throw BufferError.alreadyClosed }
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
    let newRest = try nonThreadSafeOutput()
    let ress = [newOutput] + newRest

    guard isClosed else { return ress }
    guard let rem = self.store.string else { return ress }
    return ress + [rem]
  }
}
