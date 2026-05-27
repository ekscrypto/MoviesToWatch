import SwiftUI
import DomainLogic

struct SearchSheet: View {
    let searchState: SearchState
    let onQueryChange: (String) -> Void
    let onPick: (SearchHit) -> Void
    let onClear: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Search Catalogue").font(.title3).bold()
                Spacer()
                Button("Done") {
                    onClear()
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            TextField("Title", text: $query)
                .textFieldStyle(.roundedBorder)
                .onChange(of: query) { _, newValue in
                    onQueryChange(newValue)
                }

            content
                .frame(maxWidth: .infinity, minHeight: 220, alignment: .top)
        }
        .padding(20)
        .frame(width: 480, height: 380)
    }

    @ViewBuilder
    private var content: some View {
        switch searchState {
        case .idle:
            Text("Type to search the catalogue.")
                .foregroundStyle(.secondary)
        case .debouncing(let q), .searching(let q):
            HStack {
                ProgressView().controlSize(.small)
                Text("Searching for ‘\(q)’…").foregroundStyle(.secondary)
            }
        case .results(_, let hits) where hits.isEmpty:
            Text("No matches.").foregroundStyle(.secondary)
        case .results(_, let hits):
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(hits) { hit in
                        Button {
                            onPick(hit)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(hit.title).font(.body)
                                    Text(String(hit.year)).font(.caption).foregroundStyle(.tertiary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.tint)
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        case .failed(_, let message):
            VStack(alignment: .leading, spacing: 4) {
                Text("Search failed").bold()
                Text(message).foregroundStyle(.secondary)
            }
        }
    }
}
