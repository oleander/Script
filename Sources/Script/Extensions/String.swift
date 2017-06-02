import Foundation

extension String {
  func toData() -> Data {
    return data(using: .utf8)!
  }

  func inspected() -> String {
    return "\"" + replace("\n", "↵") + "\""
  }

  func replace(_ string: String, _ with: String) -> String {
    return replacingOccurrences(of: string, with: with, options: .literal, range: nil)
  }

  func remove(_ what: String) -> String {
    return replace(what, "")
  }
}
