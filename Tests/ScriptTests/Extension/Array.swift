extension Array {
  func get(_ index: Int) -> Element? {
    if index >= count { return nil }
    return self[index]
  }
}
