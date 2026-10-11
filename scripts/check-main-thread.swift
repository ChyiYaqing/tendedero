// Run from the repository root on macOS 13:
// swiftc -target "$(uname -m)-apple-macosx13.0" Sources/Tendedero/MainThread.swift scripts/check-main-thread.swift -o /tmp/tendedero-check-main-thread
// /tmp/tendedero-check-main-thread
import Foundation

@MainActor
private final class State {
    var value = 0
}

@main
enum MainThreadCheck {
    static func main() {
        let state = assumeMainActor { State() }
        let result = assumeMainActor {
            state.value = 42
            return state.value
        }
        precondition(result == 42)
        precondition(assumeMainActor { state.value } == 42)
        precondition(assumeMainActor { state } === state)

        // Exercise the same synchronous bridge from a main-run-loop timer.
        var fired = false
        let timer = Timer(timeInterval: 0.01, repeats: false) { _ in
            assumeMainActor { state.value += 1 }
            fired = true
        }
        RunLoop.main.add(timer, forMode: .default)
        let deadline = Date(timeIntervalSinceNow: 2)
        while !fired && Date() < deadline {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }
        precondition(fired)
        precondition(assumeMainActor { state.value } == 43)
        print("Main-thread compatibility checks passed")
    }
}
