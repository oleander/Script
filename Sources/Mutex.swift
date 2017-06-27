import Foundation
import Async

protocol Mutex {
  var queue: DispatchQueue { get }
  func invoke(block: @escaping () -> Void)
}

extension Mutex {
  static func new(queue label: String, qos: DispatchQoS = .utility) -> DispatchQueue {
    return DispatchQueue(label: label, qos: qos, target: .main)
  }

  func invoke(block: @escaping () -> Void) {
    if Thread.isMainThread { return block() }
    queue.async { block() }
    // Async.custom(queue: queue) { block() }
  }
}
