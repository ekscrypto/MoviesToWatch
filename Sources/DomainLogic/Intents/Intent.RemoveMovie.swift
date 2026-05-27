import Foundation

public struct IntentRemoveMovie: Intent {
    public let id: UUID
    public init(id: UUID) { self.id = id }

    public func mutate(
        persistent: inout PersistentState,
        ephemeral: inout EphemeralState
    ) -> [any Activity] {
        let before = persistent.movies.count
        persistent.movies.removeAll { $0.id == id }
        return persistent.movies.count == before ? [] : [ActivityPersistMovies()]
    }
}
