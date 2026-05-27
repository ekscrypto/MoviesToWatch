import Foundation

/// State that is reset on every launch. Holds UI selections and in-flight
/// activity status that should not survive a relaunch.
public struct EphemeralState: Equatable, Sendable {
    public var filter: MovieFilter
    public var search: SearchState

    public init(
        filter: MovieFilter = .toWatch,
        search: SearchState = .idle
    ) {
        self.filter = filter
        self.search = search
    }
}

public enum MovieFilter: String, Sendable, CaseIterable {
    case all
    case toWatch
    case watched
}

public enum SearchState: Equatable, Sendable {
    case idle
    case debouncing(query: String)
    case searching(query: String)
    case results(query: String, hits: [SearchHit])
    case failed(query: String, message: String)
}
