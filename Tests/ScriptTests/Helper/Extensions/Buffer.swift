@testable import Script

extension Buffer {
  func append(string: String) {
    append(string.data(using: .utf8)!)
  }
}