import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var workoutDataManager: WorkoutDataManager
    @StateObject private var timerViewModel = TimerViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
            ZStack {
                AnimatedBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        workoutTypeSelector
                        
                        difficultySelector
                        
                        circularTimer
                        
                        controlButtons
                            .padding(.horizontal)
                        
                        notesSection
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Таймер")
            .alert("Сохранить тренировку?", isPresented: $timerViewModel.showingSaveAlert) {
                Button("Сохранить") {
                    timerViewModel.saveWorkout()
                }
                Button("Отменить", role: .cancel) {
                    timerViewModel.resetTimer()
                }
            } message: {
                Text("Длительность: \(timerViewModel.formattedElapsedTime)")
            }
            .alert("Тренировка завершена! 🎉", isPresented: $timerViewModel.showingCompletionAlert) {
                Button("Сохранить") {
                    timerViewModel.saveWorkout()
                }
                Button("Закрыть", role: .cancel) {
                    timerViewModel.resetTimer()
                }
            } message: {
                Text("Отличная работа! Вы завершили тренировку \(timerViewModel.selectedWorkoutType.rawValue) (\(timerViewModel.selectedDifficulty.rawValue))")
            }
            .onAppear {
                timerViewModel.setDataManager(workoutDataManager)
            }
    }
    
    private var workoutTypeSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Тип тренировки")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(WorkoutType.allCases, id: \.self) { type in
                        WorkoutTypeButton(
                            type: type,
                            isSelected: timerViewModel.selectedWorkoutType == type
                        ) {
                            timerViewModel.selectedWorkoutType = type
                            timerViewModel.updateDuration()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .clipShape(Rectangle())
        }
    }
    
    private var difficultySelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Сложность")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
            
            HStack(spacing: 12) {
                ForEach(WorkoutDifficulty.allCases, id: \.self) { difficulty in
                    DifficultyButton(
                        difficulty: difficulty,
                        workoutType: timerViewModel.selectedWorkoutType,
                        isSelected: timerViewModel.selectedDifficulty == difficulty
                    ) {
                        timerViewModel.selectedDifficulty = difficulty
                        timerViewModel.updateDuration()
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var circularTimer: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 12)
                .frame(width: 280, height: 280)
            
            Circle()
                .trim(from: 0, to: timerViewModel.progress)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "007AFF"), Color(hex: "00C7FF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: timerViewModel.progress)
            
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 220, height: 220)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 10) {
                Text(timerViewModel.selectedWorkoutType.emoji)
                    .font(.system(size: 28))
                
                Text(timerViewModel.formattedTime)
                    .font(.system(size: 38, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                
                if timerViewModel.isRunning || timerViewModel.isPaused {
                    Text("Прошло: \(timerViewModel.formattedElapsedTime)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(timerViewModel.selectedWorkoutType.rawValue)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Text("•")
                    
                    Text("\(timerViewModel.selectedDifficulty.rawValue)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                }
            }
        }
        .padding()
    }
    
    private var controlButtons: some View {
        HStack(spacing: 16) {
            if !timerViewModel.isRunning && !timerViewModel.isPaused {
                Button(action: {
                    timerViewModel.startTimer()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Старт")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "34C759"), Color(hex: "30D158")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "34C759").opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(timerViewModel.isRunning ? 0.95 : 1.0)
                .animation(.spring(response: 0.3), value: timerViewModel.isRunning)
            } else if timerViewModel.isPaused {
                Button(action: {
                    timerViewModel.resumeTimer()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Продолжить")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "34C759"), Color(hex: "30D158")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "34C759").opacity(0.3), radius: 8, x: 0, y: 4)
                }
            } else {
                Button(action: {
                    timerViewModel.pauseTimer()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Пауза")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FF9500"), Color(hex: "FF9F0A")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "FF9500").opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            
            if timerViewModel.isRunning || timerViewModel.isPaused {
                Button(action: {
                    timerViewModel.stopTimer()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Стоп")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FF3B30"), Color(hex: "FF453A")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "FF3B30").opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(Color(hex: "007AFF"))
                    .font(.system(size: 18, weight: .medium))
                
                Text("Заметки")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            TextField("Добавьте заметки о тренировке...", text: $timerViewModel.notes, axis: .vertical)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
                .lineLimit(3...6)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

struct WorkoutTypeButton: View {
    let type: WorkoutType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(type.emoji)
                    .font(.system(size: 24))
                
                Text(type.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 90, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(hex: "007AFF") : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(isSelected ? 0.2 : 0.1), radius: isSelected ? 6 : 3, x: 0, y: isSelected ? 3 : 1)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DifficultyButton: View {
    let difficulty: WorkoutDifficulty
    let workoutType: WorkoutType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text(difficulty.emoji)
                        .font(.system(size: 16))
                    Text(difficulty.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Text(formatDuration(difficulty.duration(for: workoutType)))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "007AFF") : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(isSelected ? 0.15 : 0.05), radius: isSelected ? 4 : 2, x: 0, y: isSelected ? 2 : 1)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)ч"
            } else {
                return "\(hours)ч \(remainingMinutes)м"
            }
        } else {
            return "\(minutes)м"
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)
        }
    }
}

#Preview {
    TimerView()
        .environmentObject(WorkoutDataManager())
} 
