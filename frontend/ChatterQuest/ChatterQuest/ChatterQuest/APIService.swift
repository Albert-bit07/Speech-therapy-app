//
//  APIService.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 1/9/26.
//  Backend Integration Layer - Ready for Albert's API
//

import Foundation

// MARK: - API Configuration

struct APIConfig {
    // Albert should replace this with his actual backend URL
    static let baseURL = "http://localhost:8000/api" // FastAPI default
    // static let baseURL = "https://your-backend.com/api" // Production URL
    
    static let timeout: TimeInterval = 30.0
}

// MARK: - API Service

class APIService {
    static let shared = APIService()
    
    private init() {}
    
    // MARK: - Speech Analysis Endpoint
    
    /// Send audio to backend for pronunciation analysis
    /// Albert's endpoint: POST /api/analyze-pronunciation
    func analyzePronunciation(
        audioData: Data,
        targetWord: String,
        targetLanguage: String = "en"
    ) async throws -> PronunciationResult {
        let url = URL(string: "\(APIConfig.baseURL)/analyze-pronunciation")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = APIConfig.timeout
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add target word
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"target_word\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(targetWord)\r\n".data(using: .utf8)!)
        
        // Add language
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(targetLanguage)\r\n".data(using: .utf8)!)
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError
        }
        
        let result = try JSONDecoder().decode(PronunciationResult.self, from: data)
        return result
    }
    
    // MARK: - Progress Tracking Endpoints
    
    /// Get user progress data
    /// Albert's endpoint: GET /api/progress/{userId}
    func getUserProgress(userId: String) async throws -> UserProgress {
        let url = URL(string: "\(APIConfig.baseURL)/progress/\(userId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError
        }
        
        let progress = try JSONDecoder().decode(UserProgress.self, from: data)
        return progress
    }
    
    /// Save practice session
    /// Albert's endpoint: POST /api/sessions
    func savePracticeSession(session: PracticeSession) async throws -> SessionResponse {
        let url = URL(string: "\(APIConfig.baseURL)/sessions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(session)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError
        }
        
        let sessionResponse = try JSONDecoder().decode(SessionResponse.self, from: data)
        return sessionResponse
    }
    
    // MARK: - Exercise Generation
    
    /// Get adaptive exercises based on user's difficulty areas
    /// Albert's endpoint: GET /api/exercises/adaptive
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
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError
        }
        
        let exercises = try JSONDecoder().decode([Exercise].self, from: data)
        return exercises
    }
}

// MARK: - Data Models for Backend Communication

/// The main result from pronunciation analysis - Albert will return this
struct PronunciationResult: Codable {
    let overallScore: Double // 0.0 to 1.0
    let transcribedText: String // What the user actually said
    let phonemeAnalysis: [PhonemeResult] // Detailed phoneme-level feedback
    let mistakes: [PronunciationMistake] // Specific errors identified
    let feedback: String // Human-readable feedback
    let confidence: Double // Model's confidence in the analysis
    
    enum CodingKeys: String, CodingKey {
        case overallScore = "overall_score"
        case transcribedText = "transcribed_text"
        case phonemeAnalysis = "phoneme_analysis"
        case mistakes
        case feedback
        case confidence
    }
}

/// Individual phoneme analysis result
struct PhonemeResult: Codable {
    let phoneme: String // e.g., "/r/", "/s/", "/th/"
    let position: Int // Position in word (0-indexed)
    let score: Double // 0.0 to 1.0
    let isCorrect: Bool
    let expectedSound: String? // What it should sound like
    let actualSound: String? // What was detected
}

/// Pronunciation mistake with localization
struct PronunciationMistake: Codable {
    let phoneme: String
    let position: Int
    let severity: MistakeSeverity
    let suggestion: String // How to improve
    let exampleWords: [String]? // Words to practice
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
    let timeSpent: TimeInterval // Seconds
    let attemptNumber: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case sessionId = "session_id"
        case timestamp
        case word
        case language
        case pronunciationResult = "pronunciation_result"
        case timeSpent = "time_spent"
        case attemptNumber = "attempt_number"
    }
}

/// Response after saving a session
struct SessionResponse: Codable {
    let sessionId: String
    let saved: Bool
    let rewardsEarned: RewardsEarned
    let newAchievements: [String]?
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case saved
        case rewardsEarned = "rewards_earned"
        case newAchievements = "new_achievements"
    }
}

struct RewardsEarned: Codable {
    let stars: Int
    let coins: Int
    let experiencePoints: Int
    
    enum CodingKeys: String, CodingKey {
        case stars
        case coins
        case experiencePoints = "experience_points"
    }
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
    let improvingSounds: [String] // Phonemes showing improvement
    let difficultySounds: [String] // Phonemes needing practice
    let weeklyProgress: [DailyProgress]
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case totalSessions = "total_sessions"
        case totalStars = "total_stars"
        case totalCoins = "total_coins"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case practiceCount = "practice_count"
        case averageAccuracy = "average_accuracy"
        case improvingSounds = "improving_sounds"
        case difficultySounds = "difficulty_sounds"
        case weeklyProgress = "weekly_progress"
    }
}

struct DailyProgress: Codable {
    let date: String // ISO date string
    let sessionsCompleted: Int
    let averageScore: Double
    
    enum CodingKeys: String, CodingKey {
        case date
        case sessionsCompleted = "sessions_completed"
        case averageScore = "average_score"
    }
}

/// Exercise generated by backend
struct Exercise: Codable, Identifiable {
    let id: String
    let word: String
    let phonetic: String
    let difficulty: Int // 1-5
    let targetPhonemes: [String] // Phonemes to focus on
    let category: String // e.g., "animals", "colors", "actions"
    let audioUrl: String? // Optional audio example URL
    let imageUrl: String? // Optional image URL
    let funFact: String? // Educational information
    
    enum CodingKeys: String, CodingKey {
        case id
        case word
        case phonetic
        case difficulty
        case targetPhonemes = "target_phonemes"
        case category
        case audioUrl = "audio_url"
        case imageUrl = "image_url"
        case funFact = "fun_fact"
    }
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
            return "Network connection error"
        case .serverError:
            return "Server error occurred"
        case .decodingError:
            return "Failed to process response"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

// MARK: - Mock Service for Development (Remove when backend is ready)

class MockAPIService {
    static let shared = MockAPIService()
    
    private init() {}
    
    /// Mock pronunciation analysis - Returns fake data for development
    func mockAnalyzePronunciation(
        targetWord: String
    ) async -> PronunciationResult {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        let accuracy = Double.random(in: 0.75...0.98)
        
        return PronunciationResult(
            overallScore: accuracy,
            transcribedText: targetWord.lowercased(),
            phonemeAnalysis: [
                PhonemeResult(
                    phoneme: "/b/",
                    position: 0,
                    score: 0.95,
                    isCorrect: true,
                    expectedSound: "b",
                    actualSound: "b"
                ),
                PhonemeResult(
                    phoneme: "/r/",
                    position: 5,
                    score: accuracy,
                    isCorrect: accuracy > 0.85,
                    expectedSound: "r",
                    actualSound: accuracy > 0.85 ? "r" : "w"
                )
            ],
            mistakes: accuracy < 0.85 ? [
                PronunciationMistake(
                    phoneme: "/r/",
                    position: 5,
                    severity: .moderate,
                    suggestion: "Try positioning your tongue further back",
                    exampleWords: ["rabbit", "rocket", "rainbow"]
                )
            ] : [],
            feedback: accuracy > 0.90 ? "Excellent pronunciation!" : "Good try! Let's work on the 'r' sound.",
            confidence: 0.92
        )
    }
    
    /// Mock adaptive exercises
    func mockGetAdaptiveExercises(count: Int = 5) async -> [Exercise] {
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let words = [
            ("BUTTERFLY", "but • ter • fly", "🦋", "A beautiful insect with colorful wings"),
            ("RAINBOW", "rain • bow", "🌈", "Colors that appear in the sky after rain"),
            ("ROCKET", "rock • et", "🚀", "A vehicle that flies to space"),
            ("ELEPHANT", "el • e • phant", "🐘", "The largest land animal"),
            ("SUNSHINE", "sun • shine", "☀️", "Bright light from the sun")
        ]
        
        return words.prefix(count).enumerated().map { index, word in
            Exercise(
                id: UUID().uuidString,
                word: word.0,
                phonetic: word.1,
                difficulty: Int.random(in: 1...3),
                targetPhonemes: ["/r/", "/th/", "/s/"],
                category: "nature",
                audioUrl: nil,
                imageUrl: nil,
                funFact: word.3
            )
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
