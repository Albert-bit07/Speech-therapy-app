import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName = "Bright Star"
    @AppStorage("soundEnabled") private var soundEnabled = true
    @State private var showingNameEditor = false
    @State private var tempName = ""

    var body: some View {
        Form {
            Section("Profile") {
                ProfileCard(userName: userName, onEditName: {
                    tempName = userName
                    showingNameEditor = true
                })
            }
            Section("Practice audio") {
                Toggle("Play word hints", isOn: $soundEnabled)
                Text("Controls Hear Word playback. Recording still requires microphone permission. Word hints and exercises currently use English.")
                    .font(.caption)
            }
            Section("Data and access") {
                Text("This prototype has no account login or parental access lock. Anyone using this installation can view its local notes and progress.")
                Text("Recordings are sent to the configured analysis backend. Temporary recording files are removed after analysis or leaving the game; this is not a secure-erasure guarantee.")
                Text("Notes and game rewards stay on this device. Accepted practice attempts are queued locally and sent to the backend for progress storage. There is no multi-device recovery or automatic retention policy.")
            }
            Section("Prototype scope") {
                Text("Pronunciation assessment is unavailable until a validated scoring method is implemented. The separate recognition diagnostic does not assess pronunciation.")
                Text("Reminders, custom voices, theme controls, parental controls and multilingual practice are not implemented.")
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingNameEditor) {
            NameEditorView(name: $tempName, onSave: {
                userName = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                showingNameEditor = false
            })
        }
    }
}

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


#Preview {
    SettingsView()
}
