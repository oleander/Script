@testable import Scripter

extension Script.Success: Equatable {
  public static func == (lhs: Script.Success, rhs: Script.Success) -> Bool {
    switch (lhs, rhs) {
    case (.withZeroExitCode, .withZeroExitCode):
      return true
    default:
      return false
    }
  }
}
