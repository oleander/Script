@testable import Script

extension Script.Failure: Equatable {
  public static func == (lhs: Script.Failure, rhs: Script.Failure) -> Bool {
    switch (lhs, rhs) {
    case (.syntaxError, .syntaxError):
      return true
    case (.uncaughtSignal, .uncaughtSignal):
      return true
    case (.genericMixed, .genericMixed):
      return true
    case (.generic, .generic):
      return true
    case (.pathNotFound, .pathNotFound):
      return true
    case (.notExecutable, .notExecutable):
      return true
    case (.manualTermination, .manualTermination):
      return true
    case (.withZeroExitCode, .withZeroExitCode):
      return true
    case (.withStdout, .withStdout):
      return true
    case (.withFallback, .withFallback):
      return true
    default:
      return false
    }
  }
}
