import SwiftUI

struct AIContentLibraryView: View {
    @State private var records = AIContentCache.savedContent()

    var body: some View {
        Group {
            if records.isEmpty {
                ContentUnavailableView("Kaydedilmiş içerik yok",
                                       systemImage: "books.vertical",
                                       description: Text("Oluşturduğun konu özetleri, quizler ve kartlar burada saklanır; daha sonra çevrimdışı da açabilirsin."))
            } else {
                List {
                    ForEach(records) { record in
                        NavigationLink {
                            ScrollView {
                                Text(record.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                                    .padding()
                            }
                            .navigationTitle(record.title)
                            .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(record.title).font(.headline)
                                Text(record.kind).font(.caption.weight(.medium)).foregroundStyle(.indigo)
                                Text(record.savedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Kaydedilen içerikler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { if !records.isEmpty { EditButton() } }
    }

    private func delete(at offsets: IndexSet) {
        let ids = offsets.map { records[$0].id }
        ids.forEach(AIContentCache.deleteFromLibrary(id:))
        records = AIContentCache.savedContent()
    }
}
