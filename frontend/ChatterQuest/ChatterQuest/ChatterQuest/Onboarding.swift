//
//  Onboarding.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 1/6/26.
//

//
//  OnboardingView.swift
//  ChatterQuest
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("selectedLanguage") private var selectedLanguage = "English"
    
    @State private var currentPage = 0
    @State private var tempName = ""
    @State private var tempLanguage = "English"
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.52, green: 0.80, blue: 0.98),
                    Color(red: 0.90, green: 0.94, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating elements
            FloatingElements()
            
            TabView(selection: $currentPage) {
                // Welcome Page
                WelcomePage()
                    .tag(0)
                
                // Name Entry Page
                NameEntryPage(name: $tempName)
                    .tag(1)
                
                // Language Selection Page
                LanguageSelectionPage(language: $tempLanguage)
                    .tag(2)
                
                // Ready Page
                ReadyPage(
                    name: tempName,
                    onStart: {
                        userName = tempName
                        selectedLanguage = tempLanguage
                        hasCompletedOnboarding = true
                    }
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

// MARK: - Welcome Page

struct WelcomePage: View {
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("🦋")
                    .font(.system(size: 100))
                    .scaleEffect(scale)
                
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.navy.opacity(0.8))
                
                Text("ChatterQuest")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.softBlue, Color.lavender],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Your magical journey to\nclear speech begins here!")
                    .font(.title3)
                    .foregroundColor(.navy.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Text("Swipe to continue")
                    .font(.subheadline)
                    .foregroundColor(.softBlue)
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.softBlue)
            }
            .padding(.bottom, 60)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).repeatForever()) {
                scale = 1.0
            }
        }
    }
}

// MARK: - Name Entry Page

struct NameEntryPage: View {
    @Binding var name: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("👋")
                    .font(.system(size: 80))
                    .rotationEffect(.degrees(isAnimating ? 20 : -20))
                
                Text("What's your name?")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.navy)
                    .multilineTextAlignment(.center)
                
                Text("We'll use this to cheer you on!")
                    .font(.title3)
                    .foregroundColor(.navy.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                TextField("Enter your name", text: $name)
                    .font(.title2)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.softBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 30)
                
                if name.count >= 2 {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.softGreen)
                        Text("Looks great!")
                            .foregroundColor(.softGreen)
                            .fontWeight(.semibold)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            Spacer()
            
            if name.count >= 2 {
                VStack(spacing: 16) {
                    Text("Swipe to continue")
                        .font(.subheadline)
                        .foregroundColor(.softBlue)
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.softBlue)
                }
                .padding(.bottom, 60)
                .transition(.opacity)
            } else {
                Spacer()
                    .frame(height: 100)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Language Selection Page

struct LanguageSelectionPage: View {
    @Binding var language: String
    
    let languages = [
        ("🇺🇸", "English"),
        ("🇪🇸", "Spanish"),
        ("🇫🇷", "French"),
        ("🇩🇪", "German"),
        ("🇨🇳", "Chinese")
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("🌍")
                    .font(.system(size: 80))
                
                Text("Choose your language")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.navy)
                    .multilineTextAlignment(.center)
                
                Text("We'll speak in your language!")
                    .font(.title3)
                    .foregroundColor(.navy.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                ForEach(languages, id: \.1) { flag, lang in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            language = lang
                        }
                    }) {
                        HStack(spacing: 16) {
                            Text(flag)
                                .font(.system(size: 32))
                            
                            Text(lang)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.navy)
                            
                            Spacer()
                            
                            if language == lang {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.softGreen)
                                    .font(.title2)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(language == lang ? Color.softBlue.opacity(0.2) : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            language == lang ? Color.softBlue : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: Color.softBlue.opacity(0.2), radius: 5, x: 0, y: 3)
                        )
                    }
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            VStack(spacing: 16) {
                Text("Swipe to continue")
                    .font(.subheadline)
                    .foregroundColor(.softBlue)
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.softBlue)
            }
            .padding(.bottom, 60)
        }
    }
}

// MARK: - Ready Page

struct ReadyPage: View {
    let name: String
    let onStart: () -> Void
    
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            if showConfetti {
                ConfettiView()
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 24) {
                    Text("🎉")
                        .font(.system(size: 100))
                    
                    Text("Ready, \(name)!")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.navy)
                        .multilineTextAlignment(.center)
                    
                    Text("Let's start your\namazing speech journey!")
                        .font(.title2)
                        .foregroundColor(.navy.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 20) {
                    InfoRow(icon: "star.fill", text: "Earn stars and badges", color: .sunshine)
                    InfoRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress", color: .softGreen)
                    InfoRow(icon: "speaker.wave.3.fill", text: "Practice fun words", color: .softBlue)
                    InfoRow(icon: "face.smiling.fill", text: "Have fun learning!", color: .lavender)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: onStart) {
                    HStack(spacing: 12) {
                        Text("Start My Journey")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("🚀")
                            .font(.title)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                LinearGradient(
                                    colors: [Color.softBlue, Color.lavender],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.softBlue.opacity(0.5), radius: 15, x: 0, y: 10)
                    )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showConfetti = true
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(text)
                .font(.headline)
                .foregroundColor(.navy)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
        )
    }
}

// MARK: - Floating Elements

struct FloatingElements: View {
    @State private var positions: [(x: CGFloat, y: CGFloat)] = []
    
    let emojis = ["⭐️", "🌈", "🦋", "✨", "🌸", "🎈"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(emojis.indices, id: \.self) { index in
                    Text(emojis[index])
                        .font(.system(size: 30))
                        .opacity(0.3)
                        .position(
                            x: positions.count > index ? positions[index].x : 0,
                            y: positions.count > index ? positions[index].y : 0
                        )
                }
            }
            .onAppear {
                generatePositions(in: geometry.size)
                animateElements()
            }
        }
    }
    
    func generatePositions(in size: CGSize) {
        positions = (0..<6).map { _ in
            (
                x: CGFloat.random(in: 50...size.width - 50),
                y: CGFloat.random(in: 100...size.height - 100)
            )
        }
    }
    
    func animateElements() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 3)) {
                for i in positions.indices {
                    positions[i].x += CGFloat.random(in: -50...50)
                    positions[i].y += CGFloat.random(in: -30...30)
                }
            }
        }
    }
}


#Preview {
    OnboardingView()
}
