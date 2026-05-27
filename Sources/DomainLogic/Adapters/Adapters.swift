import Foundation

/// The full set of adapters the StateMachine needs. Production wires real
/// implementations; tests wire simulated ones.
public struct Adapters: Sendable {
    public let persistence: AdapterMoviesPersistence
    public let search: AdapterMovieSearch

    public init(persistence: AdapterMoviesPersistence, search: AdapterMovieSearch) {
        self.persistence = persistence
        self.search = search
    }
}
