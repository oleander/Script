enum State: UInt8 {
  case neverExecuted = 0b00000000
  case started = 0b10000000
  case terminated = 0b00000100
  case stderrClosed = 0b00000010
  case stdoutClosed = 0b00000001
  case completed = 0b10000111
  case stdClosed = 0b10000011
  // case waitingForStderr = 0b10000101
  // case waitingForStdout = 0b10000110
  case stderrStreaming = 0b01000000
  case stdoutStreaming = 0b00100000
  case published = 0b00010000

  public static func & (lhs: UInt8, rhs: State) -> UInt8 {
    return lhs & rhs.rawValue
  }

  public static func | (lhs: UInt8, rhs: State) -> UInt8 {
    return lhs | rhs.rawValue
  }

  public static func == (lhs: UInt8, rhs: State) -> Bool {
    return lhs == rhs.rawValue
  }
}