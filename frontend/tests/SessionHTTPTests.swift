import Foundation

@main
struct SessionHTTPTests {
    static func main() async throws {
        precondition(CommandLine.arguments.count == 4)
        let api = APIService(baseURL: CommandLine.arguments[1])
        let outbox = PracticeOutbox(fileURL: URL(fileURLWithPath: CommandLine.arguments[2]))
        let phase = CommandLine.arguments[3]
        if phase == "lost-response" {
            _ = try await outbox.enqueue(word: "rain", score: 0.7, timeSpent: 2, attemptNumber: 1)
            do {
                try await outbox.flush { try await api.savePracticeSession(session: $0) }
                fatalError("Expected the proxy to drop the acknowledgment")
            } catch APIError.networkError { }
            let pending = try await outbox.pendingCount()
            precondition(pending == 1)
        } else {
            precondition(phase == "restart")
            let pending = try await outbox.pendingCount()
            precondition(pending == 1, "Restart lost the pending attempt")
            try await outbox.flush { attempt in
                let response = try await api.savePracticeSession(session: attempt)
                precondition(response.newAchievements?.isEmpty == true, "Replay repeated the first milestone")
                return response
            }
            let remaining = try await outbox.pendingCount()
            precondition(remaining == 0)
        }
        let userId = try await outbox.userId()
        let progress = try await api.getUserProgress(userId: userId)
        precondition(progress.totalSessions == 1 && progress.totalCoins == 70)
        precondition(progress.practiceCount == 1 && progress.averageAccuracy == 0.7)
        print("Actual Swift API/outbox phase passed: \(phase)")
    }
}
