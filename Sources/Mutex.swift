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
    if Thread.isMainThread { return block() }
    queue.async { block() }
  }
}
