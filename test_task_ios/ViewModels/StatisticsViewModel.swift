import Foundation
import Combine

final class StatisticsViewModel: ObservableObject {
    @Published var totalWorkouts: Int = 0
    @Published var totalDuration: Int = 0
    @Published var recentWorkouts: [WorkoutModel] = []
    @Published var allWorkouts: [WorkoutModel] = []
    
    private let dataManager: WorkoutDataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(dataManager: WorkoutDataManager) {
        self.dataManager = dataManager
        setupBindings()
        fetchStatistics()
    }
    
    private func setupBindings() {
        dataManager.$workouts
            .sink { [weak self] workouts in
                self?.allWorkouts = workouts.sorted { $0.date > $1.date }
                self?.fetchStatistics()
            }
            .store(in: &cancellables)
    }
    
    func fetchStatistics() {
        allWorkouts = dataManager.workouts.sorted { $0.date > $1.date }
        totalWorkouts = allWorkouts.count
        totalDuration = allWorkouts.reduce(0) { $0 + $1.duration }
        recentWorkouts = Array(allWorkouts.prefix(3))
    }
    
    var formattedTotalDuration: String {
        let hours = totalDuration / 3600
        let minutes = (totalDuration % 3600) / 60
        
        if hours > 0 {
            return "\(hours)ч \(minutes)м"
        } else {
            return "\(minutes)м"
        }
    }
    
    var averageWorkoutDuration: String {
        guard totalWorkouts > 0 else { return "0м" }
        let average = totalDuration / totalWorkouts
        let minutes = average / 60
        return "\(minutes)м"
    }
    
    func workoutsByType() -> [String: Int] {
        var typeCount: [String: Int] = [:]
        for workout in allWorkouts {
            typeCount[workout.type, default: 0] += 1
        }
        return typeCount
    }
    
    func deleteWorkout(_ workout: WorkoutModel) {
        dataManager.deleteWorkout(workout)
    }
    
    func clearAllData() {
        dataManager.clearAllWorkouts()
    }
} 
