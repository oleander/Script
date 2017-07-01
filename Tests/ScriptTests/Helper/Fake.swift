@testable import Script

class FakeScriptable: Scriptable {
  var result = [Std]()
  var pieces = [Std]()
  var stderr: [Script.Failure] = []
  var stdout: [Script.Success] = []

  init() {}

  func scriptDidReceive(success: Script.Success) {
    result.append(.succ(success))
    stdout.append(success)
  }

  func scriptDidReceive(failure: Script.Failure) {
    result.append(.fail(failure))
    stderr.append(failure)
  }

  func scriptDidReceive(piece: Script.Piece) {
    result.append(.piece(piece))
    pieces.append(.piece(piece))
  }
}
