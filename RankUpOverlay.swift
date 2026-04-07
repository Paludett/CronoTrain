import SwiftUI

struct RankUpOverlay: View {
    let rank: Rank
    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 16) {
                Image(systemName: rank.iconName)
                    .font(.system(size: 56))
                    .foregroundStyle(rank.color)
                    .scaleEffect(showContent ? 1.0 : 0.3)
                    .opacity(showContent ? 1.0 : 0.0)

                Text("Rank Up! 🏆")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.primaryText)
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .opacity(showContent ? 1.0 : 0.0)

                Text("You've reached \(rank.rawValue)!")
                    .font(.headline)
                    .foregroundStyle(rank.color)
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .opacity(showContent ? 1.0 : 0.0)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.cardBackground)
            )
            .shadow(color: rank.color.opacity(0.3), radius: 24, x: 0, y: 8)
            .scaleEffect(showContent ? 1.0 : 0.7)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)
        }
        .allowsHitTesting(false)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                showContent = true
            }
        }
    }
}
