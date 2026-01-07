//
//  SettingsView.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 12/30/25.
//
//
//  SettingsView.swift
//  ChatterQuest
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName = "Bright Star"
    @AppStorage("selectedLanguage") private var selectedLanguage = "English"
    @AppStorage("colorScheme") private var colorScheme = "auto"
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("voiceGender") private var voiceGender = "neutral"
    @AppStorage("difficulty") private var difficulty = "medium"
    @AppStorage("sessionLength") private var sessionLength = 10
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("parentalControls") private var parentalControls = false
    
    @State private var showingNameEditor = false
    @State private var tempName = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Cloud-themed background
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.90, green: 0.94, blue: 0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Profile Section
                        ProfileCard(
                            userName: userName,
                            onEditName: {
                                tempName = userName
                                showingNameEditor = true
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Appearance Settings
                        SettingsCard(title: "Appearance", icon: "paintbrush.fill", color: .lavender) {
                            VStack(spacing: 16) {
                                // Theme selector
                                SettingRow(
                                    icon: "moon.stars.fill",
                                    title: "Theme",
                                    color: .lavender
                                ) {
                                    Picker("Theme", selection: $colorScheme) {
                                        Label("Auto", systemImage: "circle.lefthalf.filled")
                                            .tag("auto")
                                        Label("Light", systemImage: "sun.max.fill")
                                            .tag("light")
                                        Label("Dark", systemImage: "moon.fill")
                                            .tag("dark")
                                    }
                                    .pickerStyle(.menu)
                                }
                                
                                Divider()
                                    .padding(.horizontal, -16)
                                
                                // Character display preference
                                SettingRow(
                                    icon: "sparkles",
                                    title: "Show Animations",
                                    color: .lavender
                                ) {
                                    Toggle("", isOn: .constant(true))
                                        .labelsHidden()
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Language & Voice
                        SettingsCard(title: "Language & Voice", icon: "globe", color: .softBlue) {
                            VStack(spacing: 16) {
                                SettingRow(
                                    icon: "globe",
                                    title: "Language",
                                    color: .softBlue
                                ) {
                                    Picker("Language", selection: $selectedLanguage) {
                                        Text("🇺🇸 English").tag("English")
                                        Text("🇪🇸 Spanish").tag("Spanish")
                                        Text("🇫🇷 French").tag("French")
                                        Text("🇩🇪 German").tag("German")
                                        Text("🇨🇳 Chinese").tag("Chinese")
                                    }
                                    .pickerStyle(.menu)
                                }
                                
                                Divider()
                                    .padding(.horizontal, -16)
                                
                                SettingRow(
                                    icon: "person.wave.2.fill",
                                    title: "Voice Type",
                                    color: .softBlue
                                ) {
                                    Picker("Voice", selection: $voiceGender) {
                                        Text("Neutral").tag("neutral")
                                        Text("Female").tag("female")
                                        Text("Male").tag("male")
                                        Text("Child").tag("child")
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Game Settings
                        SettingsCard(title: "Game Settings", icon: "gamecontroller.fill", color: .softGreen) {
                            VStack(spacing: 16) {
                                SettingRow(
                                    icon: "gauge.with.dots.needle.67percent",
                                    title: "Difficulty",
                                    color: .softGreen
                                ) {
                                    Picker("Difficulty", selection: $difficulty) {
                                        Text("Easy 🌱").tag("easy")
                                        Text("Medium 🌟").tag("medium")
                                        Text("Hard 🚀").tag("hard")
                                    }
                                    .pickerStyle(.menu)
                                }
                                
                                Divider()
                                    .padding(.horizontal, -16)
                                
                                SettingRow(
                                    icon: "clock.fill",
                                    title: "Session Length",
                                    color: .softGreen
                                ) {
                                    Picker("Length", selection: $sessionLength) {
                                        Text("5 min").tag(5)
                                        Text("10 min").tag(10)
                                        Text("15 min").tag(15)
                                        Text("20 min").tag(20)
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Sound & Haptics
                        SettingsCard(title: "Sound & Haptics", icon: "speaker.wave.3.fill", color: .sunshine) {
                            VStack(spacing: 16) {
                                SettingRow(
                                    icon: "speaker.wave.2.fill",
                                    title: "Sound Effects",
                                    color: .sunshine
                                ) {
                                    Toggle("", isOn: $soundEnabled)
                                        .labelsHidden()
                                }
                                
                                Divider()
                                    .padding(.horizontal, -16)
                                
                                SettingRow(
                                    icon: "hand.tap.fill",
                                    title: "Haptic Feedback",
                                    color: .sunshine
                                ) {
                                    Toggle("", isOn: $hapticEnabled)
                                        .labelsHidden()
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Notifications & Reminders
                        SettingsCard(title: "Notifications", icon: "bell.fill", color: .pink) {
                            VStack(spacing: 16) {
                                SettingRow(
                                    icon: "bell.badge.fill",
                                    title: "Daily Reminder",
                                    color: .pink
                                ) {
                                    Toggle("", isOn: $reminderEnabled)
                                        .labelsHidden()
                                }
                                
                                if reminderEnabled {
                                    Divider()
                                        .padding(.horizontal, -16)
                                    
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(.pink)
                                            .frame(width: 24)
                                        
                                        Text("Reminder Time")
                                            .foregroundColor(.navy)
                                        
                                        Spacer()
                                        
                                        Text("4:00 PM")
                                            .foregroundColor(.gray)
                                            .font(.subheadline)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Privacy & Safety
                        SettingsCard(title: "Privacy & Safety", icon: "lock.shield.fill", color: .orange) {
                            VStack(spacing: 16) {
                                SettingRow(
                                    icon: "hand.raised.fill",
                                    title: "Parental Controls",
                                    color: .orange
                                ) {
                                    Toggle("", isOn: $parentalControls)
                                        .labelsHidden()
                                }
                                
                                Divider()
                                    .padding(.horizontal, -16)
                                
                                NavigationLink(destination: Text("Privacy Policy")) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .foregroundColor(.orange)
                                            .frame(width: 24)
                                        
                                        Text("Privacy Policy")
                                            .foregroundColor(.navy)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // About Section
                        SettingsCard(title: "About", icon: "info.circle.fill", color: .gray) {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "app.badge.fill")
                                        .foregroundColor(.gray)
                                        .frame(width: 24)
                                    
                                    Text("Version")
                                        .foregroundColor(.navy)
                                    
                                    Spacer()
                                    
                                    Text("1.0.0")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                }
                                
                                Divider()
                                    .padding(.horizontal, -16)
                                
                                NavigationLink(destination: Text("Terms of Service")) {
                                    HStack {
                                        Image(systemName: "doc.plaintext.fill")
                                            .foregroundColor(.gray)
                                            .frame(width: 24)
                                        
                                        Text("Terms of Service")
                                            .foregroundColor(.navy)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                }
                                
                                Divider()
                                    .padding(.horizontal, -16)
                                
                                Button(action: {}) {
                                    HStack {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.red)
                                            .frame(width: 24)
                                        
                                        Text("Rate ChatterQuest")
                                            .foregroundColor(.navy)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Sign Out Button
                        Button(action: {}) {
                            Text("Sign Out")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: Color.red.opacity(0.2), radius: 5, x: 0, y: 3)
                                )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingNameEditor) {
                NameEditorView(
                    name: $tempName,
                    onSave: {
                        userName = tempName
                        showingNameEditor = false
                    }
                )
            }
        }
    }
}

// MARK: - Components

struct ProfileCard: View {
    let userName: String
    let onEditName: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar with cloud background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.softBlue.opacity(0.3), Color.lavender.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(String(userName.prefix(1).uppercased()))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.softBlue)
            }
            
            VStack(spacing: 8) {
                Text(userName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.navy)
                
                Button(action: onEditName) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.caption)
                        Text("Edit Name")
                            .font(.subheadline)
                    }
                    .foregroundColor(.softBlue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.softBlue.opacity(0.15))
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.softBlue.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.navy)
            }
            
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
}

struct SettingRow<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    let content: Content
    
    init(
        icon: String,
        title: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.navy)
            
            Spacer()
            
            content
        }
    }
}

struct NameEditorView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var name: String
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.95, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("What should we call you?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.navy)
                        .padding(.top, 40)
                    
                    TextField("Enter your name", text: $name)
                        .font(.title3)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.softBlue.opacity(0.2), radius: 5, x: 0, y: 3)
                        )
                        .padding(.horizontal)
                    
                    Text("This name will appear on your dashboard")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
            }
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// Extensions for new colors
extension Color {
    static let pink = Color(red: 1.0, green: 0.75, blue: 0.80)
    static let orange = Color(red: 1.0, green: 0.65, blue: 0.30)
}

#Preview {
    SettingsView()
}
