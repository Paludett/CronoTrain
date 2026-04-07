import SwiftUI

// MARK: - Rank

enum Rank: String, CaseIterable, Sendable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    case diamond = "Diamond"
    case master = "Master"

    var minXP: Int {
        switch self {
        case .bronze:   return 0
        case .silver:   return 500
        case .gold:     return 1500
        case .platinum: return 3500
        case .diamond:  return 7000
        case .master:   return 14000
        }
    }

    /// XP needed to reach the *next* rank. Returns `nil` for Master (max rank).
    var xpForNextRank: Int? {
        switch self {
        case .bronze:   return 500
        case .silver:   return 1500
        case .gold:     return 3500
        case .platinum: return 7000
        case .diamond:  return 14000
        case .master:   return nil
        }
    }

    var color: Color {
        switch self {
        case .bronze:   return Color(red: 0.72, green: 0.45, blue: 0.20)
        case .silver:   return Color.gray
        case .gold:     return Color(red: 0.93, green: 0.79, blue: 0.28)
        case .platinum: return Color.teal
        case .diamond:  return Color.blue
        case .master:   return Color.brandPurple
        }
    }

    var iconName: String {
        switch self {
        case .bronze:   return "shield.fill"
        case .silver:   return "shield.fill"
        case .gold:     return "star.fill"
        case .platinum: return "diamond.fill"
        case .diamond:  return "diamond.fill"
        case .master:   return "crown.fill"
        }
    }

    static func rank(for xp: Int) -> Rank {
        for rank in Self.allCases.reversed() {
            if xp >= rank.minXP { return rank }
        }
        return .bronze
    }

    /// Human-readable XP range label, e.g. "0 – 499 XP" or "14,000+ XP".
    var xpRangeLabel: String {
        if let next = xpForNextRank {
            return "\(minXP) – \(next - 1) XP"
        }
        return "\(minXP)+ XP"
    }
}

// MARK: - XPManager

@MainActor
final class XPManager: ObservableObject {
    private static let totalXPKey = "cronotrain_total_xp"

    @Published var totalXP: Int {
        didSet {
            UserDefaults.standard.set(totalXP, forKey: Self.totalXPKey)
        }
    }

    /// Set after `awardXP` if the user crossed into a new rank tier.
    @Published var didRankUp: Bool = false
    @Published var newRank: Rank? = nil

    init() {
        self.totalXP = UserDefaults.standard.integer(forKey: Self.totalXPKey)
    }

    var currentRank: Rank {
        Rank.rank(for: totalXP)
    }

    /// Progress fraction (0…1) toward the next rank. Returns 1.0 for Master.
    var progressToNextRank: Double {
        let rank = currentRank
        guard let target = rank.xpForNextRank else { return 1.0 }
        let base = rank.minXP
        let range = target - base
        guard range > 0 else { return 1.0 }
        return Double(totalXP - base) / Double(range)
    }

    /// Label text like "320 / 500 XP" or "14000+ XP (Max)" for Master.
    var progressLabel: String {
        let rank = currentRank
        if let target = rank.xpForNextRank {
            return "\(totalXP) / \(target) XP"
        }
        return "\(totalXP) XP (Max Rank)"
    }

    /// Calculate XP for a workout: 1 XP per 10 seconds.
    static func xpForWorkout(_ workout: Workout) -> Int {
        return workout.totalDurationSeconds / 10
    }

    /// Award XP and detect rank-up. Returns the XP amount awarded.
    @discardableResult
    func awardXP(for workout: Workout) -> Int {
        let xp = Self.xpForWorkout(workout)
        let oldRank = currentRank
        totalXP += xp
        let newCurrentRank = currentRank
        if newCurrentRank != oldRank {
            didRankUp = true
            newRank = newCurrentRank
        }
        return xp
    }

    /// Reset the rank-up flag after showing celebration.
    func clearRankUp() {
        didRankUp = false
        newRank = nil
    }
}
