import Foundation
import DomainLogic

/// Writes movies to a JSON file under Application Support. A real production
/// app would handle migrations, atomic-replace, and corruption recovery; this
/// stays small because the architecture demo is the point.
public actor JSONFileMoviesPersistence: AdapterMoviesPersistence {
    private let url: URL

    public init() throws {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = appSupport.appendingPathComponent("MoviesToWatch", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.url = dir.appendingPathComponent("movies.json")
    }

    public func load() async throws -> [Movie] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try MoviePersistenceCoding.decoder.decode([Movie].self, from: data)
    }

    public func save(_ movies: [Movie]) async throws {
        let data = try MoviePersistenceCoding.encoder.encode(movies)
        try data.write(to: url, options: .atomic)
    }
}

/// A tiny in-process search over a bundled catalogue. Demonstrates the
/// adapter pattern without depending on a network. Real apps would call OMDb,
/// TMDB, etc. — same protocol shape, same intents.
public struct BundledMovieSearch: AdapterMovieSearch {
    private static let catalogue: [SearchHit] = [
        .init(id: "1", title: "The Matrix",            year: 1999),
        .init(id: "2", title: "The Matrix Reloaded",   year: 2003),
        .init(id: "3", title: "Blade Runner",          year: 1982),
        .init(id: "4", title: "Blade Runner 2049",     year: 2017),
        .init(id: "5", title: "Inception",             year: 2010),
        .init(id: "6", title: "Interstellar",          year: 2014),
        .init(id: "7", title: "Tenet",                 year: 2020),
        .init(id: "8", title: "Oppenheimer",           year: 2023),
        .init(id: "9", title: "Dune",                  year: 2021),
        .init(id: "10", title: "Dune: Part Two",       year: 2024),
        .init(id: "11", title: "Arrival",              year: 2016),
        .init(id: "12", title: "Sicario",              year: 2015),
        .init(id: "13", title: "Heat",                 year: 1995),
        .init(id: "14", title: "Collateral",           year: 2004),
        .init(id: "15", title: "The Departed",         year: 2006),
        .init(id: "16", title: "Whiplash",             year: 2014),
        .init(id: "17", title: "La La Land",           year: 2016),
        .init(id: "18", title: "Parasite",             year: 2019),
        .init(id: "19", title: "Everything Everywhere All at Once", year: 2022),
        .init(id: "20", title: "Spirited Away",        year: 2001),
    ]

    public init() {}

    public func search(query: String) async throws -> [SearchHit] {
        try await Task.sleep(for: .milliseconds(300)) // simulate network latency
        let needle = query.lowercased()
        return Self.catalogue.filter { $0.title.lowercased().contains(needle) }
    }
}
