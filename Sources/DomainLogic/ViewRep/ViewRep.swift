import Foundation

/// A pure value-type snapshot of everything the UI needs to render. Derived
/// from `PersistentState + EphemeralState` by `ViewRep.from(...)`. SwiftUI
/// views consume a `@Published`-like stream of these; tests parse them via
/// `viewRep.values` predicates per ADR-008.
public struct ViewRep: Equatable, Sendable {
    public var hasLoaded: Bool
    public var visibleMovies: [Movie]
    public var filter: MovieFilter
    public var totalCount: Int
    public var toWatchCount: Int
    public var watchedCount: Int
    public var search: SearchState

    public init(
        hasLoaded: Bool = false,
        visibleMovies: [Movie] = [],
        filter: MovieFilter = .toWatch,
        totalCount: Int = 0,
        toWatchCount: Int = 0,
        watchedCount: Int = 0,
        search: SearchState = .idle
    ) {
        self.hasLoaded = hasLoaded
        self.visibleMovies = visibleMovies
        self.filter = filter
        self.totalCount = totalCount
        self.toWatchCount = toWatchCount
        self.watchedCount = watchedCount
        self.search = search
    }
}

extension ViewRep {
    static func from(
        _ persistent: PersistentState,
        _ ephemeral: EphemeralState,
        hasLoaded: Bool
    ) -> ViewRep {
        let all = persistent.movies
        let visible: [Movie]
        switch ephemeral.filter {
        case .all:     visible = all
        case .toWatch: visible = all.filter { !$0.watched }
        case .watched: visible = all.filter { $0.watched }
        }
        return ViewRep(
            hasLoaded: hasLoaded,
            visibleMovies: visible.sorted { $0.addedAt > $1.addedAt },
            filter: ephemeral.filter,
            totalCount: all.count,
            toWatchCount: all.lazy.filter { !$0.watched }.count,
            watchedCount: all.lazy.filter { $0.watched }.count,
            search: ephemeral.search
        )
    }
}
