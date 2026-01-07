//
//  ParentView.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 12/30/25.
//

import SwiftUI

//
//  ParentView.swift
//  ChatterQuest - Enhanced Version
//

import SwiftUI

struct ParentView: View {
    @State private var selectedTab = 0
    @State private var showingAddNote = false
    @State private var notes: [TherapyNote] = TherapyNote.mockNotes
    @State private var weeklyPractice = 4
    @State private var improvingSounds = ["/r/", "/s/", "/th/"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background
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
                        // Header stats cards
                        HStack(spacing: 16) {
                            StatCard(
                                title: "This Week",
                                value: "\(weeklyPractice)",
                                subtitle: "sessions",
                                icon: "calendar",
                                color: .softBlue
                            )
                            
                            StatCard(
                                title: "Improvement",
                                value: "+23%",
                                subtitle: "accuracy",
                                icon: "chart.line.uptrend.xyaxis",
                                color: .softGreen
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Progress chart
                        WeeklyProgressChart()
                            .padding(.horizontal)
                        
                        // Improving sounds
                        ImprovingSoundsCard(sounds: improvingSounds)
                            .padding(.horizontal)
                        
                        // Recent sessions timeline
                        RecentSessionsCard()
                            .padding(.horizontal)
                        
                        // Notes section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "note.text")
                                        .font(.title3)
                                        .foregroundColor(.softBlue)
                                    
                                    Text("Therapy Notes")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.navy)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    showingAddNote = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.softBlue)
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            if notes.isEmpty {
                                EmptyNotesView()
                            } else {
                                ForEach(notes) { note in
                                    NoteCard(note: note, onDelete: {
                                        deleteNote(note)
                                    })
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            ActionButton(
                                title: "Adjust Goals",
                                icon: "target",
                                color: .lavender
                            )
                            
                            ActionButton(
                                title: "Export Progress Report",
                                icon: "square.and.arrow.up",
                                color: .softGreen
                            )
                            
                            ActionButton(
                                title: "Schedule Reminder",
                                icon: "bell.badge",
                                color: .sunshine
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Progress Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddNote) {
                AddNoteView { newNote in
                    notes.insert(newNote, at: 0)
                }
            }
        }
    }
    
    func deleteNote(_ note: TherapyNote) {
        withAnimation {
            notes.removeAll { $0.id == note.id }
        }
    }
}

// MARK: - Components

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.navy)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

struct WeeklyProgressChart: View {
    let weeklyScores: [Double] = [0.65, 0.72, 0.78, 0.82, 0.85, 0.88, 0.92]
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.softBlue)
                Text("Weekly Progress")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.navy)
            }
            
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(weeklyScores.indices, id: \.self) { index in
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottom) {
                            Capsule()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 35, height: 120)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.softBlue,
                                            Color.softBlue.opacity(0.6)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 35, height: CGFloat(weeklyScores[index]) * 120)
                        }
                        
                        Text(days[index])
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.softBlue.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
}

struct ImprovingSoundsCard: View {
    let sounds: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.softGreen)
                Text("Sounds Improving")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.navy)
            }
            
            HStack(spacing: 12) {
                ForEach(sounds, id: \.self) { sound in
                    Text(sound)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.navy)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.softGreen.opacity(0.2),
                                            Color.softGreen.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.softGreen.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
}

struct RecentSessionsCard: View {
    let sessions = [
        Session(date: "Today", time: "2:30 PM", score: 0.92, words: 5),
        Session(date: "Yesterday", time: "3:15 PM", score: 0.88, words: 4),
        Session(date: "Jan 3", time: "4:00 PM", score: 0.85, words: 6)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.lavender)
                Text("Recent Sessions")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.navy)
            }
            
            VStack(spacing: 12) {
                ForEach(sessions) { session in
                    SessionRow(session: session)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.lavender.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
}

struct SessionRow: View {
    let session: Session
    
    var body: some View {
        HStack(spacing: 16) {
            // Date badge
            VStack(spacing: 4) {
                Text(session.date)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(session.time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(width: 80, alignment: .leading)
            
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: session.score)
                    .stroke(
                        Color.softGreen,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(session.score * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.navy)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(session.words) words practiced")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.navy)
                
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(index < getStars(session.score) ? .sunshine : .gray.opacity(0.3))
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    func getStars(_ score: Double) -> Int {
        if score >= 0.90 { return 3 }
        if score >= 0.70 { return 2 }
        return 1
    }
}

struct NoteCard: View {
    let note: TherapyNote
    let onDelete: () -> Void
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(note.category.color)
                            .frame(width: 8, height: 8)
                        
                        Text(note.category.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(note.category.color)
                    }
                    
                    Text(note.title)
                        .font(.headline)
                        .foregroundColor(.navy)
                    
                    Text(note.content)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(showingDetails ? nil : 2)
                }
                
                Spacer()
                
                Menu {
                    Button(action: {}) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            
            HStack {
                Text(note.date)
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showingDetails.toggle()
                    }
                }) {
                    Text(showingDetails ? "Show less" : "Show more")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.softBlue)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(note.category.color.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: note.category.color.opacity(0.1), radius: 5, x: 0, y: 3)
        )
    }
}

struct EmptyNotesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No notes yet")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Tap '+Add' to create your first therapy note")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.gray.opacity(0.1), radius: 5, x: 0, y: 3)
        )
        .padding(.horizontal)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .foregroundColor(.white)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Add Note View

struct AddNoteView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (TherapyNote) -> Void
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedCategory: NoteCategory = .observation
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Note Details")) {
                    TextField("Title", text: $title)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(NoteCategory.allCases, id: \.self) { category in
                            HStack {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 10, height: 10)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section(header: Text("Note Content")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let note = TherapyNote(
                            title: title,
                            content: content,
                            date: formatDate(Date()),
                            category: selectedCategory
                        )
                        onSave(note)
                        dismiss()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Models

struct Session: Identifiable {
    let id = UUID()
    let date: String
    let time: String
    let score: Double
    let words: Int
}

struct TherapyNote: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let date: String
    let category: NoteCategory
    
    static var mockNotes: [TherapyNote] {
        [
            TherapyNote(
                title: "Great progress on /r/ sound",
                content: "Child showed significant improvement with the /r/ sound today. Practiced 'rainbow' and 'rocket' multiple times with 85% accuracy. Continue focusing on initial /r/ positions.",
                date: "Jan 5, 2026",
                category: .observation
            ),
            TherapyNote(
                title: "Focus areas for next week",
                content: "Work on /s/ blends (st, sp, sk). Child struggles slightly with these combinations. Recommend 5-minute daily practice.",
                date: "Jan 4, 2026",
                category: .goal
            ),
            TherapyNote(
                title: "Parent feedback",
                content: "Mom mentioned child is more confident speaking at school. Teachers have noticed improvement in classroom participation.",
                date: "Jan 3, 2026",
                category: .milestone
            )
        ]
    }
}

enum NoteCategory: String, CaseIterable {
    case observation = "Observation"
    case goal = "Goal"
    case milestone = "Milestone"
    case concern = "Concern"
    
    var color: Color {
        switch self {
        case .observation: return .softBlue
        case .goal: return .lavender
        case .milestone: return .softGreen
        case .concern: return .sunshine
        }
    }
}

#Preview {
    ParentView()
}
