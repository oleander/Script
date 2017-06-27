struct CurrentState {
  private var state = State.neverExecuted.rawValue

  public var isCompleted: Bool {
    return has(.completed)
  }

  public var isStarted: Bool {
    return has(.started)
  }

  public var isManuallyTerminated: Bool {
    return has(.manualTermination)
  }

  public var isPublished: Bool {
    return has(.published)
  }

  public var isClosed: Bool {
    return has(.closed)
  }

  public var isStream: Bool {
    return has(.stream)
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
