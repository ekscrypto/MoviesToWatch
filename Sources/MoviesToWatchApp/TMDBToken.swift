import Foundation

/// Resolves the TMDB v4 read access token used by `TMDBMovieSearch`. The token
/// is looked up first in the `TMDB_BEARER_TOKEN` environment variable, then in
/// a `tmdb-token.txt` file at the current working directory (gitignored). The
/// file path is convenient for `swift run` invocations, which set the working
/// directory to the package root. See `README.md` for setup instructions.
enum TMDBToken {
    static func resolve() -> String? {
        if let env = ProcessInfo.processInfo.environment["TMDB_BEARER_TOKEN"] {
            let trimmed = env.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        let cwd = FileManager.default.currentDirectoryPath
        let url = URL(fileURLWithPath: cwd).appendingPathComponent("tmdb-token.txt")
        guard
            let data = try? Data(contentsOf: url),
            let raw = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
