import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: WorkoutStore
    @EnvironmentObject private var xpManager: XPManager
    @EnvironmentObject private var historyManager: WorkoutHistoryManager

    @State private var profile = UserProfile(
        name: "Lorenzo",
        level: "Silver",
        currentStreakCount: 5,
        currentStreakActivity: "Run",
        biggestStreakCount: 14,
        biggestStreakActivity: "Swimming",
        totalActivityHours: 183
    )

    private var workoutsWithStreaks: [Workout] {
        store.workouts.filter { $0.streakCount > 0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection

                    rankProgressCard

                    streaksCard

                    if !workoutsWithStreaks.isEmpty {
                        activeStreaksSection
                    }

                    activityHeatmapSection

                    activityCard
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .background(Color.appBackground)
            .navigationBarHidden(true)
        }
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.purpleSurface)
                    .frame(width: 72, height: 72)

                Image(systemName: "person.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.brandPurple)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(profile.name)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.primaryText)

                NavigationLink(destination: RankDetailsView()) {
                    HStack(spacing: 6) {
                        Image(systemName: xpManager.currentRank.iconName)
                            .foregroundStyle(xpManager.currentRank.color)
                        Text(xpManager.currentRank.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(xpManager.currentRank.color)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(Color.secondaryText)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(xpManager.currentRank.color.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    private var rankProgressCard: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: xpManager.currentRank.iconName)
                        .font(.title3)
                        .foregroundStyle(xpManager.currentRank.color)
                    Text(xpManager.currentRank.rawValue)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.primaryText)
                }
                Spacer()
                Text(xpManager.progressLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.purpleSurface)
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [xpManager.currentRank.color, xpManager.currentRank.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * xpManager.progressToNextRank, height: 10)
                        .animation(.easeInOut(duration: 0.4), value: xpManager.progressToNextRank)
                }
            }
            .frame(height: 10)

            if let nextRankXP = xpManager.currentRank.xpForNextRank {
                let remaining = nextRankXP - xpManager.totalXP
                Text("\(remaining) XP to \(Rank.rank(for: nextRankXP).rawValue)")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
            }
        }
        .padding(16)
        .appCardBackground()
    }

    private var streaksCard: some View {
        HStack(spacing: 0) {
            StatBlock(
                number: "\(profile.currentStreakCount)",
                label: profile.currentStreakActivity,
                sublabel: "Current streak"
            )

            Divider()
                .background(Color.brandPurple.opacity(0.1))
                .padding(.vertical, 10)

            StatBlock(
                number: "\(profile.biggestStreakCount)",
                label: profile.biggestStreakActivity,
                sublabel: "Biggest Streak"
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .appCardBackground()
    }

    private var activityHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(spacing: 0) {
                ActivityHeatmapView()
                    .padding(14)
            }
            .appCardBackground()
        }
    }

    private var activityCard: some View {
        VStack(spacing: 10) {
            Text("Activity Time")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.primaryText)

            Text("\(profile.totalActivityHours)h")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.brandPurple)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .appCardBackground()
    }

    private var activeStreaksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Streaks")
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(spacing: 10) {
                ForEach(workoutsWithStreaks) { workout in
                    HStack(spacing: 12) {
                        Text("🔥")
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.primaryText)

                            if !workout.scheduledDays.isEmpty {
                                Text(WeekdayPicker.displayString(for: workout.scheduledDays))
                                    .font(.caption)
                                    .foregroundStyle(Color.secondaryText)
                            }
                        }

                        Spacer()

                        Text("\(workout.streakCount)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.brandPurple)

                        Text(workout.streakCount == 1 ? "day" : "days")
                            .font(.caption)
                            .foregroundStyle(Color.secondaryText)
                    }
                    .padding(14)
                    .appCardBackground()
                }
            }
        }
    }
}

struct UserProfile: Hashable, Sendable {
    var name: String
    var level: String
    var currentStreakCount: Int
    var currentStreakActivity: String
    var biggestStreakCount: Int
    var biggestStreakActivity: String
    var totalActivityHours: Int
}

struct StatBlock: View {
    var number: String
    var label: String
    var sublabel: String

    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.title.weight(.bold))
                .foregroundStyle(Color.primaryText)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.secondaryText)

            Text(sublabel)
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .appCardBackground()
    }
}
