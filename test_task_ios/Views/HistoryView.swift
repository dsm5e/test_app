import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var workoutDataManager: WorkoutDataManager
    @State private var searchText = ""
    @State private var selectedFilterType: String = "Все"
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: WorkoutModel?
    
    var filteredWorkouts: [WorkoutModel] {
        var workouts = workoutDataManager.workouts.sorted { $0.date > $1.date }
        
        if selectedFilterType != "Все" {
            workouts = workouts.filter { workout in
                extractWorkoutType(from: workout.type) == selectedFilterType
            }
        }
        
        if !searchText.isEmpty {
            workouts = workouts.filter { workout in
                workout.type.localizedCaseInsensitiveContains(searchText) ||
                (workout.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return workouts
    }
    
    private func extractWorkoutType(from fullType: String) -> String {
        if let openParenIndex = fullType.firstIndex(of: "(") {
            return String(fullType[..<openParenIndex]).trimmingCharacters(in: .whitespaces)
        }
        return fullType
    }
    
    var groupedWorkouts: [(String, [WorkoutModel])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredWorkouts) { workout in
            calendar.startOfDay(for: workout.date)
        }
        
        return grouped.map { (date, workouts) in
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.locale = Locale(identifier: "ru_RU")
            
            let dateString: String
            if calendar.isDateInToday(date) {
                dateString = "Сегодня"
            } else if calendar.isDateInYesterday(date) {
                dateString = "Вчера"
            } else {
                dateString = formatter.string(from: date)
            }
            
            return (dateString, workouts.sorted { $0.date > $1.date })
        }.sorted { first, second in
            let firstDate = grouped.keys.first { date in
                let formatter = DateFormatter()
                formatter.dateStyle = .full
                formatter.locale = Locale(identifier: "ru_RU")
                return formatter.string(from: date) == first.0 || first.0 == "Сегодня" || first.0 == "Вчера"
            } ?? Date.distantPast
            
            let secondDate = grouped.keys.first { date in
                let formatter = DateFormatter()
                formatter.dateStyle = .full
                formatter.locale = Locale(identifier: "ru_RU")
                return formatter.string(from: date) == second.0 || second.0 == "Сегодня" || second.0 == "Вчера"
            } ?? Date.distantPast
            
            return firstDate > secondDate
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackground()
                
                VStack(spacing: 0) {
                searchAndFilterSection
                
                if filteredWorkouts.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: searchText.isEmpty ? "Нет тренировок" : "Ничего не найдено",
                        subtitle: searchText.isEmpty ? "Начните первую тренировку!" : "Попробуйте изменить поисковый запрос"
                    )
                    Spacer()
                } else {
                    workoutsList
                }
                }
            }
            .navigationTitle("История")
            .alert("Удалить тренировку?", isPresented: $showingDeleteAlert) {
                Button("Удалить", role: .destructive) {
                    if let workout = workoutToDelete {
                        workoutDataManager.deleteWorkout(workout)
                    }
                }
                Button("Отмена", role: .cancel) { }
            }
        }
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Поиск по типу или заметкам", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Очистить") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: "007AFF"))
                }
            }
            .padding()
            .background(Color(hex: "F2F2F7"))
            .cornerRadius(10)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterButton(
                        title: "Все",
                        isSelected: selectedFilterType == "Все"
                    ) {
                        selectedFilterType = "Все"
                    }
                    
                    ForEach(WorkoutType.allCases, id: \.self) { type in
                        FilterButton(
                            title: type.rawValue,
                            isSelected: selectedFilterType == type.rawValue
                        ) {
                            selectedFilterType = type.rawValue
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
    
    private var workoutsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groupedWorkouts, id: \.0) { dateString, workouts in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(dateString)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("\(workouts.count) тренировок")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        ForEach(workouts, id: \.id) { workout in
                            WorkoutCard(workout: workout) {
                                workoutToDelete = workout
                                showingDeleteAlert = true
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "007AFF") : Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct WorkoutCard: View {
    let workout: WorkoutModel
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(workoutTypeEmoji)
                    .font(.system(size: 20))
                
                Text(formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(workout.type)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(formattedDuration)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "007AFF"))
                }
                
                if let notes = workout.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Удалить", role: .destructive, action: onDelete)
        }
        .padding(.horizontal)
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
        formatter.timeStyle = .short
        return formatter.string(from: workout.date)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: workout.date)
    }
}

#Preview {
    HistoryView()
        .environmentObject(WorkoutDataManager())
} 