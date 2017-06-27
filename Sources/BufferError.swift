enum BufferError: Error {
  case alreadyClosed
  case appendingEOF
  case isStream
}
