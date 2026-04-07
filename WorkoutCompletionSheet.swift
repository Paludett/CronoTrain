import SwiftUI

struct WorkoutCompletionSheet: View {
    var xpEarned: Int
    var onRestart: () -> Void
    var onFinish: () -> Void

    @State private var showXP = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Workout Complete 🎉")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.primaryText)

                Text("Great work! What would you like to do next?")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // Animated XP earned label
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundStyle(Color(red: 0.93, green: 0.79, blue: 0.28))
                    Text("+\(xpEarned) XP")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.brandPurple)
                }
                .scaleEffect(showXP ? 1.0 : 0.3)
                .opacity(showXP ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showXP)
                .padding(.top, 4)
            }

            VStack(spacing: 10) {
                Button {
                    onRestart()
                } label: {
                    Text("Restart Workout")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [Color.brandPurple, Color.brandPurpleDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button {
                    onFinish()
                } label: {
                    Text("Finish")
                        .font(.headline)
                        .foregroundStyle(Color.brandPurple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.purpleSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.cardBackground)
        )
        .shadow(color: Color.brandPurple.opacity(0.12), radius: 20, x: 0, y: 8)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showXP = true
            }
        }
    }
}
