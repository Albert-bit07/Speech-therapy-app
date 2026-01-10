//
//  StoreAndAchievements.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 1/9/26.
//

//
//  StoreAndAchievements.swift
//  ChatterQuest
//
//  Store for spending coins & Achievements tracker
//

import SwiftUI

// MARK: - Store View

struct StoreView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var rewardsManager: RewardsManager
    
    @State private var selectedCategory: StoreCategory = .themes
    @State private var purchasedItems: Set<String> = []
    
    let storeItems = StoreItem.sampleItems
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.90, green: 0.94, blue: 0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Coin balance
                    HStack(spacing: 12) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.title)
                            .foregroundColor(.softGreen)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Coins")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("\(rewardsManager.coins)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.navy)
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.softGreen.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    
                    // Category picker
                    Picker("Category", selection: $selectedCategory) {
                        Text("🎨 Themes").tag(StoreCategory.themes)
                        Text("✨ Characters").tag(StoreCategory.characters)
                        Text("⚡️ Power-ups").tag(StoreCategory.powerups)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Items grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(filteredItems) { item in
                                StoreItemCard(
                                    item: item,
                                    isPurchased: purchasedItems.contains(item.id.uuidString),
                                    canAfford: rewardsManager.coins >= item.cost
                                ) {
                                    purchaseItem(item)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Store")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadPurchasedItems()
        }
    }
    
    var filteredItems: [StoreItem] {
        storeItems.filter { $0.category == selectedCategory }
    }
    
    func purchaseItem(_ item: StoreItem) {
        guard rewardsManager.coins >= item.cost else { return }
        
        rewardsManager.coins -= item.cost
        rewardsManager.saveToUserDefaults()
        
        purchasedItems.insert(item.id.uuidString)
        savePurchasedItems()
        
        // Add haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func loadPurchasedItems() {
        if let data = UserDefaults.standard.data(forKey: "purchasedItems"),
           let items = try? JSONDecoder().decode(Set<String>.self, from: data) {
            purchasedItems = items
        }
    }
    
    func savePurchasedItems() {
        if let data = try? JSONEncoder().encode(purchasedItems) {
            UserDefaults.standard.set(data, forKey: "purchasedItems")
        }
    }
}

// MARK: - Store Item Card

struct StoreItemCard: View {
    let item: StoreItem
    let isPurchased: Bool
    let canAfford: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Item icon
            Text(item.icon)
                .font(.system(size: 60))
            
            // Item name
            Text(item.name)
                .font(.headline)
                .foregroundColor(.navy)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Item description
            Text(item.description)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Spacer()
            
            // Purchase button
            if isPurchased {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.softGreen)
                    Text("Owned")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.softGreen)
                }
                .padding(.vertical, 10)
            } else {
                Button(action: onPurchase) {
                    HStack(spacing: 6) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.caption)
                        Text("\(item.cost)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canAfford ? Color.softBlue : Color.gray)
                    )
                }
                .disabled(!canAfford)
            }
        }
        .padding(16)
        .frame(height: 240)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.gray.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Achievements View

struct AchievementsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var rewardsManager: RewardsManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.90, green: 0.94, blue: 0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Progress overview
                        AchievementProgressCard(
                            unlockedCount: rewardsManager.achievements.count,
                            totalCount: AchievementType.allCases.count
                        )
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Achievements list
                        VStack(spacing: 16) {
                            ForEach(AchievementType.allCases, id: \.self) { type in
                                let achievement = rewardsManager.achievements.first { $0.type == type }
                                
                                AchievementCard(
                                    type: type,
                                    isUnlocked: achievement != nil,
                                    unlockedDate: achievement?.unlockedDate,
                                    progress: getProgress(for: type)
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func getProgress(for type: AchievementType) -> Double {
        switch type {
        case .firstWord:
            return rewardsManager.practiceCount >= 1 ? 1.0 : 0.0
        case .fivePractices:
            return min(Double(rewardsManager.practiceCount) / 5.0, 1.0)
        case .tenPractices:
            return min(Double(rewardsManager.practiceCount) / 10.0, 1.0)
        case .threeStreak:
            return min(Double(rewardsManager.currentStreak) / 3.0, 1.0)
        case .weekStreak:
            return min(Double(rewardsManager.currentStreak) / 7.0, 1.0)
        case .starCollector:
            return min(Double(rewardsManager.stars) / 50.0, 1.0)
        case .coinMaster:
            return min(Double(rewardsManager.coins) / 500.0, 1.0)
        case .perfectScore:
            return 0.0 // Would need to track from backend
        }
    }
}

// MARK: - Achievement Progress Card

struct AchievementProgressCard: View {
    let unlockedCount: Int
    let totalCount: Int
    
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Progress")
                        .font(.headline)
                        .foregroundColor(.navy)
                    
                    Text("\(unlockedCount) of \(totalCount) unlocked")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [Color.softBlue, Color.lavender],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(progress * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.navy)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.softBlue, Color.lavender],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 12)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.softBlue.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let type: AchievementType
    let isUnlocked: Bool
    let unlockedDate: Date?
    let progress: Double
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.sunshine.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? .sunshine : .gray.opacity(0.5))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(type.title)
                    .font(.headline)
                    .foregroundColor(isUnlocked ? .navy : .gray)
                
                Text(type.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if isUnlocked, let date = unlockedDate {
                    Text("Unlocked \(formatDate(date))")
                        .font(.caption2)
                        .foregroundColor(.softGreen)
                } else {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.softBlue)
                                .frame(width: geometry.size.width * progress)
                        }
                    }
                    .frame(height: 6)
                }
            }
            
            Spacer()
            
            // Reward
            if isUnlocked {
                VStack(spacing: 4) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .foregroundColor(.softGreen)
                    Text("+\(type.coinReward)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.softGreen)
                }
            } else {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isUnlocked ? Color.sunshine.opacity(0.3) : Color.clear, lineWidth: 2)
                )
                .shadow(color: Color.gray.opacity(0.1), radius: 5, x: 0, y: 3)
        )
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Extension for new color

extension Color {
    static let pink = Color(red: 1.0, green: 0.75, blue: 0.80)
    static let orange = Color(red: 1.0, green: 0.65, blue: 0.30)
}

#Preview("Store") {
    StoreView(rewardsManager: RewardsManager())
}

#Preview("Achievements") {
    AchievementsView(rewardsManager: RewardsManager())
}
