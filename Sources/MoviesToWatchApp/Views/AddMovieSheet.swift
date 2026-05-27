import SwiftUI

struct AddMovieSheet: View {
    let onAdd: (String, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var yearText: String = String(Calendar.current.component(.year, from: Date()))

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add a Movie").font(.title3).bold()
            Form {
                TextField("Title", text: $title)
                TextField("Year", text: $yearText)
                    .frame(maxWidth: 120)
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Add") {
                    let year = Int(yearText) ?? Calendar.current.component(.year, from: Date())
                    onAdd(title, year)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}
