extension Script {
  public enum Piece: Equatable {
    case succeeded(String)
    case failed(String)

    public static func == (lhs: Piece, rhs: Piece) -> Bool {
      switch (lhs, rhs) {
      case let (.failed(f1), .failed(f2)):
        return f1 == f2
      case let (.succeeded(s1), .succeeded(s2)):
        return s1 == s2
      default:
        return false
      }
    }

  }
}
