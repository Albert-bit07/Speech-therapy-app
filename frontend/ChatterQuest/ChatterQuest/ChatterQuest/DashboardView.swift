//
//  DashboardView.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 12/30/25.
//

//
//  DashboardView.swift
//  ChatterQuest
//
//  GAMIFIED VERSION with Worm→Cocoon→Butterfly progression
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var rewardsManager = RewardsManager()
    @State private var isVisible = false
    @State private var showingGame = false
    @State private var showingStore = false
    @State private var showingAchievements = false
    @State private var showLevelUpAnimation = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [Color.navy, Color.navy.opacity(0.8), Color.softBlue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating particles
            FloatingParticlesView()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header with animation
                    VStack(spacing: 12) {
                        Text("Hello, Bright Star!")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(isVisible ? 1.0 : 0.5)
                            .opacity(isVisible ? 1.0 : 0.0)
                        
                        // Coins and Stars Display
                        HStack(spacing: 24) {
                            CurrencyBadge(
                                icon: "star.fill",
                                count: rewardsManager.stars,
                                color: .sunshine
                            )
                            
                            CurrencyBadge(
                                icon: "bitcoinsign.circle.fill",
                                count: rewardsManager.coins,
                                color: .softGreen
                            )
                        }
                        .scaleEffect(isVisible ? 1.0 : 0.8)
                        .opacity(isVisible ? 1.0 : 0.0)
                    }
                    .padding(.top, 20)
                    
                    // Character with growth stage and progress
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.sunshine.opacity(0.3), Color.clear],
                                        center: .center,
                                        startRadius: 50,
                                        endRadius: 120
                                    )
                                )
                                .frame(width: 200, height: 200)
                                .blur(radius: 20)
                                .scaleEffect(isVisible ? 1.2 : 0.8)
                            
                            CharacterView(stage: rewardsManager.currentStage)
                        }
                        
                        // Growth stage title
                        Text(rewardsManager.currentStage.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Progress to next stage (if not at final stage)
                        if rewardsManager.currentStage != .butterfly {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Progress to \(rewardsManager.currentStage.nextStage?.displayName ?? "")")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                    
                                    Text("\(rewardsManager.practiceCount)/\(rewardsManager.currentStage.nextStage?.practiceThreshold ?? 0)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.sunshine)
                                }
                                
                                ProgressBar(progress: rewardsManager.progressToNextStage)
                            }
                            .padding(.horizontal, 40)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // Streak display
                    if rewardsManager.currentStreak > 0 {
                        StreakCard(
                            currentStreak: rewardsManager.currentStreak,
                            longestStreak: rewardsManager.longestStreak
                        )
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Quick stats cards
                    // Quick stats cards
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Streak",
                            value: "\(rewardsManager.currentStreak)",
                            subtitle: "days",
                            icon: "flame.fill",          // ← String (SF Symbol name)
                            color: .orange               // ← Color
                        )
                        
                        StatCard(
                            title: "Sessions",
                            value: "\(rewardsManager.practiceCount)",
                            subtitle: "total",
                            icon: "chart.line.uptrend.xyaxis",  // ← String
                            color: .softBlue                     // ← Color
                        )
                    }
                    .padding(.horizontal)
                    
                    // Action buttons grid
                    VStack(spacing: 16) {
                        // Start game button - PRIMARY
                        Button(action: {
                            showingGame = true
                        }) {
                            HStack {
                                Text("Start Practice")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("🚀")
                                    .font(.title)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.softBlue, Color.softBlue.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                }
                            )
                            .shadow(color: Color.softBlue.opacity(0.5), radius: 20, x: 0, y: 10)
                        }
                        

                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                    .scaleEffect(isVisible ? 1.0 : 0.8)
                    .opacity(isVisible ? 1.0 : 0.0)
                }
            }
            
            // Level up animation overlay
            if showLevelUpAnimation {
                LevelUpOverlay(stage: rewardsManager.currentStage)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showingGame) {
            GameView(rewardsManager: rewardsManager)
        }
        .sheet(isPresented: $showingStore) {
            StoreView(rewardsManager: rewardsManager)
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView(rewardsManager: rewardsManager)
        }
        .onAppear {
            rewardsManager.loadFromUserDefaults()
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
        .onChange(of: rewardsManager.currentStage) { oldStage, newStage in
            if oldStage != newStage {
                showLevelUpAnimation = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showLevelUpAnimation = false
                    }
                }
            }
        }
    }
}

// MARK: - Currency Badge

struct CurrencyBadge: View {
    let icon: String
    let count: Int
    let color: Color
    
    @State private var bounce = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.5), lineWidth: 2)
                )
        )
        .scaleEffect(bounce ? 1.1 : 1.0)
        .onChange(of: count) { _, _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bounce = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    bounce = false
                }
            }
        }
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.2))
                
                // Progress fill
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.softGreen, Color.sunshine],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(min(progress, 1.0)))
                
                // Sparkle effect at progress point
                if progress > 0 && progress < 1 {
                    Image(systemName: "sparkles")
                        .foregroundColor(.white)
                        .font(.caption)
                        .offset(x: geometry.size.width * CGFloat(progress) - 10)
                }
            }
        }
        .frame(height: 12)
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Flame icon with animation
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Text("🔥")
                    .font(.system(size: 32))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\(currentStreak) Day Streak!")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if currentStreak >= 3 {
                        Text("💪")
                            .font(.title3)
                    }
                }
                
                Text("Longest: \(longestStreak) days")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("+\(currentStreak * 2)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.sunshine)
                
                Text("bonus")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
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


// MARK: - Level Up Overlay

struct LevelUpOverlay: View {
    let stage: GrowthStage
    @State private var scale: CGFloat = 0.5
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            if showConfetti {
                ConfettiView()
            }
            
            VStack(spacing: 24) {
                Text(stage.emoji)
                    .font(.system(size: 120))
                    .scaleEffect(scale)
                
                Text("Level Up!")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                
                Text("You evolved into a \(stage.displayName)!")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                Text("✨")
                    .font(.system(size: 50))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.navy.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.sunshine, lineWidth: 3)
                    )
            )
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Floating Particles (existing from original)

struct FloatingParticlesView: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.white.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(x: particle.x, y: particle.y)
                        .blur(radius: 2)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                animateParticles()
            }
        }
    }
    
    func generateParticles(in size: CGSize) {
        particles = (0..<20).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.1...0.4)
            )
        }
    }
    
    func animateParticles() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            for i in particles.indices {
                particles[i].y -= 800
            }
        }
    }
}

#Preview {
    DashboardView()
}
