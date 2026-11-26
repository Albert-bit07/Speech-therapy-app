import Foundation

@main
struct TherapyNoteTests {
    static func check(_ condition: Bool) { precondition(condition) }

    static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("notes.json")
        var store = TherapyNoteStore(url: url)
        check(try store.load().isEmpty)
        let note = TherapyNote(title: "Practice", content: "Worked on rain", date: "2026-11-25", category: .observation)
        try store.save([note])
        var restored = TherapyNoteStore(url: url)
        let loaded = try restored.load()
        check(loaded.count == 1 && loaded[0].id == note.id && loaded[0].content == note.content)
        let edited = TherapyNote(id: note.id, title: "Updated practice", content: "Worked on sun", date: note.date, category: .goal)
        try restored.save([edited])
        var afterEditRestart = TherapyNoteStore(url: url)
        let editedNotes = try afterEditRestart.load()
        check(editedNotes.count == 1 && editedNotes[0].id == note.id)
        check(editedNotes[0].date == note.date && editedNotes[0].content == edited.content && editedNotes[0].category == .goal)
        do { try restored.save([note, note]); fatalError("Duplicate IDs accepted") } catch {}
        check(try restored.load().count == 1)
        try restored.save([])
        check(try store.load().isEmpty)
        let corrupt = Data("invalid json".utf8)
        try corrupt.write(to: url)
        do { _ = try store.load(); fatalError("Corrupt file accepted") } catch {}
        do { try store.save([]); fatalError("Corrupt file overwritten") } catch {}
        check(try Data(contentsOf: url) == corrupt)
        var blocked = TherapyNoteStore(url: directory.appendingPathComponent("missing/notes.json"))
        _ = try blocked.load()
        try Data().write(to: directory.appendingPathComponent("missing"))
        do { try blocked.save([note]); fatalError("Unwritable destination accepted") } catch {}
        print("Passed note restart, deletion, duplicate, corruption and write-failure regressions")
    }
}
