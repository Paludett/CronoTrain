import SwiftUI

// MARK: - Persisted record of a completed workout

struct CompletedWorkoutRecord: Codable, Sendable, Identifiable, Hashable {
    var id: String { "\(dateString)-\(activityTypeRaw)-\(workoutName)" }
    let dateString: String        // "yyyy-MM-dd"
    let activityTypeRaw: String   // ActivityType.rawValue
    let workoutName: String

    var activityType: ActivityType? {
        ActivityType(rawValue: activityTypeRaw)
    }

    var date: Date? {
        Self.dateFormatter.date(from: dateString)
    }

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

// MARK: - WorkoutHistoryManager

@MainActor
final class WorkoutHistoryManager: ObservableObject {
    private static let storageKey = "cronotrain_workout_history"

    @Published private(set) var records: [CompletedWorkoutRecord] = []

    init() {
        loadRecords()
    }

    // MARK: - Public API

    func recordCompletion(workout: Workout, date: Date = Date()) {
        let dateString = CompletedWorkoutRecord.dateFormatter.string(from: date)
        let record = CompletedWorkoutRecord(
            dateString: dateString,
            activityTypeRaw: workout.activityType.rawValue,
            workoutName: workout.name
        )
        records.append(record)
        saveRecords()
    }

    /// Returns all records for a given date string ("yyyy-MM-dd").
    func records(for dateString: String) -> [CompletedWorkoutRecord] {
        records.filter { $0.dateString == dateString }
    }

    /// Returns the set of activity types completed on a given date string.
    func activityTypes(for dateString: String) -> [ActivityType] {
        let types = records(for: dateString).compactMap { $0.activityType }
        return Array(Set(types))
    }

    // MARK: - Persistence

    private func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([CompletedWorkoutRecord].self, from: data)
        else { return }
        records = decoded
    }
}
