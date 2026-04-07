import SwiftUI
import UIKit

@main
struct MyApp: App {
    @StateObject private var store = WorkoutStore()
    @StateObject private var sessionManager = WorkoutSessionManager()
    @StateObject private var xpManager = XPManager()
    @StateObject private var historyManager = WorkoutHistoryManager()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var selectedTab: Int = 1
    @State private var showSplash: Bool = true

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.white)
        appearance.shadowColor = UIColor(Color.brandPurple.opacity(0.1))
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.secondaryText)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(selectedTab: $selectedTab)
                    .environmentObject(store)
                    .environmentObject(sessionManager)
                    .environmentObject(xpManager)
                    .environmentObject(historyManager)
                    .tint(.brandPurple)
                    .preferredColorScheme(.light)

                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }

                if !showSplash && !hasSeenOnboarding {
                    OnboardingView()
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .onAppear {
                MockDataSeeder.seedMockDataIfNeeded(
                    store: store,
                    xpManager: xpManager,
                    historyManager: historyManager
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}

// MARK: - Splash Screen

private struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color.deepPurple
                .ignoresSafeArea()

            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .offset(x: 10)
        }
    }
}
