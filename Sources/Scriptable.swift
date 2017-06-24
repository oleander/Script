public protocol Scriptable: class {
  func scriptDidReceive(success: Script.Success)
  func scriptDidReceive(piece: Script.Piece)
  func scriptDidReceive(failure: Script.Failure)
}
