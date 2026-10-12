import Foundation
@testable import GhosttyTerminal
import Testing

/// Ghostty wakes the app once per mailbox message, from its IO and renderer
/// threads. A burst must leave one main-queue tick outstanding, not one per
/// message.
struct TerminalWakeupGateTests {
    @Test
    func `only the first wakeup of a burst schedules a tick`() {
        let gate = TerminalWakeupGate()
        #expect(gate.claim())
        #expect(!gate.claim())
        #expect(!gate.claim())
        gate.release()
        #expect(gate.claim())
    }

    @Test
    func `concurrent wakeups claim exactly once until released`() {
        let gate = TerminalWakeupGate()
        let claims = LockedCounter()
        DispatchQueue.concurrentPerform(iterations: 10000) { _ in
            if gate.claim() { claims.increment() }
        }
        #expect(claims.value == 1)
    }
}

private final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func increment() {
        lock.lock()
        count += 1
        lock.unlock()
    }
}
