//
//  Characters.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 12/30/25.
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

// Character View with animation
struct CharacterView: View {
    let stage: GrowthStage
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [glowColor.opacity(0.4), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 20)
                .scaleEffect(isAnimating ? 1.2 : 0.9)
            
            // Character
            Text(stage.emoji)
                .font(.system(size: characterSize))
                .scaleEffect(isAnimating ? 1.05 : 0.95)
                .rotationEffect(.degrees(isAnimating ? rotationAmount : 0))
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: animationDuration)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
    
    private var characterSize: CGFloat {
        switch stage {
        case .worm: return 80
        case .cocoon: return 90
        case .butterfly: return 100
        }
    }
    
    private var glowColor: Color {
        switch stage {
        case .worm: return .softGreen
        case .cocoon: return .sunshine
        case .butterfly: return .lavender
        }
    }
    
    private var rotationAmount: Double {
        switch stage {
        case .worm: return 5
        case .cocoon: return 3
        case .butterfly: return 10
        }
    }
    
    private var animationDuration: Double {
        switch stage {
        case .worm: return 2.0
        case .cocoon: return 3.0
        case .butterfly: return 1.5
        }
    }
}

#Preview {
    CharacterView(stage: .worm)
}
