# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & test

Swift Package Manager project, macOS 14+, Swift 5.9.

```bash
swift build                                       # compile
swift run MoviesToWatchApp                        # launch the SwiftUI app
swift test                                        # run the full suite
swift test --filter MoviesToWatchTests/addingMovieAppearsInList    # single test
```

Per the global instruction in `~/.claude/CLAUDE.md`, redirect `swift test`/`swift build` output to a file under `/tmp/` and `Grep`/`Read` it — don't pipe to `grep`/`head` on the first run.

## Architecture

This repo is a demo of the ViewRep / Intent / StateMachine production pattern from <https://davepoirier.medium.com/viewrep-intent-statemachine-ios-architecture-4e3a2d589b36>. The architecture is the point of the codebase — its rules are recorded as ADRs in [`ADR/`](./ADR/), and the ADRs are authoritative. Read the ones relevant to your change before editing; don't paraphrase from memory.

| ADR | Topic |
| --- | --- |
| [ADR-001](./ADR/ADR-001-StateMachine.md) | StateMachine as one-way pipeline |
| [ADR-002](./ADR/ADR-002-FluentUnitTests.md) | Fluent unit tests |
| [ADR-003](./ADR/ADR-003-ViewRepAndIntentsInTests.md) | Drive via `Intent`, observe via `ViewRep` |
| [ADR-004](./ADR/ADR-004-StateDrivenUI.md) | State-driven UI via `ViewRep` |
| [ADR-005](./ADR/ADR-005-AdapterPattern.md) | Adapter pattern for system I/O |
| [ADR-006](./ADR/ADR-006-SwiftConcurrency.md) | Swift Concurrency only (no GCD / Combine) |
| [ADR-007](./ADR/ADR-007-SwiftUI.md) | SwiftUI for UI |
| [ADR-008](./ADR/ADR-008-TestExpectationsForViewRepWaits.md) | Predicate-driven `ViewRep` waits |
| [ADR-009](./ADR/ADR-009-ViewRepFailFastOnInvariants.md) | `ViewRep` consumers fail fast |
| [ADR-010](./ADR/ADR-010-SwiftTesting.md) | Swift Testing only (no XCTest) |
| [ADR-011](./ADR/ADR-011-WireShapeLockedAgainstLiteralFixtures.md) | Wire shapes locked against literal fixtures |
| [ADR-012](./ADR/ADR-012-CollapseFastOnCancel.md) | Cancellation is terminal |
| [ADR-013](./ADR/ADR-013-StateMachineInternalStateIsNotQueryable.md) | StateMachine internal state is not queryable |

Run `/adr-check` to audit pending changes against every ADR.

## Where things live

- `Sources/DomainLogic/State/` — `PersistentState`, `EphemeralState`, `Movie`, wire-shape coding.
- `Sources/DomainLogic/Intents/` — `Intent` conformers (one `mutate(...)` each).
- `Sources/DomainLogic/Activities/` — `Activity` conformers (async work, re-enter via `send(_:)`).
- `Sources/DomainLogic/StateMachine/StateMachine.swift` — the only actor; owns state and the `viewReps` `AsyncStream`.
- `Sources/DomainLogic/ViewRep/ViewRep.swift` — pure derived snapshot the UI binds to.
- `Sources/DomainLogic/Adapters/` — adapter protocols (`AdapterMoviesPersistence`, `AdapterMovieSearch`).
- `Sources/MoviesToWatchApp/` — macOS host: `AppState`, SwiftUI views, `ProductionAdapters.swift`.
- `Tests/DomainLogicTests/Scaffolding/` — `ScenarioForMoviesToWatch` and the simulated adapters.
- `Tests/DomainLogicTests/MoviesToWatchTests.swift` — worked examples of the fluent-scenario style.

## Adding a feature

Add an `Intent`, optionally an `Activity`, expose a fluent verb on `ScenarioForMoviesToWatch`, then write the test as a transcript. If a step can't be expressed fluently, the scenario API is missing a method — add the method, don't bypass the chain (ADR-002).
