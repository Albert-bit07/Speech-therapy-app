import Foundation

@main
struct RecordingPermissionTests {
    static func main() {
        var gate = RecordingPermissionGate()
        precondition(gate.begin() == nil)
        gate.activate()
        let old = gate.begin()!
        precondition(gate.isPending && gate.begin() == nil)
        gate.deactivate()
        precondition(!gate.isPending && !gate.complete(old))
        gate.activate()
        let current = gate.begin()!
        precondition(!gate.complete(old) && gate.isPending)
        precondition(gate.complete(current) && !gate.isPending)
        precondition(!gate.complete(current))
        let retry = gate.begin()!
        precondition(gate.complete(retry))
        gate.deactivate()
        precondition(gate.begin() == nil)
        print("Passed permission dismissal, duplicate and stale callback regressions")
    }
}
