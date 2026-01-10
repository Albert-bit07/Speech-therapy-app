//
//  Rewardssystem.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 1/9/26.
//

//
//  RewardsSystem.swift
//  ChatterQuest
//
//  Gamification System: Stars, Coins, and Character Growth
//

import SwiftUI
// MARK: - Rewards Manager

class RewardsManager: ObservableObject {
    @Published var coins: Int = 0
    @Published var stars: Int = 0
    @Published var practiceCount: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var achievements: [Achievement] = []
    
    var currentStage: GrowthStage {
        switch practiceCount {
        case 0..<5: return .worm
        case 5..<10: return .cocoon
        default: return .butterfly
        }
    }
    
    var progressToNextStage: Double {
        guard let nextStage = currentStage.nextStage else { return 1.0 }
        
        let currentThreshold = currentStage.practiceThreshold
        let nextThreshold = nextStage.practiceThreshold
        let progress = practiceCount - currentThreshold
        let totalNeeded = nextThreshold - currentThreshold
        
        return Double(progress) / Double(totalNeeded)
    }
    
    // MARK: - Reward Calculation
    
    /// Calculate rewards based on pronunciation accuracy from backend
    func calculateRewards(accuracy: Double, wordDifficulty: Int = 1) -> RewardResult {
        var earnedStars = 0
        var earnedCoins = 0
        
        // Stars based on accuracy (0-3 stars)
        if accuracy >= 0.90 {
            earnedStars = 3
        } else if accuracy >= 0.75 {
            earnedStars = 2
        } else if accuracy >= 0.60 {
            earnedStars = 1
        }
        
        // Coins calculation: base coins + difficulty multiplier + accuracy bonus
        let baseCoins = 10
        let difficultyMultiplier = wordDifficulty
        let accuracyBonus = Int(accuracy * 20) // 0-20 bonus coins
        earnedCoins = (baseCoins * difficultyMultiplier) + accuracyBonus
        
        // Streak bonus
        if earnedStars > 0 {
            let streakBonus = min(currentStreak * 2, 20) // Max 20 bonus coins from streak
            earnedCoins += streakBonus
        }
        
        return RewardResult(
            stars: earnedStars,
            coins: earnedCoins,
            accuracy: accuracy,
            isNewRecord: accuracy > 0.95
        )
    }
    
    /// Award rewards and update progress
    func awardRewards(_ result: RewardResult) {
        stars += result.stars
        coins += result.coins
        
        if result.stars > 0 {
            practiceCount += 1
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else {
            currentStreak = 0
        }
        
        // Check for achievements
        checkAchievements()
    }
    
    /// Reset daily streak (call this when user misses a day)
    func resetStreak() {
        currentStreak = 0
    }
    
    // MARK: - Achievements System
    
    private func checkAchievements() {
        // First Word achievement
        if practiceCount == 1 && !hasAchievement(.firstWord) {
            unlockAchievement(.firstWord)
        }
        
        // Practice achievements
        if practiceCount == 5 && !hasAchievement(.fivePractices) {
            unlockAchievement(.fivePractices)
        }
        
        if practiceCount == 10 && !hasAchievement(.tenPractices) {
            unlockAchievement(.tenPractices)
        }
        
        // Streak achievements
        if currentStreak == 3 && !hasAchievement(.threeStreak) {
            unlockAchievement(.threeStreak)
        }
        
        if currentStreak == 7 && !hasAchievement(.weekStreak) {
            unlockAchievement(.weekStreak)
        }
        
        // Star achievements
        if stars >= 50 && !hasAchievement(.starCollector) {
            unlockAchievement(.starCollector)
        }
        
        // Coin achievements
        if coins >= 500 && !hasAchievement(.coinMaster) {
            unlockAchievement(.coinMaster)
        }
    }
    
    private func hasAchievement(_ type: AchievementType) -> Bool {
        achievements.contains { $0.type == type }
    }
    
    private func unlockAchievement(_ type: AchievementType) {
        let achievement = Achievement(type: type, unlockedDate: Date())
        achievements.append(achievement)
        
        // Award bonus coins for achievement
        coins += type.coinReward
    }
    
    // MARK: - Persistence (for later integration with backend)
    
    func saveToUserDefaults() {
        UserDefaults.standard.set(coins, forKey: "coins")
        UserDefaults.standard.set(stars, forKey: "stars")
        UserDefaults.standard.set(practiceCount, forKey: "practiceCount")
        UserDefaults.standard.set(currentStreak, forKey: "currentStreak")
        UserDefaults.standard.set(longestStreak, forKey: "longestStreak")
    }
    
    func loadFromUserDefaults() {
        coins = UserDefaults.standard.integer(forKey: "coins")
        stars = UserDefaults.standard.integer(forKey: "stars")
        practiceCount = UserDefaults.standard.integer(forKey: "practiceCount")
        currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
        longestStreak = UserDefaults.standard.integer(forKey: "longestStreak")
    }
}

// MARK: - Reward Result

struct RewardResult {
    let stars: Int
    let coins: Int
    let accuracy: Double
    let isNewRecord: Bool
}

// MARK: - Achievements System

struct Achievement: Identifiable, Codable {
    let id = UUID()
    let type: AchievementType
    let unlockedDate: Date
}

enum AchievementType: String, Codable, CaseIterable {
    case firstWord = "first_word"
    case fivePractices = "five_practices"
    case tenPractices = "ten_practices"
    case threeStreak = "three_streak"
    case weekStreak = "week_streak"
    case starCollector = "star_collector"
    case coinMaster = "coin_master"
    case perfectScore = "perfect_score"
    
    var title: String {
        switch self {
        case .firstWord: return "First Steps"
        case .fivePractices: return "Getting Started"
        case .tenPractices: return "Dedicated Learner"
        case .threeStreak: return "On a Roll"
        case .weekStreak: return "Week Warrior"
        case .starCollector: return "Star Collector"
        case .coinMaster: return "Coin Master"
        case .perfectScore: return "Perfection"
        }
    }
    
    var description: String {
        switch self {
        case .firstWord: return "Practiced your first word!"
        case .fivePractices: return "Completed 5 practice sessions"
        case .tenPractices: return "Completed 10 practice sessions"
        case .threeStreak: return "3 days in a row!"
        case .weekStreak: return "7 days in a row!"
        case .starCollector: return "Collected 50 stars"
        case .coinMaster: return "Earned 500 coins"
        case .perfectScore: return "Got a perfect score!"
        }
    }
    
    var icon: String {
        switch self {
        case .firstWord: return "star.fill"
        case .fivePractices: return "5.circle.fill"
        case .tenPractices: return "10.circle.fill"
        case .threeStreak: return "flame.fill"
        case .weekStreak: return "flame.fill"
        case .starCollector: return "sparkles"
        case .coinMaster: return "bitcoinsign.circle.fill"
        case .perfectScore: return "crown.fill"
        }
    }
    
    var coinReward: Int {
        switch self {
        case .firstWord: return 50
        case .fivePractices: return 100
        case .tenPractices: return 200
        case .threeStreak: return 75
        case .weekStreak: return 250
        case .starCollector: return 300
        case .coinMaster: return 500
        case .perfectScore: return 150
        }
    }
}

// MARK: - Store Items (for spending coins)

struct StoreItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let cost: Int
    let icon: String
    let category: StoreCategory
}

enum StoreCategory {
    case themes
    case characters
    case powerups
}

// Example store items
extension StoreItem {
    static let sampleItems = [
        StoreItem(
            name: "Rainbow Theme",
            description: "Colorful rainbow background",
            cost: 100,
            icon: "🌈",
            category: .themes
        ),
        StoreItem(
            name: "Ocean Theme",
            description: "Peaceful ocean waves",
            cost: 150,
            icon: "🌊",
            category: .themes
        ),
        StoreItem(
            name: "Special Crown",
            description: "Golden crown for your character",
            cost: 200,
            icon: "👑",
            category: .characters
        ),
        StoreItem(
            name: "Hint Helper",
            description: "Get helpful pronunciation hints",
            cost: 50,
            icon: "💡",
            category: .powerups
        )
    ]
}
