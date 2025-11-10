import SwiftUI

// MARK: - Key Button

struct KeyButton: View {
    let label: String
    let action: (String) -> Void

    var body: some View {
        Button { action(label) } label: {
            Text(label)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
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
    @State private var headerHeight: CGFloat = 0

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
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.1)
                                .allowsTightening(true)
                                .multilineTextAlignment(.trailing)
                                .padding(.horizontal, 8)

                            TextField("", text: $result)
                                .font(displayFont(geo: geo))
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.1)
                                .allowsTightening(true)
                                .multilineTextAlignment(.trailing)
                                .padding(.horizontal, 8)
                                .disabled(true)
                        }
                        .background(
                            GeometryReader { g in
                                Color.clear
                                    .onAppear { headerHeight = g.size.height }
                                    // iOS 17+ onChange two-parameter form
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
                                    // TODO: wire real logic
                                    print(label)
                                }
                                .frame(height: max(36, metrics.cellHeight))
                                .font(metrics.buttonFont)
                                .monospacedDigit()
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
        let baselineHeight = geo.size.height / 4 - 18
        let size = min(max(baselineHeight * 0.6, 18), 72)
        return .system(size: size, design: .rounded)
    }

    func gridMetrics(geo: GeometryProxy, headerHeight: CGFloat)
        -> (rows: Int, cellHeight: CGFloat, buttonFont: Font, gridSpacing: CGFloat)
    {
        let gridSpacing: CGFloat = 5
        let verticalPaddings: CGFloat = 16 /*top*/ + 24 /*bottom*/

        // Integer ceiling division: rows = ceil(keys/count per row)
        let rows = (keys.count + columns.count - 1) / columns.count

        let availableForGrid = max(0, geo.size.height - verticalPaddings - headerHeight)
        let cellHeight = (availableForGrid - gridSpacing * CGFloat(rows - 1)) / CGFloat(rows)

        let buttonPointSize = max(18, min(44, cellHeight * 0.45))
        let buttonFont = Font.system(size: buttonPointSize, weight: .regular, design: .rounded)

        return (rows, cellHeight, buttonFont, gridSpacing)
    }
}

// MARK: - Preview

#Preview { ContentView() }
