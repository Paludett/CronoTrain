import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: nil,
            isLogo: true,
            title: "Welcome to FitClock",
            subtitle: "Your smart workout timer, built for athletes."
        ),
        OnboardingPage(
            icon: "plus.circle.fill",
            isLogo: false,
            title: "Build Your Workouts",
            subtitle: "Create custom routines with exercises, sets, and rest periods tailored to your goals."
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            isLogo: false,
            title: "Track Your Progress",
            subtitle: "Earn XP, build streaks, and watch your rank grow with every session."
        ),
        OnboardingPage(
            icon: "flame.fill",
            isLogo: false,
            title: "Stay Consistent",
            subtitle: "Schedule your workouts by day and keep your streak alive."
        ),
        OnboardingPage(
            icon: "checkmark.circle.fill",
            isLogo: false,
            title: "You're All Set",
            subtitle: "Let's get moving."
        )
    ]

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page, isLastPage: index == pages.count - 1) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                hasSeenOnboarding = true
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.brandPurple : Color.brandPurple.opacity(0.25))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Page Data Model

private struct OnboardingPage {
    let icon: String?
    let isLogo: Bool
    let title: String
    let subtitle: String
}

// MARK: - Single Page View

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLastPage: Bool
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon or Logo
            if page.isLogo {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: Color.brandPurple.opacity(0.18), radius: 20, x: 0, y: 8)
            } else if let icon = page.icon {
                Image(systemName: icon)
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.brandPurple, Color.brandPurpleLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }

            Spacer()

            if isLastPage {
                Button(action: onGetStarted) {
                    Text("Get Started")
                        .appPrimaryButton()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            } else {
                // Keep spacing consistent across pages
                Color.clear
                    .frame(height: 56)
                    .padding(.bottom, 24)
            }
        }
        .padding(.top, 40)
    }
}
