import Foundation

/// State that survives app relaunches. The StateMachine is the only writer;
/// every change flows through an `Intent.mutate(...)`. Persistence to disk is
/// driven by `Activity.PersistMovies`, which the StateMachine schedules after
/// every mutation that touches this struct.
public struct PersistentState: Codable, Equatable, Sendable {
    public var movies: [Movie]

    public init(movies: [Movie] = []) {
        self.movies = movies
    }
}
