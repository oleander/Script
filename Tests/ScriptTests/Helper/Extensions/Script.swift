@testable import Script

extension Script.Result: Equatable {
  public static func == (lhs: Script.Result, rhs: Script.Result) -> Bool {
    switch (lhs, rhs) {
    case let (.failed(f1), .failed(f2)):
      return f1 == f2
    case let (.succeeded(s1), .succeeded(s2)):
      return s1 == s2
    default:
      return false
    }
  }
}