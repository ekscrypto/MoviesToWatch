import Foundation

public struct IntentToggleWatched: Intent {
    public let id: UUID
    public init(id: UUID) { self.id = id }

    public func mutate(
        persistent: inout PersistentState,
        ephemeral: inout EphemeralState
    ) -> [any Activity] {
        guard let idx = persistent.movies.firstIndex(where: { $0.id == id }) else {
            return []
        }
        persistent.movies[idx].watched.toggle()
        return [ActivityPersistMovies()]
    }
}
