import Foundation

/// An atomic, serial mutation of state. Intents are processed one at a time by
/// the `StateMachine` actor; `mutate(...)` runs synchronously inside the actor
/// so the read-modify-write is race-free.
///
/// An intent may return a list of `Activity` instances to schedule. The
/// StateMachine launches them outside the serial mutation point.
public protocol Intent: Sendable {
    func mutate(
        persistent: inout PersistentState,
        ephemeral: inout EphemeralState
    ) -> [any Activity]
}
