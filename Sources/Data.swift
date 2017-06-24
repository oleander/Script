import Foundation

extension Data {
  var string: String? {
    if isEmpty { return nil }
    guard let string = String(data: self, encoding: .utf8) else {
      return nil
    }

    return string
  }

  var isEOF: Bool {
    return count == 0
  }
}