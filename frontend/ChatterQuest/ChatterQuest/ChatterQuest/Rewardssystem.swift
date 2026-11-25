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

enum GrowthStage: String, Codable {
    case worm = "worm"
    case cocoon = "cocoon"
    case butterfly = "butterfly"

    var displayName: String {
        switch self {
        case .worm: return "Little Worm"
        case .cocoon: return "Growing Cocoon"
        case .butterfly: return "Beautiful Butterfly"
        }
    }

    var emoji: String {
        switch self {
        case .worm: return "🐛"
        case .cocoon: return "🥚"
        case .butterfly: return "🦋"
        }
    }

    var practiceThreshold: Int {
        switch self {
        case .worm: return 0
        case .cocoon: return 5
        case .butterfly: return 10
        }
    }

    var nextStage: GrowthStage? {
        switch self {
        case .worm: return .cocoon
        case .cocoon: return .butterfly
        case .butterfly: return nil  // Already at final stage
        }
    }
}


// MARK: - Rewards Manager

class RewardsManager: ObservableObject {
    @Published var coins: Int = 0
    @Published var stars: Int = 0
    @Published var practiceCount: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var achievements: [Achievement] = []
    @Published var purchasedItems: Set<String> = []
    private let defaults: UserDefaults
    private var readable = true

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    private struct SavedRewards: Codable {
        var coins: Int
        var stars: Int
        var practiceCount: Int
        var currentStreak: Int
        var longestStreak: Int
        var achievements: [Achievement]
        var purchasedItems: Set<String>
    }

    private var snapshot: SavedRewards {
        SavedRewards(coins: coins, stars: stars, practiceCount: practiceCount,
                     currentStreak: currentStreak, longestStreak: longestStreak,
                     achievements: achievements, purchasedItems: purchasedItems)
    }

    private func apply(_ saved: SavedRewards) {
        coins = saved.coins
        stars = saved.stars
        practiceCount = saved.practiceCount
        currentStreak = saved.currentStreak
        longestStreak = saved.longestStreak
        achievements = saved.achievements
        purchasedItems = saved.purchasedItems
    }

    private func persist(_ saved: SavedRewards) -> Bool {
        guard readable, let data = try? JSONEncoder().encode(saved) else { return false }
        // One value contains both the balance and ownership, avoiding a partial
        // purchase snapshot between separate preference-key writes.
        defaults.set(data, forKey: "rewardsSnapshotV1")
        return true
    }

    func purchase(_ item: StoreItem) -> Bool {
        guard item.cost >= 0, coins >= item.cost, !purchasedItems.contains(item.id) else { return false }
        var saved = snapshot
        saved.coins -= item.cost
        saved.purchasedItems.insert(item.id)
        guard persist(saved) else { return false }
        apply(saved)
        return true
    }
    
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
    
    @discardableResult
    func saveToUserDefaults() -> Bool { persist(snapshot) }

    @discardableResult
    func loadFromUserDefaults() -> Bool {
        if let data = defaults.data(forKey: "rewardsSnapshotV1") {
            guard let saved = try? JSONDecoder().decode(SavedRewards.self, from: data) else {
                readable = false
                return false
            }
            readable = true
            apply(saved)
            return true
        }
        // Legacy versions did not save achievements; their history cannot be
        // reconstructed from balances. Preserve all values that were saved.
        coins = defaults.integer(forKey: "coins")
        stars = defaults.integer(forKey: "stars")
        practiceCount = defaults.integer(forKey: "practiceCount")
        currentStreak = defaults.integer(forKey: "currentStreak")
        longestStreak = defaults.integer(forKey: "longestStreak")
        if let data = defaults.data(forKey: "purchasedItems"),
           let items = try? JSONDecoder().decode(Set<String>.self, from: data) {
            purchasedItems = items
        }
        return saveToUserDefaults()
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
    var id: AchievementType { type }
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
    let id: String
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
            id: "rainbow-theme",
            name: "Rainbow Theme",
            description: "Colorful rainbow background",
            cost: 100,
            icon: "🌈",
            category: .themes
        ),
        StoreItem(
            id: "ocean-theme",
            name: "Ocean Theme",
            description: "Peaceful ocean waves",
            cost: 150,
            icon: "🌊",
            category: .themes
        ),
        StoreItem(
            id: "special-crown",
            name: "Special Crown",
            description: "Golden crown for your character",
            cost: 200,
            icon: "👑",
            category: .characters
        ),
        StoreItem(
            id: "hint-helper",
            name: "Hint Helper",
            description: "Get helpful pronunciation hints",
            cost: 50,
            icon: "💡",
            category: .powerups
        )
    ]
}
