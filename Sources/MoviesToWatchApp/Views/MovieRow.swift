import SwiftUI
import DomainLogic

struct MovieRow: View {
    let movie: Movie
    let send: (any Intent) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                send(IntentToggleWatched(id: movie.id))
            } label: {
                Image(systemName: movie.watched ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(movie.watched ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(movie.title)
                    .font(.body)
                    .strikethrough(movie.watched, color: .secondary)
                    .foregroundStyle(movie.watched ? .secondary : .primary)
                Text(String(movie.year))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button(role: .destructive) {
                send(IntentRemoveMovie(id: movie.id))
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .opacity(0.6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
