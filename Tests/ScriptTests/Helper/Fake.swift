@testable import Script

class FakeScriptable: Scriptable {
  var result = [Std]()

  init() {}

  func scriptDidReceive(success: Script.Success) {
    result.append(.succ(success))
  }

  func scriptDidReceive(failure: Script.Failure) {
    result.append(.fail(failure))
  }
}