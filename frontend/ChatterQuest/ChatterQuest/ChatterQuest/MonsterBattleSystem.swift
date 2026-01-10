//
//  MonsterBattleSystem.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 1/10/26.
//

import SwiftUI
import Combine  
// MARK: - Monster Types

enum MonsterType: String, CaseIterable {
    case rMonster = "R Monster"
    case sMonster = "S Monster"
    case thMonster = "TH Monster"
    case lMonster = "L Monster"
    case genericMonster = "Word Monster"
    
    var emoji: String {
        switch self {
        case .rMonster: return "👹"
        case .sMonster: return "🐍"
        case .thMonster: return "👾"
        case .lMonster: return "🦎"
        case .genericMonster: return "👻"
        }
    }
    
    var displayName: String {
        return rawValue
    }
    
    var color: Color {
        switch self {
        case .rMonster: return .red
        case .sMonster: return .green
        case .thMonster: return .purple
        case .lMonster: return .orange
        case .genericMonster: return .blue
        }
    }
    
    var maxHealth: Int {
        switch self {
        case .rMonster: return 100
        case .sMonster: return 80
        case .thMonster: return 90
        case .lMonster: return 85
        case .genericMonster: return 75
        }
    }
    
    var description: String {
        switch self {
        case .rMonster: return "Master of the /r/ sound!"
        case .sMonster: return "Hisses with /s/ sounds!"
        case .thMonster: return "Controls /th/ sounds!"
        case .lMonster: return "Lord of /l/ sounds!"
        case .genericMonster: return "Challenges your pronunciation!"
        }
    }
    
    static func monsterForWord(_ word: String) -> MonsterType {
        let lowercased = word.lowercased()
        
        if lowercased.contains("r") {
            return .rMonster
        } else if lowercased.contains("s") {
            return .sMonster
        } else if lowercased.contains("th") {
            return .thMonster
        } else if lowercased.contains("l") {
            return .lMonster
        } else {
            return .genericMonster
        }
    }
}

// MARK: - Battle State

class BattleState: ObservableObject {
    @Published var playerHealth: Int = 100
    @Published var monsterHealth: Int = 100
    @Published var currentMonster: MonsterType = .genericMonster
    @Published var damageDealt: Int = 0
    @Published var showDamage: Bool = false
    @Published var comboCount: Int = 0
    @Published var isMonsterDefeated: Bool = false
    @Published var battleLog: [String] = []
    
    func startBattle(word: String) {
        currentMonster = MonsterType.monsterForWord(word)
        monsterHealth = currentMonster.maxHealth
        playerHealth = 100
        comboCount = 0
        isMonsterDefeated = false
        battleLog = []
        addLog("Battle started against \(currentMonster.displayName)!")
    }
    
    func attack(accuracy: Double) {
        // Calculate damage based on accuracy
        let baseDamage = Int(accuracy * 50) // 0-50 damage
        let comboDamage = comboCount * 5 // Bonus for combo
        let totalDamage = baseDamage + comboDamage
        
        damageDealt = totalDamage
        showDamage = true
        
        // Apply damage to monster
        monsterHealth = max(0, monsterHealth - totalDamage)
        
        // Update combo
        if accuracy >= 0.75 {
            comboCount += 1
            addLog("Hit! Combo x\(comboCount)!")
        } else {
            comboCount = 0
            addLog("Miss! Combo broken.")
        }
        
        // Check if monster is defeated
        if monsterHealth <= 0 {
            isMonsterDefeated = true
            addLog("Monster defeated! Victory!")
        }
        
        // Hide damage after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showDamage = false
        }
    }
    
    func isCriticalHit(accuracy: Double) -> Bool {
        return accuracy >= 0.90
    }
    
    private func addLog(_ message: String) {
        battleLog.insert(message, at: 0)
        if battleLog.count > 5 {
            battleLog.removeLast()
        }
    }
    
    func reset() {
        playerHealth = 100
        monsterHealth = 100
        comboCount = 0
        isMonsterDefeated = false
        battleLog = []
        damageDealt = 0
        showDamage = false
    }
}

// MARK: - Monster View

struct MonsterView: View {
    let monster: MonsterType
    let health: Int
    @State private var bounce = false
    @State private var shake = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Monster emoji with effects
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [monster.color.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                // Monster
                Text(monster.emoji)
                    .font(.system(size: 100))
                    .scaleEffect(bounce ? 1.1 : 1.0)
                    .rotationEffect(.degrees(shake ? -5 : 5))
            }
            
            // Monster name
            Text(monster.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Health bar
            VStack(spacing: 8) {
                HStack {
                    Text("HP")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(health)/\(monster.maxHealth)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.2))
                        
                        // Health fill
                        RoundedRectangle(cornerRadius: 8)
                            .fill(healthBarGradient)
                            .frame(width: geometry.size.width * healthPercentage)
                    }
                }
                .frame(height: 16)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                bounce = true
            }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                shake = true
            }
        }
    }
    
    var healthPercentage: CGFloat {
        return CGFloat(health) / CGFloat(monster.maxHealth)
    }
    
    var healthBarGradient: LinearGradient {
        if healthPercentage > 0.5 {
            return LinearGradient(
                colors: [.green, .green.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if healthPercentage > 0.25 {
            return LinearGradient(
                colors: [.orange, .orange.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [.red, .red.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - Player Health View

struct PlayerHealthView: View {
    let health: Int
    let maxHealth: Int = 100
    
    var body: some View {
        HStack(spacing: 12) {
            // Player icon
            ZStack {
                Circle()
                    .fill(Color.softBlue.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Text("🐛")
                    .font(.system(size: 30))
            }
            
            // Health info
            VStack(alignment: .leading, spacing: 4) {
                Text("You")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [.softBlue, .softBlue.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(health) / CGFloat(maxHealth))
                        }
                    }
                    .frame(height: 12)
                    
                    Text("\(health)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 35, alignment: .trailing)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.softBlue.opacity(0.5), lineWidth: 2)
                )
        )
    }
}

// MARK: - Damage Display

struct DamageDisplay: View {
    let damage: Int
    let isCritical: Bool
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Text(isCritical ? "💥 \(damage)! CRITICAL!" : "-\(damage)")
            .font(isCritical ? .title : .title2)
            .fontWeight(.bold)
            .foregroundColor(isCritical ? .orange : .red)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    offset = -100
                    opacity = 0
                }
            }
    }
}

// MARK: - Combo Display

struct ComboDisplay: View {
    let combo: Int
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        if combo > 1 {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundColor(.orange)
                
                Text("COMBO x\(combo)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.3))
                    .overlay(
                        Capsule()
                            .stroke(Color.orange, lineWidth: 2)
                    )
            )
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - Battle Log

struct BattleLog: View {
    let logs: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(logs.prefix(3), id: \.self) { log in
                Text("• \(log)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
}

#Preview {
    ZStack {
        Color.navy.ignoresSafeArea()
        
        VStack(spacing: 30) {
            MonsterView(monster: .rMonster, health: 65)
            
            PlayerHealthView(health: 85)
                .padding(.horizontal)
            
            ComboDisplay(combo: 3)
        }
    }
}
