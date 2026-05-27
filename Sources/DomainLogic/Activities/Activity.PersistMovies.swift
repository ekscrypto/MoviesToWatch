import Foundation

/// Signals the StateMachine that persistence should be flushed. The
/// StateMachine debounces concurrent requests — multiple in-flight saves
/// collapse into one loop that always writes the freshest snapshot, so a
/// stale save can never clobber a newer one (and the persistence adapter
/// stays free to be a simple "write the bytes" adapter).
public struct ActivityPersistMovies: Activity {
    public init() {}

    public func run(on stateMachine: StateMachine) async {
        await stateMachine.requestPersist()
    }
}
