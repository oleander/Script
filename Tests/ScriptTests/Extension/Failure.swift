@testable import Script

extension Script.Failure: Equatable {
  public static func == (lhs: Script.Failure, rhs: Script.Failure) -> Bool {
    switch (lhs, rhs) {
    case (.terminated, .terminated):
      return true
    case (.notExec, .notExec):
      return true
    case (.notFound, .notFound):
      return true
    case (.misuse, .misuse):
      return true
    case (.exit, .exit):
      return true
    case (.crash, .crash):
      return true
    default:
      return false
    }
  }
}