import Foundation

extension Script {
  public enum Failure {
    case syntaxError(String?, Int)
    case uncaughtSignal(String?, Int)
    case genericMixed(String?, String?, Int)
    case generic(String?, Int)
    case pathNotFound(String?, Int)
    case notExecutable(String?, Int)
    case manualTermination(String?, Int)
    case withZeroExitCode(String?)
    case withStdout(String?, Int)
    case withFallback(Process.TerminationReason, Int, String?, String?)
  }
}
