//
//  ContentView.swift
//  ex01
//
//  Created by Aleksandra Kachanova on 09/11/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var text: String = "A simple text"
    var body: some View {
        VStack {
            Text(
                text
            ).padding(10)
                .background(Color.green.opacity(0.6))
                .cornerRadius(10)
                .font(Font.largeTitle)
            Button("Click me") {
                if text == "A simple text" {
                    text = "Hello World"
                }
                else {
                    text = "A simple text"
                }
            }.padding(10)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(10)
            .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black, lineWidth: 1))
            .foregroundColor(Color.black)
        }
    }
}

#Preview {
    ContentView()
}
