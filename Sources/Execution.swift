import Foundation

public class Execution: Log, Mutex {
  internal let queue = Execution.new(queue: "Execution")
  public var isStdoutStreaming: Bool { return state.isStdoutStreaming }
  public var isStderrStreaming: Bool { return state.isStderrStreaming }

  public typealias Failure = (Script.Failure) -> Void
  public typealias Success = (Script.Success) -> Void

  private let args: [String]
  private var state = CurrentState()
  private let center = NotificationCenter.default
  private var isStarted: Bool { return state.isStarted }
  private var isPublished: Bool { return state.isPublished }
  private var isTerminated: Bool { return state.isTerminated }
  private var isCompleted: Bool { return state.isCompleted }
  private var stdoutCallbacks = [Success]()
  private var stderrCallbacks = [Failure]()
  private var streamedStderrCallbacks = [(String) -> Void]()
  private var streamedStdoutCallbacks = [(String) -> Void]()
  private var terminationCallbacks = [(Reason) -> Void]()
  private let bashPath = "/bin/bash"
  private let process = Process()
  private let stdoutPipe = Pipe()
  private let stderrPipe = Pipe()
  private let stdout: FileHandle
  private let stderr: FileHandle
  private var stdoutBuffer = Buffer()
  private var stderrBuffer = Buffer()
  private let path: String
  internal let id: Int

  public init(path: String, args: [String] = [], id: Int) {
    self.id = id
    self.stdout = stdoutPipe.fileHandleForReading
    self.stderr = stderrPipe.fileHandleForReading
    self.args = args
    self.path = path

    process.launchPath = bashPath
    process.arguments = arguments
    process.environment = currentEnv
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    invoke { [weak self] in
      self?.stdout.readabilityHandler = { [weak self] handle in
        guard let this = self else {
          return print("[Log] Execution(std) handler has already been relased")
        }

        let data = handle.availableData

        if data.isEOF {
          return this.set(state: .stdoutClosed)
        }

        this.stdoutBuffer.append(data)
        this.stdoutBuffer.output() { [weak self] items in
          guard let this = self else { return }

          if !items.isEmpty {
            this.set(state: .stdoutStreaming)
          }

          for output in items {
            for callback in this.streamedStdoutCallbacks {
              callback(output)
            }
          }
        }
      }

      self?.stderr.readabilityHandler = { [weak self] handle in
        guard let this = self else {
          return print("[Log] Execution(err) handler has already been relased")
        }

        let data = handle.availableData

        if data.isEOF {
          return this.set(state: .stderrClosed)
        }

        this.stderrBuffer.append(data)
        this.stderrBuffer.output() { [weak self] items in
          guard let this = self else { return }

          if !items.isEmpty {
            this.set(state: .stderrStreaming)
          }

          for output in items {
            for callback in this.streamedStderrCallbacks {
              callback(output)
            }
          }
        }
      }

      self?.process.terminationHandler = { [weak self] _ in
        guard let this = self else {
          return print("[LOG] Execution has already been deallocated")
        }

        this.log("Script has been terminated")
        this.set(state: .terminated)
      }
    }
  }

  public func onFailure(callback: @escaping Failure) {
    stderrCallbacks.append(callback)
  }

  public func onSuccess(callback: @escaping Success) {
    stdoutCallbacks.append(callback)
  }

  public func onTermination(callback: @escaping (Reason) -> Void) {
    terminationCallbacks.append(callback)
  }

  public func onStreamedFailure(callback: @escaping (String) -> Void) {
    streamedStderrCallbacks.append(callback)
  }

  public func onStreamedSuccess(callback: @escaping (String) -> Void) {
    streamedStdoutCallbacks.append(callback)
  }

  public var isRunning: Bool {
    return process.isRunning
  }

  public func terminate() throws {
    guard isStarted else { throw RuntimeError.notRunning }
    guard isRunning else { throw RuntimeError.notRunning }
    if isTerminated { throw RuntimeError.alreadyTerminated }
    if isCompleted { throw RuntimeError.alreadyCompleted }

    process.terminate()
  }

  public func run() throws {
    if isStarted { throw RuntimeError.alreadyStarted }

    invoke { [weak self] in
      self?.set(state: .started)
      self?.process.launch()
    }
  }

  private func set(state other: State) {
    log("Set state to: \(other)")
    state.update(state: other)

    switch other {
    case .stderrClosed:
      stderrBuffer.close()
      stderr.readabilityHandler = nil
    case .stdoutClosed:
      stdoutBuffer.close()
      stdout.readabilityHandler = nil
    case .terminated:
      process.terminationHandler = nil
    default:
      break
    }

    publish()
  }

  private func publish() {
    guard isTerminated else {
      return log("Script has not terminated yet")
    }

    if isStdoutStreaming {
      stdoutBuffer.tilTheEnd() { [weak self] items in
        for output in items {
          for callback in (self?.streamedStdoutCallbacks ?? []) {
            callback(output)
          }
        }
      }
    }

    if isStderrStreaming {
      stderrBuffer.tilTheEnd() { [weak self] items in
        for output in items {
          for callback in (self?.streamedStderrCallbacks ?? []) {
            callback(output)
          }
        }
      }
    }

    // for callback in terminationCallbacks {
    //   callback((
    //     process.terminationReason,
    //     Int(process.terminationStatus),
    //     stderrBuffer.everything ?? "",
    //     stdoutBuffer.everything ?? ""
    //   ))
    // }

    guard !isPublished else {
      return log("Already published, ignoring: \(state)")
    }

    switch normalizedOutput {
    case let .failed(result):
      stderrCallbacks.forEach { $0(result) }
    case let .succeeded(result):
      stdoutCallbacks.forEach { $0(result) }
    }

    state.update(state: .published)
  }

  private var reason: Reason {
    return (
      process.terminationReason,
      Int(process.terminationStatus),
      stdoutBuffer.everything,
      stderrBuffer.everything
    )
  }

  private var normalizedOutput: Script.Result {
    switch reason {
    case let (.exit, 0, stdout, _):
      return .succeeded(.withZeroExitCode(stdout))
    case let (.exit, 0, .none, .some(stderr)):
      return .failed(.withZeroExitCode(stderr))
    case let (.uncaughtSignal, 15, .none, stderr):
      return .failed(.manualTermination(stderr, 15))
    case let (.exit, 2, .none, stderr):
      return .failed(.syntaxError(stderr, 2))
    case let (.exit, 126, .none, stderr):
      return .failed(.notExecutable(stderr, 126))
    case let (.exit, 127, .none, stderr):
      return .failed(.pathNotFound(stderr, 127))
    case let (.exit, code, .none, stderr):
      return .failed(.generic(stderr, code))
    case let (.uncaughtSignal, code, .none, stderr):
      return .failed(.uncaughtSignal(stderr, code))
    case let (.exit, code, .some(stdout), .some(stderr)):
      return .failed(.genericMixed(stdout, stderr, code))
    case let (.exit, code, .some(stdout), .none):
      return .failed(.withStdout(stdout, code))
    case let (type, code, stdout, stderr):
      return .failed(.withFallback(type, code, stdout, stderr))
    }
  }

  private var namedArgs: [String] {
    if args.isEmpty { return [] }
    return (0..<args.count).map { "\"$" + String($0) + "\"" }
  }

  private func escape(_ string: String) -> String {
    return string.replace("'", "\\'").replace("\"", "\\\"")
  }

  private var arguments: [String] {
    return ["-c", (escape(path) + " " + namedArgs.joined(separator: " "))] + args
  }

  private var currentEnv: [String: String] {
    return ProcessInfo.processInfo.environment
  }
}
