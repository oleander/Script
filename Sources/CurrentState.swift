struct CurrentState {
  private var state = State.neverExecuted.rawValue

  public var isCompleted: Bool {
    return has(.completed)
  }

  public var isStarted: Bool {
    return has(.started)
  }

  public var isStderrClosed: Bool {
    return has(.stderrClosed)
  }

  public var isStdoutStreaming: Bool {
    return has(.stdoutStreaming)
  }

  public var isStderrStreaming: Bool {
    return has(.stderrStreaming)
  }

  public var isPublished: Bool {
    return has(.published)
  }

  public var isStdoutClosed: Bool {
    return has(.stdoutClosed)
  }

  public var isTerminated: Bool {
    return has(.terminated)
  }

  public mutating func update(state with: State) {
    state = state | with
  }

  private func has(_ isState: State) -> Bool {
    return (state & isState) == isState
  }
}
