import Foundation
import SwiftUI
import DomainLogic

/// Observable bridge between SwiftUI and the StateMachine. Owns the
/// StateMachine, consumes its `viewReps` stream once, and republishes the
/// latest value as a `@Published`-equivalent for SwiftUI views.
@MainActor
@Observable
final class AppState {
    private(set) var viewRep: ViewRep = .init()

    let stateMachine: StateMachine
    private var consumer: Task<Void, Never>?

    init() {
        let persistence: AdapterMoviesPersistence
        do {
            persistence = try JSONFileMoviesPersistence()
        } catch {
            assertionFailure("could not build persistence: \(error)")
            persistence = NullPersistence()
        }
        let search: AdapterMovieSearch
        if let token = TMDBToken.resolve() {
            search = TMDBMovieSearch(bearerToken: token)
        } else {
            print("MoviesToWatch: no TMDB token found — falling back to BundledMovieSearch. See README for setup.")
            search = BundledMovieSearch()
        }
        let adapters = Adapters(persistence: persistence, search: search)
        self.stateMachine = StateMachine(adapters: adapters)
        startConsumingViewReps()
        Task { await stateMachine.bootstrap() }
    }

    private func startConsumingViewReps() {
        let stream = stateMachine.viewReps
        consumer = Task { @MainActor [weak self] in
            for await next in stream {
                self?.viewRep = next
            }
        }
    }

    func send(_ intent: any Intent) {
        Task { await stateMachine.send(intent) }
    }
}

/// Fallback that swallows reads/writes — used only if Application Support
/// isn't writable, which would mean a much bigger problem than this demo.
struct NullPersistence: AdapterMoviesPersistence {
    func load() async throws -> [Movie] { [] }
    func save(_ movies: [Movie]) async throws {}
}
