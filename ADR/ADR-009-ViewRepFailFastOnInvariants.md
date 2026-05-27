Decision: `ViewRep` is trusted to be internally consistent. Consumers downstream of a `ViewRep` field — SwiftUI views, `ViewRep` sub-mappers — may assume any state implied by the `ViewRep` is present (for example, if a `ViewRep` case names a selected movie, the matching movie entry exists) and `fatalError()` if it isn't. Silent degradation — a placeholder view, an empty-state fallback, an optional return unwrapped to a default — is the wrong fix. The invariants that keep `ViewRep` valid are enforced upstream by the StateMachine and pinned by fluent unit tests (ADR-002, ADR-003); a violation is a bug to surface, not to hide.

Optional return types remain appropriate for genuine "nothing to render" cases driven by user toggles or nil-in / nil-out passthroughs — not for required state that the `ViewRep` is supposed to guarantee.

## Review Scope

**Drops** findings that ask `ViewRep` consumers to gracefully degrade (return a placeholder, fall back to an empty state, or make a required field optional) instead of `fatalError()`-ing on a missing invariant. **Strengthens** findings about types whose doc-comments claim a contract their signature doesn't enforce (default-valued parameters papering over a "required" field, optional properties the code treats as non-optional) — encode invariants in the type, not the comment.
