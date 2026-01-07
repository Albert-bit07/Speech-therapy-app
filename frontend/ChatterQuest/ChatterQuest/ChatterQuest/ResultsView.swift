//
//  ResultsView.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 12/30/25.
//
import SwiftUI

struct ResultsView: View {
    let targetWord: String
    let onNextWord: () -> Void
    let onTryAgain: () -> Void
    
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    @State private var starsEarned = 2
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.softGreen, Color.softBlue.opacity(0.7), Color.navy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Confetti
            if showConfetti {
                ConfettiView()
            }
            
            VStack(spacing: 32) {
                Spacer()
                
                // Success message
                VStack(spacing: 16) {
                    Text("🎉")
                        .font(.system(size: 80))
                        .scaleEffect(scale)
                    
                    Text("Great job!")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("You earned \(starsEarned) stars!")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Stars earned
                HStack(spacing: 20) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < starsEarned ? "star.fill" : "star")
                            .font(.system(size: 50))
                            .foregroundColor(index < starsEarned ? .sunshine : .white.opacity(0.3))
                            .scaleEffect(scale)
                            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(Double(index) * 0.15), value: scale)
                    }
                }
                .padding(.vertical, 20)
                
                // Pronunciation breakdown
                VStack(spacing: 12) {
                    Text("You said:")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 8) {
                        Text("but")
                        Text("•")
                        Text("ter")
                            .foregroundColor(.sunshine)
                            .fontWeight(.bold)
                        Text("•")
                        Text("fly")
                    }
                    .font(.title)
                    .foregroundColor(.white)
                    
                    Text("💡 Great job with the 'r' sound!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                )
                .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: onTryAgain) {
                        Text("Try Again")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                    )
                            )
                    }
                    
                    Button(action: onNextWord) {
                        HStack {
                            Text("Next Word")
                                .font(.headline)
                                .fontWeight(.bold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.softBlue)
                                .shadow(color: Color.softBlue.opacity(0.5), radius: 10, x: 0, y: 5)
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
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

// Confetti animation
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    struct ConfettiPiece: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var rotation: Double
        var color: Color
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    Rectangle()
                        .fill(piece.color)
                        .frame(width: 10, height: 10)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(x: piece.x, y: piece.y)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
    }
    
    func generateConfetti(in size: CGSize) {
        let colors: [Color] = [.sunshine, .softBlue, .softGreen, .lavender, .pink, .orange]
        
        confettiPieces = (0..<50).map { _ in
            ConfettiPiece(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                rotation: Double.random(in: 0...360),
                color: colors.randomElement()!
            )
        }
        
        withAnimation(.linear(duration: 3)) {
            for i in confettiPieces.indices {
                confettiPieces[i].y = size.height + 50
                confettiPieces[i].rotation += Double.random(in: 360...720)
            }
        }
    }
}

#Preview {
    ResultsView(
        targetWord: "BUTTERFLY",
        onNextWord: {},
        onTryAgain: {}
    )
}

