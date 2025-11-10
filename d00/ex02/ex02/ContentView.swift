import SwiftUI

// MARK: - Key Button

struct KeyButton: View {
    let label: String
    let action: (String) -> Void

    var body: some View {
        Button { action(label) } label: {
            Text(label)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle)
        .accessibilityLabel("Key \(label)")
    }
}

// MARK: - Content

struct ContentView: View {
    @State private var expression: String = "0"
    @State private var result: String = "0"
    @State private var headerHeight: CGFloat = 0 // we re-render the view when we rotate the device, thats why it is a @state

    private let keys: [String] = [
        "AC","C","/","*",
        "7","8","9","-",
        "4","5","6","+",
        "1","2","3","=",
        "0","."
    ]
    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 12) {
                        // --- Header (measured via background GeometryReader) ---
                        VStack(spacing: 5) {
                            TextField("", text: $expression)
                                .font(displayFont(geo: geo))
                                .multilineTextAlignment(.trailing)
                                .padding(.horizontal, 8)
                                .disabled(true)

                            TextField("", text: $result)
                                .font(displayFont(geo: geo))
                                .multilineTextAlignment(.trailing)
                                .padding(.horizontal, 8)
                                .disabled(true)
                        }
                        .background(
                            GeometryReader { g in
                                Color.clear
                                    // For ios < 17 (initial: true doesn't work)
                                    .onAppear { headerHeight = g.size.height }
                                    // iOs 17+ onChange two-parameter form
                                    .onChange(of: g.size.height, initial: true) { _, newHeight in
                                        headerHeight = newHeight
                                    }
                            }
                        )

                        // --- Keypad ---
                        let metrics = gridMetrics(geo: geo, headerHeight: headerHeight)

                        LazyVGrid(columns: columns, spacing: metrics.gridSpacing) {
                            ForEach(keys, id: \.self) { k in
                                KeyButton(label: k) { label in
                                    print(label)
                                }
                                .frame(height: max(36, metrics.cellHeight)) // don't let the grid become too big on big screens
                                .font(metrics.buttonFont)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 16)
                    .frame(minHeight: geo.size.height, alignment: .bottom)
                }
                .safeAreaPadding(.top)
            }
            .navigationTitle("Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 0.05, green: 0.3, blue: 0.7), for: .navigationBar)
        }
    }

    // MARK: - Sizing Helpers (inside the struct)

    func displayFont(geo: GeometryProxy) -> Font {
        let baselineHeight = geo.size.height / 4 - 18 // approximate height of each textfield
        let size = min(max(baselineHeight * 0.6, 18), 72) // don't let the text be too big or too small
        return Font.system(size: size)
    }

    func gridMetrics(geo: GeometryProxy, headerHeight: CGFloat)
        -> (rows: Int, cellHeight: CGFloat, buttonFont: Font, gridSpacing: CGFloat)
    {
        let gridSpacing: CGFloat = 5 // soace between buttons vertically
        let verticalPaddings: CGFloat = 16 + 24 // extra space at the top and at the bottom

        // Integer ceiling division: rows = ceil(keys/count per row)
        let rows = (keys.count + columns.count - 1) / columns.count

        let availableForGrid = geo.size.height - verticalPaddings - headerHeight
        let cellHeight = (availableForGrid - gridSpacing * CGFloat(rows - 1)) / CGFloat(rows)

        let buttonFontSize = max(18, min(44, cellHeight * 0.45)) // don't let the numbers be too big or too small
        let buttonFont = Font.system(size: buttonFontSize)
        return (rows, cellHeight, buttonFont, gridSpacing)
    }
}

// MARK: - Preview

#Preview { ContentView() }

