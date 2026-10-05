import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ClassesListView()
            }
            .ignoresSafeArea(.container, edges: .horizontal)
            .tabItem {
                Label("Classes", systemImage: "books.vertical.fill")
            }

            NavigationStack {
                QuizBrowserView()
            }
            .ignoresSafeArea(.container, edges: .horizontal)
            .tabItem {
                Label("Take a Quiz", systemImage: "bolt.fill")
            }

            NavigationStack {
                ProgressDashboardView()
            }
            .ignoresSafeArea(.container, edges: .horizontal)
            .tabItem {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
        .tint(.orange)
    }
}

#Preview {
    RootView()
}
