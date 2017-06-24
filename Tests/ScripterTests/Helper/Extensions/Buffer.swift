@testable import Scripter

extension Buffer {
  func append(string: String) {
    do {
      try append(string.data(using: .utf8)!)
    } catch {
      print("[ERROR] Could not append string")
    }
  }
}