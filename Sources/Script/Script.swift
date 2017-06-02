import Foundation

public class Script {
  private var queue = DispatchQueue(label: "Script")
  private var state = ScriptState.idle
  private let path: String
  private let args: [String]
  private var handler: FileHandle
  private var errHandler: FileHandle
  private var pipe = Pipe()
  private var errPipe = Pipe()
  private var process = Process()
  private var buffer = Buffer()
  private var errBuffer = Buffer()
  private let bashPath = "/bin/bash"
  private let center = NotificationCenter.default
  private let bundle = Bundle.main
  public weak var delegate: Scriptable?

  public convenience init(path: String, args: [String] = [], delegate: Scriptable, autostart: Bool = false) {
    self.init(path: path, args: args)
    self.delegate = delegate
    if autostart { start() }
  }

  public init(path: String, args: [String] = []) {
    self.path = path
    self.args = args
    handler = pipe.fileHandleForReading
    errHandler = errPipe.fileHandleForReading
    process.launchPath = bashPath
    process.arguments = arguments
    process.standardOutput = pipe
    process.standardError = errPipe
    process.terminationHandler = terminationHandler
    process.environment = currentEnv
    setObs()
  }

  public func stop() {
    if process.isRunning {
      process.terminate()
    } else {
      err("Not running, nothing to terminate")
    }
  }

  public func restart() {
    synced(self) {
      self.set(state: .executing)
    }
  }

  public func start() {
    synced(self) {
      self.set(state: .executing)
    }
  }

  private func succeeded(_ data: String?, status: Int) {
    guard let result = data else {
      return log("No data to report")
    }

    guard let aDel = self.delegate else {
      return err("Succeeded running script but got no delegate to deliver to. Deallocated?")
    }

    log("Succeeded with exit code \(status)")

    aDel.scriptDidReceive(
      success: Success(
        status: status,
        output: result
      )
    )
  }

  private func set(state to: ScriptState) {
    switch (state, to) {
    case (.finished, .eof):
      log("EOF on finish (finished => EOF => finished)")
    case (.eof, .eof):
      log("EOF on EOF (EOF => EOF)")
    case (.idle, .executing):
      log("Starting to execute script (idle => executing)")
      process.launch()
      handler.waitForDataInBackgroundAndNotify()
    case let (.terminated(.exit, status), .streaming):
      log("Terminated script is set to stream. Mark as terminated and report stream (terminated => streaming => terminated")
      handleStream()
      succeeded(currentBuffer, status: status)
    case let (.terminated(reason, status), .streaming):
      log("Terminating => streaming")
      handleStream()
      lockdown(reason: reason, status: status)
    case (_, .executing):
      log("[X] Script is running, terminating (\(state) => executing)")
      stop()
      reset()
      start()
    case (_, .finished):
      fail("Can't set finished manually")
    case (.streaming, .streaming):
      log("[X] Script is streaming (streaming => streaming")
      handleStream()
    case (.executing, .streaming):
      log("[X] Script is streaming (executing => streaming")
      handleStream()
    case (.finished, .streaming):
      log("Script is finished but got streaming. (finished => streaming => finished)")
      handleStream()
    case let (.streaming, .terminated(.exit, status)):
      log("Terminating streaming script (streaming => terminated), waiting for EOF")
      handleStream()
      succeeded(currentBuffer, status: status)
    case (.executing, .terminated):
      log("Script has been terminated, waiting for EOF (executing => terminated)")
    case let (.eof, .terminated(reason, status)):
      log("Stream handler closed and script terminated (EOF => terminated)")
      lockdown(reason: reason, status: status)
    case (.streaming, .eof):
      log("Streaming reached EOF (streaming => EOF => streaming")
    case (.eof, .streaming):
      log("From EOF to streaming")
    case (.executing, .eof):
      log("Executing => EOF")
    case let (.terminated(reason, status), .eof):
      log("Script is terminated and has is in state EOF, report data (terminated => EOF)")
      lockdown(reason: reason, status: status)
    case let (.streaming, .terminated(reason, status)):
      log("Terminating streaming script (streaming => terminated), waiting for EOF")
      handleStream()
      lockdown(reason: reason, status: status)
    default:
      err("Invalid state (\(state) => \(to))")
    }

    self.state = to
  }

  private func failed(_ message: Failure) {
    guard let delegate = self.delegate else {
      return err("Failed script but got no delegate to deliver to. Deallocated?")
    }

    err("Failed with error message: '\(message)'")
    delegate.scriptDidReceive(failure: message)
  }

  @objc private func handleData() {
    synced(self) {
      self.processData()
    }
  }

  private func handleStream() {
    for line in self.buffer.reset() {
      succeeded(line, status: 0)
    }
  }

  var isRunning: Bool {
    return process.isRunning
  }

  private var isDarkMode: Bool {
    return UserDefaults.standard
      .string(forKey: "AppleInterfaceStyle") == "Dark"
  }

  private var fileName: String {
    return (path as NSString).lastPathComponent + ":" + args.joined(separator: ",")
  }

  private var currentBuffer: String? {
    guard !buffer.isEmpty else {
      return nil
    }

    let out = buffer.toString()
    buffer.clear()
    return out
  }

  private var currentErrBuffer: String {
    errBuffer.append(data: errHandler.availableData)
    let out = errBuffer.toString()
    errBuffer.clear()
    return out
  }

  private func processData() {
    let data = handler.availableData
    buffer.append(data: data)

    if buffer.isFinish() {
      set(state: .streaming)
    }

    if data.isEOF() {
      set(state: .eof)
    }

    if !data.isEOF() {
      handler.waitForDataInBackgroundAndNotify()
    }

    let data2 = errHandler.availableData
    errBuffer.append(data: data2)

    if !data2.isEOF() {
      errHandler.waitForDataInBackgroundAndNotify()
    }
  }

  private func terminationHandler(_ process: Process) {
    synced(self) {
      self.set(state:
        .terminated(
          self.process.terminationReason,
          Int(self.process.terminationStatus)
        )
      )
    }
  }

  private var namedArgs: [String] {
    guard !args.isEmpty else {
      return []
    }

    return (0..<args.count).map { "\"$" + String($0) + "\"" }
  }

  private func quote(_ a: String) -> String {
    return "\"" + a + "\""
  }

  private var arguments: [String] {
    let run = ["-c", (path + " " + namedArgs.joined(separator: " "))] + args
    log("Example ~; bash " + run.joined(separator: " "))
    return run
  }

  private func lockdown(reason: Process.TerminationReason, status: Int) {
    log("Locked script with reason \(reason) and status \(status)")

    switch (reason, status) {
    case (.exit, 0):
      succeeded(currentBuffer, status: 0)
    case (.exit, 2):
      failed(.misuse(currentErrBuffer))
    case (.exit, 126):
      failed(.notExec)
    case (.exit, 127):
      failed(.notFound)
    case let (.exit, code):
      failed(.exit(currentErrBuffer, code))
    case (.uncaughtSignal, 15):
      failed(.terminated)
    case let (.uncaughtSignal, code):
      failed(.exit(currentErrBuffer, code))
    }
  }

  private func log(_ msg: String) {
    print("warninxg: [Log] '\(fileName) => \(state)' \(msg)")
  }

  private func err(_ msg: String) {
    print("warninxg: [Err] '\(fileName) => \(state)' \(msg)")
  }

  private func fail(_ msg: String) -> Never {
    preconditionFailure("[Bug] '\(fileName) => \(state)' \(msg)")
  }

  private func handleCrash(_ message: String) {
    err("Crashed with message: '\(message)'")
    failed(.crash(message))
  }

  private var currentEnv: [String: String] {
    return ProcessInfo.processInfo.environment
  }

  private func setObs() {
    center.removeObserver(self)
    center.addObserver(
      self,
      selector: #selector(handleData),
      name: .NSFileHandleDataAvailable,
      object: handler
    )
  }

  private func reset() {
    pipe = Pipe()
    handler = pipe.fileHandleForReading
    errPipe = Pipe()
    errHandler = errPipe.fileHandleForReading
    process = Process()
    buffer = Buffer()
    errBuffer = Buffer()
    state = .idle
    process.launchPath = bashPath
    process.arguments = arguments
    process.environment = currentEnv
    process.standardOutput = pipe
    process.standardError = errPipe
    process.terminationHandler = terminationHandler
    setObs()
  }

  // TODO: remove lock
  @objc private func synced(_ lock: Any, closure: @escaping () -> Void) {
    queue.sync { closure() }
  }
}
