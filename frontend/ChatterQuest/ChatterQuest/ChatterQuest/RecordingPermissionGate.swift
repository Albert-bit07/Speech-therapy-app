import Foundation

struct RecordingPermissionGate {
    private(set) var isActive = false
    private var pending: UUID?
    var isPending: Bool { pending != nil }

    mutating func activate() {
        isActive = true
    }

    mutating func deactivate() {
        isActive = false
        pending = nil
    }

    mutating func begin() -> UUID? {
        guard isActive, pending == nil else { return nil }
        let token = UUID()
        pending = token
        return token
    }

    mutating func complete(_ token: UUID) -> Bool {
        guard isActive, pending == token else { return false }
        pending = nil
        return true
    }
}
