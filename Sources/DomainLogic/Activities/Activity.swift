import Foundation

/// Long-running async work. Activities write back to the StateMachine by
/// dispatching intents — they never mutate state directly.
public protocol Activity: Sendable {
    func run(on stateMachine: StateMachine) async
}
