import Testing
import Foundation
@testable import DomainLogic

@Suite("Movies To Watch — fluent scenarios")
@MainActor
struct MoviesToWatchTests {

    @Test func addingMovieAppearsInList() async throws {
        try await ScenarioForMoviesToWatch
            .freshLaunch()
            .addMovie(title: "The Matrix", year: 1999)
            .expectMovieInList(title: "The Matrix", watched: false)
            .expectCounts(total: 1, toWatch: 1, watched: 0)
    }

    @Test func togglingWatchedMovesBetweenFilters() async throws {
        try await ScenarioForMoviesToWatch
            .freshLaunch()
            .addMovie(title: "Arrival", year: 2016)
            .expectCounts(toWatch: 1, watched: 0)
            .toggleWatched(movieAt: 0)
            .expectCounts(toWatch: 0, watched: 1)
            .setFilter(.watched)
            .expectMovieInList(title: "Arrival", watched: true)
            .setFilter(.toWatch)
            .expectMovieAbsent(title: "Arrival")
    }

    @Test func removingMovieDropsItFromBothFiltersAndCounts() async throws {
        try await ScenarioForMoviesToWatch
            .freshLaunch()
            .addMovie(title: "Dune", year: 2021)
            .addMovie(title: "Heat", year: 1995)
            .expectCounts(total: 2)
            .removeMovie(titled: "Dune")
            .expectMovieAbsent(title: "Dune")
            .expectCounts(total: 1, toWatch: 1)
    }

    @Test func searchSurfacesHitsFromAdapter() async throws {
        let blade = SearchHit(id: "tt0083658", title: "Blade Runner", year: 1982)
        let blade2049 = SearchHit(id: "tt1856101", title: "Blade Runner 2049", year: 2017)

        try await ScenarioForMoviesToWatch
            .freshLaunch()
            .search("Blade Runner", arm: .hits([blade, blade2049]))
            .expectSearchResults(for: "Blade Runner", contain: "Blade Runner 2049")
    }

    @Test func searchFailureSurfacesAsFailedState() async throws {
        try await ScenarioForMoviesToWatch
            .freshLaunch()
            .search("Nope", arm: .failure(message: "network down"))
            .expectSearchFailed(for: "Nope")
    }

    @Test func addingFromSearchHitWritesThroughToList() async throws {
        let hit = SearchHit(id: "tt9", title: "Inception", year: 2010)
        try await ScenarioForMoviesToWatch
            .freshLaunch()
            .search("Inception", arm: .hits([hit]))
            .expectSearchResults(for: "Inception", contain: "Inception")
            .addFromHit(hit)
            .expectMovieInList(title: "Inception", watched: false)
            .expectCounts(total: 1)
    }

    @Test func moviesPersistAcrossRelaunch() async throws {
        try await ScenarioForMoviesToWatch
            .freshLaunch()
            .addMovie(title: "Tenet", year: 2020)
            .addMovie(title: "Oppenheimer", year: 2023)
            .toggleWatched(movieAt: 0) // marks Oppenheimer (most-recent-first) watched
            .expectCounts(total: 2, watched: 1)
            .waitForPersistedCount(2)
            .relaunch()
            .expectCounts(total: 2, watched: 1)
            .expectMovieInList(title: "Tenet")
            .setFilter(.all)
            .expectMovieInList(title: "Oppenheimer", watched: true)
    }

    @Test func rapidTypingCoalescesIntoOneAdapterCall() async throws {
        let inception = SearchHit(id: "tt9", title: "Inception", year: 2010)
        try await ScenarioForMoviesToWatch
            .freshLaunch(searchDebounceInterval: .milliseconds(150))
            .search("I",         arm: .hits([]))
            .search("In",        arm: .hits([]))
            .search("Ince",      arm: .hits([]))
            .search("Inception", arm: .hits([inception]))
            .expectSearchResults(for: "Inception", contain: "Inception")
            .expectAdapterQueries(["Inception"])
    }

    @Test func clearingMidDebounceCancelsTheSearch() async throws {
        try await ScenarioForMoviesToWatch
            .freshLaunch(searchDebounceInterval: .milliseconds(150))
            .startSearch("Dune")
            .clearSearch()
            .waitForDebounceWindow()
            .expectAdapterQueries([])
    }

    @Test func startingMoviesSurviveBootstrap() async throws {
        let preexisting = [
            Movie(title: "Heat", year: 1995),
            Movie(title: "Collateral", year: 2004, watched: true),
        ]
        try await ScenarioForMoviesToWatch
            .freshLaunch(startingMovies: preexisting)
            .expectCounts(total: 2, toWatch: 1, watched: 1)
    }
}
