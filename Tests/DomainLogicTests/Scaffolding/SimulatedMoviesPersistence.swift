import Foundation
@testable import DomainLogic

/// In-memory persistence used by `ScenarioForMoviesToWatch`. Exposes
/// `snapshot` so tests can assert what was written, and `replace(_:)` so a
/// test can simulate a relaunch where the on-disk movies differ from what
/// the previous session would have saved.
public actor SimulatedMoviesPersistence: AdapterMoviesPersistence {
    private var stored: [Movie]

    public init(initial: [Movie] = []) {
        self.stored = initial
    }

    public func load() async throws -> [Movie] { stored }

    public func save(_ movies: [Movie]) async throws { stored = movies }

    public func snapshot() -> [Movie] { stored }

    /// Replace the simulated on-disk contents. Useful in tests that simulate
    /// a relaunch against a curated starting state.
    public func replace(_ movies: [Movie]) { stored = movies }
}
