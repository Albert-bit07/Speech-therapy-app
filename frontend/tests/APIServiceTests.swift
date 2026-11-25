import Foundation

final class StubProtocol: URLProtocol {
    static var status = 200
    static var payload = Data()
    static var transportError: Error?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        if let error = Self.transportError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status,
                                       httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.payload)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() { }
}

@main
struct APIServiceTests {
    static func main() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let api = APIService(session: session)
        for (status, expected) in [(503, "unavailable"), (422, "invalidAnalysis"), (500, "serverError")] {
            StubProtocol.status = status
            do {
                _ = try await api.analyzePronunciation(audioData: Data([0, 1]), targetWord: "rain")
                fatalError("Expected failure for HTTP \(status)")
            } catch let error as APIError {
                precondition(String(describing: error) == expected, "HTTP error was misclassified")
            }
        }
        StubProtocol.status = 200
        StubProtocol.payload = Data("not JSON".utf8)
        do {
            _ = try await api.analyzePronunciation(audioData: Data(), targetWord: "rain")
            fatalError("Expected decoding failure")
        } catch APIError.decodingError { }
        StubProtocol.payload = Data(#"{"overall_score":0.7,"transcribed_text":"rain","phoneme_analysis":[],"mistakes":[],"feedback":"Practice","confidence":0.6}"#.utf8)
        let result = try await api.analyzePronunciation(audioData: Data(), targetWord: "rain")
        precondition(result.overallScore == 0.7 && result.transcribedText == "rain")
        StubProtocol.payload = Data("[]".utf8)
        let exercises = try await api.getAdaptiveExercises(userId: "test")
        precondition(exercises.isEmpty)
        StubProtocol.transportError = URLError(.notConnectedToInternet)
        do {
            _ = try await api.analyzePronunciation(audioData: Data(), targetWord: "rain")
            fatalError("Expected transport failure")
        } catch APIError.networkError { }
        try await testPracticeOutbox(api: api)
        print("Passed API client and durable practice outbox regression scenarios")
    }
    static func testPracticeOutbox(api: APIService) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("outbox.json")
        let original = PracticeOutbox(fileURL: file)
        let attempt = try await original.enqueue(word: "rain", score: 0.7, timeSpent: 2, attemptNumber: 1)
        let userId = try await original.userId()
        let restarted = PracticeOutbox(fileURL: file)
        let recoveredUser = try await restarted.userId()
        precondition(recoveredUser == userId)
        do {
            try await restarted.flush { try await api.savePracticeSession(session: $0) }
            fatalError("Expected network failure")
        } catch APIError.networkError { }
        let pending = try await restarted.pendingCount()
        precondition(pending == 1)
        let recovered = PracticeOutbox(fileURL: file)
        StubProtocol.transportError = nil
        StubProtocol.payload = Data("""
        {"session_id":"\(attempt.sessionId)","saved":true,"rewards_earned":{"stars":1,"coins":70,"experience_points":35},"new_achievements":[]}
        """.utf8)
        try await recovered.flush { saved in
            precondition(saved.sessionId == attempt.sessionId && saved.timestamp == attempt.timestamp)
            precondition(saved.userId == userId && saved.pronunciationResult.overallScore == 0.7)
            precondition(saved.pronunciationResult.transcribedText.isEmpty)
            return try await api.savePracticeSession(session: saved)
        }
        let empty = try await PracticeOutbox(fileURL: file).pendingCount()
        precondition(empty == 0)
        _ = try await recovered.enqueue(word: "sun", score: 0.9, timeSpent: 1, attemptNumber: 2)
        do {
            try await recovered.flush { _ in
                SessionResponse(sessionId: "wrong-id", saved: true,
                                rewardsEarned: RewardsEarned(stars: 0, coins: 0, experiencePoints: 0), newAchievements: [])
            }
            fatalError("Mismatched acknowledgment removed an attempt")
        } catch PracticeOutbox.StorageError.invalidAcknowledgment { }
        var sent = [String]()
        try await recovered.flush { saved in
            sent.append(saved.sessionId)
            if sent.count == 1 {
                _ = try await recovered.enqueue(word: "moon", score: 0.5, timeSpent: 1, attemptNumber: 3)
                try await recovered.flush { _ in fatalError("Concurrent drain resent an in-flight attempt") }
            }
            return SessionResponse(sessionId: saved.sessionId, saved: true,
                                   rewardsEarned: RewardsEarned(stars: 0, coins: 0, experiencePoints: 0), newAchievements: [])
        }
        precondition(sent.count == 2 && Set(sent).count == 2)
        let remaining = try await recovered.pendingCount()
        precondition(remaining == 0)
        for number in 1...100 {
            _ = try await recovered.enqueue(word: "rain", score: 0.7, timeSpent: 1, attemptNumber: number)
        }
        do {
            _ = try await recovered.enqueue(word: "rain", score: 0.7, timeSpent: 1, attemptNumber: 101)
            fatalError("Queue capacity was not enforced")
        } catch PracticeOutbox.StorageError.full { }
        let fullCount = try await PracticeOutbox(fileURL: file).pendingCount()
        precondition(fullCount == 100)
        do {
            _ = try await recovered.enqueue(word: "rain", score: .nan, timeSpent: 1, attemptNumber: 1)
            fatalError("Accepted a non-finite score")
        } catch PracticeOutbox.StorageError.invalidAttempt { }
        try Data("broken".utf8).write(to: file)
        do {
            _ = try await PracticeOutbox(fileURL: file).userId()
            fatalError("Corrupt store was silently replaced")
        } catch is DecodingError { }
        let blocked = file.appendingPathComponent("child.json")
        do {
            _ = try await PracticeOutbox(fileURL: blocked).enqueue(word: "rain", score: 0.7, timeSpent: 1, attemptNumber: 1)
            fatalError("Accepted a session without durable storage")
        } catch { }
    }
}
