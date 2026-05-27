Decision: One-way state machine as the basis for state synchronization and as the single source of truth for the UI.

Reasoning: A serial mutation point lets the app run multiple concurrent activities (e.g. search, persistence, future bulk operations) without ad-hoc locks and without tying activity lifetimes to view controllers or view state. The one-way state machine also offers the unique ability to perfectly reproduce race conditions on logic decisions by replaying the captured intent stream against an initial state — useful for diagnosing tricky bugs after the fact.

## Review Scope

**Strengthens** findings about code that mutates `PersistentState` / `EphemeralState` outside of an `Intent`, introduces ad-hoc locks/queues to coordinate state, ties long-running operations to view lifetimes, or branches business logic on something other than the StateMachine's serial mutation point. **Drops** complaints that the single serial intent pipeline is a "bottleneck" — serial mutation is the deliberate trade that buys race-condition replay and removes locking from the rest of the codebase.
