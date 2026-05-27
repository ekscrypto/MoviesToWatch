import Foundation
@testable import DomainLogic

/// Fluent test driver. Constructs a fully-wired `StateMachine` with
/// simulated adapters, then provides chainable user-action methods and
/// ViewRep-based expectations.
///
/// Per ADR-003, tests never reach into the StateMachine's internal state —
/// they drive via `send(_:)` and observe via the ViewRep stream. Per ADR-008,
/// waits race the predicate against a timeout task; no `Task.sleep` polling.
@MainActor
public final class ScenarioForMoviesToWatch {
    public let stateMachine: StateMachine
    public let persistence: SimulatedMoviesPersistence
    public let search: SimulatedMovieSearch

    private var observedViewReps: [ViewRep] = []
    private var waiters: [Waiter] = []
    private var consumer: Task<Void, Never>!

    private struct Waiter {
        let id: UUID
        let predicate: (ViewRep) -> Bool
        let continuation: CheckedContinuation<Bool, Never>
    }

    public struct TimeoutError: Error, CustomStringConvertible {
        public let description: String
        init(_ description: String) { self.description = description }
    }

    public struct ExpectationFailure: Error, CustomStringConvertible {
        public let description: String
        init(_ description: String) { self.description = description }
    }

    private init(
        stateMachine: StateMachine,
        persistence: SimulatedMoviesPersistence,
        search: SimulatedMovieSearch
    ) {
        self.stateMachine = stateMachine
        self.persistence = persistence
        self.search = search
        let stream = stateMachine.viewReps
        self.consumer = Task { @MainActor [weak self] in
            for await vr in stream {
                self?.handle(vr)
            }
        }
    }

    deinit { consumer.cancel() }

    /// Boot a fresh app. `startingMovies` simulates what would have been on
    /// disk from a previous session. `searchDebounceInterval` defaults to
    /// `.zero` so existing tests don't pay a debounce wait per search — tests
    /// that exercise debounce coalescing pass a non-zero value explicitly.
    public static func freshLaunch(
        startingMovies: [Movie] = [],
        searchDebounceInterval: Duration = .zero
    ) async throws -> ScenarioForMoviesToWatch {
        let persistence = SimulatedMoviesPersistence(initial: startingMovies)
        let search = SimulatedMovieSearch()
        let adapters = Adapters(persistence: persistence, search: search)
        let stateMachine = StateMachine(
            adapters: adapters,
            searchDebounceInterval: searchDebounceInterval
        )
        let scenario = ScenarioForMoviesToWatch(
            stateMachine: stateMachine,
            persistence: persistence,
            search: search
        )
        await stateMachine.bootstrap()
        try await scenario.waitFor("initial load to complete") { $0.hasLoaded }
        return scenario
    }

    // MARK: User actions

    @discardableResult
    public func addMovie(title: String, year: Int) async -> Self {
        await stateMachine.send(IntentAddMovie(title: title, year: year))
        return self
    }

    @discardableResult
    public func toggleWatched(movieAt index: Int) async throws -> Self {
        try await waitFor("≥\(index + 1) visible movies") { vr in
            vr.visibleMovies.count > index
        }
        let id = observedViewReps.last!.visibleMovies[index].id
        await stateMachine.send(IntentToggleWatched(id: id))
        return self
    }

    @discardableResult
    public func toggleWatched(titled title: String) async throws -> Self {
        try await waitFor("movie '\(title)' visible") { vr in
            vr.visibleMovies.contains { $0.title == title }
        }
        let id = observedViewReps.last!.visibleMovies.first { $0.title == title }!.id
        await stateMachine.send(IntentToggleWatched(id: id))
        return self
    }

    @discardableResult
    public func removeMovie(titled title: String) async throws -> Self {
        try await waitFor("movie '\(title)' visible") { vr in
            vr.visibleMovies.contains { $0.title == title }
        }
        let id = observedViewReps.last!.visibleMovies.first { $0.title == title }!.id
        await stateMachine.send(IntentRemoveMovie(id: id))
        return self
    }

    @discardableResult
    public func setFilter(_ filter: MovieFilter) async -> Self {
        await stateMachine.send(IntentSetFilter(filter))
        return self
    }

    @discardableResult
    public func search(_ query: String, arm response: SimulatedMovieSearch.Response) async -> Self {
        await search.arm(response)
        await stateMachine.send(IntentStartSearch(query: query))
        return self
    }

    /// Dispatches `IntentStartSearch` without arming the search adapter. Used
    /// by tests that exercise debounce-cancel paths where the search must
    /// never reach the adapter at all.
    @discardableResult
    public func startSearch(_ query: String) async -> Self {
        await stateMachine.send(IntentStartSearch(query: query))
        return self
    }

    @discardableResult
    public func clearSearch() async -> Self {
        await stateMachine.send(IntentClearSearch())
        return self
    }

    /// Sleeps for the configured search debounce window plus a small margin so
    /// any pending `ActivityDebounceSearch` has had a chance to wake up and
    /// run its `IntentDebounceElapsed` guard. Encapsulated here so test bodies
    /// don't sprinkle `Task.sleep` for adapter-timing observations (ADR-002).
    @discardableResult
    public func waitForDebounceWindow(margin: Duration = .milliseconds(100)) async -> Self {
        try? await Task.sleep(for: stateMachine.searchDebounceInterval + margin)
        return self
    }

    /// Asserts the search adapter has received exactly the expected query
    /// list. Wrapping the adapter access in a scenario method keeps the test
    /// body free of raw adapter plumbing per ADR-002.
    @discardableResult
    public func expectAdapterQueries(_ expected: [String]) async throws -> Self {
        let actual = await search.receivedQueries
        if actual != expected {
            throw ExpectationFailure(
                "expected adapter queries \(expected), got \(actual)"
            )
        }
        return self
    }

    /// Waits until the simulated persistence holds `expected` movies on disk.
    /// Wraps the adapter access so test bodies stay free of raw adapter
    /// plumbing (ADR-002); the wait observes the adapter, not a `ViewRep`, so
    /// it falls under ADR-008's documented adapter-wait exception.
    @discardableResult
    public func waitForPersistedCount(
        _ expected: Int,
        timeout: Duration = .seconds(2)
    ) async throws -> Self {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while ContinuousClock.now < deadline {
            if await persistence.snapshot().count == expected { return self }
            try? await Task.sleep(for: .milliseconds(20))
        }
        if await persistence.snapshot().count == expected { return self }
        throw TimeoutError("timed out waiting for persisted count == \(expected)")
    }

    @discardableResult
    public func addFromHit(_ hit: SearchHit) async -> Self {
        await stateMachine.send(IntentAddFromSearchHit(hit: hit))
        return self
    }

    /// Simulates an app relaunch: tears down the current StateMachine and
    /// returns a fresh one against the same simulated disk.
    public func relaunch() async throws -> ScenarioForMoviesToWatch {
        consumer.cancel()
        let onDisk = await persistence.snapshot()
        return try await ScenarioForMoviesToWatch.freshLaunch(startingMovies: onDisk)
    }

    // MARK: Expectations

    @discardableResult
    public func expect(
        _ reason: String,
        timeout: Duration = .seconds(2),
        _ predicate: @escaping @Sendable (ViewRep) -> Bool
    ) async throws -> Self {
        try await waitFor(reason, timeout: timeout, predicate)
        return self
    }

    @discardableResult
    public func expectMovieInList(
        title: String,
        watched: Bool? = nil
    ) async throws -> Self {
        try await waitFor("movie '\(title)' visible") { vr in
            vr.visibleMovies.contains { movie in
                guard movie.title == title else { return false }
                if let watched { return movie.watched == watched }
                return true
            }
        }
        return self
    }

    @discardableResult
    public func expectMovieAbsent(title: String) async throws -> Self {
        try await waitFor("movie '\(title)' absent") { vr in
            !vr.visibleMovies.contains { $0.title == title }
        }
        return self
    }

    @discardableResult
    public func expectCounts(
        total: Int? = nil,
        toWatch: Int? = nil,
        watched: Int? = nil
    ) async throws -> Self {
        try await waitFor("counts total=\(total as Any) toWatch=\(toWatch as Any) watched=\(watched as Any)") { vr in
            if let total, vr.totalCount != total { return false }
            if let toWatch, vr.toWatchCount != toWatch { return false }
            if let watched, vr.watchedCount != watched { return false }
            return true
        }
        return self
    }

    @discardableResult
    public func expectSearchResults(
        for query: String,
        contain title: String
    ) async throws -> Self {
        try await waitFor("search '\(query)' returns '\(title)'") { vr in
            if case .results(let q, let hits) = vr.search,
               q == query,
               hits.contains(where: { $0.title == title }) {
                return true
            }
            return false
        }
        return self
    }

    @discardableResult
    public func expectSearchFailed(
        for query: String
    ) async throws -> Self {
        try await waitFor("search '\(query)' failed") { vr in
            if case .failed(let q, _) = vr.search, q == query { return true }
            return false
        }
        return self
    }

    public var latestViewRep: ViewRep? { observedViewReps.last }
    public var viewRepHistory: [ViewRep] { observedViewReps }

    // MARK: Internals

    private func handle(_ vr: ViewRep) {
        observedViewReps.append(vr)
        var remaining: [Waiter] = []
        for w in waiters {
            if w.predicate(vr) {
                w.continuation.resume(returning: true)
            } else {
                remaining.append(w)
            }
        }
        waiters = remaining
    }

    private func waitFor(
        _ reason: String,
        timeout: Duration = .seconds(2),
        _ predicate: @escaping @Sendable (ViewRep) -> Bool
    ) async throws {
        if let last = observedViewReps.last, predicate(last) { return }
        let id = UUID()
        let succeeded = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            waiters.append(Waiter(id: id, predicate: predicate, continuation: cont))
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: timeout)
                guard let self else { return }
                if let idx = self.waiters.firstIndex(where: { $0.id == id }) {
                    let waiter = self.waiters.remove(at: idx)
                    waiter.continuation.resume(returning: false)
                }
            }
        }
        if !succeeded {
            throw TimeoutError("timed out waiting for: \(reason)")
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
