import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var workoutDataManager: WorkoutDataManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(onStartWorkout: { selectedTab = 1 })
                .tabItem { EmptyView() }
                .tag(0)
            
            TimerView()
                .tabItem { EmptyView() }
                .tag(1)
            
            HistoryView()
                .tabItem { EmptyView() }
                .tag(2)
            
            ProfileView()
                .tabItem { EmptyView() }
                .tag(3)
        }
        .accentColor(Color(hex: "007AFF"))
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            UITabBar.appearance().isHidden = true
        }
        .overlay(
            CustomTabBar(selectedTab: $selectedTab),
            alignment: .bottom
        )
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        (icon: "house.fill", title: "Главная"),
        (icon: "timer", title: "Таймер"),
        (icon: "clock.arrow.circlepath", title: "История"),
        (icon: "person.fill", title: "Профиль")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 20, weight: .medium))
                        Text(tabs[index].title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(selectedTab == index ? Color(hex: "007AFF") : .gray)
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 5)
    }
}

#Preview {
    ContentView().environmentObject(WorkoutDataManager())
} 
