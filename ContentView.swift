import SwiftUI

struct ContentView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            TimerView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Timer", systemImage: "clock")
                }
                .tag(0)

            TrainsView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Trains", systemImage: "pencil.and.list.clipboard")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(2)
        }
        .background(Color.appBackground)
    }
}
