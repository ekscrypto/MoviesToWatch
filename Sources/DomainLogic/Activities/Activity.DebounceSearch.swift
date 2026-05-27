import Foundation

/// Waits for the StateMachine's configured search-debounce interval, then
/// dispatches `IntentDebounceElapsed`. The intent itself decides whether to
/// fire the real search by checking that the query is still the pending one.
public struct ActivityDebounceSearch: Activity {
    public let query: String
    public init(query: String) { self.query = query }

    public func run(on stateMachine: StateMachine) async {
        try? await Task.sleep(for: stateMachine.searchDebounceInterval)
        await stateMachine.send(IntentDebounceElapsed(query: query))
    }
}
