//
//  GameView_Battle.swift
//  ChatterQuest
//
//  GameView with Monster Battle System
//

import SwiftUI
import AVFoundation

struct GameView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var rewardsManager: RewardsManager
    @StateObject private var battleState = BattleState()
    
    @State private var isRecording = false
    @State private var showResults = false
    @State private var scale: CGFloat = 1.0
    @State private var recordingPulse = false
    @State private var isProcessing = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordedAudioURL: URL?
    @State private var pronunciationResult: PronunciationResult?
    
    // Exercise data
    @State private var currentExercise: Exercise?
    @State private var exercises: [Exercise] = []
    @State private var currentExerciseIndex = 0
    @State private var sessionStartTime = Date()
    @State private var attemptNumber = 1
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [Color.purple.opacity(0.8), Color.navy, Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Battle stars background
            BattleStarsBackground()
            
            if isProcessing {
                ProcessingView()
            } else if let exercise = currentExercise {
                battleContent(exercise: exercise)
            } else {
                loadingView
            }
        }
        .task {
            await loadExercises()
        }
        .sheet(isPresented: $showResults) {
            if let result = pronunciationResult, let exercise = currentExercise {
                BattleResultsView(
                    targetWord: exercise.word,
                    pronunciationResult: result,
                    battleState: battleState,
                    rewardsManager: rewardsManager,
                    onNextBattle: {
                        moveToNextExercise()
                    },
                    onRetry: {
                        showResults = false
                        attemptNumber += 1
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    func battleContent(exercise: Exercise) -> some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Battle counter
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Battle \(currentExerciseIndex + 1)/\(exercises.count)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                )
            }
            .padding()
            
            Spacer()
            
            // Combo display
            if battleState.comboCount > 1 {
                ComboDisplay(combo: battleState.comboCount)
                    .padding(.bottom, 10)
            }
            
            // Monster
            ZStack {
                MonsterView(
                    monster: battleState.currentMonster,
                    health: battleState.monsterHealth
                )
                
                // Damage display
                if battleState.showDamage {
                    DamageDisplay(
                        damage: battleState.damageDealt,
                        isCritical: battleState.damageDealt >= 45
                    )
                    .offset(y: -50)
                }
            }
            .padding(.vertical, 20)
            
            Spacer()
            
            // Battle instruction
            Text("Defeat the monster!")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.bottom, 8)
            
            // Word display
            VStack(spacing: 12) {
                Text("Say:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(exercise.word)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                
                Text(exercise.phonetic)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
            )
            .padding(.horizontal)
            
            Spacer()
            
            // Audio hint button
            Button(action: playWord) {
                HStack {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.title3)
                    Text("Hear Word")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.softGreen)
                        .shadow(color: Color.softGreen.opacity(0.5), radius: 10)
                )
            }
            .scaleEffect(scale)
            .padding(.bottom, 20)
            
            // Attack button (microphone)
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                ZStack {
                    // Outer pulse ring
                    if isRecording {
                        Circle()
                            .stroke(Color.red.opacity(0.5), lineWidth: 4)
                            .frame(width: 140, height: 140)
                            .scaleEffect(recordingPulse ? 1.3 : 1.0)
                    }
                    
                    // Main button
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isRecording ? [.red, .red.opacity(0.7)] : [.softBlue, .lavender],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .shadow(
                            color: (isRecording ? Color.red : Color.softBlue).opacity(0.6),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                    
                    VStack(spacing: 8) {
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 40))
                        
                        Text(isRecording ? "STOP" : "ATTACK!")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                }
            }
            .disabled(isProcessing || battleState.isMonsterDefeated)
            .padding(.bottom, 20)
            
            // Player health
            PlayerHealthView(health: battleState.playerHealth)
                .padding(.horizontal)
                .padding(.bottom, 30)
        }
    }
    
    var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Preparing battle...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Audio Recording
    
    func startRecording() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                DispatchQueue.main.async {
                    self.setupRecording()
                }
            }
        }
    }
    
    func setupRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording_\(UUID().uuidString).wav")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            recordedAudioURL = audioFilename
            isRecording = true
            
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                recordingPulse = true
            }
            
        } catch {
            print("Failed to set up recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        recordingPulse = false
        
        if let audioURL = recordedAudioURL {
            Task {
                await processRecording(audioURL: audioURL)
            }
        }
    }
    
    func processRecording(audioURL: URL) async {
        guard let exercise = currentExercise else { return }
        
        isProcessing = true
        
        do {
            let audioData = try Data(contentsOf: audioURL)
            
            // Use mock API for development
            let result = await MockAPIService.shared.mockAnalyzePronunciation(
                targetWord: exercise.word
            )
            
            // Apply damage to monster
            battleState.attack(accuracy: result.overallScore)
            
            // Calculate rewards
            let rewardResult = rewardsManager.calculateRewards(
                accuracy: result.overallScore,
                wordDifficulty: exercise.difficulty
            )
            
            pronunciationResult = result
            isProcessing = false
            
            // Check if monster is defeated
            if battleState.isMonsterDefeated {
                // Award rewards
                rewardsManager.awardRewards(rewardResult)
                rewardsManager.saveToUserDefaults()
                
                // Show victory screen
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showResults = true
                }
            }
            
        } catch {
            print("Error processing recording: \(error)")
            isProcessing = false
        }
    }
    
    // MARK: - Exercise Management
    
    func loadExercises() async {
        exercises = await MockAPIService.shared.mockGetAdaptiveExercises(count: 5)
        
        if !exercises.isEmpty {
            currentExercise = exercises[0]
            battleState.startBattle(word: exercises[0].word)
        }
    }
    
    func moveToNextExercise() {
        showResults = false
        attemptNumber = 1
        sessionStartTime = Date()
        
        if currentExerciseIndex < exercises.count - 1 {
            currentExerciseIndex += 1
            currentExercise = exercises[currentExerciseIndex]
            battleState.startBattle(word: exercises[currentExerciseIndex].word)
        } else {
            // All battles completed
            dismiss()
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
        
        // TODO: Add actual TTS
    }
}

// MARK: - Battle Stars Background

struct BattleStarsBackground: View {
    @State private var stars: [BattleStar] = []
    
    struct BattleStar: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white.opacity(star.opacity))
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x, y: star.y)
                        .blur(radius: 1)
                }
            }
            .onAppear {
                generateStars(in: geometry.size)
                animateStars()
            }
        }
    }
    
    func generateStars(in size: CGSize) {
        stars = (0..<30).map { _ in
            BattleStar(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.3...0.8)
            )
        }
    }
    
    func animateStars() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
            for i in stars.indices {
                stars[i].opacity = Double.random(in: 0.3...0.8)
            }
        }
    }
}

// MARK: - Processing View

struct ProcessingView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [.softBlue, .lavender],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(rotation))
                }
                
                VStack(spacing: 8) {
                    Text("Calculating Damage...")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Analyzing your attack")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.navy.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.softBlue, lineWidth: 2)
                    )
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

#Preview {
    GameView(rewardsManager: RewardsManager())  
}
