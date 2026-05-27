Decision: Test scaffolding that waits for a `ViewRep` state must observe the `StateMachine.viewReps` `AsyncStream<ViewRep>` from a structured `Task` and resolve the moment the predicate holds, never a `Task.sleep` polling loop. The wait surfaces to a Swift Testing case (ADR-010) as a `withTaskGroup` that races the predicate task against a timeout task, reporting failure through `Issue.record`. The source of truth is always the stream, not wall-clock polling.

Reasoning: A predicate-driven wait returns the instant the predicate holds and observes every transient state, whereas a sleep loop quantises wall time to the poll interval and can miss brief intermediate states between samples. The `AsyncStream` makes every emission observable in causal order to a subscriber whose `Task` was already running when the emission was yielded — so standardising on stream-observation keeps every scenario helper consistent and avoids per-helper ad-hoc timing.

Note: the one exception in this demo is `waitUntil(...)` used to wait on a *simulated adapter* (e.g. before relaunch) — that wait is observing the adapter, not the `ViewRep`, so it is not bound by this ADR. The rule binds anything that waits on app-state visible through `ViewRep`.

## Review Scope

**Strengthens** findings about `Task.sleep`-based waits, polling loops, or any test timing that doesn't observe `StateMachine.viewReps`. Conversely, **drops** complaints about a wait being "racy" when it already uses the stream — actor isolation closes the subscribe-vs-emit race by construction.
