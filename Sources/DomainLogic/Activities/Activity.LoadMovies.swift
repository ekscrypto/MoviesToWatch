import Foundation

/// Runs once at launch: asks the persistence adapter for the saved movie list
/// and writes it back into state via `IntentMoviesLoaded`.
public struct ActivityLoadMovies: Activity {
    public init() {}

    public func run(on stateMachine: StateMachine) async {
        let movies: [Movie]
        do {
            movies = try await stateMachine.adapters.persistence.load()
        } catch {
            // For a demo, a missing/corrupt store reloads empty. Production
            // would surface an error banner via a dedicated intent.
            movies = []
        }
        await stateMachine.send(IntentMoviesLoaded(movies: movies))
    }
}
