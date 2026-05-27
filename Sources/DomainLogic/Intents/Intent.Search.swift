import Foundation

public struct IntentStartSearch: Intent {
    public let query: String
    public init(query: String) { self.query = query }

    public func mutate(
        persistent: inout PersistentState,
        ephemeral: inout EphemeralState
    ) -> [any Activity] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            ephemeral.search = .idle
            return []
        }
        // Park the query in `.debouncing`. `ActivityDebounceSearch` will sleep
        // for the configured interval and then send `IntentDebounceElapsed`,
        // which fires the real search only if this is still the latest query.
        ephemeral.search = .debouncing(query: trimmed)
        return [ActivityDebounceSearch(query: trimmed)]
    }
}

public struct IntentDebounceElapsed: Intent {
    public let query: String
    public init(query: String) { self.query = query }

    public func mutate(
        persistent: inout PersistentState,
        ephemeral: inout EphemeralState
    ) -> [any Activity] {
        // A newer keystroke (or a clear) replaced the pending query while we
        // were waiting — drop this fire.
        guard case .debouncing(let pending) = ephemeral.search, pending == query else {
            return []
        }
        ephemeral.search = .searching(query: query)
        return [ActivitySearchMovies(query: query)]
    }
}

public struct IntentSearchCompleted: Intent {
    public let query: String
    public let hits: [SearchHit]

    public init(query: String, hits: [SearchHit]) {
        self.query = query
        self.hits = hits
    }

    public func mutate(
        persistent: inout PersistentState,
        ephemeral: inout EphemeralState
    ) -> [any Activity] {
        // Drop late results from a query that was superseded.
        if case .searching(let inflight) = ephemeral.search, inflight == query {
            ephemeral.search = .results(query: query, hits: hits)
        }
        return []
    }
}

public struct IntentSearchFailed: Intent {
    public let query: String
    public let message: String

    public init(query: String, message: String) {
        self.query = query
        self.message = message
    }

    public func mutate(
        persistent: inout PersistentState,
        ephemeral: inout EphemeralState
    ) -> [any Activity] {
        if case .searching(let inflight) = ephemeral.search, inflight == query {
            ephemeral.search = .failed(query: query, message: message)
        }
        return []
    }
}

public struct IntentClearSearch: Intent {
    public init() {}

    public func mutate(
        persistent: inout PersistentState,
        ephemeral: inout EphemeralState
    ) -> [any Activity] {
        ephemeral.search = .idle
        return []
    }
}

public struct IntentAddFromSearchHit: Intent {
    public let hit: SearchHit
    public init(hit: SearchHit) { self.hit = hit }

    public func mutate(
        persistent: inout PersistentState,
        ephemeral: inout EphemeralState
    ) -> [any Activity] {
        persistent.movies.append(Movie(title: hit.title, year: hit.year))
        ephemeral.search = .idle
        return [ActivityPersistMovies()]
    }
}
