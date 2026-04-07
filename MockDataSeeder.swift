import Foundation

/// Seeds the app with realistic mock data on first launch so testers see a fully
/// configured experience. Gated by a UserDefaults flag so it runs only once and
/// never overwrites real user data.
@MainActor
enum MockDataSeeder {

    private static let hasSeededKey = "hasSeededMockData"

    static func seedMockDataIfNeeded(
        store: WorkoutStore,
        xpManager: XPManager,
        historyManager: WorkoutHistoryManager
    ) {
        guard !UserDefaults.standard.bool(forKey: hasSeededKey) else { return }

        // ── 1. Pre-built Workouts ──────────────────────────────────────

        let morningRun = Workout(
            name: "Morning Run",
            activityType: .run,
            segments: [
                TimerSegment(name: "Warm-up Jog",    type: .run,  durationSeconds: 300, repeatCount: 1, restBetweenRepeats: 0),
                TimerSegment(name: "Interval Sprint", type: .run,  durationSeconds: 60,  repeatCount: 4, restBetweenRepeats: 30),
                TimerSegment(name: "Steady Run",      type: .run,  durationSeconds: 600, repeatCount: 1, restBetweenRepeats: 0),
                TimerSegment(name: "Cool-down Walk",  type: .walk, durationSeconds: 180, repeatCount: 1, restBetweenRepeats: 0)
            ],
            scheduledDays: [2, 4, 6],   // Mon, Wed, Fri
            streakCount: 7,
            lastCompletedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())
        )

        let upperBody = Workout(
            name: "Upper Body",
            activityType: .gym,
            segments: [
                TimerSegment(name: "Bench Press",     type: .exercise, durationSeconds: 45, repeatCount: 4, restBetweenRepeats: 60),
                TimerSegment(name: "Overhead Press",   type: .exercise, durationSeconds: 45, repeatCount: 3, restBetweenRepeats: 60),
                TimerSegment(name: "Dumbbell Rows",    type: .exercise, durationSeconds: 45, repeatCount: 3, restBetweenRepeats: 60),
                TimerSegment(name: "Lateral Raises",   type: .exercise, durationSeconds: 30, repeatCount: 3, restBetweenRepeats: 45),
                TimerSegment(name: "Tricep Dips",      type: .exercise, durationSeconds: 40, repeatCount: 3, restBetweenRepeats: 45)
            ],
            scheduledDays: [3, 5],       // Tue, Thu
            streakCount: 4,
            lastCompletedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())
        )

        let poolRecovery = Workout(
            name: "Pool Recovery",
            activityType: .pool,
            segments: [
                TimerSegment(name: "Freestyle Warm-up", type: .swim, durationSeconds: 300, repeatCount: 1, restBetweenRepeats: 0),
                TimerSegment(name: "Backstroke Laps",   type: .swim, durationSeconds: 120, repeatCount: 3, restBetweenRepeats: 60),
                TimerSegment(name: "Cool-down Swim",    type: .swim, durationSeconds: 240, repeatCount: 1, restBetweenRepeats: 0)
            ],
            scheduledDays: [1],          // Sunday
            streakCount: 0,
            lastCompletedDate: nil
        )

        store.workouts = [morningRun, upperBody, poolRecovery]

        // ── 2. XP and Rank ─────────────────────────────────────────────
        // Set total XP to 1340 (Silver range: 500–1499, close to Gold at 1500)
        xpManager.totalXP = 1340

        // ── 3. Activity Heatmap — last 60 days ─────────────────────────
        // Seeded PRNG for reproducible but organic-looking data
        var rng = SeededGenerator(seed: 42)
        let calendar = Calendar.current
        let today = Date()

        for dayOffset in stride(from: -60, through: -1, by: 1) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            // 1=Sun 2=Mon 3=Tue 4=Wed 5=Thu 6=Fri 7=Sat

            switch weekday {
            case 2, 4, 6: // Mon, Wed, Fri — run days (~75% chance)
                if rng.next(upperBound: 100) < 75 {
                    historyManager.recordCompletion(workout: morningRun, date: date)
                }
            case 3, 5:    // Tue, Thu — gym days (~70% chance)
                if rng.next(upperBound: 100) < 70 {
                    historyManager.recordCompletion(workout: upperBody, date: date)
                }
            case 1:       // Sun — pool (~40% chance)
                if rng.next(upperBound: 100) < 40 {
                    historyManager.recordCompletion(workout: poolRecovery, date: date)
                }
            case 7:       // Sat — occasional bonus session (~20% chance)
                let roll = rng.next(upperBound: 100)
                if roll < 10 {
                    historyManager.recordCompletion(workout: morningRun, date: date)
                } else if roll < 20 {
                    historyManager.recordCompletion(workout: upperBody, date: date)
                }
            default:
                break
            }

            // ~8% chance of a second workout on any active day
            if rng.next(upperBound: 100) < 8 {
                let pick = rng.next(upperBound: 3)
                let bonus = pick == 0 ? morningRun : (pick == 1 ? upperBody : poolRecovery)
                historyManager.recordCompletion(workout: bonus, date: date)
            }
        }

        // ── 4. Mark as seeded ──────────────────────────────────────────
        UserDefaults.standard.set(true, forKey: hasSeededKey)
    }
}

// MARK: - Lightweight seeded PRNG (xorshift64)

private struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 1 : seed
    }

    mutating func next(upperBound: Int) -> Int {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Int(state % UInt64(upperBound))
    }
}
