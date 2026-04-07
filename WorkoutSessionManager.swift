import SwiftUI

@MainActor
final class WorkoutSessionManager: ObservableObject {
    @Published var activeWorkout: Workout? = nil
    @Published var sessionID: UUID = UUID()
    @Published var elapsedSeconds: Int = 0
    @Published var currentSegmentIndex: Int = 0
    @Published var currentRepeat: Int = 1
    @Published var isRunning: Bool = false

    func startSession(workout: Workout) {
        activeWorkout = workout
        sessionID = UUID()
        elapsedSeconds = 0
        currentSegmentIndex = 0
        currentRepeat = 1
        isRunning = true
    }

    func clearSession() {
        activeWorkout = nil
        elapsedSeconds = 0
        currentSegmentIndex = 0
        currentRepeat = 1
        isRunning = false
    }
}
