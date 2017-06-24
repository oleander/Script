extension String {
  func replace(_ this: String, _ with: String) -> String {
    return replacingOccurrences(of: this, with: with, options: .literal, range: nil)
  }

  var inspected: String {
    return "\"" + replace("\n", "↵") + "\""
  }

  func remove(_ what: String) -> String {
    return replace(what, "")
  }
}
