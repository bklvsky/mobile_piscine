import SwiftUI

struct ContentView: View {
    @State private var selection = tabs[0].title
    @State private var location = ""

    var body: some View {
        VStack {
            TabView(selection: $selection) {
                ForEach(tabs, id: \.title) { tab in
                    WeatherView(location: $location, time: tab.title)
                    .tag(tab.title)
                }
            }.tabViewStyle(.page(indexDisplayMode: .never))
        }
        .safeAreaInset(edge: .top) {
            SearchBar(location: $location).background(.thinMaterial)
        }
        .safeAreaInset(edge: .bottom) {
            CustomTabBar(selection: $selection)
                .background(.thinMaterial)
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
}
