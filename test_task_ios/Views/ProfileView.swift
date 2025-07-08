import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var workoutDataManager: WorkoutDataManager
    @State private var showingClearDataAlert = false
    @State private var showingImagePicker = false
    @State private var profileImage: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        profileHeader
                        statisticsSection
                        workoutTypesSection
                        settingsSection
                    }
                    .padding(.bottom, 80)
                    .padding()
                }
            }
            .navigationTitle("Профиль")
            
            .alert("Очистить все данные?", isPresented: $showingClearDataAlert) {
                Button("Очистить", role: .destructive) {
                    workoutDataManager.clearAllWorkouts()
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("Это действие удалит все ваши тренировки. Отменить это действие будет невозможно.")
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $profileImage)
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            Button(action: {
                showingImagePicker = true
            }) {
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(Color(hex: "007AFF"))
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            
            VStack(spacing: 4) {
                Text("Спортсмен")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Продолжайте тренироваться!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(hex: "F2F2F7"))
        .cornerRadius(16)
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Статистика")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                StatisticRow(
                    icon: "figure.strengthtraining.traditional",
                    title: "Всего тренировок",
                    value: "\(workoutDataManager.workouts.count)",
                    color: Color(hex: "34C759")
                )
                
                StatisticRow(
                    icon: "clock",
                    title: "Общее время",
                    value: formatTotalDuration(workoutDataManager.workouts.reduce(0) { $0 + $1.duration }),
                    color: Color(hex: "FF9500")
                )
                
                StatisticRow(
                    icon: "chart.bar",
                    title: "Средняя тренировка",
                    value: formatAverageDuration(),
                    color: Color(hex: "007AFF")
                )
                
                StatisticRow(
                    icon: "calendar",
                    title: "Дней с тренировками",
                    value: "\(uniqueWorkoutDays)",
                    color: Color(hex: "FF3B30")
                )
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var workoutTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Тренировки по типам")
                .font(.headline)
                .fontWeight(.semibold)
            
            if workoutDataManager.workouts.count > 0 {
                VStack(spacing: 8) {
                    ForEach(Array(workoutsByType().sorted(by: { $0.value > $1.value })), id: \.key) { type, count in
                        WorkoutTypeRow(type: type, count: count, total: workoutDataManager.workouts.count)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            } else {
                EmptyStateView(
                    icon: "chart.pie",
                    title: "Нет данных",
                    subtitle: "Начните тренироваться для отображения статистики"
                )
            }
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Настройки")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "speaker.wave.2",
                    title: "Звуки таймера",
                    subtitle: "Включить звуковые уведомления",
                    action: { }
                )
                
                Divider()
                    .padding(.leading, 44)
                
                SettingsRow(
                    icon: "trash",
                    title: "Очистить данные",
                    subtitle: "Удалить все тренировки",
                    isDestructive: true,
                    action: {
                        showingClearDataAlert = true
                    }
                )
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
        
    private var uniqueWorkoutDays: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(workoutDataManager.workouts.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
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
    
    private func formatAverageDuration() -> String {
        guard workoutDataManager.workouts.count > 0 else { return "0м" }
        let average = workoutDataManager.workouts.reduce(0) { $0 + $1.duration } / workoutDataManager.workouts.count
        return formatTotalDuration(average)
    }
    
    private func workoutsByType() -> [String: Int] {
        var result: [String: Int] = [:]
        for workout in workoutDataManager.workouts {
            let baseType = extractWorkoutType(from: workout.type)
            result[baseType, default: 0] += 1
        }
        return result
    }
    
    private func extractWorkoutType(from fullType: String) -> String {
        if let openParenIndex = fullType.firstIndex(of: "(") {
            return String(fullType[..<openParenIndex]).trimmingCharacters(in: .whitespaces)
        }
        return fullType
    }
}

struct StatisticRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
    }
}

struct WorkoutTypeRow: View {
    let type: String
    let count: Int
    let total: Int
    
    var percentage: Double {
        Double(count) / Double(total)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(workoutTypeEmoji)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(type)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "007AFF"))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(Color(hex: "007AFF"))
                            .frame(width: geometry.size.width * percentage, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
            }
        }
    }
    
    private var workoutTypeEmoji: String {
        let baseType = extractWorkoutType(from: type)
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
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDestructive ? Color(hex: "FF3B30") : Color(hex: "007AFF"))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? Color(hex: "FF3B30") : .primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !isDestructive {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(WorkoutDataManager())
}
