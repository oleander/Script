import Foundation

protocol Mutex {
  var queue: DispatchQueue { get }
  func invoke(block: @escaping () -> Void)
}

extension Mutex {
  static func new(queue label: String) -> DispatchQueue {
    return DispatchQueue(label: label, qos: .background, target: .main)
  }

  func invoke(block: @escaping () -> Void) {
    // TODO: Fix this
    // if queue.label == "Buffer" && inTests { block() }
    // else { queue.async { block() } }
    queue.async { block() }
  }

  var inTests: Bool {
    return ProcessInfo.processInfo.environment["TESTS"] != nil
  }
}
