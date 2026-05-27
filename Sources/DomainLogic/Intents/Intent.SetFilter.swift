import Foundation

public struct IntentSetFilter: Intent {
    public let filter: MovieFilter
    public init(_ filter: MovieFilter) { self.filter = filter }

    public func mutate(
        persistent: inout PersistentState,
        ephemeral: inout EphemeralState
    ) -> [any Activity] {
        ephemeral.filter = filter
        return []
    }
}
