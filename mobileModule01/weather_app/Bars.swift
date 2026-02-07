import SwiftUI

struct CustomTabBar: View {
    @Binding var selection: String

    var body: some View {
        HStack {
            Spacer()
            ForEach(tabs, id: \.title) { tab in
                Button {
                    selection = tab.title
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(tab.title == selection ? Color.blue : Color.gray)
                        Text(tab.title)
                            .lineLimit(1)
                            .foregroundStyle(tab.title == selection ? Color.blue : Color.gray)
                    }
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(15)
    }
}

struct SearchBar: View {
    @Binding var location: String
    @State private var input: String = ""

    var body: some View {
        HStack {
            Button {
                if !input.isEmpty {
                    location = input
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white)
                    .padding(10)
            }
            .background(Color.gray)
            .clipShape(Circle())

            TextField("Search", text: $input)
                .padding(7)
                .background(Color.white)
                .cornerRadius(10)
                .padding(10)
                .onSubmit {
                    if !input.isEmpty {
                        location = input
                    }
                }

            Button {
                location = "Geolocation"
            } label: {
                Image(systemName: "location.fill")
                    .foregroundColor(.white)
                    .padding(10)
            }
            .background(Color.gray)
            .clipShape(Circle())
        }
        .padding(10)
    }
}
