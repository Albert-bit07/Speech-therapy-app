//
//  DashboardView.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 12/30/25.
//

import SwiftUI

struct DashboardView: View {
    @State private var isVisible = false
    @State private var showingGame = false
    @State private var starsCollected = 8
    @State private var totalStars = 12
    @AppStorage("practiceCount") private var practiceCount = 3
    
    var growthStage: GrowthStage {
        switch practiceCount {
        case 0..<5: return .worm
        case 5..<10: return .cocoon
        default: return .butterfly
        }
    }
    
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
                        
                        Text("🌟")
                            .font(.system(size: 50))
                            .rotationEffect(.degrees(isVisible ? 360 : 0))
                    }
                    .padding(.top, 20)
                    
                    // Character with glow effect
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
                        
                        CharacterView(stage: growthStage)
                    }
                    .padding(.vertical, 20)
                    
                    // Growth message
                    Text(getGrowthMessage())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .scaleEffect(isVisible ? 1.0 : 0.8)
                        .opacity(isVisible ? 1.0 : 0.0)
                    
                    // Progress stars
                    VStack(spacing: 16) {
                        Text("Stars Collected")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack(spacing: 12) {
                            ForEach(0..<totalStars, id: \.self) { index in
                                StarView(isFilled: index < starsCollected, delay: Double(index) * 0.1)
                            }
                        }
                        
                        Text("\(starsCollected)/\(totalStars) ⭐️")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.sunshine)
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            )
                    )
                    .padding(.horizontal)
                    
                    // Start game button with pulse
                    Button(action: {
                        showingGame = true
                    }) {
                        HStack {
                            Text("Start Game")
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
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                    .scaleEffect(isVisible ? 1.0 : 0.8)
                    .opacity(isVisible ? 1.0 : 0.0)
                }
            }
        }
        .sheet(isPresented: $showingGame) {
            GameView()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
    
    func getGrowthMessage() -> String {
        switch growthStage {
        case .worm:
            return "You're just getting started! 🌱\nKeep practicing to grow!"
        case .cocoon:
            return "Amazing progress! 🎉\nYou're transforming!"
        case .butterfly:
            return "You've become a beautiful butterfly! 🦋\nKeep soaring!"
        }
    }
}

// Animated star view
struct StarView: View {
    let isFilled: Bool
    let delay: Double
    @State private var scale: CGFloat = 0.3
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: isFilled ? "star.fill" : "star")
            .font(.title2)
            .foregroundColor(isFilled ? .sunshine : .white.opacity(0.3))
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(delay)) {
                    scale = 1.0
                    rotation = 360
                }
            }
    }
}

// Floating particles background
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
