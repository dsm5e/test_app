import Foundation
import CoreData

struct WorkoutModel: Identifiable, Codable {
    let id: UUID
    let type: String
    let duration: Int
    let date: Date
    let notes: String?
    
    init(id: UUID = UUID(), type: String, duration: Int, date: Date = Date(), notes: String? = nil) {
        self.id = id
        self.type = type
        self.duration = duration
        self.date = date
        self.notes = notes
    }
}

final class WorkoutDataManager: ObservableObject {
    @Published var workouts: [WorkoutModel] = []

    private let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "Workout") // имя должно совпадать с .xcdatamodeld (без .xcdatamodel!)
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Failed to load Core Data: \(error)")
            } else {
                self.fetchWorkouts()
            }
        }
    }

    func saveWorkout(_ workout: WorkoutModel) {
        let context = container.viewContext
        let entity = WorkoutEntity(context: context)

        entity.id = workout.id
        entity.type = workout.type
        entity.duration = Int32(workout.duration)
        entity.date = workout.date
        entity.notes = workout.notes

        saveContext()
        fetchWorkouts()
    }

    func deleteWorkout(_ workout: WorkoutModel) {
        let context = container.viewContext
        let request: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", workout.id as CVarArg)

        if let results = try? context.fetch(request),
           let object = results.first {
            context.delete(object)
            saveContext()
            fetchWorkouts()
        }
    }

    func clearAllWorkouts() {
        let context = container.viewContext
        let request: NSFetchRequest<NSFetchRequestResult> = WorkoutEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(deleteRequest)
            saveContext()
            workouts = []
        } catch {
            print("❌ Failed to clear workouts: \(error)")
        }
    }

    private func fetchWorkouts() {
        let context = container.viewContext
        let request: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()

        do {
            let entities = try context.fetch(request)
            workouts = entities.map { entity in
                WorkoutModel(
                    id: entity.id ?? UUID(),
                    type: entity.type ?? "",
                    duration: Int(entity.duration),
                    date: entity.date ?? Date(),
                    notes: entity.notes
                )
            }
        } catch {
            print("❌ Failed to fetch workouts: \(error)")
        }
    }

    private func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Failed to save context: \(error)")
            }
        }
    }
}
