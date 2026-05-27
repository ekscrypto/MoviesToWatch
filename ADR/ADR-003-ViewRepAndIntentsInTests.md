Decision: Use `ViewRep` observers and user-shaped `Intent`s in tests rather than internal state manipulations.

Reasoning: We observe the data that the user has access to, and use the app like a user. This improves the ability to confirm the app will behave the same between unit tests and production, and allows refactoring of activities and intent implementations without breaking the tests.

## Review Scope

**Strengthens** findings about tests that poke internal `PersistentState` / `EphemeralState`, call activities directly, or assert against state fields instead of the `ViewRep` surface. Drives must go through `Intent.*`; observations must come from the `StateMachine.viewReps` stream.
