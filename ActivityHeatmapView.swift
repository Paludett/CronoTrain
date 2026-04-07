import SwiftUI

// MARK: - Day cell data

struct HeatmapDay: Identifiable {
    let id: String          // "yyyy-MM-dd"
    let date: Date
    let activityTypes: [ActivityType]

    var isEmpty: Bool { activityTypes.isEmpty }
}

// MARK: - ActivityHeatmapView

struct ActivityHeatmapView: View {
    @EnvironmentObject private var historyManager: WorkoutHistoryManager

    /// Number of full weeks to display (columns in the grid).
    private let weekCount = 53
    private let cellSize: CGFloat = 10
    private let cellSpacing: CGFloat = 2

    @State private var selectedDay: HeatmapDay? = nil
    @State private var tooltipPosition: CGPoint = .zero

    // Day labels shown on the left side (Mon, Wed, Fri)
    private let dayLabels: [(row: Int, label: String)] = [
        (1, "Mon"), (3, "Wed"), (5, "Fri")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            heatmapLegend

            ZStack(alignment: .topLeading) {
                ScrollViewReader { scrollProxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 0) {
                            // Day labels column
                            VStack(alignment: .trailing, spacing: 0) {
                                ForEach(0..<7, id: \.self) { row in
                                    if let match = dayLabels.first(where: { $0.row == row }) {
                                        Text(match.label)
                                            .font(.system(size: 8))
                                            .foregroundStyle(Color.secondaryText)
                                            .frame(width: 24, height: cellSize + cellSpacing, alignment: .trailing)
                                    } else {
                                        Color.clear
                                            .frame(width: 24, height: cellSize + cellSpacing)
                                    }
                                }
                            }
                            .padding(.trailing, 2)

                            // Grid of weeks
                            LazyHStack(alignment: .top, spacing: cellSpacing) {
                                ForEach(weeks.indices, id: \.self) { weekIndex in
                                    VStack(spacing: cellSpacing) {
                                        ForEach(weeks[weekIndex]) { day in
                                            dayCellView(day: day)
                                                .id(day.id)
                                        }
                                    }
                                    .id("week-\(weekIndex)")
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.trailing, 4)
                    }
                    .onAppear {
                        // Scroll to the most recent week
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.none) {
                                scrollProxy.scrollTo("week-\(weeks.count - 1)", anchor: .trailing)
                            }
                        }
                    }
                }

                // Tooltip overlay
                if let day = selectedDay {
                    tooltipView(for: day)
                }
            }
        }
        .onTapGesture {
            // Dismiss tooltip when tapping outside
            if selectedDay != nil {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedDay = nil
                }
            }
        }
    }

    // MARK: - Computed grid data

    private var weeks: [[HeatmapDay]] {
        let calendar = Calendar.current
        let today = Date()
        let totalDays = weekCount * 7

        // Find the start date: go back enough days to fill the grid,
        // aligning columns so the last column ends on today's week.
        let todayWeekday = calendar.component(.weekday, from: today) // 1=Sun
        // We use Monday-first: Mon=0 .. Sun=6
        let dayOfWeekIndex = (todayWeekday + 5) % 7
        let daysBack = totalDays - 1 - dayOfWeekIndex
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: today) else {
            return []
        }

        let formatter = CompletedWorkoutRecord.dateFormatter
        var result: [[HeatmapDay]] = []
        var currentWeek: [HeatmapDay] = []

        for offset in 0..<totalDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else { continue }
            // Don't show future dates
            if date > today {
                // fill remaining with placeholder invisible cells
                if !currentWeek.isEmpty {
                    result.append(currentWeek)
                }
                break
            }
            let dateString = formatter.string(from: date)
            let types = historyManager.activityTypes(for: dateString)
            let day = HeatmapDay(id: dateString, date: date, activityTypes: types)
            currentWeek.append(day)
            if currentWeek.count == 7 {
                result.append(currentWeek)
                currentWeek = []
            }
        }
        if !currentWeek.isEmpty {
            result.append(currentWeek)
        }
        return result
    }

    // MARK: - Day cell

    @ViewBuilder
    private func dayCellView(day: HeatmapDay) -> some View {
        let fillView = dayCellFill(for: day)
        fillView
            .frame(width: cellSize, height: cellSize)
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if selectedDay?.id == day.id {
                        selectedDay = nil
                    } else {
                        selectedDay = day
                    }
                }
            }
    }

    @ViewBuilder
    private func dayCellFill(for day: HeatmapDay) -> some View {
        if day.isEmpty {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.heatmapEmpty)
        } else if day.activityTypes.count == 1, let type = day.activityTypes.first {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(type.activityColor)
        } else {
            // Multiple activity types — use a diagonal gradient blend
            let colors = day.activityTypes.map(\.activityColor)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    // MARK: - Tooltip

    @ViewBuilder
    private func tooltipView(for day: HeatmapDay) -> some View {
        let dateLabel = tooltipDateLabel(day.date)
        let workoutLabels = day.activityTypes.map(\.rawValue)

        VStack(alignment: .leading, spacing: 4) {
            Text(dateLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.primaryText)

            if day.isEmpty {
                Text("No workouts")
                    .font(.caption2)
                    .foregroundStyle(Color.secondaryText)
            } else {
                Text(workoutLabels.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundStyle(Color.secondaryText)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.cardBackground)
                .shadow(color: Color.brandPurple.opacity(0.12), radius: 8, x: 0, y: 4)
        )
        .transition(.opacity)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, -4)
        .allowsHitTesting(false)
    }

    private func tooltipDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    // MARK: - Legend

    private var heatmapLegend: some View {
        HStack(spacing: 12) {
            ForEach(ActivityType.allCases) { type in
                HStack(spacing: 4) {
                    Circle()
                        .fill(type.activityColor)
                        .frame(width: 8, height: 8)
                    Text(type.rawValue)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondaryText)
                }
            }
            Spacer()
        }
    }
}
