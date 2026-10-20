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
        print("Passed 7 API client regression scenarios")
    }
}
