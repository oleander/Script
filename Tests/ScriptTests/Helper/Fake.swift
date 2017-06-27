@testable import Script

class FakeScriptable: Scriptable {
  var result = [Std]()
  var pieces = [Std]()

  init() {}

  func scriptDidReceive(success: Script.Success) {
    result.append(.succ(success))
  }

  func scriptDidReceive(failure: Script.Failure) {
    result.append(.fail(failure))
  }

  func scriptDidReceive(piece: Script.Piece) {
    result.append(.piece(piece))
    pieces.append(.piece(piece))
  }
}
