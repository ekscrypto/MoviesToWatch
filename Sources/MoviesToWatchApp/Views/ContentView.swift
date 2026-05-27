import SwiftUI
import DomainLogic

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var showingAddSheet = false
    @State private var showingSearchSheet = false

    var body: some View {
        let vr = appState.viewRep
        VStack(spacing: 0) {
            header(vr)
            Divider()
            if !vr.hasLoaded {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vr.visibleMovies.isEmpty {
                EmptyStateView(filter: vr.filter)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vr.visibleMovies) { movie in
                            MovieRow(movie: movie) { intent in
                                appState.send(intent)
                            }
                            Divider().padding(.leading)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 520, minHeight: 420)
        .sheet(isPresented: $showingAddSheet) {
            AddMovieSheet { title, year in
                appState.send(IntentAddMovie(title: title, year: year))
            }
        }
        .sheet(isPresented: $showingSearchSheet) {
            SearchSheet(searchState: vr.search,
                        onQueryChange: { appState.send(IntentStartSearch(query: $0)) },
                        onPick: { hit in
                            appState.send(IntentAddFromSearchHit(hit: hit))
                            showingSearchSheet = false
                        },
                        onClear: { appState.send(IntentClearSearch()) })
        }
    }

    @ViewBuilder
    private func header(_ vr: ViewRep) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Movies To Watch").font(.title2).bold()
                Text("\(vr.toWatchCount) to watch · \(vr.watchedCount) watched")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Picker("", selection: Binding(
                get: { vr.filter },
                set: { appState.send(IntentSetFilter($0)) }
            )) {
                Text("To watch").tag(MovieFilter.toWatch)
                Text("Watched").tag(MovieFilter.watched)
                Text("All").tag(MovieFilter.all)
            }
            .pickerStyle(.segmented)
            .frame(width: 240)
            Button {
                showingSearchSheet = true
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .help("Search the catalogue")
            Button {
                showingAddSheet = true
            } label: {
                Image(systemName: "plus")
            }
            .help("Add a movie")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct EmptyStateView: View {
    let filter: MovieFilter

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "film")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text(message)
                .foregroundStyle(.secondary)
        }
    }

    private var message: String {
        switch filter {
        case .all:     return "No movies yet. Tap + to add one."
        case .toWatch: return "Nothing on the watchlist. Tap + or 🔍 to add."
        case .watched: return "No watched movies yet."
        }
    }
}
