@testable import Script
import PathKit
import Foundation
import Nimble

let rootPath = Path(FileManager.default.currentDirectoryPath) + Path("Tests/ScriptTests/Scripts")
func toFile(_ path: String) -> String {
  return (rootPath + Path(path)).string
}

func verify<T>(_ message: String, block: @escaping (T) -> State) -> Predicate<T> {
  return Predicate.define { actualExpression in
    guard let result = try actualExpression.evaluate() else {
      return PredicateResult(
        status: .fail,
        message: .expectedCustomValueTo(message, "nothing")
      )
    }

    switch block(result) {
    case let .bool(status, actual):
      return PredicateResult(
        bool: status,
        message: .expectedCustomValueTo(message, String(describing: actual))
      )
    case let .fail(actual):
      return PredicateResult(
        status: .fail,
        message: .expectedCustomValueTo(message, String(describing: actual))
      )
    case let .lift(result):
      return result
    }
  }
}


func toSucc(_ output: String) -> Std {
  return .succ(Script.Success(status: 0, output: output))
}

func have(events: [ScriptEvent]) -> Predicate<(String, Bool, [ScriptAction])> {
  let message = "have events \(events)"
  var delegate: FakeScriptable!
  var script: Script!
  var hasInit = false

  return verify(message) { params in
    let (path, autostart, actions) = params
    if !hasInit {
      delegate = FakeScriptable()
      script = Script(path: toFile(path), args: [], delegate: delegate, autostart: autostart)
      hasInit = true
      for action in actions {
        switch action {
        case .restart:
          script.restart()
        case .stop:
          script.stop()
        case .sleep:
          sleep(2)
        case .start:
          script.start()
        }
      }
    }

    let result = delegate.result
    let newEvents = result.reduce([ScriptEvent]()) { acc, out in
      switch out {
      case .succ:
        return acc + [.success]
      case .fail(.terminated):
        return acc + [.termination]
      default:
        return acc + [.unknown(String(describing: out))]
      }
    }

    if newEvents == events {
      script.stop()
    }

    return .bool(newEvents == events, newEvents)
  }
}

func have(environment env: String, setTo value: String) -> Predicate<Script.Result> {
  /* TODO: Compare against env */
  return verify("environment \(env) set to \(value)") { result in
    switch result {
    case let .success(result):
      return .bool(result.output == value + "\n", result)
    default:
      return .fail(result)
    }
  }
}

func beTerminated() -> Predicate<Script.Result> {
  return verify("be terminated") { result in
    switch result {
    case .failure(.terminated()):
      return .bool(true, result)
    default:
      return .bool(false, result)
    }
  }
}

func beAMisuse(with exp: String) -> Predicate<Script.Result> {
  return verify("be misused with \(exp)") { result in
    switch result {
    case let .failure(.misuse(message)) where message.contains(exp):
      return .bool(message.contains(exp), message)
    default:
      return .fail(result)
    }
  }
}

func script(_ path: String, withArgs args: [String] = []) -> (String, [String]) {
  return (toFile(path), args)
}

func code(_ code: String, withArgs args: [String] = []) -> (String, [String]) {
  return (code, args)
}

func execute(path: String, args: [String] = [], autostart: Bool = true) -> (FakeScriptable, Script) {
  let delegate = FakeScriptable()
  return (
    delegate,
    Script(path: path, args: args, delegate: delegate, autostart: autostart)
  )
}

func crash(with message: String) -> Predicate<(String, [String])> {
  return that(in: [.fail(.crash(message))], message: "crash with \(message.inspected())")
}

func crash(_ failure: Script.Failure) -> Predicate<(String, [String])> {
  return that(in: [.fail(failure)], message: "fail as not found")
}

func lift<T, U>(_ that: Predicate<U>, block: @escaping (T) -> U) -> Predicate<T> {
  return Predicate.define { exp in
    return try that.satisfies(exp.cast { maybe in
      if let val = maybe {
        return block(val)
      }

      return nil
    })
  }
}

// expect(script).toEventually(succeed(with: "output"))
func succeed(with message: String) -> Predicate<String> {
  return succeed(with: [message])
}

// expect(script).toEventually(succeed(with: ["output"]))
func succeed(with messages: [String]) -> Predicate<String> {
  return lift(succeed(with: messages)) { path in (path, [String]()) }
}

func succeed(with message: String) -> Predicate<(String, [String])> {
  return that(in: [toSucc(message)], message: message)
}

func succeed(with messages: [String]) -> Predicate<(String, [String])> {
  return that(in: messages.map(toSucc), message: "succeed with outputs \(messages)")
}

// expect(script).toEventually(exit(message: "output", andStatusCode: 2))
func exit(with message: String, andStatusCode status: Int) -> Predicate<(String, [String])> {
  return that(
    in: [.fail(.exit(message, status))],
    message: "exit with output \(message.inspected()) and status code \(status)"
  )
}

func that(in expected: [Std], message: String) -> Predicate<(String, [String])> {
  return lift(that2(in: expected, message: message)) { param in
    let (path, args) = param
    return (path, args, true)
  }
}

// TODO: Rename
func that2(in expected: [Std], message: String) -> Predicate<(String, [String], Bool)> {
  if expected.isEmpty { preconditionFailure("Arg can't be empty") }

  var delegate: FakeScriptable!
  var script: Script!
  var hasInit = false

  return verify(message) { params in
    let (path, args, autostart) = params
    if !hasInit {
      let (d, s)  = execute(path: path, args: args, autostart: autostart)
      delegate = d
      script = s
      hasInit = true
    }

    let result = delegate.result
    let res = result.enumerated().reduce(true) { acc, state in
      let (index, status) = state
      switch expected.get(index) {
      case let .some(exp):
        return exp == status
      case .none:
        return acc
      }
    }

    if res && result.count == expected.count {
      script.stop()
      return .bool(true, result)
    }

    return .bool(false, result)
  }
}
