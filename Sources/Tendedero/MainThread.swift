import Foundation

/// Synchronous AppKit callbacks already run on the main thread. Swift 5.9's
/// MainActor.assumeIsolated requires macOS 14, so check the thread on Ventura
/// before removing the closure's actor annotation. Never dispatch or escape it:
/// Quick Look delegates must return their results synchronously.
@available(*, noasync, message: "Call the main actor with await instead")
func assumeMainActor<T>(_ operation: @MainActor () -> T) -> T {
    if #available(macOS 14, *) {
        return MainActor.assumeIsolated(operation)
    }
    precondition(Thread.isMainThread, "Expected a main-thread callback")
    return withoutActuallyEscaping(operation) { closure in
        unsafeBitCast(closure, to: (() -> T).self)()
    }
}
