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
    }
}

// MARK: - Content
struct ContentView: View {
    @State private var expression = "0"
    @State private var result = "0"
    @State private var headerHeight: CGFloat = 0
    @State private var showError = false

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
                        headerView(geo: geo)

                        let metrics = gridMetrics(geo: geo, headerHeight: headerHeight)

                        keypadView(metrics: metrics)
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 16)
                    .frame(minHeight: geo.size.height, alignment: .bottom)
                }
                .safeAreaPadding(.top)
                .navigationTitle("Calculator")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(Color(red: 0.05, green: 0.3, blue: 0.7), for: .navigationBar)
                .alert("Invalid input", isPresented: $showError) {
                    Button("OK", role: .cancel) { }
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func headerView(geo: GeometryProxy) -> some View {
        VStack(spacing: 5) {
            TextField("", text: $expression)
                .font(displayFont(geo: geo))
                .allowsTightening(true) // to let the digits be smaller when a string is big
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, 8)

            TextField("", text: $result)
                .font(displayFont(geo: geo))
                .allowsTightening(true)
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, 8)
                .disabled(true)
        }
        .background(
            GeometryReader { g in
                Color.clear
                    // With iOS 17’s two-parameter onChange + initial: true,
                    // onAppear is not strictly needed.
                    .onChange(of: g.size.height, initial: true) { _, newHeight in
                        headerHeight = newHeight
                    }
            }
        )
    }

    @ViewBuilder
    private func keypadView(metrics: (rows: Int, cellHeight: CGFloat, buttonFont: Font, gridSpacing: CGFloat)) -> some View {
        LazyVGrid(columns: columns, spacing: metrics.gridSpacing) {
            ForEach(keys, id: \.self) { k in
                KeyButton(label: k) { label in
                    handleKey(label)
                }
                .frame(height: max(36, metrics.cellHeight))
                .font(metrics.buttonFont)
            }
        }
    }

    // MARK: - Logic

    private func handleKey(_ label: String) {
        if result != "0" {
            let label_is_num = label.first?.isNumber
            if label_is_num == false {expression = result}
            result = "0"
            
        }
        switch label {
        case "AC":
            expression = "0"
            result = "0"

        case "C":
            expression.removeLast()

        case "=":
            let last = expression.last
            if last == "." {
                expression.append("0")
            }
            else if last?.isNumber == false {
                showError.toggle()
                return
            }
            
            result = compute_result()
        case ".":
            let token = currentNumber(in: expression)
            if currentHasDot(in: expression) {
                showError.toggle()
                return
            }
            else if token.last?.isNumber == false {
                expression.append("0") // autocomplete for trailing '.'
            }
            expression.append(label)

        case "-":
            let token = currentNumber(in: expression)
            if currentHasUnaryMinus(in: expression) {
                showError.toggle()
                return
            }
            if let last = token.last, last == "." {
                expression.append("0") // autocomplete trailing '.'
            }
            expression.append("-")
            
        default:
            let label_is_num = label.first?.isNumber
            let last_char_expression = expression.last
            // Prevent adding two operators in a row
            if expression == "0" && label_is_num == true {
                expression = ""
            }
            else if last_char_expression == "." && label_is_num == false {
                expression.append("0") // autocomplete
            }
            else if last_char_expression?.isNumber == false && label_is_num == false {
                showError.toggle()
                return
            }
            expression.append(contentsOf: label)
        }
    }

    // MARK: - Sizing Helpers

    func displayFont(geo: GeometryProxy) -> Font {
        let baselineHeight = geo.size.height / 4 - 18
        let size = min(max(baselineHeight * 0.6, 18), 72)
        return .system(size: size, design: .rounded)
    }

    func gridMetrics(geo: GeometryProxy, headerHeight: CGFloat)
        -> (rows: Int, cellHeight: CGFloat, buttonFont: Font, gridSpacing: CGFloat)
    {
        let gridSpacing: CGFloat = 5
        let verticalPaddings: CGFloat = 16 + 24
        let rows = (keys.count + columns.count - 1) / columns.count
        let availableForGrid = max(0, geo.size.height - verticalPaddings - headerHeight)
        let cellHeight = (availableForGrid - gridSpacing * CGFloat(rows - 1)) / CGFloat(rows)
        let buttonPointSize = max(18, min(44, cellHeight * 0.45))
        let buttonFont = Font.system(size: buttonPointSize, weight: .regular, design: .rounded)
        return (rows, cellHeight, buttonFont, gridSpacing)
    }


    // Helpers — put inside ContentView
    private func currentNumberRange(in s: String) -> Range<String.Index> {
        let end = s.endIndex
        var i = end
        while i > s.startIndex {
            let prev = s.index(before: i)
            let c = s[prev]
            if "+*/".contains(c) {
                return s.index(after: prev)..<end
            }
            if c == "-" {
                // If the '-' is binary (char before it is a digit or '.'),
                // we stop here; otherwise it's unary and part of the number.
                if prev > s.startIndex {
                    let before = s[s.index(before: prev)]
                    if before.isNumber || before == "." {
                        return s.index(after: prev)..<end
                    }
                }
                // unary '-', keep scanning
            }
            i = prev
        }
        return s.startIndex..<end
    }

    private func currentNumber(in s: String) -> String {
        String(s[currentNumberRange(in: s)])
    }

    private func currentHasDot(in s: String) -> Bool {
        currentNumber(in: s).contains(".")
    }

    private func currentHasUnaryMinus(in s: String) -> Bool {
        let token = currentNumber(in: s)
        return token.first == "-"
    }

    
// MARK: - Compute

    private enum CalcError: Error {
        case empty
        case invalidToken
        case malformedNumber
        case trailingOperator
        case divisionByZero
        case notFinite
    }

    private enum Token {
        case number(Double)
        case op(Character)
    }

    func compute_result() -> String {
        do {
            let toks = try tokenize(expression)
            let rpn  = try toRPN(toks)
            let val  = try evalRPN(rpn)
            guard val.isFinite else { throw CalcError.notFinite }
            // Nice formatting: drop trailing .0 (e.g., 42.0 -> 42)
            let s = String(val)
            if s.hasSuffix(".0") { return String(s.dropLast(2)) }
            return s
        } catch CalcError.divisionByZero {
            return "Error: ÷0"
        } catch CalcError.trailingOperator {
            return "Error: trailing operator"
        } catch CalcError.malformedNumber {
            return "Error: bad number"
        } catch {
            return "Error"
        }
    }

    // Turn the input string into tokens, handling unary minus.
    private func tokenize(_ s: String) throws -> [Token] {
        let chars = Array(s.trimmingCharacters(in: .whitespaces))
        if chars.isEmpty { throw CalcError.empty }

        var i = 0
        var out: [Token] = []
        var prevWasOperator = true // start allows unary minus

        func readNumber(startSign: Bool) throws -> Token {
            var j = i
            var numStr = ""
            var sawDot = false

            if startSign, j < chars.count, chars[j] == "-" {
                numStr.append("-")
                j += 1
            }
            // allow leading dot: ".5"
            while j < chars.count {
                let c = chars[j]
                if c.isNumber {
                    numStr.append(c)
                    j += 1
                } else if c == "." {
                    if sawDot { throw CalcError.malformedNumber }
                    sawDot = true
                    numStr.append(c)
                    j += 1
                } else {
                    break
                }
            }

            // Validate number shape: "-", ".", "-.", "" are invalid
            if numStr == "-" || numStr == "." || numStr == "-." || numStr.isEmpty {
                throw CalcError.malformedNumber
            }
            guard let v = Double(numStr), v.isFinite else { throw CalcError.malformedNumber }
            i = j
            return .number(v)
        }

        while i < chars.count {
            let c = chars[i]

            if c.isWhitespace {
                i += 1
                continue
            }

            if c.isNumber || c == "." || (c == "-" && prevWasOperator) {
                // number (possibly with unary -)
                let tok = try readNumber(startSign: prevWasOperator && c == "-")
                out.append(tok)
                prevWasOperator = false
                continue
            }

            if "+-*/".contains(c) {
                // prevent two operators in a row (except unary minus, handled above)
                if prevWasOperator { throw CalcError.invalidToken }
                out.append(.op(c))
                prevWasOperator = true
                i += 1
                continue
            }

            // Any other character is invalid
            throw CalcError.invalidToken
        }

        // If expression ends with an operator -> error
        if case .op = out.last { throw CalcError.trailingOperator }

        return out
    } // TBD : remove duplicating checks

    // Shunting-yard: infix -> RPN
    private func toRPN(_ tokens: [Token]) throws -> [Token] {
        var output: [Token] = []
        var stack: [Character] = []

        func prec(_ op: Character) -> Int {
            switch op {
            case "*", "/": return 2
            case "+", "-": return 1
            default: return 0
            }
        }

        for t in tokens {
            switch t {
            case .number:
                output.append(t)
            case .op(let op):
                while let top = stack.last, prec(top) >= prec(op) {
                    output.append(.op(stack.removeLast()))
                }
                stack.append(op)
            }
        }
        while let op = stack.popLast() {
            output.append(.op(op))
        }
        return output
    }

    // Evaluate RPN safely with Double, detecting divide-by-zero / non-finite.
    private func evalRPN(_ rpn: [Token]) throws -> Double {
        var st: [Double] = []
        for t in rpn {
            switch t {
            case .number(let v):
                st.append(v)
            case .op(let op):
                guard st.count >= 2 else { throw CalcError.invalidToken }
                let rhs = st.removeLast()
                let lhs = st.removeLast()
                let res: Double
                switch op {
                case "+": res = lhs + rhs
                case "-": res = lhs - rhs
                case "*": res = lhs * rhs
                case "/":
                    if rhs == 0 { throw CalcError.divisionByZero }
                    res = lhs / rhs
                default:
                    throw CalcError.invalidToken
                }
                guard res.isFinite else { throw CalcError.notFinite }
                // TBD: what does the notFinite do?
                st.append(res)
            }
        }
        guard st.count == 1 else { throw CalcError.invalidToken }
        return st[0]
    }
}

// MARK: - Preview
#Preview { ContentView() }
