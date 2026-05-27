import Foundation
@testable import DomainLogic

/// Programmable fake for `AdapterMovieSearch`. Tests pre-arm a response, then
/// fire an `IntentStartSearch`; this fake answers the next `search(query:)`
/// call with the pre-armed hits, error, or delayed result.
public actor SimulatedMovieSearch: AdapterMovieSearch {
    public enum Response: Sendable {
        case hits([SearchHit])
        case failure(message: String)
    }

    private var nextResponse: Response = .hits([])
    private(set) public var receivedQueries: [String] = []

    public init() {}

    public func arm(_ response: Response) { nextResponse = response }

    public func arm(hits: [SearchHit]) { nextResponse = .hits(hits) }

    public func arm(failure message: String) {
        nextResponse = .failure(message: message)
    }

    public func search(query: String) async throws -> [SearchHit] {
        receivedQueries.append(query)
        switch nextResponse {
        case .hits(let hits): return hits
        case .failure(let message): throw AdapterMovieSearchError(message)
        }
    }
}
