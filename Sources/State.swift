enum State: UInt8 {
  case neverExecuted = 0b00000000
  case started = 0b10000000
  case completed       = 0b00000111
  case stdoutCompleted = 0b00000001
  case stderrCompleted = 0b00000010
  case terminated      = 0b00000100
  case manualTermination = 0b00001000
  case closed = 0b01000000
  case stream = 0b00100000
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
