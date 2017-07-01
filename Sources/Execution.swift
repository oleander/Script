import Foundation
import Async

public class Execution: Log {
  public typealias Failure = (Script.Failure) -> Void
  public typealias Success = (Script.Success) -> Void

  private let args: [String]
  private var state = CurrentState()
  private var isStarted: Bool { return state.isStarted }
  private var isPublished: Bool { return state.isPublished }
  private var isTerminated: Bool { return state.isTerminated }
  private var isCompleted: Bool { return state.isCompleted }
  private var isManuallyTerminated: Bool { return state.isManuallyTerminated }
  private var stdoutCallbacks = [Success]()
  private var stderrCallbacks = [Failure]()
  private var streamedStderrCallbacks = [(String) -> Void]()
  private var streamedStdoutCallbacks = [(String) -> Void]()
  private var terminationCallbacks = [(Reason) -> Void]()
  private let bashPath = "/bin/bash"
  private let process = Process()
  private let stdoutPipe = Pipe()
  private let stderrPipe = Pipe()
  private var stdout: Handler?
  private var stderr: Handler?
  private let env: Env
  private let path: String
  internal let id: String

  public init(path: String, args: [String] = [], env: Env = Env(), id: String) {
    self.args = args
    self.path = path
    self.env = env
    self.id = id

    process.launchPath = bashPath
    process.arguments = arguments
    process.environment = env
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    self.stdout = Handler(stdoutPipe.fileHandleForReading)
    self.stderr = Handler(stderrPipe.fileHandleForReading)

    self.stdout?.onPiece { [weak self] piece in
      for callback in (self?.streamedStdoutCallbacks ?? []) {
        callback(piece)
      }
    }

    self.stderr?.onPiece { [weak self] piece in
      for callback in (self?.streamedStderrCallbacks ?? []) {
        callback(piece)
      }
    }

    self.stderr?.onTermination { [weak self] in
      self?.set(state: .stderrCompleted)
    }

    self.stdout?.onTermination { [weak self] in
      self?.set(state: .stdoutCompleted)
    }

    process.terminationHandler = { [weak self] process in
      process.terminationHandler = nil

      switch (process.terminationReason, process.terminationStatus) {
      case (.exit, _):
        self?.set(state: .terminated)
      case (.uncaughtSignal, 15):
        self?.manualTermination()
      case (.uncaughtSignal, _):
        self?.set(state: .terminated)
      }
    }
  }

  public func manualTermination() {
    set(state: .manualTermination)
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

  public func terminate() {
    log("Called #terminate")

    if isManuallyTerminated {
      return log("Already manually terminated")
    }

    set(state: .manualTermination)
    close()

    if isRunning {
      process.terminate()
    }
  }

  public func run() {
    if isStarted { return }
    set(state: .started)
    process.launch()
  }

  public func clear() {
    stdout?.clear()
    stderr?.clear()
  }

  public func close() {
    stderr?.close()
    stdout?.close()
  }

  private func set(state other: State) {
    log("Set state to: \(other)")
    state.update(state: other)

    switch other {
    case .manualTermination:
      close()
    default:
      break
    }

    guard isCompleted else {
      return log("Not completed: \(state)")
    }

    guard !isPublished else {
      return log("Already published")
    }

    if isManuallyTerminated {
      return log("Process is manually terminated, ignore #publish")
    }

    switch normalizedOutput {
    case let .failed(result):
      stderrCallbacks.forEach { callback in
        callback(result)
      }
    case let .succeeded(result):
      stdoutCallbacks.forEach { callback in
        callback(result)
      }
    }

    state.update(state: .published)
  }

  private var reason: Reason {
    return (
      process.terminationReason,
      Int(process.terminationStatus),
      stdout?.output,
      stderr?.output
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

  deinit { terminate() }
}
