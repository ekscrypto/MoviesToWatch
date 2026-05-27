import Foundation

/// Calls the search adapter and writes the result back as an intent. The
/// completion intent itself drops late results from a superseded query, so
/// this activity doesn't need to dedupe.
public struct ActivitySearchMovies: Activity {
    public let query: String
    public init(query: String) { self.query = query }

    public func run(on stateMachine: StateMachine) async {
        do {
            let hits = try await stateMachine.adapters.search.search(query: query)
            await stateMachine.send(IntentSearchCompleted(query: query, hits: hits))
        } catch {
            let message = (error as? AdapterMovieSearchError)?.message
                ?? "Search failed."
            await stateMachine.send(IntentSearchFailed(query: query, message: message))
        }
    }
}
