import XCTest
@testable import Vapor

class ConsoleTests: XCTestCase {
    static let allTests = [
        ("testCommandRun", testCommandRun),
        ("testCommandInsufficientArgs", testCommandInsufficientArgs),
        ("testCommandFetchArgs", testCommandFetchArgs),
        ("testCommandFetchOptions", testCommandFetchOptions),
        ("testDefaultServe", testDefaultServe),
    ]

    func testCommandRun() {
        let console = TestConsoleDriver()
        let app = Application(console: console, arguments: ["/path/to/exe", "test-1"])

        app.commands = [
            TestOneCommand(console: console)
        ]

        do {
            try app.runCommands()
            XCTAssertEqual(console.input(), "Test 1 Ran", "Command 1 did not run")
        } catch {
            XCTFail("Command 1 failed: \(error)")
        }
    }

    func testCommandInsufficientArgs() {
        let console = TestConsoleDriver()
        let app = Application(console: console, arguments: ["/path/to/exe", "test-2"])

        let command = TestTwoCommand(console: console)
        app.commands = [
            command
        ]

        do {
            try app.runCommands()
            XCTFail("Command 2 did not fail")
        } catch {
            XCTAssert(console.input().contains("Usage: /path/to/exe test-2 <arg-1> [--opt-1] [--opt-2]"), "Did not print signature")
        }
    }

    func testCommandFetchArgs() {
        let console = TestConsoleDriver()
        let app = Application(console: console, arguments: ["/path/to/ext", "test-2", "123"])

        let command = TestTwoCommand(console: console)
        app.commands = [
            command
        ]

        do {
            try app.runCommands()
            XCTAssertEqual(console.input(), "123", "Did not print 123")
        } catch {
            XCTFail("Command 2 failed to run: \(error)")
        }
    }


    func testCommandFetchOptions() {
        let console = TestConsoleDriver()
        let app = Application(console: console, arguments: ["/path/to/ext", "test-2", "123", "--opt-1=abc"])

        let command = TestTwoCommand(console: console)
        app.commands = [
            command
        ]

        do {
            try app.runCommands()
            XCTAssert(console.input() == "123abc", "Did not print 123abc")
        } catch {
            XCTFail("Command 2 failed to run: \(error)")
        }
    }

    func testDefaultServe() {
        final class TestServe: Command {
            let id: String = "serve"
            let console: Console
            static var ran = false

            init(console: Console) {
                self.console = console
            }

            func run(arguments: [String]) {
                TestServe.ran = true
            }
        }

        let app = Application(arguments: ["/path/to/exec"])
        app.commands = [TestServe(console: app.console)]

        do {
            try app.runCommands()
            XCTAssert(TestServe.ran, "Serve did not default")
        } catch {
            XCTFail("Serve did not default: \(error)")
        }
    }
}

final class TestOneCommand: Command {
    let id: String = "test-1"
    let console: Console
    var counter = 0

    init(console: Console) {
        self.console = console
    }

    func run(arguments: [String]) throws {
        console.print("Test 1 Ran")
    }
}

final class TestTwoCommand: Command {
    let id: String = "test-2"
    let console: Console

    let signature: [Argument] = [
        ArgValue(name: "arg-1"),
        Option(name: "opt-1"),
        Option(name: "opt-2")
    ]

    init(console: Console) {
        self.console = console
    }

    func run(arguments: [String]) throws {
        let arg1 = try value("arg-1", from: arguments).string ?? ""
        console.print(arg1)

        let opt1 = arguments.option("opt-1").string ?? ""
        console.print(opt1)
    }
}

class TestConsoleDriver: Console {
    var buffer: Bytes

    init() {
        buffer = []
    }

    func output(_ string: String, style: ConsoleStyle, newLine: Bool) {
        buffer += string.data.bytes
    }

    func input() -> String {
        let string = buffer.string
        buffer = []
        return string
    }

    func clear(_ clear: ConsoleClear) {

    }

    func execute(_ command: String) throws {

    }

    func subexecute(_ command: String, input: String) throws -> String {
        return ""
    }


    let size: (width: Int, height: Int) = (0,0)
}
