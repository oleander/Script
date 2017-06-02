public protocol Scriptable: class {
  func scriptDidReceive(success: Script.Success)
  func scriptDidReceive(failure: Script.Failure)
}
