import Foundation

enum WorkoutType: String, CaseIterable {
    case strength = "Силовая тренировка"
    case cardio = "Кардио"
    case yoga = "Йога"
    case stretching = "Растяжка"
    case other = "Другое"
    
    var emoji: String {
        switch self {
        case .strength: return "💪"
        case .cardio: return "🏃"
        case .yoga: return "🧘"
        case .stretching: return "🤸"
        case .other: return "🏋️"
        }
    }
}

enum WorkoutDifficulty: String, CaseIterable {
    case easy = "Легко"
    case medium = "Средне"
    case hard = "Сложно"
    
    var emoji: String {
        switch self {
        case .easy: return "🟢"
        case .medium: return "🟡"
        case .hard: return "🔴"
        }
    }
    
    func duration(for workoutType: WorkoutType) -> Int {
        switch workoutType {
        case .strength:
            switch self {
            case .easy: return 600    // 10 минут
            case .medium: return 1200 // 20 минут
            case .hard: return 1800   // 30 минут
            }
        case .cardio:
            switch self {
            case .easy: return 900    // 15 минут
            case .medium: return 1800 // 30 минут
            case .hard: return 2700   // 45 минут
            }
        case .yoga:
            switch self {
            case .easy: return 1200   // 20 минут
            case .medium: return 2400 // 40 минут
            case .hard: return 3600   // 60 минут
            }
        case .stretching:
            switch self {
            case .easy: return 600    // 10 минут
            case .medium: return 900  // 15 минут
            case .hard: return 1200   // 20 минут
            }
        case .other:
            switch self {
            case .easy: return 10    // test
            case .medium: return 1800 // 30 минут
            case .hard: return 3600   // 60 минут
            }
        }
    }
} 
