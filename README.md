# Movies To Watch — ViewRep/Intent/StateMachine demo

A self-contained macOS app that demonstrates Page Object unit tests with a
State Machine architecture, including a view data representation (ViewRep):
<https://davepoirier.medium.com/viewrep-intent-statemachine-ios-architecture-4e3a2d589b36>).

The app lets you maintain a list of movies you want to watch, mark them as
watched, search a (mock) catalogue, and persists everything to disk.

## What this demo shows

| Layer            | File(s)                                            | What it demonstrates |
|------------------|----------------------------------------------------|----------------------|
| **State**        | `Sources/DomainLogic/State/*`                      | `PersistentState` (on-disk) and `EphemeralState` (in-memory) carried inside an actor. |
| **Intent**       | `Sources/DomainLogic/Intents/Intent.*.swift`       | Atomic, serial state mutations. Each intent has a single `mutate(...)` method. |
| **Activity**     | `Sources/DomainLogic/Activities/Activity.*.swift`  | Long-running async work that reads state via intents and writes results via intents. |
| **StateMachine** | `Sources/DomainLogic/StateMachine/StateMachine.swift` | Single source of truth. Processes intents serially, publishes throttled `ViewRep`s. |
| **ViewRep**      | `Sources/DomainLogic/ViewRep/*`                    | A pure value type derived from state. UI consumes it; tests parse it. |
| **Adapter**      | `Sources/DomainLogic/Adapters/Adapter.*.swift`     | Every external dependency (disk, search service) behind a protocol — fully mockable. |
| **Fluent tests** | `Tests/DomainLogicTests/Scaffolding/Scenario*.swift` | Tests read like user actions, drive the app via intents, observe via ViewRep. |

## Run it

```bash
swift run MoviesToWatchApp     # launches the SwiftUI app
swift test                     # runs the fluent test suite
```

## TMDB search setup (optional)

The app uses [The Movie Database (TMDB)](https://www.themoviedb.org) as its
production search backend. Without a token the app still runs — it falls back
to the small in-process `BundledMovieSearch` catalogue, which is enough to
exercise the UI and the architecture.

To wire the real TMDB API:

1. Create a free TMDB account at <https://www.themoviedb.org/signup>.
2. Open <https://www.themoviedb.org/settings/api> and request an API key for
   personal / developer use. Approval is usually instant.
3. From the same settings page, copy the **API Read Access Token** (the v4
   bearer token — a long JWT-looking string, *not* the v3 `api_key`).
4. Save the token to a file at the repository root:

   ```bash
   cp tmdb-token.txt.example tmdb-token.txt
   # then paste your token into tmdb-token.txt (one line, no quotes)
   ```

   `tmdb-token.txt` is listed in `.gitignore` so the secret never lands in a
   commit. The committed `tmdb-token.txt.example` is just a placeholder.

5. Alternatively, set the `TMDB_BEARER_TOKEN` environment variable before
   launch — the env var wins over the file:

   ```bash
   TMDB_BEARER_TOKEN='eyJh…' swift run MoviesToWatchApp
   ```

The token resolution logic lives in `Sources/MoviesToWatchApp/TMDBToken.swift`.
If neither source is set, `AppState` logs a notice on launch and uses
`BundledMovieSearch`.

## Try the tests first

`Tests/DomainLogicTests/MoviesToWatchTests.swift` is the best place to start.
Every test reads top-to-bottom like a user transcript:

```swift
@Test func addingMovieAppearsInToWatchList() async throws {
    try await ScenarioForMoviesToWatch
        .freshLaunch()
        .addMovie(title: "The Matrix", year: 1999)
        .expectMovieInList(title: "The Matrix", watched: false)
}
```

No mocks are wired by the test author; the scenario factory wires the
simulated adapters once. The test never reaches into `StateMachine` internals
— it drives via intents and observes via `ViewRep.values`.
