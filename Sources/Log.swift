// import LoggerAPI
// import HeliumLogger

protocol Log {
  var id: Int { get }
  func log(_ msg: String)
  func err(_ msg: String)
}

extension Log {
  internal func log(_ msg: String) {
    // LoggerAPI.Log.warning("[\(id)] " + msg)
    print("[LOG\(id)] " + msg)
  }

  internal func err(_ msg: String) {
    print("[ERR:\(id)] " + msg)
    // LoggerAPI.Log.error("[\(id)] " + msg)
  }
}