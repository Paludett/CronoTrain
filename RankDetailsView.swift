import SwiftUI

struct RankDetailsView: View {
    @EnvironmentObject private var xpManager: XPManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroSection
                rankTierList
                progressCard
                motivationCard
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .navigationTitle("Rank Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                xpManager.currentRank.color.opacity(0.25),
                                xpManager.currentRank.color.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)

                Image(systemName: xpManager.currentRank.iconName)
                    .font(.system(size: 44))
                    .foregroundStyle(xpManager.currentRank.color)
            }

            Text(xpManager.currentRank.rawValue)
                .font(.title.weight(.bold))
                .foregroundStyle(Color.primaryText)

            Text("\(xpManager.totalXP) XP")
                .font(.title3.weight(.semibold))
                .foregroundStyle(xpManager.currentRank.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .appCardBackground()
    }

    // MARK: - Rank Tier List

    private var rankTierList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Ranks")
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(spacing: 10) {
                ForEach(Rank.allCases, id: \.self) { rank in
                    rankTierCard(rank)
                }
            }
        }
    }

    private func rankTierCard(_ rank: Rank) -> some View {
        let isCurrent = rank == xpManager.currentRank
        let isAchieved = xpManager.totalXP >= rank.minXP

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(rank.color.opacity(isAchieved ? 0.18 : 0.06))
                    .frame(width: 44, height: 44)

                Image(systemName: rank.iconName)
                    .font(.title3)
                    .foregroundStyle(isAchieved ? rank.color : Color.secondaryText.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(rank.rawValue)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(isAchieved ? Color.primaryText : Color.secondaryText)

                    if isCurrent {
                        Text("Current")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(rank.color)
                            )
                    }
                }

                Text(rank.xpRangeLabel)
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()

            if isAchieved {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(rank.color)
            } else {
                Image(systemName: "lock.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText.opacity(0.35))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBackground)
        )
        .overlay(
            isCurrent
                ? RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(rank.color, lineWidth: 2)
                : nil
        )
        .shadow(
            color: isCurrent ? rank.color.opacity(0.18) : Color.brandPurple.opacity(0.06),
            radius: isCurrent ? 14 : 8,
            x: 0,
            y: isCurrent ? 6 : 3
        )
        .scaleEffect(isCurrent ? 1.02 : 1.0)
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        VStack(spacing: 14) {
            Text("Progress")
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
                .textCase(.uppercase)
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)

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

            HStack {
                Text(xpManager.progressLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)
                Spacer()
            }

            if let nextXP = xpManager.currentRank.xpForNextRank {
                let remaining = nextXP - xpManager.totalXP
                let estimatedWorkouts = max(1, Int(ceil(Double(remaining) / 60.0)))

                VStack(spacing: 6) {
                    Text("You need **\(remaining) more XP** to reach \(Rank.rank(for: nextXP).rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(Color.primaryText)
                        .multilineTextAlignment(.center)

                    Text("≈ \(estimatedWorkouts) average workout\(estimatedWorkouts == 1 ? "" : "s") to go")
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                }
                .padding(.top, 4)
            } else {
                Text("You've reached the highest rank! 👑")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(xpManager.currentRank.color)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .appCardBackground()
    }

    // MARK: - Motivation Card

    private var motivationCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.brandPurple.opacity(0.5))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text("How XP Works")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primaryText)

                Text("Complete workouts to earn XP. The longer your session, the more XP you earn — 1 XP per 10 seconds of training.")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.purpleSurface.opacity(0.5))
        )
    }
}
