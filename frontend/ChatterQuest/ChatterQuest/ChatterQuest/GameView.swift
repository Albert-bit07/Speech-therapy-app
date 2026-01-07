//
//  GameView.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 12/30/25.
//

import SwiftUI
import AVFoundation

struct GameView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isRecording = false
    @State private var showResults = false
    @State private var scale: CGFloat = 1.0
    @State private var recordingPulse = false
    
    let words = ["BUTTERFLY", "RAINBOW", "SUNSHINE", "UNICORN"]
    @State private var currentWord = "BUTTERFLY"
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [Color.lavender, Color.softBlue.opacity(0.6), Color.navy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Close button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Instruction
                Text("Say the word")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Word display with sparkles
                ZStack {
                    // Glow effect
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            RadialGradient(
                                colors: [Color.sunshine.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(height: 150)
                        .blur(radius: 20)
                    
                    VStack(spacing: 12) {
                        AnimatedWordView(word: currentWord)
                        
                        Text(getPhonetic(currentWord))
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                    )
                }
                .padding(.horizontal)
                
                // Audio button
                Button(action: {
                    playWord()
                }) {
                    HStack {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.title2)
                        Text("Hear the word")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.softGreen)
                            .shadow(color: Color.softGreen.opacity(0.5), radius: 10, x: 0, y: 5)
                    )
                }
                .scaleEffect(scale)
                
                // Recording button
                Button(action: {
                    toggleRecording()
                }) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.softBlue)
                            .frame(width: 100, height: 100)
                            .shadow(color: (isRecording ? Color.red : Color.softBlue).opacity(0.6), radius: 20, x: 0, y: 10)
                        
                        if isRecording {
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                .frame(width: 120, height: 120)
                                .scaleEffect(recordingPulse ? 1.2 : 1.0)
                        }
                        
                        VStack(spacing: 4) {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                                .font(.system(size: 32))
                            Text(isRecording ? "Stop" : "Speak")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                    }
                }
                .padding(.vertical, 20)
                
                Spacer()
                
                // Info card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.sunshine)
                        Text("Did you know?")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Text(getInfo(currentWord))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(4)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showResults) {
            ResultsView(
                targetWord: currentWord,
                onNextWord: {
                    currentWord = words.randomElement() ?? "BUTTERFLY"
                    showResults = false
                },
                onTryAgain: {
                    showResults = false
                }
            )
        }
    }
    
    func playWord() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            scale = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                scale = 1.0
            }
        }
        // Add actual audio playback here
    }
    
    func toggleRecording() {
        isRecording.toggle()
        
        if isRecording {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                recordingPulse = true
            }
        } else {
            recordingPulse = false
            // Simulate processing delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showResults = true
            }
        }
    }
    
    func getPhonetic(_ word: String) -> String {
        switch word {
        case "BUTTERFLY": return "but • ter • fly"
        case "RAINBOW": return "rain • bow"
        case "SUNSHINE": return "sun • shine"
        case "UNICORN": return "u • ni • corn"
        default: return ""
        }
    }
    
    func getInfo(_ word: String) -> String {
        switch word {
        case "BUTTERFLY": return "A colorful flying insect with beautiful wings. Butterflies love flowers!"
        case "RAINBOW": return "A beautiful arc of colors that appears in the sky after rain."
        case "SUNSHINE": return "The bright light that comes from the sun on a beautiful day."
        case "UNICORN": return "A magical horse with a horn on its head from fairy tales."
        default: return ""
        }
    }
}

#Preview {
    GameView()
}

