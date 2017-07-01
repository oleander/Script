func + (lhs: [String: String], rhs: [String: String]) -> [String: String] {
  var output = [String: String]()

  for (key, value) in lhs {
    output[key] = value
  }

  for (key, value) in rhs {
    output[key] = value
  }

  return output
}
