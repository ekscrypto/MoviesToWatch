---
description: Scan the codebase for violations of every ADR in ./ADR/
argument-hint: "[optional: ADR number or path glob to scope the scan]"
allowed-tools: Read, Glob, Grep, Bash, Agent
---

# /adr-check — Architecture Decision Record audit

You are running an **audit pass** over this repository's Architecture Decision Records. The ADRs live in `ADR/ADR-NNN-*.md` at the repo root and each one's `## Review Scope` section defines what counts as a violation (and what does **not**). The ADRs are the spec — read them, do not paraphrase from memory.

## Scope of this run

$ARGUMENTS

If `$ARGUMENTS` is empty, audit every ADR against the entire `Sources/` and `Tests/` trees. If `$ARGUMENTS` names a specific ADR (e.g. `ADR-006` or `6`), only run that ADR's checks. If `$ARGUMENTS` looks like a path glob, only audit files matching it.

## Procedure

1. **Enumerate ADRs.** `Glob` `ADR/ADR-*.md` and `Read` each one in full. Treat the `Decision`, `Reasoning`, and `## Review Scope` (`Strengthens` / `Drops`) sections as the authoritative checklist. Do not invent rules that aren't in the ADRs, and respect every `Drops` clause — those are explicit non-violations.

2. **Plan the scan per-ADR.** For each ADR, write down (internally) the concrete patterns that would constitute a violation in Swift code. Lean on the prompts below for the ADRs in this repo, but the ADR text wins if it disagrees:

   - **ADR-001 — StateMachine as one-way pipeline.** Mutations to `PersistentState`/`EphemeralState` outside `Intent.mutate(...)`. Ad-hoc locks/queues, `NSLock`, `os_unfair_lock`, `DispatchSemaphore`, `actor` types added next to `StateMachine`. Business logic branching on something other than the serial mutation point.
   - **ADR-002 — Fluent unit tests.** In `Tests/`: disjoint `let scenario = …` followed by standalone `await scenario.foo()`; raw `FileManager`/`URLSession`/adapter plumbing in test bodies; setup helpers that return a captured scenario. Tests that swallow failures (`try?` on the chain, `_ = try await` on an assertion).
   - **ADR-003 — Drive via `Intent`, observe via `ViewRep`.** Tests that call activities directly, mutate `PersistentState`/`EphemeralState` from test code, or assert on `stateMachine`-internal fields rather than the `viewReps` stream.
   - **ADR-004 — State-driven UI via `ViewRep`.** SwiftUI views that read app data from anywhere other than `ViewRep` / `AppState.viewRep`. `@State` that branches business logic or persists past the view's lifetime. Direct calls into `StateMachine` from views (must go through `AppState.send`).
   - **ADR-005 — Adapter pattern for system I/O.** Domain or activity code that calls `URLSession`, `FileManager`, `Process`, `Bundle`, `UserDefaults`, `Keychain`, or other OS APIs directly instead of through an `Adapter*` protocol. New external dependencies wired without a protocol seam.
   - **ADR-006 — Swift Concurrency only.** Any `DispatchQueue`, `DispatchQueue.async`, `asyncAfter`, `dispatch_*`, `PassthroughSubject`, `CurrentValueSubject`, `.sink`, `.throttle`, `.debounce`, `Combine` import in domain/activity/UI-observation code. Delays that use anything other than `Task.sleep`.
   - **ADR-007 — SwiftUI for UI.** New `NSViewController`/`NSView`/AppKit-only bindings in UI code when SwiftUI would suffice. AppKit glue that reintroduces delegate/retention-cycle risk.
   - **ADR-008 — Predicate-driven `ViewRep` waits.** `Task.sleep`-based polling loops in tests that wait on app state; sleep-then-assert patterns; any wait on `viewReps` that doesn't race a predicate Task against a timeout Task. The `waitUntil(...)` exception applies only to *adapter* waits, not `ViewRep`.
   - **ADR-009 — `ViewRep` consumers fail fast.** `ViewRep` sub-mappers / SwiftUI views that gracefully degrade on a missing invariant (placeholder view, empty-state fallback, `??` default, `if let … else { EmptyView() }`) where the `ViewRep` shape guarantees the value. Doc-comments that claim non-optional contracts the signature doesn't enforce.
   - **ADR-010 — Swift Testing only.** Any `import XCTest`, `XCTestCase` subclass, `XCAssert*`, `XCTestExpectation`, `XCTSkip`, `XCTFail`, `setUp`/`tearDown` override in `Tests/`.
   - **ADR-011 — Wire shapes locked against literal fixtures.** `Codable` types written to disk or sent across a process boundary whose only test coverage is a round-trip; missing literal-string fixture; types with a `schemaVersion` field but no `currentSchemaVersion` constant, no forward-rejection `init(from:)`, or no test pinning either. Changes to `CodingKeys`, enum discriminators, or `Optional` encoding strategy without a matching fixture update in the same change.
   - **ADR-012 — Cancellation is terminal.** Lifecycle Update `Intent`s whose `mutate(...)` accepts a running-shaped status without first refusing to overwrite the cancelling/terminal shape. Activities that keep emitting status `Intent`s after observing cooperative cancellation. Activities that mirror intermediate output into `PersistentState`/`EphemeralState` with no consumer.
   - **ADR-013 — StateMachine internal state is not queryable.** New `func get…`, `func read…`, `func current…`, or property accessors on `StateMachine` that hand `PersistentState`/`EphemeralState` (or values derived from them) to non-`Intent` callers. Widening of the `internal` helpers `markLoaded()` / `snapshotMovies()` to a broader scope. Activities or tests that branch on a StateMachine accessor instead of dispatching an `Intent`.

3. **Execute the scan.** Prefer `Grep` with focused patterns and a `glob`/`type` filter (e.g. `type: "swift"`, `glob: "Sources/**/*.swift"`). For ADRs that need broader judgement (ADR-002, ADR-009, ADR-011, ADR-012), `Read` the suspect files in full — do not rely on a single regex hit. When a scan would take more than ~4 focused Greps, spawn an `Agent` (subagent_type `Explore`, thoroughness `medium`) with the ADR's `## Review Scope` text inlined into the prompt and ask it to return a list of `file:line — finding` lines.

4. **Filter by `Drops` clauses.** Before recording a finding, re-read the ADR's `Drops` section. Sanctioned exceptions (e.g. SwiftUI `@State` for animations under ADR-004; the `waitUntil(...)` adapter-wait exception under ADR-008; in-memory `Codable` shapes under ADR-011) are **not** violations. If a candidate finding matches a `Drops` clause, discard it silently.

5. **Verify before reporting.** For each surviving finding, `Read` the surrounding ±20 lines to confirm the violation is real in context (not a comment, not a test demonstrating the anti-pattern intentionally, not the documented exception). False positives are worse than misses here — the report has to be trustworthy enough to action without re-checking every line.

## Report format

Output a single Markdown report to the conversation (no file writes). Group strictly by ADR; within each ADR, list findings as bullet items keyed by `path:line`:

```
# ADR audit — <repo name>

## ADR-001 — StateMachine as one-way pipeline
- Sources/DomainLogic/Activities/Foo.swift:42 — `persistent.movies.append(...)` mutation outside `Intent.mutate(...)`; activities must dispatch an Intent (ADR-001 + ADR-013).
- …

## ADR-006 — Swift Concurrency only
- (no findings)

…

# Summary
- Total findings: N
- ADRs with findings: ADR-001, ADR-004, …
- ADRs clean: ADR-002, ADR-003, …
```

Rules for the report:

- **One ADR section per ADR**, in numeric order, even when empty (write `(no findings)` so the reader can tell the check ran).
- **Cite `path:line`** for every finding, with one-sentence "why this violates" anchored in ADR vocabulary.
- **Quote the offending snippet** only when the violation isn't self-evident from the path/line. Keep snippets to ≤3 lines.
- **Cross-reference ADRs** when a single finding violates more than one (e.g. an `actor` accessor that breaks both ADR-001 and ADR-013) — list it once under the primary ADR and mention the secondary in the same bullet.
- **Do not propose fixes** in this report. The job is detection. Fixes are a separate request.
- **Do not flag the ADRs themselves**, the `Tests/.../Scaffolding/` simulated adapters (they're the sanctioned doubles), or `ProductionAdapters.swift` boundary code that legitimately wraps `URLSession`/`FileManager` (that's the adapter — the violation would be skipping the adapter, not implementing it).

If the audit finds zero violations across all ADRs, still print the per-ADR sections (each `(no findings)`) and the summary — a clean run is a meaningful result.
