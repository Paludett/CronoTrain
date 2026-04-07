import SwiftUI

enum ActivityType: String, CaseIterable, Identifiable, Sendable {
    case run = "Run"
    case gym = "Gym"
    case pool = "Pool"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .run:
            return "figure.run"
        case .gym:
            return "dumbbell"
        case .pool:
            return "figure.pool.swim"
        }
    }

    var allowedSegmentTypes: [TimerSegmentType] {
        switch self {
        case .run:
            return [.run, .walk]
        case .pool:
            return [.swim]
        case .gym:
            return [.exercise]
        }
    }
}

enum TimerSegmentType: String, CaseIterable, Identifiable, Sendable {
    case run = "Run"
    case walk = "Walk"
    case swim = "Swim"
    case exercise = "Exercise"

    var id: String { rawValue }

    var badgeColor: Color {
        return .purpleSurface
    }
}

struct TimerSegment: Identifiable, Hashable, Sendable {
    var id = UUID()
    var name: String
    var type: TimerSegmentType
    var durationSeconds: Int
    var repeatCount: Int = 1
    var restBetweenRepeats: Int = 0  // seconds of rest between each repeat (0 = no rest)
}

struct Workout: Identifiable, Hashable, Sendable {
    var id = UUID()
    var name: String
    var activityType: ActivityType
    var segments: [TimerSegment]
    /// Days of the week this workout is scheduled (1 = Sunday … 7 = Saturday, matching Calendar.component(.weekday))
    var scheduledDays: Set<Int> = []
    var streakCount: Int = 0
    var lastCompletedDate: Date? = nil

    var totalDurationSeconds: Int {
        segments.reduce(0) { total, seg in
            let activeTime = seg.durationSeconds * seg.repeatCount
            let restTime = seg.repeatCount > 1 ? seg.restBetweenRepeats * (seg.repeatCount - 1) : 0
            return total + activeTime + restTime
        }
    }
}

@MainActor
final class WorkoutStore: ObservableObject {
    @Published var workouts: [Workout]

    init(workouts: [Workout] = []) {
        if workouts.isEmpty {
            self.workouts = [
                Workout(
                    name: "10km",
                    activityType: .run,
                    segments: [
                        TimerSegment(name: "Run", type: .run, durationSeconds: 900, repeatCount: 1, restBetweenRepeats: 0)
                    ]
                ),
                Workout(
                    name: "5km",
                    activityType: .run,
                    segments: [
                        TimerSegment(name: "Run", type: .run, durationSeconds: 600, repeatCount: 1)
                    ]
                ),
                Workout(
                    name: "A – Push Pull",
                    activityType: .gym,
                    segments: [
                        TimerSegment(name: "Bench Press", type: .exercise, durationSeconds: 180, repeatCount: 3, restBetweenRepeats: 60)
                    ]
                ),
                Workout(
                    name: "Beach Swimming",
                    activityType: .pool,
                    segments: [
                        TimerSegment(name: "Swim", type: .swim, durationSeconds: 300, repeatCount: 2, restBetweenRepeats: 90)
                    ]
                )
            ]
        } else {
            self.workouts = workouts
        }
    }

    func addWorkout(_ workout: Workout) {
        workouts.append(workout)
    }

    func addSegment(to workoutID: UUID, segment: TimerSegment) {
        guard let index = workouts.firstIndex(where: { $0.id == workoutID }) else { return }
        workouts[index].segments.append(segment)
    }

    func updateWorkout(_ workout: Workout) {
        guard let index = workouts.firstIndex(where: { $0.id == workout.id }) else { return }
        workouts[index] = workout
    }

    /// Called when the user finishes a workout. Returns true if the streak was incremented.
    @discardableResult
    func completeWorkout(id: UUID) -> Bool {
        guard let index = workouts.firstIndex(where: { $0.id == id }) else { return false }
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)

        // Only count streak if today is a scheduled day
        guard workouts[index].scheduledDays.contains(todayWeekday) else { return false }

        // Avoid double-counting completions on the same day
        if let last = workouts[index].lastCompletedDate,
           calendar.isDate(last, inSameDayAs: today) {
            return false
        }

        // Check if the previous scheduled day was missed
        if let last = workouts[index].lastCompletedDate {
            let previousScheduledDay = Self.previousScheduledDay(
                before: today,
                scheduledDays: workouts[index].scheduledDays,
                calendar: calendar
            )
            if let prev = previousScheduledDay, !calendar.isDate(last, inSameDayAs: prev) {
                // Missed a day — reset streak
                workouts[index].streakCount = 0
            }
        }

        workouts[index].streakCount += 1
        workouts[index].lastCompletedDate = today
        return true
    }

    /// Finds the most recent scheduled day before the given date (not including the date itself).
    private static func previousScheduledDay(before date: Date, scheduledDays: Set<Int>, calendar: Calendar) -> Date? {
        guard !scheduledDays.isEmpty else { return nil }
        var check = calendar.date(byAdding: .day, value: -1, to: date)!
        for _ in 0..<7 {
            let wd = calendar.component(.weekday, from: check)
            if scheduledDays.contains(wd) { return check }
            check = calendar.date(byAdding: .day, value: -1, to: check)!
        }
        return nil
    }
}
