// import Quick
// import Nimble
// import HeliumLogger
// @testable import Script
//
// class BufferTests: QuickSpec {
//   override func spec() {
//     beforeEach {
//       // HeliumLogger.load()
//     }
//
//     it("defaults to empty list") {
//       Buffer().output() {
//         expect($0).to(beEmpty())
//       }
//     }
//
//     it("defaults to empty") {
//       expect(Buffer().toString()).to(beEmpty())
//     }
//
//     it("contains data") {
//       let buffer = Buffer()
//       buffer.append(string: "ABC")
//       expect(buffer.toString()).to(equal("ABC"))
//     }
//
//     it("resets store") {
//       let buffer = Buffer(withDelimiter: "NOT FOUND")
//       buffer.append(string: "ABC")
//       buffer.output() {
//         expect($0).to(beEmpty())
//         expect(buffer.toString()).to(equal("ABC"))
//       }
//     }
//
//     context("isFinish") {
//       it("is not after appending ") {
//         let buffer = Buffer(withDelimiter: "DEF")
//         buffer.append(string: "ABC")
//       }
//
//       it("finds in the end") {
//         let buffer = Buffer(withDelimiter: "DEF")
//         buffer.append(string: "DEF")
//         buffer.output() {
//           expect($0).to(equal([""]))
//         }
//       }
//
//       it("finds near the end") {
//         let buffer = Buffer(withDelimiter: "DEF")
//         buffer.append(string: "DEFXXX")
//         buffer.output() {
//           expect($0).to(equal([""]))
//           expect(buffer.toString()).to(equal("XXX"))
//         }
//       }
//     }
//
//     context("edge cases") {
//       it("handles longer delimiter then current buffer length (empty)") {
//         let buffer = Buffer(withDelimiter: "ABC")
//         buffer.output() { expect($0).to(beEmpty()) }
//         expect(buffer.toString()).to(beEmpty())
//       }
//
//        it("handles longer delimiter then current buffer length") {
//         let buffer = Buffer(withDelimiter: "ABC")
//         buffer.append(string: "X")
//         buffer.output() { expect($0).to(beEmpty()) }
//         expect(buffer.toString()).to(equal("X"))
//       }
//
//       it("shorter delimiter then buffer content") {
//         let buffer = Buffer(withDelimiter: "A")
//         buffer.append(string: "BC")
//         buffer.output() { expect($0).to(beEmpty()) }
//         expect(buffer.toString()).to(equal("BC"))
//       }
//
//       it("handles partial matched delimiter") {
//         let buffer = Buffer(withDelimiter: "AB")
//         buffer.append(string: "A")
//         buffer.output() { expect($0).to(beEmpty()) }
//         expect(buffer.toString()).to(equal("A"))
//       }
//
//       it("handles empty delimiter") {
//         let buffer = Buffer(withDelimiter: "")
//         buffer.append(string: "ABC")
//         buffer.output() { expect($0).to(beEmpty()) }
//         expect(buffer.toString()).to(equal("ABC"))
//       }
//
//       it("handles empty delimiter and buffer") {
//         let buffer = Buffer(withDelimiter: "")
//         buffer.output() { expect($0).to(beEmpty()) }
//         expect(buffer.toString()).to(beEmpty())
//       }
//     }
//
//     context("multiply results") {
//       it("is not after appending") {
//         let buffer = Buffer(withDelimiter: "DEF")
//         buffer.append(string: "ABC")
//         buffer.append(string: "ABC")
//         expect(buffer.toString()).to(equal("ABCABC"))
//       }
//
//       it("finds in the end") {
//         let buffer = Buffer(withDelimiter: "DEF")
//         buffer.append(string: "DEF")
//         buffer.append(string: "X")
//         buffer.append(string: "DEF")
//         buffer.output() {
//           expect($0).to(equal(["", "X"]))
//           expect(buffer.toString()).to(beEmpty())
//         }
//       }
//
//       it("finds near the end") {
//         let buffer = Buffer(withDelimiter: "DEF")
//         buffer.append(string: "DEFXXX")
//         buffer.append(string: "DEFXXX")
//         buffer.output() {
//           expect($0).to(equal(["", "XXX"]))
//           expect(buffer.toString()).to(equal("XXX"))
//         }
//       }
//
//       it("finds delimiters in a row") {
//         let buffer = Buffer(withDelimiter: "X")
//         buffer.append(string: "XXX")
//         buffer.output() {
//           expect($0).to(equal(["", "", ""]))
//         }
//         expect(buffer.toString()).to(beEmpty())
//       }
//
//       it("handles recurring rows") {
//         let buffer = Buffer(withDelimiter: "X")
//         buffer.append(string: "XA")
//         buffer.output() {
//           expect($0).to(equal([""]))
//         }
//         buffer.append(string: "X")
//
//         buffer.output() {
//           expect($0).to(equal(["A"]))
//         }
//       }
//     }
//   }
// }
