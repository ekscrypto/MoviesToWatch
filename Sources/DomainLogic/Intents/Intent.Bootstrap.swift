import Foundation

/// First intent sent at launch. Schedules the persistence-load activity but
/// otherwise leaves state alone.
public struct IntentBootstrap: Intent {
    public init() {}

    public func mutate(
        persistent: inout PersistentState,
        ephemeral: inout EphemeralState
    ) -> [any Activity] {
        [ActivityLoadMovies()]
    }
}
