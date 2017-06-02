extension Array where Element: Equatable {
  func has(_ el: Element) -> Bool {
    return contains(el)
  }
}
