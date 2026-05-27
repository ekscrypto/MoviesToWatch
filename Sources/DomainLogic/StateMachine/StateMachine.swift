import Foundation

/// Single source of truth. Owns `PersistentState` and `EphemeralState`,
/// processes `Intent`s serially inside the actor, and publishes a throttled
/// stream of `ViewRep`s.
///
/// Per ADR-013, this type exposes no read accessors for state — activities
/// that need a value send an intent whose `mutate(...)` performs the read
/// inside the serial point.
public actor StateMachine {
    public static let throttleInterval: Duration = .milliseconds(250)

    private var persistent: PersistentState
    private var ephemeral: EphemeralState
    private var hasLoaded: Bool = false

    public nonisolated let adapters: Adapters
    public nonisolated let searchDebounceInterval: Duration
    public nonisolated let viewReps: AsyncStream<ViewRep>
    private let viewRepContinuation: AsyncStream<ViewRep>.Continuation

    private var pendingFlush: Task<Void, Never>?
    private var lastEmitAt: ContinuousClock.Instant?
    private var lastEmitted: ViewRep?

    private var persistRequested = false
    private var persistLoopActive = false

    public init(
        adapters: Adapters,
        persistent: PersistentState = .init(),
        searchDebounceInterval: Duration = .milliseconds(300)
    ) {
        self.adapters = adapters
        self.searchDebounceInterval = searchDebounceInterval
        self.persistent = persistent
        self.ephemeral = .init()
        let (stream, continuation) = AsyncStream<ViewRep>.makeStream(
            bufferingPolicy: .bufferingNewest(8)
        )
        self.viewReps = stream
        self.viewRepContinuation = continuation
    }

    /// Process an intent, then schedule any activities it produced.
    public func send(_ intent: any Intent) {
        let activities = intent.mutate(
            persistent: &persistent,
            ephemeral: &ephemeral
        )
        scheduleViewRepEmit()
        for activity in activities {
            Task { [self] in await activity.run(on: self) }
        }
    }

    /// Called once at app launch to kick off the initial load.
    public func bootstrap() {
        send(IntentBootstrap())
    }

    /// Mutator used by `IntentMoviesLoaded` to flip the loaded gate. Kept
    /// internal to the actor so external callers can't bypass it.
    internal func markLoaded() {
        hasLoaded = true
    }

    /// Captures the current movie list inside the actor's serial point for
    /// `Activity.PersistMovies`. Returning a value-type snapshot is safe.
    internal func snapshotMovies() -> [Movie] {
        persistent.movies
    }

    /// Requests a debounced flush to the persistence adapter. Multiple
    /// concurrent requests coalesce into one save loop that always writes
    /// the freshest snapshot — no stale save can clobber a newer one.
    internal func requestPersist() {
        persistRequested = true
        guard !persistLoopActive else { return }
        persistLoopActive = true
        Task { [self] in await self.runPersistLoop() }
    }

    private func runPersistLoop() async {
        while popPersistRequest() {
            let snapshot = persistent.movies
            try? await adapters.persistence.save(snapshot)
        }
    }

    private func popPersistRequest() -> Bool {
        if persistRequested {
            persistRequested = false
            return true
        }
        persistLoopActive = false
        return false
    }

    private func scheduleViewRepEmit() {
        let now = ContinuousClock.now
        if let last = lastEmitAt {
            let elapsed = last.duration(to: now)
            if elapsed >= Self.throttleInterval {
                emitNow()
            } else if pendingFlush == nil {
                let remaining = Self.throttleInterval - elapsed
                pendingFlush = Task { [self] in
                    try? await Task.sleep(for: remaining)
                    self.flush()
                }
            }
        } else {
            emitNow()
        }
    }

    private func flush() {
        pendingFlush = nil
        emitNow()
    }

    private func emitNow() {
        let next = ViewRep.from(persistent, ephemeral, hasLoaded: hasLoaded)
        if next == lastEmitted { return }
        lastEmitted = next
        lastEmitAt = ContinuousClock.now
        viewRepContinuation.yield(next)
    }
}
