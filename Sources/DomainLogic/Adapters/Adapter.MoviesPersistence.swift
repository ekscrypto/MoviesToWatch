import Foundation

/// Reads and writes the persisted movie list. The production implementation
/// uses a JSON file under Application Support; tests use an in-memory
/// `SimulatedMoviesPersistence`.
public protocol AdapterMoviesPersistence: Sendable {
    func load() async throws -> [Movie]
    func save(_ movies: [Movie]) async throws
}
