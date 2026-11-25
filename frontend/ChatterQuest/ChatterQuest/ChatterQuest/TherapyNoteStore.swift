import Foundation

struct TherapyNote: Identifiable, Codable {
    var id = UUID()
    let title: String
    let content: String
    let date: String
    let category: NoteCategory
}

enum NoteCategory: String, CaseIterable, Codable {
    case observation = "Observation"
    case goal = "Goal"
    case milestone = "Milestone"
    case concern = "Concern"
}

struct TherapyNoteStore {
    enum StoreError: Error { case unreadable, invalidNotes }
    private let url: URL
    private var loaded = false

    init(url: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("ChatterQuest/therapy-notes.json")) {
        self.url = url
    }

    mutating func load() throws -> [TherapyNote] {
        loaded = false
        guard FileManager.default.fileExists(atPath: url.path) else {
            loaded = true
            return []
        }
        let data = try Data(contentsOf: url)
        guard data.count <= 2_000_000 else { throw StoreError.invalidNotes }
        let notes = try JSONDecoder().decode([TherapyNote].self, from: data)
        try validate(notes)
        loaded = true
        return notes
    }

    func save(_ notes: [TherapyNote]) throws {
        guard loaded else { throw StoreError.unreadable }
        try validate(notes)
        let data = try JSONEncoder().encode(notes)
        guard data.count <= 2_000_000 else { throw StoreError.invalidNotes }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    private func validate(_ notes: [TherapyNote]) throws {
        guard notes.count <= 100, Set(notes.map(\.id)).count == notes.count,
              notes.allSatisfy({ !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  $0.title.count <= 200 && $0.content.count <= 10_000 && $0.date.count <= 100 })
        else { throw StoreError.invalidNotes }
    }
}
