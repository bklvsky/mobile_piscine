import SwiftUI


let tabs: [(title: String, systemImage: String)] = [
    ("Currently", "cloud.sun"),
    ("Today", "calendar"),
    ("Weekly", "calendar.badge.clock")
]

struct WeatherView: View {
    @Binding var location: String
    let time: String

    var body: some View {
        VStack {
            Text(time).font(.largeTitle)
            if !location.isEmpty {
                Text(location).font(.largeTitle)
            }
        }
    }
}
