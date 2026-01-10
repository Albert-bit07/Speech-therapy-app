//
//  APIService.swift
//  ChatterQuest
//
//  UPDATED - Connected to Python Backend
//  Ready for production with proper error handling
//

import Foundation

// MARK: - API Configuration

struct APIConfig {
    // IMPORTANT: Update these for your deployment
    
    // Local development (when running backend on same machine)
    static let baseURL = "http://localhost:8000/api"
    
    // iOS Simulator connecting to Mac backend
    // static let baseURL = "http://127.0.0.1:8000/api"
    
    // Physical iPhone connecting to Mac (use your Mac's IP)
    // Find Mac IP: System Settings > Network > Your Network > Details
    // static let baseURL = "http://192.168.1.XXX:8000/api"
    
    // Production deployment
    // static let baseURL = "https://your-backend.com/api"
    
    static let timeout: TimeInterval = 30.0
    static let enableLogging = true  // Set false in production
}

// MARK: - API Service

class APIService {
    static let shared = APIService()
    
    private init() {}
    
    // MARK: - Speech Analysis Endpoint
    
    /// Send audio to backend for pronunciation analysis
    /// Backend endpoint: POST /api/analyze-pronunciation
    func analyzePronunciation(
        audioData: Data,
        targetWord: String,
        targetLanguage: String = "en"
    ) async throws -> PronunciationResult {
        
        let urlString = "\(APIConfig.baseURL)/analyze-pronunciation"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        logRequest("POST", urlString, ["word": targetWord, "language": targetLanguage])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = APIConfig.timeout
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add target word
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"target_word\"\r\n\r\n")
        body.append("\(targetWord)\r\n")
        
        // Add language
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
        body.append("\(targetLanguage)\r\n")
        
        // Add audio file
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.wav\"\r\n")
        body.append("Content-Type: audio/wav\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError
            }
            
            logResponse(httpResponse.statusCode, data)
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorMessage = String(data: data, encoding: .utf8) {
                    log("❌ Server error: \(errorMessage)")
                }
                throw APIError.serverError
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let result = try decoder.decode(PronunciationResult.self, from: data)
            
            log("✅ Analysis successful: \(result.overallScore * 100)%")
            return result
            
        } catch let error as DecodingError {
            log("❌ Decoding error: \(error)")
            throw APIError.decodingError
        } catch {
            log("❌ Network error: \(error)")
            throw APIError.networkError
        }
    }
    
    // MARK: - Progress Tracking Endpoints
    
    /// Get user progress data
    /// Backend endpoint: GET /api/progress/{userId}
    func getUserProgress(userId: String) async throws -> UserProgress {
        
        let urlString = "\(APIConfig.baseURL)/progress/\(userId)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        logRequest("GET", urlString)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = APIConfig.timeout
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError
            }
            
            logResponse(httpResponse.statusCode, data)
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let progress = try decoder.decode(UserProgress.self, from: data)
            
            log("✅ Progress loaded: \(progress.totalSessions) sessions")
            return progress
            
        } catch let error as DecodingError {
            log("❌ Decoding error: \(error)")
            throw APIError.decodingError
        } catch {
            log("❌ Network error: \(error)")
            throw APIError.networkError
        }
    }
    
    /// Save practice session
    /// Backend endpoint: POST /api/sessions
    func savePracticeSession(session: PracticeSession) async throws -> SessionResponse {
        
        let urlString = "\(APIConfig.baseURL)/sessions"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        logRequest("POST", urlString, ["word": session.word])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = APIConfig.timeout
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            request.httpBody = try encoder.encode(session)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError
            }
            
            logResponse(httpResponse.statusCode, data)
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let sessionResponse = try decoder.decode(SessionResponse.self, from: data)
            
            log("✅ Session saved: \(sessionResponse.rewardsEarned.stars) stars earned")
            return sessionResponse
            
        } catch let error as EncodingError {
            log("❌ Encoding error: \(error)")
            throw APIError.decodingError
        } catch let error as DecodingError {
            log("❌ Decoding error: \(error)")
            throw APIError.decodingError
        } catch {
            log("❌ Network error: \(error)")
            throw APIError.networkError
        }
    }
    
    // MARK: - Exercise Generation
    
    /// Get adaptive exercises based on user's difficulty areas
    /// Backend endpoint: GET /api/exercises/adaptive
    func getAdaptiveExercises(
        userId: String,
        count: Int = 5,
        difficulty: String = "medium"
    ) async throws -> [Exercise] {
        
        var components = URLComponents(string: "\(APIConfig.baseURL)/exercises/adaptive")!
        components.queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "count", value: String(count)),
            URLQueryItem(name: "difficulty", value: difficulty)
        ]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        logRequest("GET", url.absoluteString)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = APIConfig.timeout
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError
            }
            
            logResponse(httpResponse.statusCode, data)
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let exercises = try decoder.decode([Exercise].self, from: data)
            
            log("✅ Loaded \(exercises.count) exercises")
            return exercises
            
        } catch let error as DecodingError {
            log("❌ Decoding error: \(error)")
            throw APIError.decodingError
        } catch {
            log("❌ Network error: \(error)")
            throw APIError.networkError
        }
    }
    
    // MARK: - Logging Helpers
    
    private func logRequest(_ method: String, _ url: String, _ params: [String: Any] = [:]) {
        guard APIConfig.enableLogging else { return }
        print("📤 \(method) \(url)")
        if !params.isEmpty {
            print("   Params: \(params)")
        }
    }
    
    private func logResponse(_ statusCode: Int, _ data: Data) {
        guard APIConfig.enableLogging else { return }
        print("📥 Response: \(statusCode)")
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("   Data: \(json)")
        }
    }
    
    private func log(_ message: String) {
        guard APIConfig.enableLogging else { return }
        print(message)
    }
}

// MARK: - Data Models (matching backend)

/// The main result from pronunciation analysis
struct PronunciationResult: Codable {
    let overallScore: Double
    let transcribedText: String
    let phonemeAnalysis: [PhonemeResult]
    let mistakes: [PronunciationMistake]
    let feedback: String
    let confidence: Double
}

/// Individual phoneme analysis result
struct PhonemeResult: Codable {
    let phoneme: String
    let position: Int
    let score: Double
    let isCorrect: Bool
    let expectedSound: String?
    let actualSound: String?
}

/// Pronunciation mistake with localization
struct PronunciationMistake: Codable {
    let phoneme: String
    let position: Int
    let severity: MistakeSeverity
    let suggestion: String
    let exampleWords: [String]?
}

enum MistakeSeverity: String, Codable {
    case minor
    case moderate
    case major
}

/// Practice session data to send to backend
struct PracticeSession: Codable {
    let userId: String
    let sessionId: String
    let timestamp: Date
    let word: String
    let language: String
    let pronunciationResult: PronunciationResult
    let timeSpent: TimeInterval
    let attemptNumber: Int
}

/// Response after saving a session
struct SessionResponse: Codable {
    let sessionId: String
    let saved: Bool
    let rewardsEarned: RewardsEarned
    let newAchievements: [String]?
}

struct RewardsEarned: Codable {
    let stars: Int
    let coins: Int
    let experiencePoints: Int
}

/// User progress data from backend
struct UserProgress: Codable {
    let userId: String
    let totalSessions: Int
    let totalStars: Int
    let totalCoins: Int
    let currentStreak: Int
    let longestStreak: Int
    let practiceCount: Int
    let averageAccuracy: Double
    let improvingSounds: [String]
    let difficultySounds: [String]
    let weeklyProgress: [DailyProgress]
}

struct DailyProgress: Codable {
    let date: String
    let sessionsCompleted: Int
    let averageScore: Double
}

/// Exercise generated by backend
struct Exercise: Codable, Identifiable {
    let id: String
    let word: String
    let phonetic: String
    let difficulty: Int
    let targetPhonemes: [String]
    let category: String
    let audioUrl: String?
    let imageUrl: String?
    let funFact: String?
}

// MARK: - Error Handling

enum APIError: LocalizedError {
    case invalidURL
    case networkError
    case serverError
    case decodingError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network connection error. Check your internet connection."
        case .serverError:
            return "Server error occurred. Please try again."
        case .decodingError:
            return "Failed to process response from server."
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

// MARK: - Helper Extension for Data

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

// MARK: - Connection Test Helper

extension APIService {
    /// Test connection to backend
    func testConnection() async -> Bool {
        do {
            // Try to hit the health endpoint
            let healthURL = APIConfig.baseURL.replacingOccurrences(of: "/api", with: "/health")
            guard let url = URL(string: healthURL) else { return false }
            
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                let isConnected = (200...299).contains(httpResponse.statusCode)
                print(isConnected ? "✅ Backend connected!" : "❌ Backend unreachable")
                return isConnected
            }
            return false
        } catch {
            print("❌ Backend connection failed: \(error)")
            return false
        }
    }
}