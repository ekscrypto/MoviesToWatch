Decision: Use the Adapter pattern to wrap every system interaction — network calls, on-disk persistence, sub-process execution, OS APIs — behind a protocol. In this demo: `AdapterMoviesPersistence` and `AdapterMovieSearch`.

Reasoning: Makes it possible to substitute stub / simulated implementations during unit tests to reproduce any success / failure state and have near-perfect control over timings. Production wiring (`ProductionAdapters.swift`) and simulated wiring (`Tests/DomainLogicTests/Scaffolding/`) sit on either side of the same protocol.

## Review Scope

**Strengthens** findings about domain or activity code that calls `URLSession`, `FileManager`, `Process`, or other system facilities directly instead of going through an `Adapter.*` interface — anything that cannot be substituted by a `Simulated*` test double is a violation. **Drops** complaints that the adapter layer is "extra indirection" or "boilerplate" — the indirection is the deliberate cost of full mockability and is non-negotiable for code paths under test.
