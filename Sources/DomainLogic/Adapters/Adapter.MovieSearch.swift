import Foundation

/// Searches a movie catalogue (production: a small bundled list; tests: a
/// programmable fake). Returns at most a handful of hits.
public protocol AdapterMovieSearch: Sendable {
    func search(query: String) async throws -> [SearchHit]
}

public struct AdapterMovieSearchError: Error, Equatable, Sendable {
    public let message: String
    public init(_ message: String) { self.message = message }
}
