Decision: Have the UI fully reactive to the app's state, mediated by `ViewRep`.

Reasoning: Avoids issues where internal state and visible state disagree, or where multiple UI representations of the same state drift. Allows unit tests to observe the state of the UI at any time. Also makes it easy to reconstruct SwiftUI previews of any app state for fine-tuning UX.

Exception: SwiftUI may use `@State` variables for non-critical paths to improve UX, especially around animations and input fields, and for transient input buffers that are flushed to state via `Intent`.

Reconciliation contract: local `@State` mirroring a `ViewRep` value must accept that the next `ViewRep` render is authoritative — initialise from `ViewRep`, never persist beyond the view's lifetime, and never branch business logic on the local copy.

## Review Scope

**Strengthens** findings about UI that renders from sources other than `ViewRep`, branches business logic on local `@State`, persists `@State` past the view's lifetime, or shows data that disagrees with the underlying app state. **Drops** complaints about SwiftUI `@State` used for animations, transient input buffers, or other non-critical UX paths that flush back through `Intent` — these are the sanctioned exception.
