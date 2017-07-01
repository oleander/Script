import Foundation

class Handler: Log {
  private var data = Data()
  private let queue = DispatchQueue(label: "Handler", qos: .background, target: .main)
  private weak var handler: FileHandle?
  private var completeCallbacks = [(String) -> Void]()
  private var pieceCallbacks = [(String) -> Void]()
  private var terminationCallbacks = [() -> Void]()
  private var state = CurrentState()
  private var isClosed: Bool { return state.isClosed }
  private var isStream: Bool { return state.isStream }
  internal let id = "Handler"
  private var obs: NSObjectProtocol?
  private let buffer: Buffer

  init(_ handler: FileHandle, delimiter: String) {
    self.handler = handler
    self.buffer = Buffer(withDelimiter: delimiter)
    self.obs = NotificationCenter.default.addObserver(
      forName: .NSFileHandleDataAvailable,
      object: handler,
      queue: .main
    ) { [weak self, weak handler] _ in
      guard let aHandler = handler else { return }
      self?.handleEvent(data: aHandler.availableData)
    }

    self.next()
  }

  public var output: String? {
    if data.isEmpty { return nil }
    if let string = String(data: data, encoding: .utf8) {
      return string
    }
    return nil
  }

  private func next() {
    queue.async { [weak self] in
      self?.handler?.waitForDataInBackgroundAndNotify()
    }
  }

  public func onComplete(block: @escaping (String) -> Void) {
    completeCallbacks.append(block)
  }

  public func onTermination(block: @escaping () -> Void) {
    terminationCallbacks.append(block)
  }

  public func onPiece(block: @escaping (String) -> Void) {
    pieceCallbacks.append(block)
  }

  private func handleEvent(data: Data) {
    if isClosed { return log("Already closed") }

    self.buffer.append(data)
    self.data.append(data)

    if data.isEOF {
      return complete()
    }

    let items = buffer.output
    for output in items {
      for callback in pieceCallbacks {
        broadcast { callback(output) }
      }
    }

    if !items.isEmpty {
      state.update(state: .stream)
    }

    next()
  }

  private func broadcast(block: () -> Void) {
    if !isClosed { block() }
  }

  public func clear() {
    buffer.clearMainBuffer()
  }

  private func complete() {
    log("Handler did finish")

    if isStream {
      for item in buffer.tilTheEnd {
        for callback in pieceCallbacks {
          broadcast { callback(item) }
        }
      }
    }

    if let result = output {
      for callback in completeCallbacks {
        broadcast { callback(result) }
      }
    }

    for callback in terminationCallbacks {
      callback()
    }

    close()
  }

  func close() {
    if isClosed { return log("Handler is already closed") } else { log("Closing handler") }

    handler?.readabilityHandler = nil
    buffer.close()
    state.update(state: .closed)
    NotificationCenter.default.removeObserver(obs!)
  }

  deinit { close() }
}
