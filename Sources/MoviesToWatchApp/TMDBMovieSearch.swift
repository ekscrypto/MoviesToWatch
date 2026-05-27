import Foundation
import DomainLogic

/// Production search adapter backed by the TMDB v3 `/search/movie` endpoint,
/// authenticated with a v4 read access token via the `Authorization: Bearer`
/// header. Throws `AdapterMovieSearchError` on transport / API failures so
/// `ActivitySearchMovies` surfaces the message as `SearchState.failed`.
public struct TMDBMovieSearch: AdapterMovieSearch {
    private let bearerToken: String
    private let session: URLSession
    private let endpoint: URL

    public init(
        bearerToken: String,
        session: URLSession = .shared,
        endpoint: URL = URL(string: "https://api.themoviedb.org/3/search/movie")!
    ) {
        self.bearerToken = bearerToken
        self.session = session
        self.endpoint = endpoint
    }

    public func search(query: String) async throws -> [SearchHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "query", value: trimmed),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "page", value: "1"),
        ]
        guard let url = components.url else {
            throw AdapterMovieSearchError("Could not build search URL.")
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AdapterMovieSearchError("Network error: \(error.localizedDescription)")
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let apiMessage = (try? JSONDecoder().decode(TMDBError.self, from: data))?.status_message
            throw AdapterMovieSearchError(apiMessage ?? "TMDB returned HTTP \(http.statusCode).")
        }

        let decoded: TMDBSearchResponse
        do {
            decoded = try JSONDecoder().decode(TMDBSearchResponse.self, from: data)
        } catch {
            throw AdapterMovieSearchError("Could not parse TMDB response.")
        }

        return decoded.results.compactMap { entry in
            // Skip entries without a usable release year — TMDB occasionally
            // returns "" for unreleased or incomplete records.
            guard let releaseDate = entry.release_date,
                  let year = Int(releaseDate.prefix(4)) else { return nil }
            return SearchHit(id: String(entry.id), title: entry.title, year: year)
        }
    }
}

private struct TMDBSearchResponse: Decodable {
    let results: [TMDBEntry]
}

private struct TMDBEntry: Decodable {
    let id: Int
    let title: String
    let release_date: String?
}

private struct TMDBError: Decodable {
    let status_message: String?
}
