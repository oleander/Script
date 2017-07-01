import Foundation

public typealias Env = [String: String]
public class Script: Log {
  private var execution: Execution?
  private let path: String
  private let args: [String]
  private let env: Env
  private let bashPath = "/bin/bash"
  public weak var delegate: Scriptable?
  internal let id: String
  private let queue = DispatchQueue(label: "Script", qos: .background, target: .main)

  public convenience init(path: String, args: [String] = [], env: Env = Env(), delegate: Scriptable, autostart: Bool = false) {
    self.init(path: path, args: args, env: env)
    self.delegate = delegate
    if autostart { start() }
  }

  public init(path: String, args: [String] = [], env: Env = Env()) {
    self.env = Script.env(from: env)
    self.path = path
    self.args = args
    self.id = path.split("/").last ?? "??"
  }

  public func stop() {
    execution?.terminate()
  }

  public func restart() {
    stop()
    start()
  }

  public func start() {
    stop()
    setup()
    execution?.run()
  }

  private func succeeded(_ result: Success) {
    guard let delegate = delegate else { return }
    log("Succeeded with output: \(result)")
    delegate.scriptDidReceive(success: result)
  }

  private func failed(_ message: Failure) {
    guard let delegate = self.delegate else { return }
    err("Failed with error message: '\(message)'")
    delegate.scriptDidReceive(failure: message)
  }

  public var isRunning: Bool {
    return execution?.isRunning ?? false
  }

  public func clear() {
    execution?.clear()
  }

  private func setup() {
    execution = Execution(path: path, args: args, env: env, id: id)

    execution?.onStreamedSuccess { [weak self] output in
      self?.queue.async { [weak self] in
        self?.log("OnStreamedSuccess: \(output.inspected)")
        self?.delegate?.scriptDidReceive(piece: .succeeded(output))
      }
    }

    execution?.onStreamedFailure { [weak self] failure in
      self?.queue.async { [weak self] in
        self?.err("OnStreamedFailure: \(failure)")
        self?.delegate?.scriptDidReceive(piece: .failed(failure))
      }
    }

    execution?.onFailure { [weak self] failure in
      if case .manualTermination = failure { return }
      self?.queue.async { [weak self] in
        self?.err("OnFailure: \(failure)")
        self?.failed(failure)
      }
    }

    execution?.onSuccess { [weak self] result in
      self?.queue.async { [weak self] in
        self?.log("Success: \(result)")
        self?.succeeded(result)
      }
    }
  }

  static private func env(from env: Env) -> Env {
    return ProcessInfo.processInfo.environment + env
  }
}
