import AVFoundation
import UIKit

/// Manages haptic feedback and system sounds for workout phase transitions.
@MainActor
enum FeedbackManager {

    // MARK: - Audio Session

    /// Configures AVAudioSession so sounds play even when the device is on silent mode.
    /// Call this once before any sound needs to play (e.g. in the timer view's .onAppear).
    static func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Silently ignore — audio may not work on silent mode but the app won't crash
        }
    }

    // MARK: - Feedback Triggers

    /// Plays haptic + sound when an exercise segment ends.
    static func playExerciseEndFeedback() {
        triggerHaptic()
        // Clean short beep (system sound 1057)
        AudioServicesPlaySystemSound(1057)
    }

    /// Plays haptic + sound when a rest period ends.
    static func playRestEndFeedback() {
        triggerHaptic()
        // More prominent tone to distinguish from exercise end (system sound 1005)
        AudioServicesPlaySystemSound(1005)
    }

    // MARK: - Private

    private static func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}
