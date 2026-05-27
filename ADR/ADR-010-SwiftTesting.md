Decision: All test suites use Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`, `@Suite`, `confirmation`) exclusively. No `XCTest` symbols are permitted — no `XCTestCase` subclassing, no `XCAssert*`, no `XCTestExpectation`, no `XCTSkip` / `XCTFail`, no `setUp` / `tearDown` overrides.

## Review Scope

**Strengthens** findings about any residual `XCTest` symbol in new or migrated code. New suites must use `@Suite` / `@Test` / `#expect` / `#require` / `confirmation` and report failures via `Issue.record`.
