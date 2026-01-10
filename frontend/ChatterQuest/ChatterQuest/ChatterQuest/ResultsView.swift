//
//  ResultsView.swift
//  ChatterQuest
//
//  UPDATED with Pronunciation Feedback & Rewards Display
//

import SwiftUI

struct ResultsView: View {
    let targetWord: String
    let pronunciationResult: PronunciationResult
    @ObservedObject var rewardsManager: RewardsManager
    let onNextWord: () -> Void
    let onTryAgain: () -> Void
    
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    @State private var showRewards = false
    
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
            // Background
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Confetti for good performance
            if showConfetti && pronunciationResult.overallScore >= 0.75 {
                ConfettiView()
            }
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 20)
                    
                    // Success message
                    VStack(spacing: 16) {
                        Text(resultEmoji)
                            .font(.system(size: 80))
                            .scaleEffect(scale)
                        
                        Text(resultTitle)
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        // Score percentage
                        Text("\(Int(pronunciationResult.overallScore * 100))%")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.sunshine)
                    }
                    
                    // Rewards earned (animated)
                    if showRewards {
                        RewardsEarnedCard(
                            stars: starsEarned,
                            coins: coinsEarned
                        )
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Pronunciation breakdown
                    PronunciationBreakdownCard(
                        targetWord: targetWord,
                        result: pronunciationResult
                    )
                    .padding(.horizontal)
                    
                    // Feedback message
                    FeedbackCard(feedback: pronunciationResult.feedback)
                        .padding(.horizontal)
                    
                    // Mistakes and tips (if any)
                    if !pronunciationResult.mistakes.isEmpty {
                        MistakesCard(mistakes: pronunciationResult.mistakes)
                            .padding(.horizontal)
                    }
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: onTryAgain) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Try Again")
                                    .font(.headline)
                            }
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
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if pronunciationResult.overallScore >= 0.75 {
                    showConfetti = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showRewards = true
                }
            }
        }
    }
    
    private var resultEmoji: String {
        let score = pronunciationResult.overallScore
        if score >= 0.95 { return "🎉" }
        if score >= 0.85 { return "⭐️" }
        if score >= 0.75 { return "👍" }
        return "💪"
    }
    
    private var resultTitle: String {
        let score = pronunciationResult.overallScore
        if score >= 0.95 { return "Perfect!" }
        if score >= 0.85 { return "Excellent!" }
        if score >= 0.75 { return "Great job!" }
        return "Good try!"
    }
    
    private var backgroundColors: [Color] {
        let score = pronunciationResult.overallScore
        if score >= 0.85 {
            return [Color.softGreen, Color.softBlue.opacity(0.7), Color.navy]
        } else if score >= 0.70 {
            return [Color.softBlue, Color.lavender.opacity(0.7), Color.navy]
        } else {
            return [Color.lavender, Color.softBlue.opacity(0.6), Color.navy]
        }
    }
}

// MARK: - Rewards Earned Card

struct RewardsEarnedCard: View {
    let stars: Int
    let coins: Int
    
    @State private var starScale: CGFloat = 0.5
    @State private var coinScale: CGFloat = 0.5
    
    var body: some View {
        HStack(spacing: 32) {
            // Stars
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < stars ? "star.fill" : "star")
                            .font(.title)
                            .foregroundColor(index < stars ? .sunshine : .white.opacity(0.3))
                    }
                }
                .scaleEffect(starScale)
                
                Text("+\(stars) Stars")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Divider()
                .frame(height: 60)
                .background(Color.white.opacity(0.3))
            
            // Coins
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.softGreen)
                    
                    Text("+\(coins)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .scaleEffect(coinScale)
                
                Text("Coins")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.sunshine.opacity(0.5), lineWidth: 2)
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                starScale = 1.0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.4)) {
                coinScale = 1.0
            }
        }
    }
}

// MARK: - Pronunciation Breakdown Card

struct PronunciationBreakdownCard: View {
    let targetWord: String
    let result: PronunciationResult
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(.softBlue)
                Text("Pronunciation Analysis")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Transcribed text
            VStack(alignment: .leading, spacing: 8) {
                Text("You said:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(result.transcribedText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Phoneme analysis (if available)
            if !result.phonemeAnalysis.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sound Analysis:")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    ForEach(result.phonemeAnalysis, id: \.phoneme) { phoneme in
                        PhonemeRow(phoneme: phoneme)
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
                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                )
        )
    }
}

struct PhonemeRow: View {
    let phoneme: PhonemeResult
    
    var body: some View {
        HStack {
            Text(phoneme.phoneme)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 50, alignment: .leading)
            
            // Score bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(phoneme.isCorrect ? Color.softGreen : Color.orange)
                        .frame(width: geometry.size.width * CGFloat(phoneme.score))
                }
            }
            .frame(height: 8)
            
            Text("\(Int(phoneme.score * 100))%")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 45, alignment: .trailing)
            
            Image(systemName: phoneme.isCorrect ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(phoneme.isCorrect ? .softGreen : .orange)
        }
    }
}

// MARK: - Feedback Card

struct FeedbackCard: View {
    let feedback: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "quote.bubble.fill")
                .font(.title2)
                .foregroundColor(.lavender)
            
            Text(feedback)
                .font(.body)
                .foregroundColor(.white)
                .lineSpacing(6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.lavender.opacity(0.5), lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Mistakes Card

struct MistakesCard: View {
    let mistakes: [PronunciationMistake]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.sunshine)
                Text("Tips to Improve")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            ForEach(mistakes, id: \.phoneme) { mistake in
                MistakeRow(mistake: mistake)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.sunshine.opacity(0.5), lineWidth: 1.5)
                )
        )
    }
}

struct MistakeRow: View {
    let mistake: PronunciationMistake
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(mistake.phoneme)
                    .font(.headline)
                    .foregroundColor(.white)
                
                severityBadge
                
                Spacer()
            }
            
            Text(mistake.suggestion)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            if let examples = mistake.exampleWords, !examples.isEmpty {
                HStack(spacing: 8) {
                    Text("Practice:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    ForEach(examples.prefix(3), id: \.self) { word in
                        Text(word)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.sunshine)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.sunshine.opacity(0.2))
                            )
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    @ViewBuilder
    var severityBadge: some View {
        let (text, color) = severityInfo
        
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
            )
    }
    
    var severityInfo: (String, Color) {
        switch mistake.severity {
        case .minor: return ("Minor", .softGreen)
        case .moderate: return ("Moderate", .orange)
        case .major: return ("Focus", .red)
        }
    }
}

// MARK: - Confetti View (from previous)

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
        pronunciationResult: PronunciationResult(
            overallScore: 0.92,
            transcribedText: "butterfly",
            phonemeAnalysis: [
                PhonemeResult(phoneme: "/b/", position: 0, score: 0.95, isCorrect: true, expectedSound: "b", actualSound: "b"),
                PhonemeResult(phoneme: "/r/", position: 5, score: 0.88, isCorrect: true, expectedSound: "r", actualSound: "r")
            ],
            mistakes: [],
            feedback: "Excellent pronunciation! Your 'r' sound is getting much better!",
            confidence: 0.94
        ),
        rewardsManager: RewardsManager(),
        onNextWord: {},
        onTryAgain: {}
    )
}
