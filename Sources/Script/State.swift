import Foundation

extension Script {
  enum ScriptState {
    case idle
    case finished
    case eof
    case executing
    case stopped
    case streaming
    case terminated(Process.TerminationReason, Int)
  }
}