import SwiftUI

@MainActor
final class WorkoutRunnerViewModel: ObservableObject {
    let workout: Workout
    @Published var currentSegmentIndex: Int = 0
    @Published var currentRepeat: Int = 1
    @Published var elapsedInSegment: Int = 0
    @Published var isRunning: Bool = false
    @Published var showCompletionPrompt: Bool = false
    @Published var isWorkoutComplete: Bool = false
    /// True when we are currently counting down a rest-between-repeats phase
    @Published var isRestPhase: Bool = false
    /// True when the completion prompt is specifically the rest-complete / next-set prompt
    @Published var isRestPrompt: Bool = false
    /// True when rest finishes and the "Rest Complete" alert should be shown
    @Published var showRestCompleteAlert: Bool = false

    init(workout: Workout) {
        self.workout = workout
    }

    var currentSegment: TimerSegment {
        workout.segments[currentSegmentIndex]
    }

    var currentDisplayName: String {
        if isRestPhase {
            return "Rest"
        }
        return currentSegment.name
    }

    var displaySegmentType: String {
        if isWorkoutComplete {
            return "Completed"
        }
        if isRestPhase {
            return "Rest"
        }
        return currentSegment.type.rawValue
    }

    var timeRemainingInSegment: Int {
        if isRestPhase {
            return max(currentSegment.restBetweenRepeats - elapsedInSegment, 0)
        }
        return max(currentSegment.durationSeconds - elapsedInSegment, 0)
    }

    var nextSegmentName: String {
        if isRestPhase {
            return "\(currentSegment.name) — Set \(currentRepeat) of \(currentSegment.repeatCount)"
        }
        if currentRepeat < currentSegment.repeatCount {
            if currentSegment.restBetweenRepeats > 0 {
                return "Rest • \(formatDuration(currentSegment.restBetweenRepeats))"
            }
            return currentSegment.name
        }
        let nextIndex = currentSegmentIndex + 1
        return nextIndex < workout.segments.count ? workout.segments[nextIndex].name : "Finish"
    }

    var nextSegmentDurationSeconds: Int {
        if isRestPhase {
            return currentSegment.durationSeconds
        }
        if currentRepeat < currentSegment.repeatCount {
            if currentSegment.restBetweenRepeats > 0 {
                return currentSegment.restBetweenRepeats
            }
            return currentSegment.durationSeconds
        }
        let nextIndex = currentSegmentIndex + 1
        return nextIndex < workout.segments.count ? workout.segments[nextIndex].durationSeconds : 0
    }

    var totalRemainingSeconds: Int {
        var remaining = timeRemainingInSegment
        let seg = currentSegment
        let repeatsLeft = seg.repeatCount - currentRepeat
        if repeatsLeft > 0 {
            remaining += repeatsLeft * seg.durationSeconds
            remaining += repeatsLeft * seg.restBetweenRepeats
        }
        if currentSegmentIndex + 1 < workout.segments.count {
            let future = workout.segments[(currentSegmentIndex + 1)...]
            remaining += future.reduce(0) {
                $0 + ($1.durationSeconds * $1.repeatCount) + ($1.repeatCount > 1 ? $1.restBetweenRepeats * ($1.repeatCount - 1) : 0)
            }
        }
        return remaining
    }

    func start() {
        guard !isWorkoutComplete else { return }
        isRunning = true
    }

    func pause() {
        isRunning = false
    }

    func skip() {
        advancePhase(triggerPrompt: false)
    }

    func stop() {
        isRunning = false
    }

    func restartWorkout() {
        currentSegmentIndex = 0
        currentRepeat = 1
        elapsedInSegment = 0
        isRunning = false
        showCompletionPrompt = false
        isWorkoutComplete = false
        isRestPhase = false
        isRestPrompt = false
        showRestCompleteAlert = false
    }

    func continueToNext() {
        advancePhase(triggerPrompt: false)
        isRunning = true
    }

    /// Add 30 seconds of rest and resume the rest timer
    func addRestTime() {
        showRestCompleteAlert = false
        isRestPhase = true
        elapsedInSegment = max(currentSegment.restBetweenRepeats - 30, 0)
        isRunning = true
    }

    /// Dismiss the rest alert and advance to the next exercise
    func dismissRestAlertAndContinue() {
        showRestCompleteAlert = false
        isRunning = true
    }

    func takeBreak() {
        showCompletionPrompt = false
        isRunning = false
    }

    func tick() {
        guard isRunning, !isWorkoutComplete else { return }
        elapsedInSegment += 1
        if timeRemainingInSegment <= 0 {
            isRunning = false
            advancePhase(triggerPrompt: true)
        }
    }

    private func advancePhase(triggerPrompt: Bool) {
        // Play sound & haptic feedback when a phase ends naturally
        if triggerPrompt {
            if isRestPhase {
                FeedbackManager.playRestEndFeedback()
            } else {
                FeedbackManager.playExerciseEndFeedback()
            }
        }

        elapsedInSegment = 0

        if isRestPhase {
            isRestPhase = false
            if triggerPrompt {
                // Rest just finished — pause and show the Rest Complete alert
                isRunning = false
                showRestCompleteAlert = true
            }
            return
        }

        let seg = currentSegment
        if currentRepeat < seg.repeatCount {
            currentRepeat += 1
            if seg.restBetweenRepeats > 0 {
                isRestPhase = true
                isRestPrompt = false
                showCompletionPrompt = false
                isRunning = true
            } else {
                isRestPrompt = false
                showCompletionPrompt = triggerPrompt
            }
        } else if currentSegmentIndex + 1 < workout.segments.count {
            currentSegmentIndex += 1
            currentRepeat = 1
            isRestPhase = false
            isRestPrompt = false
            showCompletionPrompt = triggerPrompt
        } else {
            isWorkoutComplete = true
            isRestPhase = false
            isRestPrompt = false
            showCompletionPrompt = triggerPrompt
        }
    }
}
