import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var workoutDataManager: WorkoutDataManager
    @State private var showingTimer = false
    let onStartWorkout: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        statisticsSection
                        startWorkoutButton
                        recentWorkoutsSection
                    }
                    .padding()
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("SportTimer")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Привет!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Готов к тренировке?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "figure.run")
                    .font(.title)
                    .foregroundColor(Color(hex: "007AFF"))
            }
        }
        .padding()
        .background(Color(hex: "F2F2F7"))
        .cornerRadius(12)
    }
    
    private var statisticsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Тренировок",
                value: "\(workoutDataManager.workouts.count)",
                icon: "figure.strengthtraining.traditional",
                color: Color(hex: "34C759")
            )
            
            StatCard(
                title: "Общее время",
                value: formatTotalDuration(workoutDataManager.workouts.reduce(0) { $0 + $1.duration }),
                icon: "clock",
                color: Color(hex: "FF9500")
            )
        }
    }
    
    private var startWorkoutButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                showingTimer = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showingTimer = false
                onStartWorkout()
            }
        }) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                
                Text("Начать тренировку")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.title3)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(hex: "007AFF"))
            .cornerRadius(12)
            .scaleEffect(showingTimer ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: showingTimer)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Последние тренировки")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !workoutDataManager.workouts.isEmpty {
                    NavigationLink(destination: HistoryView()) {
                        Text("Все")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "007AFF"))
                    }
                }
            }
            
            if workoutDataManager.workouts.isEmpty {
                EmptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: "Нет тренировок",
                    subtitle: "Начните первую тренировку!"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(recentWorkouts, id: \.id) { workout in
                        WorkoutMiniCard(workout: workout)
                    }
                }
            }
        }
    }
    
    private var recentWorkouts: [WorkoutModel] {
        workoutDataManager.workouts.sorted { $0.date > $1.date }.prefix(3).map { $0 }
    }
    
    private func formatTotalDuration(_ duration: Int) -> String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        
        if hours > 0 {
            return "\(hours)ч \(minutes)м"
        } else {
            return "\(minutes)м"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct WorkoutMiniCard: View {
    let workout: WorkoutModel
    
    var body: some View {
        HStack(spacing: 12) {
            Text(workoutTypeEmoji)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.type)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formattedDuration)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "007AFF"))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
    
    private var workoutTypeEmoji: String {
        let baseType = extractWorkoutType(from: workout.type)
        switch baseType {
        case "Силовая тренировка": return "💪"
        case "Кардио": return "🏃"
        case "Йога": return "🧘"
        case "Растяжка": return "🤸"
        default: return "🏋️"
        }
    }
    
    private func extractWorkoutType(from fullType: String) -> String {
        if let openParenIndex = fullType.firstIndex(of: "(") {
            return String(fullType[..<openParenIndex]).trimmingCharacters(in: .whitespaces)
        }
        return fullType
    }
    
    private var formattedDuration: String {
        let duration = workout.duration
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        
        if hours > 0 {
            return "\(hours)ч \(minutes)м"
        } else {
            return "\(minutes)м"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: workout.date)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    HomeView(onStartWorkout: {})
        .environmentObject(WorkoutDataManager())
}
