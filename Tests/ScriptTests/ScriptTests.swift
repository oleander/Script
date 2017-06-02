import Quick
import Nimble
import Foundation
@testable import Script

class ScriptTests: QuickSpec {
  override func spec() {
    beforeEach {
      Nimble.AsyncDefaults.Timeout = 5
    }

    describe("stdout") {
      it("handles base case") {
        expect(script("basic.sh")).toEventually(succeed(with: "Hello\n"))
      }

      it("handles sleep") {
        expect(script("sleep.sh")).toEventually(succeed(with: "sleep\n"))
      }

      describe("args") {
        it("handles args") {
          expect(script("arguments.sh", withArgs: ["1", "2", "3"])).toEventually(succeed(with: "1|2|3\n"))
        }

        it("handles with '") {
          expect(script("arguments.sh", withArgs: ["1", "'"])).toEventually(succeed(with: "1|'\n"))
        }

        it("handles with \"") {
          expect(script("arguments.sh", withArgs: ["1", "\""])).toEventually(succeed(with: "1|\"\n"))
        }

        it("handles with space") {
          expect(script("arguments.sh", withArgs: ["1", " ", "3"])).toEventually(succeed(with: "1| |3\n"))
        }

        it("handles with space (end)") {
          expect(script("arguments.sh", withArgs: ["1", " "])).toEventually(succeed(with: "1| \n"))
        }
      }

      describe("inline") {
        it("handles arguments") {
          expect(code("echo", withArgs: ["A"])).toEventually(succeed(with: "A\n"))
        }

        it("handles without argument") {
          expect(code("echo B")).toEventually(succeed(with: "B\n"))
        }
      }

      describe("env") {
        it("should share environment with the host") {
          let testValue = "ABC 123"
          setenv("SHAREDBITBARENV", testValue, true)
          expect(script("env.sh", withArgs: ["SHAREDBITBARENV"])).toEventually(succeed(with: testValue + "\n"))
        }
      }

      describe("file names") {
        it("handles file with single quote") {
          expect(script("name-with-'.sh")).toEventually(succeed(with: "A\n"))
        }

        it("handles file with double quote") {
          expect(script("name-with-\".sh")).toEventually(succeed(with: "A\n"))
        }

        it("handles file with space in name") {
          expect(script("space\\ script.sh")).toEventually(succeed(with: "Hello\n"))
        }
      }

      describe("stream") {
        it("handles one output") {
          expect(script("stream-nomore.sh")).toEventually(succeed(with: "A\n"))
        }

        it("handles more then one") {
          expect(script("stream-more.sh")).toEventually(succeed(with: ["A\n", "B\n"]))
        }

        it("handles empty stream") {
          expect(script("stream-nothing.sh")).toEventually(succeed(with: ""))
        }

        it("handles sleep") {
          expect(script("stream-sleep.sh")).toEventually(succeed(with: ["A\n", "B\n"]))
        }
      }
    }

    describe("stderr") {
      describe("crash") {
        it("is missing shebang") {
          expect(script("missing-sh-bin.sh")).toEventually(succeed(with: "Hello\n"))
        }

        it("handles non-executable script") {
          expect(script("nonexec.sh")).toEventually(crash(.notExec))
        }

        it("handles non-executable script") {
          expect(script("does-not-exist.sh")).toEventually(crash(.notFound))
        }
      }

      describe("misuse") {
        it("handles invalid syntax") {
          expect(script("invalid-syntax.sh")).toEventually(crash(.misuse("syntax error: unexpected end of file")))
        }
      }

      describe("status code") {
        it("exit code 1, no output") {
          expect(script("exit1-no-output.sh")).toEventually(exit(with: "", andStatusCode: 1))
        }

        it("exit code 1, with output") {
          expect(script("exit1-output.sh")).toEventually(exit(with: "Exit 1\n", andStatusCode: 1))
        }
      }
    }

    describe("actions") {
      let path = "sleep.sh"

      describe("autostart") {
        it("should not start automaticly if autostart = false") {
          expect((path, false, [])).toNotEventually(have(events: [.success]))
        }

        it("should start automaticly if autostart = true") {
          expect((path, true, [])).toEventually(have(events: [.success]))
        }
      }

      describe("stop") {
        it("should stop script and signal termination") {
          expect((path, true, [.stop])).toEventually(have(events: []))
          expect((path, true, [.stop])).toNotEventually(have(events: [.success]))
          expect((path, true, [.stop])).toNotEventually(have(events: [.termination]))
        }

        it("should be able to stop a non running script") {
          expect((path, false, [.stop])).toNotEventually(have(events: [.termination]))
          expect((path, false, [.stop])).toNotEventually(have(events: [.success]))
        }
      }

      describe("restart") {
        it("should terminate and start on restart") {
          expect((path, true, [.restart])).toEventually(have(events: [.success]))
          expect((path, true, [.restart])).toNotEventually(have(events: [.termination]))
        }
      }

      describe("start") {
        it("should only run once (autostart=false)") {
          expect(("sleep.sh", false, [.start, .start])).toEventually(have(events: [.success]))
        }

        it("should only run once (autostart=true)") {
          expect(("sleep.sh", true, [.start, .start])).toEventually(have(events: [.success]))
        }
      }

      describe("sequence") {
        it("should handle sequence ending with 'start'") {
          expect(("sleep.sh", true, [.start, .stop, .restart, .start, .stop, .start])).toEventually(have(events: [.success]))
        }

        it("should handle sequence ending with 'stop'") {
          expect(("sleep.sh", true, [.start, .stop, .restart, .start, .stop, .stop])).toEventually(have(events: []))
        }

        it("should handle sequence ending with 'stop'") {
          expect(("sleep.sh", true, [.start, .stop, .restart, .start, .stop, .restart])).toEventually(have(events: [.success]))
        }
      }
    }
  }
}
