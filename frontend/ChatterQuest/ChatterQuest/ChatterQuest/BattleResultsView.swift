//
//  BattleResultsView.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 1/10/26.
//

import SwiftUI

struct BattleResultsView: View {
    let targetWord: String
    let pronunciationResult: PronunciationResult
    @ObservedObject var battleState: BattleState
    @ObservedObject var rewardsManager: RewardsManager
    let onNextBattle: () -> Void
    let onRetry: () -> Void
    
    @State private var showVictory = false
    @State private var showRewards = false
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    
    private var starsEarned: Int {
        rewardsManager.calculateRewards(
            accuracy: pronunciationResult.overallScore
        ).stars
    }
    
    private var coinsEarned: Int {
        rewardsManager.calculateRewards(
            accuracy: pronunciationResult.overallScore
        ).coins
    }
    
    var body: some View {
        ZStack {
            // Epic victory background
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.8),
                    Color.purple.opacity(0.7),
                    Color.navy
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Confetti
            if showConfetti {
                ConfettiView()
            }
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Victory banner
                    if showVictory {
                        VStack(spacing: 16) {
                            Text("⚔️")
                                .font(.system(size: 80))
                                .scaleEffect(scale)
                            
                            Text("VICTORY!")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Monster Defeated!")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Defeated monster
                    VStack(spacing: 12) {
                        Text(battleState.currentMonster.emoji)
                            .font(.system(size: 60))
                            .grayscale(1.0)
                            .opacity(0.5)
                        
                        Text("\(battleState.currentMonster.displayName) Defeated")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal)
                    
                    // Battle stats
                    if showRewards {
                        BattleStatsCard(
                            accuracy: pronunciationResult.overallScore,
                            combos: battleState.comboCount,
                            criticalHits: battleState.isCriticalHit(accuracy: pronunciationResult.overallScore) ? 1 : 0
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // Rewards earned
                    if showRewards {
                        RewardsEarnedCard(
                            stars: starsEarned,
                            coins: coinsEarned
                        )
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Pronunciation feedback
                    if !pronunciationResult.mistakes.isEmpty {
                        TipsCard(mistakes: pronunciationResult.mistakes)
                            .padding(.horizontal)
                    }
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: onNextBattle) {
                            HStack(spacing: 12) {
                                Text("Next Battle")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.orange, Color.red.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color.orange.opacity(0.5), radius: 15, x: 0, y: 10)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            // Staggered animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                showVictory = true
                scale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showConfetti = true
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showRewards = true
                }
            }
        }
    }
}

// MARK: - Battle Stats Card

struct BattleStatsCard: View {
    let accuracy: Double
    let combos: Int
    let criticalHits: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.orange)
                Text("Battle Performance")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 20) {
                StatBadge(
                    icon: "target",
                    label: "Accuracy",
                    value: "\(Int(accuracy * 100))%",
                    color: .softGreen
                )
                
                StatBadge(
                    icon: "flame.fill",
                    label: "Max Combo",
                    value: "x\(combos)",
                    color: .orange
                )
                
                StatBadge(
                    icon: "bolt.fill",
                    label: "Critical",
                    value: "\(criticalHits)",
                    color: .yellow
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.5), lineWidth: 2)
                )
        )
    }
}

struct StatBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Tips Card

struct TipsCard: View {
    let mistakes: [PronunciationMistake]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.sunshine)
                Text("Battle Tips")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(mistakes.prefix(2), id: \.phoneme) { mistake in
                    HStack(alignment: .top, spacing: 12) {
                        Text("•")
                            .foregroundColor(.sunshine)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mistake.phoneme)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.sunshine)
                            
                            Text(mistake.suggestion)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.sunshine.opacity(0.5), lineWidth: 2)
                )
        )
    }
}

#Preview {
    BattleResultsView(
        targetWord: "ROCKET",
        pronunciationResult: PronunciationResult(
            overallScore: 0.92,
            transcribedText: "rocket",
            phonemeAnalysis: [],
            mistakes: [
                PronunciationMistake(
                    phoneme: "/r/",
                    position: 0,
                    severity: .minor,
                    suggestion: "Great job! Try keeping your tongue slightly further back.",
                    exampleWords: ["rabbit", "rainbow", "rocket"]
                )
            ],
            feedback: "Excellent pronunciation!",
            confidence: 0.94
        ),
        battleState: {
            let state = BattleState()
            state.currentMonster = .rMonster
            state.comboCount = 5
            return state
        }(),
        rewardsManager: RewardsManager(),
        onNextBattle: {},
        onRetry: {}
    )
}
