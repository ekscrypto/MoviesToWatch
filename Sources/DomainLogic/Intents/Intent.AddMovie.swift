import Foundation

public struct IntentAddMovie: Intent {
    public let title: String
    public let year: Int

    public init(title: String, year: Int) {
        self.title = title
        self.year = year
    }

    public func mutate(
        persistent: inout PersistentState,
        ephemeral: inout EphemeralState
    ) -> [any Activity] {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        persistent.movies.append(Movie(title: trimmed, year: year))
        return [ActivityPersistMovies()]
    }
}
