import Foundation

public class Script: Log, Mutex {
  internal var queue = Script.new(queue: "Script")
  private var execution: Execution?
  private let path: String
  private let args: [String]
  private let bashPath = "/bin/bash"
  public weak var delegate: Scriptable?
  internal let id = Int(arc4random_uniform(1000))

  public convenience init(path: String, args: [String] = [], delegate: Scriptable, autostart: Bool = false) {
    self.init(path: path, args: args)
    self.delegate = delegate
    if autostart { start() }
  }

  public init(path: String, args: [String] = []) {
    self.path = path
    self.args = args
  }

  public func stop() {
    guard isRunning else {
      return log("Process isn't running")
    }

    do {
      try execution?.terminate()
    } catch {
      err("Could not terminate script: \(error)")
    }
  }

  // TODO: Should throw
  public func restart() {
    stop()
    start()
  }

  // TODO: Same as above
  public func start() {
    invoke { [weak self] in
      guard let this = self else { return }
      this.stop()
      this.setupExec()
      do {
        try this.execution?.run()
      } catch {
        this.err("Chould not start script: \(error)")
      }
    }
  }

  private func succeeded(_ result: Success) {
    guard let delegate = delegate else {
      return err("Succeeded running script but got no delegate to deliver to. Deallocated?")
    }

    log("Succeeded with output: \(result)")
    delegate.scriptDidReceive(success: result)
  }

  private func failed(_ message: Failure) {
    guard let delegate = self.delegate else {
      return err("Failed script but got no delegate to deliver to. Deallocated?")
    }

    err("Failed with error message: '\(message)'")
    delegate.scriptDidReceive(failure: message)
  }

  public var isRunning: Bool {
    return execution?.isRunning ?? false
  }

  // private var fileName: String {
  //   return (path as NSString).lastPathComponent + ":" + args.joined(separator: ",")
  // }

  // @objc private func terminationHandler(_ process: Process) {
  //   log("called terminationHandler")
  //   set(state:
  //     .terminated(
  //       process.terminationReason,
  //       Int(process.terminationStatus)
  //     )
  //   )
  // }

  // private var namedArgs: [String] {
  //   guard !args.isEmpty else {
  //     return []
  //   }
  //
  //   return (0..<args.count).map { "\"$" + String($0) + "\"" }
  // }
  //
  // private func escape(_ string: String) -> String {
  //   return string.replace("'", "\\'").replace("\"", "\\\"")
  // }

  // private var arguments: [String] {
  //   let run = ["-c", (escape(path) + " " + namedArgs.joined(separator: " "))] + args
  //   log("Example ~; bash " + run.joined(separator: " "))
  //   return run
  // }


  // private func fail(_ msg: String) -> Never {
  //   preconditionFailure("[Bug] '\(fileName) => \(state)' \(msg)")
  // }

  // private func handleCrash(_ message: String) {
  //   err("Crashed with message: '\(message)'")
  //   failed(.crash(message))
  // }

  // private var currentEnv: [String: String] {
  //   return ProcessInfo.processInfo.environment
  // }

  private func setupExec() {
    execution = Execution(path: path, args: args, id: id)

    execution?.onStreamedSuccess { [weak self] output in
      self?.log("OnStreamedSuccess: \(output.inspected)")
      self?.delegate?.scriptDidReceive(piece: .succeeded(output))
    }

    execution?.onStreamedFailure { [weak self] failure in
      self?.err("OnStreamedFailure: \(failure)")
      self?.delegate?.scriptDidReceive(piece: .failed(failure))
    }

    execution?.onFailure { [weak self] failure in
      if case .manualTermination = failure {
        return print("[LOG] manual termination, abort")
      }

      self?.err("OnFailure: \(failure)")
      self?.failed(failure)
    }

    execution?.onSuccess { [weak self] result in
      guard let this = self else {
        return print("[Log] Self no longer exists for onSuccess")
      }

      // if (this.execution?.isStdoutStreaming ?? false) {
      //   return this.log("Ignore stream")
      // }

      this.log("Success: \(result)")
      this.succeeded(result)
    }
  }
}
