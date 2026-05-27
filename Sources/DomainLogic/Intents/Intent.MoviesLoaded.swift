import Foundation

/// Dispatched by `Activity.LoadMovies` once the persistence adapter returns.
/// Replaces the persistent movie list and flips `hasLoaded` so the UI can
/// transition out of its loading state.
public struct IntentMoviesLoaded: Intent {
    public let movies: [Movie]
    public init(movies: [Movie]) { self.movies = movies }

    public func mutate(
        persistent: inout PersistentState,
        ephemeral: inout EphemeralState
    ) -> [any Activity] {
        persistent.movies = movies
        return [ActivityMarkLoaded()]
    }
}

/// Tiny no-state activity that flips the `hasLoaded` flag inside the actor.
/// Kept as an activity (not an intent on its own) so the `IntentMoviesLoaded`
/// is purely a data drop and the loaded gate is a single source-controlled
/// flip.
struct ActivityMarkLoaded: Activity {
    func run(on stateMachine: StateMachine) async {
        await stateMachine.markLoaded()
        // Nudge a fresh emit so hasLoaded propagates to the UI promptly.
        await stateMachine.send(IntentNudge())
    }
}

struct IntentNudge: Intent {
    func mutate(
        persistent: inout PersistentState,
        ephemeral: inout EphemeralState
    ) -> [any Activity] { [] }
}
