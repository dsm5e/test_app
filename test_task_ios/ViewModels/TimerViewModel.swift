import Foundation
import SwiftUI
import Combine
import UserNotifications

final class TimerViewModel: ObservableObject {
    @Published var timeRemaining: Int = 600
    @Published var timeElapsed: Int = 0
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var selectedWorkoutType: WorkoutType = .cardio
    @Published var selectedDifficulty: WorkoutDifficulty = .medium
    @Published var notes: String = ""
    @Published var showingSaveAlert: Bool = false
    @Published var showingCompletionAlert: Bool = false
    
    private var timer: Timer?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var dataManager: WorkoutDataManager?
    private var totalDuration: Int = 0
    private var backgroundEntryTime: Date?
    
    init() {
        setupNotifications()
        updateDuration()
        setupAppStateObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
        endBackgroundTask()
        cancelScheduledNotifications()
    }
    
    func setDataManager(_ dataManager: WorkoutDataManager) {
        self.dataManager = dataManager
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    private func setupAppStateObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleAppWillEnterForeground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleAppDidEnterBackground()
        }
    }
    
    private func scheduleCompletionNotification() {
        cancelScheduledNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = "Тренировка завершена! 🎉"
        content.body = "Отличная работа! Тренировка \(selectedWorkoutType.rawValue) (\(selectedDifficulty.rawValue)) завершена."
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_COMPLETION"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timeRemaining), repeats: false)
        let request = UNNotificationRequest(identifier: "workout-complete-scheduled", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Ошибка планирования уведомления: \(error)")
            }
        }
    }
    
    private func cancelScheduledNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["workout-complete-scheduled"])
    }
    
    private func sendCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Тренировка завершена! 🎉"
        content.body = "Отличная работа! Тренировка \(selectedWorkoutType.rawValue) (\(selectedDifficulty.rawValue)) завершена."
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_COMPLETION"
        
        let request = UNNotificationRequest(identifier: "workout-complete-immediate", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func handleAppDidEnterBackground() {
        if isRunning {
            backgroundEntryTime = Date()
        }
    }
    
    private func handleAppWillEnterForeground() {
        guard isRunning,
              let backgroundEntryTime = backgroundEntryTime else { return }
        
        let timeInBackground = Int(Date().timeIntervalSince(backgroundEntryTime))
        let newTimeElapsed = timeElapsed + timeInBackground
        let newTimeRemaining = max(0, totalDuration - newTimeElapsed)
        
        self.timeElapsed = newTimeElapsed
        self.timeRemaining = newTimeRemaining
        self.backgroundEntryTime = nil
        
        if newTimeRemaining <= 0 && (isRunning || isPaused) {
            completeWorkout()
        }
    }
    
    func startTimer() {
        isRunning = true
        isPaused = false
        
        if timeElapsed == 0 {
            totalDuration = selectedDifficulty.duration(for: selectedWorkoutType)
            timeRemaining = totalDuration
        }
        
        startBackgroundTask()
        scheduleCompletionNotification()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.timeElapsed += 1
                self.timeRemaining -= 1
                
                if self.timeRemaining <= 0 {
                    self.completeWorkout()
                }
            }
        }
    }
    
    func pauseTimer() {
        isPaused = true
        timer?.invalidate()
        timer = nil
        endBackgroundTask()
        cancelScheduledNotifications()
    }
    
    func resumeTimer() {
        isPaused = false
        startBackgroundTask()
        scheduleCompletionNotification()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.timeElapsed += 1
                self.timeRemaining -= 1
                
                if self.timeRemaining <= 0 {
                    self.completeWorkout()
                }
            }
        }
    }
    
    func stopTimer() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        endBackgroundTask()
        cancelScheduledNotifications()
        
        if timeElapsed > 0 {
            showingSaveAlert = true
        }
    }
    
    func resetTimer() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        endBackgroundTask()
        cancelScheduledNotifications()
        
        timeElapsed = 0
        backgroundEntryTime = nil
        updateDuration()
        notes = ""
        showingSaveAlert = false
        showingCompletionAlert = false
    }
    
    func updateDuration() {
        if !isRunning && !isPaused {
            totalDuration = selectedDifficulty.duration(for: selectedWorkoutType)
            timeRemaining = totalDuration
            timeElapsed = 0
        }
    }
    
    private func completeWorkout() {
        guard isRunning || isPaused else { return }
        
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        endBackgroundTask()
        cancelScheduledNotifications()
        
        timeRemaining = 0
        
        sendCompletionNotification()
        showingCompletionAlert = true
    }
    
    func saveWorkout() {
        guard let dataManager = dataManager else { return }
        guard timeElapsed > 0 else { 
            resetTimer()
            return 
        }
        
        let workout = WorkoutModel(
            type: "\(selectedWorkoutType.rawValue) (\(selectedDifficulty.rawValue))",
            duration: timeElapsed,
            date: Date(),
            notes: notes.isEmpty ? nil : notes
        )
        
        dataManager.saveWorkout(workout)
        resetTimer()
    }
    
    private func startBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    var formattedTime: String {
        let time = isRunning || isPaused ? timeRemaining : totalDuration
        let hours = time / 3600
        let minutes = (time % 3600) / 60
        let seconds = time % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var formattedElapsedTime: String {
        let hours = timeElapsed / 3600
        let minutes = (timeElapsed % 3600) / 60
        let seconds = timeElapsed % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(timeElapsed) / Double(totalDuration)
    }
} 
