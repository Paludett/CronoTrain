import Foundation
import SwiftUI

func formatDuration(_ seconds: Int) -> String {
    if seconds < 60 {
        return "\(seconds)s"
    }
    if seconds % 60 == 0 {
        return "\(seconds / 60)min"
    }
    return formatTime(seconds)
}

func formatMinutes(_ seconds: Int) -> String {
    let minutes = max(1, Int(ceil(Double(seconds) / 60.0)))
    return "\(minutes)min"
}

func formatTime(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    return String(format: "%02d:%02d", minutes, remainingSeconds)
}

// MARK: - Wiggle / Jiggle animation (iOS home screen style)

struct WiggleModifier: ViewModifier {
    var isWiggling: Bool
    var index: Int = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(isWiggling ? 1.02 : 1.0)
            .animation(
                isWiggling
                    ? Animation
                        .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.15)
                    : .easeInOut(duration: 0.2),
                value: isWiggling
            )
    }
}

extension View {
    func wiggling(_ isWiggling: Bool, angle: Double = 0.3) -> some View {
        modifier(WiggleModifier(isWiggling: isWiggling))
    }
}

// MARK: - Brand color system

extension Color {
    // Brand
    static let brandPurple = Color(red: 0.44, green: 0.29, blue: 0.95)
    static let brandPurpleLight = Color(red: 0.62, green: 0.50, blue: 0.98)
    static let brandPurpleDark = Color(red: 0.28, green: 0.16, blue: 0.72)
    /// Deep purple for splash / launch screen background (#5B2D8E)
    static let deepPurple = Color(red: 0.357, green: 0.176, blue: 0.557)

    // Backgrounds
    static let appBackground = Color(red: 0.97, green: 0.97, blue: 0.99)
    static let cardBackground = Color.white
    static let sheetBackground = Color(red: 0.96, green: 0.95, blue: 0.99)

    // Text
    static let primaryText = Color(red: 0.10, green: 0.08, blue: 0.18)
    static let secondaryText = Color(red: 0.52, green: 0.49, blue: 0.62)

    // Accent surfaces
    static let purpleSurface = Color(red: 0.92, green: 0.89, blue: 0.99)

    // Destructive
    static let destructiveRose = Color(red: 0.85, green: 0.36, blue: 0.46)

    // Heatmap
    static let heatmapEmpty = Color(red: 0.92, green: 0.92, blue: 0.94)
}

// MARK: - Activity type colors (for heatmap)

extension ActivityType {
    var activityColor: Color {
        switch self {
        case .run:  return Color(red: 1.0, green: 0.58, blue: 0.0)   // orange
        case .gym:  return Color.brandPurple                          // purple
        case .pool: return Color(red: 0.20, green: 0.60, blue: 0.95) // blue
        }
    }
}

// MARK: - Shared style helpers

extension View {
    func appPrimaryButton() -> some View {
        font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.brandPurple)
            )
    }

    func appSecondaryButton() -> some View {
        font(.headline)
            .foregroundStyle(Color.brandPurple)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.purpleSurface)
            )
    }

    func appDestructiveButton() -> some View {
        font(.headline)
            .foregroundStyle(Color.destructiveRose)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.purpleSurface)
            )
    }

    func appCardBackground(cornerRadius: CGFloat = 16) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.cardBackground)
        )
        .shadow(color: Color.brandPurple.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - WeekdayPicker

struct WeekdayPicker: View {
    @Binding var selectedDays: Set<Int>

    /// Weekday indices (Calendar: 1=Sun, 2=Mon … 7=Sat) displayed Mon-first
    private static let orderedWeekdays: [(Int, String)] = [
        (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S"), (1, "S")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scheduled Days")
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            HStack(spacing: 8) {
                ForEach(Self.orderedWeekdays, id: \.0) { weekday, label in
                    let isSelected = selectedDays.contains(weekday)
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if isSelected { selectedDays.remove(weekday) }
                            else { selectedDays.insert(weekday) }
                        }
                    } label: {
                        Text(label)
                            .font(.caption.weight(.semibold))
                            .frame(width: 36, height: 36)
                            .foregroundStyle(isSelected ? .white : Color.brandPurple)
                            .background(
                                Circle()
                                    .fill(isSelected ? Color.brandPurple : Color.clear)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.brandPurple.opacity(isSelected ? 0 : 0.4), lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Convert a Set<Int> to a display string like "Mon, Wed, Fri"
    static func displayString(for days: Set<Int>) -> String {
        let names: [Int: String] = [1: "Sun", 2: "Mon", 3: "Tue", 4: "Wed", 5: "Thu", 6: "Fri", 7: "Sat"]
        let sorted = orderedWeekdays.map(\.0).filter { days.contains($0) }
        return sorted.compactMap { names[$0] }.joined(separator: ", ")
    }
}
