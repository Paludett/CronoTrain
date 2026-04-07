import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var store: WorkoutStore
    @EnvironmentObject private var sessionManager: WorkoutSessionManager
    @Binding var selectedTab: Int

    var body: some View {
        Group {
            if let workout = sessionManager.activeWorkout {
                WorkoutRunnerView(workout: workout, selectedTab: $selectedTab)
                    .id(sessionManager.sessionID)
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.28, green: 0.16, blue: 0.72), location: 0.0),
                    .init(color: Color(red: 0.44, green: 0.29, blue: 0.95).opacity(0.6), location: 0.25),
                    .init(color: Color(red: 0.62, green: 0.50, blue: 0.98).opacity(0.15), location: 0.55),
                    .init(color: Color.white.opacity(0.0), location: 0.78),
                    .init(color: Color.white, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()
                Text("No Active Session")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("Start a workout from Trains to begin your timer.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Button {
                    selectedTab = 1
                } label: {
                    Text("Go to Trains")
                        .appPrimaryButton()
                }
                .padding(.horizontal, 40)
                Spacer()
            }
        }
    }
}
