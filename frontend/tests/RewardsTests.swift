import Foundation

@main
struct RewardsTests {
    static func main() throws {
        let suite = "rewards-tests-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = RewardsManager(defaults: defaults)
        precondition(first.loadFromUserDefaults())
        first.stars = 50
        first.coins = 500
        first.awardRewards(RewardResult(stars: 0, coins: 0, accuracy: 0, isNewRecord: false))
        let coins = first.coins
        let identifiers = first.achievements.map(\.id)
        let dates = first.achievements.map(\.unlockedDate)
        precondition(identifiers.contains(.starCollector) && identifiers.contains(.coinMaster))
        precondition(first.saveToUserDefaults())
        let restored = RewardsManager(defaults: defaults)
        precondition(restored.loadFromUserDefaults())
        precondition(restored.achievements.map(\.id) == identifiers)
        precondition(restored.achievements.map(\.unlockedDate) == dates)
        restored.awardRewards(RewardResult(stars: 0, coins: 0, accuracy: 0, isNewRecord: false))
        precondition(restored.coins == coins, "Restart awarded the same milestone twice")
        precondition(Set(StoreItem.sampleItems.map(\.id)).count == StoreItem.sampleItems.count)
        let item = StoreItem.sampleItems[0]
        precondition(restored.purchase(item))
        let purchased = RewardsManager(defaults: defaults)
        precondition(purchased.loadFromUserDefaults())
        precondition(purchased.coins == coins - item.cost)
        precondition(purchased.purchasedItems.contains(item.id))
        precondition(!purchased.purchase(item), "A duplicate purchase charged twice")
        precondition(purchased.coins == coins - item.cost)
        let unaffordable = StoreItem(id: "expensive", name: "Test", description: "", cost: Int.max, icon: "", category: .themes)
        precondition(!purchased.purchase(unaffordable))

        // Existing counters migrate without inventing missing achievement history.
        defaults.removePersistentDomain(forName: suite)
        defaults.set(123, forKey: "coins")
        defaults.set(12, forKey: "stars")
        defaults.set(6, forKey: "practiceCount")
        let legacy = RewardsManager(defaults: defaults)
        precondition(legacy.loadFromUserDefaults())
        precondition(legacy.coins == 123 && legacy.stars == 12 && legacy.practiceCount == 6)
        precondition(legacy.achievements.isEmpty)
        let migrated = RewardsManager(defaults: defaults)
        precondition(migrated.loadFromUserDefaults() && migrated.coins == 123)
        let corrupt = Data("broken".utf8)
        defaults.set(corrupt, forKey: "rewardsSnapshotV1")
        precondition(!migrated.loadFromUserDefaults())
        precondition(!migrated.saveToUserDefaults())
        precondition(!migrated.purchase(item))
        precondition(defaults.data(forKey: "rewardsSnapshotV1") == corrupt)
        print("Passed local rewards restart, ownership, duplicate-credit and migration regressions")
    }
}
