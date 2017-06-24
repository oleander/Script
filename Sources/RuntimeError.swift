enum RuntimeError: Error {
  case alreadyStarted
  case notRunning
  case alreadyTerminated
  case alreadyCompleted
}
