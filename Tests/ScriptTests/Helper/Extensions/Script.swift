@testable import Script

extension Script {
  enum Result {
    case success(Success)
    case failure(Failure)
  }
}